#Anything and everything to do with view controllers (not directly UI) above the driver level

Dir.chdir File.join File.dirname(__FILE__), '../../'
require './spec/env/kern.rb'
require './spec/lib/helpers.rb'
require './spec/lib/io_extensions.rb'
require './spec/lib/rspec_extensions.rb'

RSpec.describe "kern:controller_sticky_action_spec" do
  include_context "kern"

  it "Can use the sticky_action actions" do
    #Compile the controller
    ctx = flok_new_user File.read('./spec/kern/assets/sticky_action/a.rb')

    #Run the embed function
    dump = ctx.evald %{
      //Call embed on main root view
      base = _embed("foo", 0, {}, null);
    }
  end

  it "Going to an action from a sticky action does not result in the previous action releasing it's views, but it does hide them" do
    #Compile the controller
    ctx = flok_new_user File.read('./spec/kern/assets/sticky_action/a.rb')

    #Run the embed function
    dump = ctx.evald %{
      //Call embed on main root view
      _embed("foo", 0, {}, null);
    }
    foo_base = ctx.eval("foo_base")
    bar_base = ctx.eval("bar_base")
    bar2_base = ctx.eval("bar2_base")

    @driver.int "int_event", [foo_base, "next_clicked", {}]

    #Expect it not to have a free
    expect {
      @driver.ignore_up_to "if_free_view"
    }.to raise_error /Waited/

    ##Should have hidden the views contained in the spots
    @driver.ignore_up_to "if_hide_view"
    expect(@driver.get "if_hide_view").to eq([bar_base+1, true])

    #Should have hidden the views contained in the spots
    @driver.ignore_up_to "if_hide_view"
    expect(@driver.get "if_hide_view").to eq([bar2_base+1, true])
  end

  it "Going to an action from a sticky action, and then back to the original action, does re-show all the views implicated in the original sticky action" do
    #Compile the controller
    ctx = flok_new_user File.read('./spec/kern/assets/sticky_action/a.rb')

    #Run the embed function
    dump = ctx.evald %{
      //Call embed on main root view
      _embed("foo", 0, {}, null);
    }
    foo_base = ctx.eval("foo_base")
    bar_base = ctx.eval("bar_base")
    bar2_base = ctx.eval("bar2_base")

    @driver.int "int_event", [foo_base, "next_clicked", {}]
    @driver.int "int_event", [foo_base, "back_clicked", {}]

    hello_base = ctx.eval("hello_base")

    #Expect a free of hello
    @driver.ignore_up_to "if_free_view"
    expect(@driver.get "if_free_view").to eq([hello_base+1])

    #Should have shown the views that were previously hidden
    @driver.ignore_up_to "if_hide_view"
    expect(@driver.get "if_hide_view").to eq([bar_base+1, false])

    #Should have shown the views that were previously hidden
    @driver.ignore_up_to "if_hide_view"
    expect(@driver.get "if_hide_view").to eq([bar2_base+1, false])
  end

  it "Going to a sticky_action from a sticky action, and then back to the original action, does re-show all the views implicated in the original sticky action and hide all the views from the second sticky_action" do
    #Compile the controller
    ctx = flok_new_user File.read('./spec/kern/assets/sticky_action/a.rb')

    #Run the embed function
    dump = ctx.evald %{
      //Call embed on main root view
      _embed("foo", 0, {}, null);
    }
    foo_base = ctx.eval("foo_base")
    bar_base = ctx.eval("bar_base")
    bar2_base = ctx.eval("bar2_base")

    @driver.int "int_event", [foo_base, "next2_clicked", {}]
    bar3_base = ctx.eval("bar3_base")

    #Should hide the views in a (bar & bar2) and create the views of c (bar3)
    @driver.ignore_up_to "if_hide_view"
    expect(@driver.get "if_hide_view").to eq([bar_base+1, true])
    expect(@driver.get "if_hide_view").to eq([bar2_base+1, true])

    #Should have created a new view for c
    @driver.ignore_up_to "if_init_view"
    expect(@driver.get("if_init_view")[0]).to eq("bar3")

    #Now we go 'back' to 'a'
    @driver.int "int_event", [foo_base, "back_clicked", {}]

    #No views should have been released
    expect {
      @driver.ignore_up_to "if_free_view"
    }.to raise_error /Waited/

    #Should now hide the views of c
    @driver.ignore_up_to "if_hide_view"
    expect(@driver.get "if_hide_view").to eq([bar3_base+1, true])

    #And show the views of 'a'
    @driver.ignore_up_to "if_hide_view"
    expect(@driver.get "if_hide_view").to eq([bar_base+1, false])
    expect(@driver.get "if_hide_view").to eq([bar2_base+1, false])

    #Now, switch *again* to 'c'
    @driver.int "int_event", [foo_base, "next2_clicked", {}]

    #No views should have been created as we recover it from the heap
    expect {
      @driver.ignore_up_to "if_init_view"
    }.to raise_error /Waited/

    #Should hide the views in a (bar & bar2) and create the views of c (bar3)
    @driver.ignore_up_to "if_hide_view"
    expect(@driver.get "if_hide_view").to eq([bar_base+1, true])
    expect(@driver.get "if_hide_view").to eq([bar2_base+1, true])


    #Should show the views in c
    @driver.ignore_up_to "if_hide_view"
    expect(@driver.get "if_hide_view").to eq([bar3_base+1, false])
  end
  
  #it "Dumping a controller that loaded a sticky_action will dump all the views of the sticky action when the controller is removed" do
    ##Compile the controller
    #ctx = flok_new_user File.read('./spec/kern/assets/sticky_action/b.rb')

    ##Run the embed function
    #dump = ctx.evald %{
      #//Call embed on main root view
      #_embed("foo", 0, {}, null);
    #}
    #foo_base = ctx.eval("foo_base")
    #bar_base = ctx.eval("bar_base")

    ##Cause bar to switch to 'about' action and sticky embed hello
    #@driver.int "int_event", [bar_base, "next_clicked", {}]
    #hello_base = ctx.eval("hello_base")

    ##Switch bar back to index, which will just hide hello
    #@driver.int "int_event", [bar_base, "back_clicked", {}]

    ##Should not have destroyed hello
    #expect {
      #@driver.ignore_up_to "if_free_view"
    #}.to raise_error /Waited/

    ##Switch foo to 'about', destroying bar controller
    #@driver.int "int_event", [foo_base, "next_clicked", {}]

    ##Should have destroyed bar controller
    #@driver.ignore_up_to "if_free_view"
    #expect(@driver.get("if_free_view")[0]).to eq(bar_base+1)

    ##Should have destroyed hello controller
    #@driver.ignore_up_to "if_free_view"
    #expect(@driver.get("if_free_view")[0]).to eq(hello_base+1)
  #end

end
