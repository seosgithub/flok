#Anything and everything to do with view controllers (not directly UI) above the driver level

Dir.chdir File.join File.dirname(__FILE__), '../../'
require './spec/env/kern.rb'
require './spec/lib/helpers.rb'
require './spec/lib/io_extensions.rb'
require './spec/lib/rspec_extensions.rb'

RSpec.describe "kern:service_controller_spec" do
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

 it "Does signal disconnect to the service" do
    #Compile the controller
    ctx = flok_new_user File.read('./spec/kern/assets/service_controller1.rb'), File.read("./spec/kern/assets/service_config1.rb"), File.read("./spec/kern/assets/service0.rb")

    #Run the embed function
    ctx.eval %{
      //Call embed on main root view
      base = _embed("my_controller", 0, {}, null);

      //Drain queue
      int_dispatch([3, "int_event", base, "next", {}]);
    }

    expect(ctx.eval("on_disconnect_called")).to eq(true)
  end

  it "Does send a controller a timed signal when it is connected" do
    #Compile the controller
    ctx = flok_new_user File.read('./spec/kern/assets/service_controller0.rb'), File.read("./spec/kern/assets/service_config1.rb"), File.read("./spec/kern/assets/service0.rb")

    #Run the embed function
    ctx.eval %{
      //Call embed on main root view
      base = _embed("my_controller", 0, {}, null);
    }

    @driver.int "int_timer"
    @driver.int "int_timer"
    @driver.int "int_timer"
    @driver.int "int_timer"
    expect(ctx.eval("ping_called")).to eq(true)
  end

  it "Does sleep when there are no more sessions" do
    #Compile the controller
    ctx = flok_new_user File.read('./spec/kern/assets/service_controller1.rb'), File.read("./spec/kern/assets/service_config1.rb"), File.read("./spec/kern/assets/service0.rb")

    #Run the embed function
    ctx.eval %{
      //Call embed on main root view
      base = _embed("my_controller", 0, {}, null);

      //Drain queue
      int_dispatch([3, "int_event", base, "next", {}]);
    }

    expect(ctx.eval("on_sleep_called")).to eq(true)
  end

  it "No longer receives timer events when it is not awake" do
    #Compile the controller
    ctx = flok_new_user File.read('./spec/kern/assets/service_controller1.rb'), File.read("./spec/kern/assets/service_config1.rb"), File.read("./spec/kern/assets/service1.rb")

    #Run the embed function
    ctx.eval %{
      //Call embed on main root view
      base = _embed("my_controller", 0, {}, null);

      //Drain queue
      int_dispatch([3, "int_event", base, "next", {}]);
    }

    100.times do
      @driver.int "int_timer"
    end

    expect(ctx.eval("every_ticks")).to eq(0)
  end

  it "Receives timer events when it is re-activated" do
    #Compile the controller
    ctx = flok_new_user File.read('./spec/kern/assets/service_controller1.rb'), File.read("./spec/kern/assets/service_config1.rb"), File.read("./spec/kern/assets/service1.rb")

    #Run the embed function
    ctx.eval %{
      //Call embed on main root view
      base = _embed("my_controller", 0, {}, null);

      //Drain queue
      int_dispatch([3, "int_event", base, "next", {}]);
    }

    100.times do
      @driver.int "int_timer"
    end

    #Now we are going back to the other action, which should wake it up
    ctx.eval %{
      //Drain queue
      int_dispatch([3, "int_event", base, "next", {}]);
    }

    100.times do
      @driver.int "int_timer"
    end

    expect(ctx.eval("every_ticks")).to eq(25)
  end

  it "Does have all the right variables after sending a custom event to the service and a timer event has fired" do
    #Compile the controller
    ctx = flok_new_user File.read('./spec/kern/assets/service_controller2.rb'), File.read("./spec/kern/assets/service_config1.rb"), File.read("./spec/kern/assets/service2.rb")

    #Run the embed function
    ctx.eval %{
      //Call embed on main root view
      base = _embed("my_controller", 0, {}, null);
    }

    #Base pointer of the controller that uses the service
    my_base = ctx.eval("my_base")

    #Need to get timer first because the first controller holds the timer
    100.times do
      @driver.int "int_timer"
    end

    #Next will now cause a disconnect (controller no longer holds service) 
    ctx.eval %{
      int_dispatch([3, "int_event", base, "next", {}]);
    }

    connect_sessions = JSON.parse(ctx.eval("JSON.stringify(connect_sessions)"))
    disconnect_bp = ctx.eval("disconnect_bp")
    disconnect_sessions = JSON.parse(ctx.eval("JSON.stringify(disconnect_sessions)"))
    every_ticks_sessions= JSON.parse(ctx.eval("JSON.stringify(every_ticks_sessions)"))
    ping_bp = ctx.eval("ping_bp")
    ping_params = JSON.parse(ctx.eval("JSON.stringify(ping_params)"))
    ping_sessions = JSON.parse(ctx.eval("JSON.stringify(ping_sessions)"))

    #We need to convert to strings because we're using Object.keys to verify hashes
    #Connect happends when my_other_controller is embedded
    expect(connect_sessions).to eq([my_base.to_s])

    #Disconnect happends when my_controller switches to my_other_action
    expect(disconnect_bp).to eq(my_base)
    expect(disconnect_sessions).to eq([])

    #Timer was fired before we switched to no service instance
    expect(every_ticks_sessions).to eq([my_base.to_s])

    #Ping is hit during the service
    expect(ping_bp).to eq(7)
    expect(ping_params).to eq({"hello" => "world"})
    expect(ping_sessions).to eq([my_base.to_s])
  end

  it "fails to compile when trying to Request() with something not defined in services" do
    #Compile the controller
    expect { flok_new_user File.read('./spec/kern/assets/service_controller3.rb'), File.read("./spec/kern/assets/service_config1.rb"), File.read("./spec/kern/assets/service2.rb")
    }.to raise_exception
  end
end
