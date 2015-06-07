#Anything and everything to do with view controllers (not directly UI) above the driver level

Dir.chdir File.join File.dirname(__FILE__), '../../'
require './spec/env/kern.rb'
require './spec/lib/helpers.rb'
require './spec/lib/io_extensions.rb'
require './spec/lib/rspec_extensions.rb'

RSpec.describe "kern:vm_service" do
  include_context "kern"

 #it "Can be used inside a controller" do
    ##Compile the controller
    #ctx = flok_new_user File.read('./spec/kern/assets/vm/controller0.rb'), File.read("./spec/kern/assets/vm/config0.rb")

    ##Run the embed function
    #ctx.eval %{
      #//Call embed on main root view
      #base = _embed("my_controller", 0, {}, null);

      #//Drain queue
      #int_dispatch([]);
    #}

    #base = ctx.eval("base")
    #res = ctx.eval("vm_did_wakeup")
    #expect(res).to eq(true)
  #end

 it "Can include the spec0 pager and call read_sync" do
    #Compile the controller
    ctx = flok_new_user File.read('./spec/kern/assets/vm/controller1.rb'), File.read("./spec/kern/assets/vm/config1.rb")

    #Run the embed function
    ctx.eval %{
      //Call embed on main root view
      base = _embed("my_controller", 0, {}, null);

      //Drain queue
      int_dispatch([]);
    }

    #Verify that the vm service is getting the read_sync request
    res = ctx.eval("vm_read_sync_called")
    expect(res).to eq(true)

    #Verify that the vm service is disptaching the request
    res = ctx.eval("spec0_read_sync_called")
    expect(res).to eq(true)
  end
end
