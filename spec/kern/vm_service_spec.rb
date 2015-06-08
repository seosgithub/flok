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

 #it "Does pass options to spec0 in init" do
    ##Compile the controller
    #ctx = flok_new_user File.read('./spec/kern/assets/vm/controller0.rb'), File.read("./spec/kern/assets/vm/config1.rb")

    ##Run the embed function
    #ctx.eval %{
      #//Call embed on main root view
      #base = _embed("my_controller", 0, {}, null);

      #//Drain queue
      #int_dispatch([]);
    #}

    #base = ctx.eval("base")
    #res = JSON.parse(ctx.eval("JSON.stringify(spec0_init_options)"))
    #expect(res).to eq({"hello" => "world"})
  #end

 #it "Can include the spec0 pager and call read_sync" do
    ##Compile the controller
    #ctx = flok_new_user File.read('./spec/kern/assets/vm/controller1.rb'), File.read("./spec/kern/assets/vm/config1.rb")

    ##Run the embed function
    #ctx.eval %{
      #//Call embed on main root view
      #base = _embed("my_controller", 0, {}, null);

      #//Drain queue
      #int_dispatch([]);
    #}

    ##Verify that the vm service is getting the read_sync request
    #res = ctx.eval("vm_read_sync_called")
    #expect(res).to eq(true)

    ##Verify that the vm service is disptaching the request
    #res = ctx.eval("spec0_read_sync_called")
    #expect(res).to eq(true)
  #end

  #it "Can include the spec0 pager and call read_sync and then get a reply" do
    ##Compile the controller
    #ctx = flok_new_user File.read('./spec/kern/assets/vm/controller1.rb'), File.read("./spec/kern/assets/vm/config1.rb")

    ##Run the embed function
    #ctx.eval %{
      #//Call embed on main root view
      #base = _embed("my_controller", 0, {}, null);

      #//Drain queue
      #int_dispatch([]);
    #}

    ##Verify that the read did return from the spec0 pager
    #res = ctx.eval("read_res_params")
    #expect(res).not_to eq(nil)
  #end


  #it "Can include the spec0 pager and call read and then get a reply" do
    ##Compile the controller
    #ctx = flok_new_user File.read('./spec/kern/assets/vm/controller2.rb'), File.read("./spec/kern/assets/vm/config1.rb")

    ##Run the embed function
    #ctx.eval %{
      #//Call embed on main root view
      #base = _embed("my_controller", 0, {}, null);

      #//Drain queue
      #int_dispatch([]);
    #}

    ##Verify that the read did return from the spec0 pager
    #res = ctx.eval("read_res_params")
    #expect(res).not_to eq(nil)
  #end

  #it "Can include the spec0 pager and call write and and then read to get a reply" do
    ##Compile the controller
    #ctx = flok_new_user File.read('./spec/kern/assets/vm/controller3.rb'), File.read("./spec/kern/assets/vm/config1.rb")

    ##Run the embed function
    #ctx.eval %{
      #//Call embed on main root view
      #base = _embed("my_controller", 0, {}, null);

      #//Drain queue
      #int_dispatch([]);
    #}

    ##Verify that the read did return from the spec0 pager
    #res = JSON.parse(ctx.eval("JSON.stringify(read_res_params)"))
    #expect(res).to eq({
      #"key" => 33,
      #"value" => 22
    #})
  #end

#  it "Write then read does will hit the pager for the read, a write is not guaranteed to be 1 to 1 but a read is, additionally, the reads only went through once" do
    ##Compile the controller
    #ctx = flok_new_user File.read('./spec/kern/assets/vm/controller4.rb'), File.read("./spec/kern/assets/vm/config1.rb")

    ##Run the embed function
    #ctx.eval %{
      #//Call embed on main root view
      #base = _embed("my_controller", 0, {}, null);

      #//Drain queue
      #int_dispatch([]);
    #}

    #expect(ctx.eval("spec0_read_count")).to eq(1)
  #end

  #it "Can read through and then send another read_res for a change on the page" do
    ##Compile the controller
    #ctx = flok_new_user File.read('./spec/kern/assets/vm/controller5.rb'), File.read("./spec/kern/assets/vm/config2.rb")

    ##Run the embed function
    #ctx.eval %{
      #//Call embed on main root view
      #base = _embed("my_controller", 0, {}, null);

      #//Drain queue
      #int_dispatch([]);
    #}

    ##read_res from spec is called multiple times and returns an array of the parms
    #res = JSON.parse(ctx.eval("JSON.stringify(read_res_called_with)"))

    ##Expect 2 responses, first is cache miss, second is cache hit, third is cache updated
    #expect(res).to eq [
      #{"key" => "my_key", "value" => "a"},
      #{"key" => "my_key", "value" => "a"},
      #{"key" => "my_key", "value" => "b"}
    #]
  #end

  it "Can watch a key and then be sent a read_res whenever that key changes" do
    #Compile the controller
    ctx = flok_new_user File.read('./spec/kern/assets/vm/controller6.rb'), File.read("./spec/kern/assets/vm/config3.rb")

    #Run the embed function
    ctx.eval %{
      //Call embed on main root view
      base = _embed("my_controller", 0, {}, null);

      //Drain queue
      int_dispatch([]);
    }

    #Trigger notification
    ctx.eval("spec2_spec_trigger()")

    #read_res from spec is called multiple times and returns an array of the parms
    res = JSON.parse(ctx.eval("JSON.stringify(read_res_called_with)"))

    #Expect 2 responses, first is cache miss, second is cache hit, third is cache updated
    expect(res).to eq [
      {"key" => "my_key", "value" => "a"},
      {"key" => "my_key", "value" => "a"},
      {"key" => "my_key", "value" => "b"}
    ]
  end

end
