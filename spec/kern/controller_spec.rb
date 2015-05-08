#Anything and everything to do with view controllers (not directly UI) above the driver level

Dir.chdir File.join File.dirname(__FILE__), '../../'
require './spec/env/kern.rb'
require './spec/lib/helpers.rb'
require './spec/lib/io_extensions.rb'
require './spec/lib/rspec_extensions.rb'

RSpec.describe "kern:controller_spec" do
  include_context "kern"

  ##Can initialize a controller via embed and have the correct if_dispatch messages
  #it "Can initiate a controller via _embed" do
    ##Compile the controller
    #ctx = flok_new_user File.read('./spec/kern/assets/controller0.rb')

    ##Run the embed function
    #ctx.eval %{
      #//Call embed on main root view
      #base = _embed("my_controller", 0, {});

      #//Drain queue
      #int_dispatch([]);
    #}

    #base = ctx.eval("base")

    #@driver.mexpect("if_init_view", ["test_view", {}, base, ["main", "hello", "world"]])
    #@driver.mexpect("if_attach_view", [base, 0])
  #end

  #it "Can initiate a controller via _embed and have a controller_info located in tel table" do
    ##Compile the controller
    #ctx = flok_new_user File.read('./spec/kern/assets/controller0.rb')

    ##Run the embed function
    #ctx.eval %{
      #//Call embed on main root view
      #base = _embed("my_controller", 0, {});

      #//Drain queue
      #int_dispatch([]);
    #}

    #base = ctx.eval("base")
    #ctx.eval %{ 
      #info = tel_deref(#{base})
    #}

    #info = ctx.eval("info")
    #expect(info).not_to eq(nil)

    ##Should have the right set of keys in the controller info
    #ctx.eval %{
      #context = info.context
      #action = info.action
      #cte = info.cte
    #}

    #expect(ctx.eval('context')).not_to eq(nil)
    #expect(ctx.eval('action')).not_to eq(nil)
    #expect(ctx.eval('cte')).not_to eq(nil)
  #end

  #it "calls on_entry with the base pointer when a controller is embedded for the initial action" do
    ##Compile the controller
    #ctx = flok_new_user File.read('./spec/kern/assets/controller0.rb')

    ##Run the embed function
    #ctx.eval %{
      #//Call embed on main root view
      #base = _embed("my_controller", 0, {});

      #//Drain queue
      #int_dispatch([]);
    #}

    #expect(ctx.eval('on_entry_base_pointer')).to eq(ctx.eval("base"))
  #end

  #it "calls on_entry with the base pointer when a controller is embedded for the initial action" do
    ##Compile the controller
    #ctx = flok_new_user File.read('./spec/kern/assets/controller0.rb')

    ##Run the embed function
    #ctx.eval %{
      #//Call embed on main root view
      #base = _embed("my_controller", 0, {});

      #//Drain queue
      #int_dispatch([]);
    #}

    #expect(ctx.eval('on_entry_base_pointer')).to eq(ctx.eval("base"))
  #end

  #it "can embed a controller within a controller and put the right views in" do
    ##Compile the controller
    #ctx = flok_new_user File.read('./spec/kern/assets/controller1.rb')

    ##Run the embed function
    #ctx.eval %{
      #//Call embed on main root view
      #base = _embed("my_controller", 0, {});

      #//Drain queue
      #int_dispatch([]);
    #}

    #base = ctx.eval('base')

    ##First, we expect the base vc to be setup as a view
    #@driver.mexpect("if_init_view", ["test_view", {}, base, ["main", "hello", "world"]])
    #@driver.mexpect("if_attach_view", [base, 0])

    ##Now we expect the embedded view to be setup as a view within the base view
    ##+3 because it's after the base view and the base has two spots
    ##+1 on the base because we should have emebedded in the 'hello' spot per controller1.rb
    #@driver.mexpect("if_init_view", ["test_view2", {}, base+3, ["main", "hello", "world"]])
    #@driver.mexpect("if_attach_view", [base+3, base+1])
  #end

  #it "can embed a controller within a controller and allocate the correct view controller instance" do
    ##Compile the controller
    #ctx = flok_new_user File.read('./spec/kern/assets/controller1.rb')

    ##Run the embed function
    #ctx.eval %{
      #//Call embed on main root view
      #base = _embed("my_controller", 0, {});

      #//Drain queue
      #int_dispatch([]);
    #}

    #base = ctx.eval('base')

    ##+3 because it's after the base view (has two spots)
    #ctx.eval %{ 
      #info = tel_deref(#{base+3})     
    #}

    #info = ctx.eval("info")
    #expect(info).not_to eq(nil)
  #end

  #it "calls on_entry with the base pointer when the sub_controller is embedded" do
    ##Compile the controller
    #ctx = flok_new_user File.read('./spec/kern/assets/controller1.rb')

    ##Run the embed function
    #ctx.eval %{
      #//Call embed on main root view
      #base = _embed("my_controller", 0, {});

      #//Drain queue
      #int_dispatch([]);
    #}

    ##+3 because the base has 2 spots, so it should have incremented to 3
    #expect(ctx.eval('on_entry_base_pointer')).to eq(ctx.eval("base")+3)
  #end

  #it "Can receive 'test_event' destined for the controller and set a variable" do
    ##Compile the controller
    #ctx = flok_new_user File.read('./spec/kern/assets/event_test.rb')

    ##Run the embed function
    #ctx.eval %{
      #//Call embed on main root view
      #base = _embed("my_controller", 0, {});

      #//Drain queue with test event
      #int_dispatch([3, "int_event", base, "test_event", {}]);
    #}

    ##Now we expect some variables to be set in the action
    #expect(ctx.eval("test_action_called_base")).not_to eq(nil)
    #expect(ctx.eval("test_action_called_params")).not_to eq(nil)
  #end

  #it "Can initiate a controller via _embed and have a tracked list of embeds in info" do
    ##Compile the controller
    #ctx = flok_new_user File.read('./spec/kern/assets/controller1.rb')

    ##Run the embed function
    #ctx.eval %{
      #//Call embed on main root view
      #base = _embed("my_controller", 0, {});

      #//Drain queue
      #int_dispatch([]);
    #}

    #base = ctx.eval("base")
    #ctx.eval %{ 
      #info = tel_deref(#{base})
    #}

    ##Should have the right set of keys in the controller info
    #ctx.eval %{
      #embeds = JSON.stringify(info.embeds)
    #}
    #embeds = JSON.parse(ctx.eval("embeds"))

    ##Expect base+3 because it's the vc itself, not the spot it's in
    #expect(embeds).to eq([base+3])
  #end

  #it "Can receive 'test_event' and change actions" do
    ##Compile the controller
    #ctx = flok_new_user File.read('./spec/kern/assets/goto.rb')

    ##Run the embed function
    #ctx.eval %{
      #//Call embed on main root view
      #base = _embed("my_controller", 0, {});

      #//Drain queue with test event
      #int_dispatch([3, "int_event", base, "test_event", {}]);
    #}

    ##Now we expect the action for the controller to be 'my_other_action' and for it's on_entry
    ##to be called
    #expect(ctx.eval("my_other_action_on_entry_called")).not_to eq(nil)
  #end

  it "Does tear down the old embedded view from the embedded view controller when switching actions" do
    #Compile the controller
    ctx = flok_new_user File.read('./spec/kern/assets/goto.rb')

    #Run the embed function
    ctx.eval %{
      //Call embed on main root view
      base = _embed("my_controller", 0, {});

      //Drain queue with test event
      int_dispatch([3, "int_event", base, "test_event", {}]);
    }

    base = ctx.eval("base")

    #Expect that a view was embedded inside a view at this point
    @driver.mexpect("if_init_view", ["test_view", {}, base, ["main", "hello", "world"]])
    @driver.mexpect("if_attach_view", [base, 0])
    @driver.mexpect("if_init_view", ["test_view2", {}, base+3, ["main"]])
    @driver.mexpect("if_attach_view", [base+3, base+1])

    #And then the request to switch views with the 'test_event' removed the second view
    @driver.mexpect("if_free_view", [base+3])
  end
end
