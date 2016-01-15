#Everything to do with the 'share' and 'map_share' helpers

Dir.chdir File.join File.dirname(__FILE__), '../../'
require './spec/env/kern.rb'
require './spec/lib/helpers.rb'
require './spec/lib/io_extensions.rb'
require './spec/lib/rspec_extensions.rb'

RSpec.describe "kern:controller_share_spec" do
  include_context "kern"

  it "Can use the share & map_share functions within a controller" do
    #Compile the controller
    ctx = flok_new_user File.read('./spec/kern/assets/share/controller0.rb')

    #Run the embed function
    ctx.eval %{
      //Call embed on main root view
      base = _embed("foo", 0, {}, null);

      //Drain queue
      int_dispatch([]);
    }

    base = ctx.eval("base")

    @driver.mexpect("if_init_view", ["foo", {}, base+1, ["main", "content"]])
  end

  it "Can access the shared properties in the sharing controller" do
    #Compile the controller
    ctx = flok_new_user File.read('./spec/kern/assets/share/controller1.rb')

    #Run the embed function
    ctx.eval %{
      //Call embed on main root view
      base = _embed("foo", 0, {}, null);

      //Drain queue
      int_dispatch([]);
    }

    base = ctx.eval("base")

    @driver.mexpect("if_init_view", ["foo", {}, base+1, ["main", "content"]])
    expect(JSON.parse(ctx.eval("JSON.stringify(foo_shared_user)"))).to eq({"uid" => "foo"})
  end

  it "Can access the shared properties in the embedded controller" do
    #Compile the controller
    ctx = flok_new_user File.read('./spec/kern/assets/share/controller1.rb')

    #Run the embed function
    ctx.eval %{
      //Call embed on main root view
      base = _embed("foo", 0, {}, null);

      //Drain queue
      int_dispatch([]);
    }

    base = ctx.eval("base")

    expect(JSON.parse(ctx.eval("JSON.stringify(bar_shared_user)"))).to eq({"uid" => "foo"})
    @driver.mexpect("if_init_view", ["foo", {}, base+1, ["main", "content"]])
  end

  it "Can use the share_spot & map_shared_spot functions within a controller" do
    #Compile the controller
    ctx = flok_new_user File.read('./spec/kern/assets/share/controller0_spot.rb')

    #Run the embed function
    ctx.eval %{
      //Call embed on main root view
      base = _embed("foo", 0, {}, null);

      //Drain queue
      int_dispatch([]);
    }

    base = ctx.eval("base")

    @driver.mexpect("if_init_view", ["foo", {}, base+1, ["main", "content"]])
  end

  it "Does result in the spot being embedded within 'foo' hierarchy" do
    #Compile the controller
    ctx = flok_new_user File.read('./spec/kern/assets/share/controller0_spot.rb')

    #Run the embed function
    ctx.eval %{
      //Call embed on main root view
      base = _embed("foo", 0, {}, null);

      //Drain queue
      int_dispatch([]);
    }

    foo_base = ctx.eval("foo_base")
    hello_base = ctx.eval("hello_bp")
    bar_base = ctx.eval("bar_base")

    #First foo => root
    @driver.ignore_up_to "if_attach_view"
    @driver.mexpect "if_attach_view", [foo_base+1, 0]

    #Then we expect bar => foo.content
    @driver.ignore_up_to "if_attach_view"
    @driver.mexpect "if_attach_view", [bar_base+1, foo_base+2]

    #Here's the special one, foo is a mapped space so
    #hello => foo.content
    @driver.ignore_up_to "if_attach_view"
    @driver.mexpect("if_attach_view", [hello_base+1, foo_base+2])
  end

  it "When switching via Goto to actions, the shared spot's view is destroyed based on the sub-controllers lifetime for a view that's in the middle of the hierarchy (because free only effects top-most views from the pivot of the spot, we embed a shared spot which must be destroyed by itself)" do
    #Compile the controller
    ctx = flok_new_user File.read('./spec/kern/assets/share/controller2_spot.rb')

    #Run the embed function
    ctx.eval %{
      //Call embed on main root view
      base = _embed("foo", 0, {}, null);

      //Drain queue
      int_dispatch([]);
    }

    foo_base = ctx.eval("foo_base")
    hello_base = ctx.eval("hello_bp")
    bar_base = ctx.eval("bar_base")
    bar2_base = ctx.eval("bar2_base")


    #First foo => root
    @driver.ignore_up_to "if_attach_view"
    @driver.mexpect "if_attach_view", [foo_base+1, 0]

    #Then we expect bar => foo.content
    @driver.ignore_up_to "if_attach_view"
    @driver.mexpect "if_attach_view", [bar_base+1, foo_base+2]

    #Then we expect bar2 => bar.content
    @driver.ignore_up_to "if_attach_view"
    @driver.mexpect "if_attach_view", [bar2_base+1, bar_base+2]

    #Here's the special one, bar
    #hello => foo.content
    @driver.ignore_up_to "if_attach_view"
    @driver.mexpect("if_attach_view", [hello_base+1, foo_base+2])

    #Next, should destroy hierarchy below bar
    @driver.int "int_event", [bar_base, "next_clicked", {}]

    #Should free bar2
    @driver.ignore_up_to "if_free_view"
    @driver.mexpect("if_free_view", [bar2_base+1])

    #Should free hello as it's lifetime is bound to bar2
    @driver.ignore_up_to "if_free_view"
    @driver.mexpect("if_free_view", [hello_base+1])
  end

  it "When pushing & popping actions, the shared spot's view is not destroyed during the push pop phase" do
    #Compile the controller
    ctx = flok_new_user File.read('./spec/kern/assets/share/controller3_spot.rb')

    #Run the embed function
    ctx.eval %{
      //Call embed on main root view
      base = _embed("foo", 0, {}, null);

      //Drain queue
      int_dispatch([]);
    }

    foo_base = ctx.eval("foo_base")
    hello_base = ctx.eval("hello_bp")
    bar_base = ctx.eval("bar_base")
    bar2_base = ctx.eval("bar2_base")

    #First foo => root
    @driver.ignore_up_to "if_attach_view"
    @driver.mexpect "if_attach_view", [foo_base+1, 0]

    #Then we expect bar => foo.content
    @driver.ignore_up_to "if_attach_view"
    @driver.mexpect "if_attach_view", [bar_base+1, foo_base+2]

    #Then we expect bar2 => bar.content
    @driver.ignore_up_to "if_attach_view"
    @driver.mexpect "if_attach_view", [bar2_base+1, bar_base+2]

    #Here's the special one, bar
    #hello => foo.content
    @driver.ignore_up_to "if_attach_view"
    @driver.mexpect("if_attach_view", [hello_base+1, foo_base+2])

    #Next, should destroy hierarchy below bar
    @driver.int "int_event", [bar_base, "next_clicked", {}]
    @driver.int "int_event", [bar_base, "back_clicked", {}]

    hello2_base = ctx.eval("hello2_bp")

    #Should free hello as it's lifetime is bound to bar2
    @driver.ignore_up_to "if_free_view"
    @driver.mexpect("if_free_view", [hello2_base+1])

    #Should receieve no more frees
    expect {
      @driver.ignore_up_to "if_free_view"
    }.to raise_error /Waited/

    #Now do the second 'next_clicked' which is a Goto
    @driver.int "int_event", [bar_base, "next2_clicked", {}]

    #Should free bar2
    @driver.ignore_up_to "if_free_view"
    @driver.mexpect("if_free_view", [bar2_base+1])

    #Should free hello as it's lifetime is bound to bar2
    @driver.ignore_up_to "if_free_view"
    @driver.mexpect("if_free_view", [hello_base+1])
  end
end
