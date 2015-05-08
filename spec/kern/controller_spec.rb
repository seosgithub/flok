#Anything and everything to do with view controllers (not directly UI) above the driver level

Dir.chdir File.join File.dirname(__FILE__), '../../'
require './spec/env/kern.rb'
require './spec/lib/helpers.rb'
require './spec/lib/io_extensions.rb'
require './spec/lib/rspec_extensions.rb'

RSpec.describe "kern:controller_spec" do
  include_context "kern"

  #Can initialize a controller via embed and have the correct if_dispatch messages
  it "Can initiate a controller via _embed" do
    #Compile the controller
    ctx = flok_new_user File.read('./spec/kern/assets/controller0.rb')

    #Run the embed function
    ctx.eval %{
      //Call embed on main root view
      base = _embed("my_controller", 0, {});

      //Drain queue
      int_dispatch([]);
    }

    base = ctx.eval("base")

    @driver.mexpect("if_init_view", ["test_view", {}, base, ["main", "hello", "world"]])
    @driver.mexpect("if_attach_view", [base, 0])
  end

  it "Can initiate a controller via _embed and have a controller_info located in tel table" do
    #Compile the controller
    ctx = flok_new_user File.read('./spec/kern/assets/controller0.rb')

    #Run the embed function
    ctx.eval %{
      //Call embed on main root view
      base = _embed("my_controller", 0, {});

      //Drain queue
      int_dispatch([]);
    }

    base = ctx.eval("base")
    ctx.eval %{ 
      info = tel_deref(#{base})
    }

    info = ctx.eval("info")
    expect(info).not_to eq(nil)

    #Should have the right set of keys in the controller info
    ctx.eval %{
      context = info.context
      action = info.action
      cte = info.cte
    }

    expect(ctx.eval('context')).not_to eq(nil)
    expect(ctx.eval('action')).not_to eq(nil)
    expect(ctx.eval('cte')).not_to eq(nil)
  end

  it "calls on_entry with the base pointer when a controller is embedded for the initial action" do
    #Compile the controller
    ctx = flok_new_user File.read('./spec/kern/assets/controller0.rb')

    #Run the embed function
    ctx.eval %{
      //Call embed on main root view
      base = _embed("my_controller", 0, {});

      //Drain queue
      int_dispatch([]);
    }

    expect(ctx.eval('on_entry_base_pointer')).to eq(ctx.eval("base"))
  end

  it "calls on_entry with the base pointer when a controller is embedded for the initial action" do
    #Compile the controller
    ctx = flok_new_user File.read('./spec/kern/assets/controller0.rb')

    #Run the embed function
    ctx.eval %{
      //Call embed on main root view
      base = _embed("my_controller", 0, {});

      //Drain queue
      int_dispatch([]);
    }

    expect(ctx.eval('on_entry_base_pointer')).to eq(ctx.eval("base"))
  end
end
