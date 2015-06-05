#Anything and everything to do with view controllers (not directly UI) above the driver level

Dir.chdir File.join File.dirname(__FILE__), '../../'
require './spec/env/kern.rb'
require './spec/lib/helpers.rb'
require './spec/lib/io_extensions.rb'
require './spec/lib/rspec_extensions.rb'

RSpec.describe "kern:service_spec" do
  include_context "kern"

  it "service can be used inside a controller" do
    #Compile the controller
    ctx = flok_new_user File.read('./spec/kern/assets/service_controller0.rb'), File.read("./spec/kern/assets/service_config0.rb")

    #Run the embed function
    ctx.eval %{
      //Call embed on main root view
      base = _embed("my_controller", 0, {}, null);

      //Drain queue
      int_dispatch([]);
    }

    base = ctx.eval("base")

    @driver.mexpect("if_init_view", ["my_controller", {}, base+1, ["main", "hello", "world"]])
    @driver.mexpect("if_controller_init", [base, base+1, "my_controller", {}])
    @driver.mexpect("if_attach_view", [base+1, 0])
    @driver.mexpect("if_event", [base, "action", {"from" => nil, "to" => "my_action"}])
  end

  it "Does call the wakeup and the connect for service when a controller is opened" do
    #Compile the controller
    ctx = flok_new_user File.read('./spec/kern/assets/service_controller0.rb'), File.read("./spec/kern/assets/service_config1.rb"), File.read("./spec/kern/assets/service0.rb")

    #Run the embed function
    ctx.eval %{
      //Call embed on main root view
      base = _embed("my_controller", 0, {}, null);

      //Drain queue
      int_dispatch([]);
    }

    expect(ctx.eval("on_wakeup_called")).to eq(true)
    expect(ctx.eval("on_connect_called")).to eq(true)
  end
end
