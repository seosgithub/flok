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

  it "can embed a controller within a controller and put the right views in" do
    #Compile the controller
    ctx = flok_new_user File.read('./spec/kern/assets/controller1.rb')

    #Run the embed function
    ctx.eval %{
      //Call embed on main root view
      base = _embed("my_controller", 0, {});

      //Drain queue
      int_dispatch([]);
    }

    base = ctx.eval('base')

    #First, we expect the base vc to be setup as a view
    @driver.mexpect("if_init_view", ["test_view", {}, base, ["main", "hello", "world"]])
    @driver.mexpect("if_attach_view", [base, 0])

    #Now we expect the embedded view to be setup as a view within the base view
    #+3 because it's after the base view and the base has two spots
    #+1 on the base because we should have emebedded in the 'hello' spot per controller1.rb
    @driver.mexpect("if_init_view", ["test_view2", {}, base+3, ["main", "hello", "world"]])
    @driver.mexpect("if_attach_view", [base+3, base+1])
  end

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

end
