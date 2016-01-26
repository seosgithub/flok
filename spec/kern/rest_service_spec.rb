#The rest service

Dir.chdir File.join File.dirname(__FILE__), '../../'
require './spec/env/kern.rb'
require './spec/lib/helpers.rb'
require './spec/lib/io_extensions.rb'
require './spec/lib/rspec_extensions.rb'
require 'zlib'

RSpec.describe "kern:rest_service" do
  include Zlib
  include_context "kern"

  it "Can use rest service" do
    ctx = flok_new_user File.read('./spec/kern/assets/rest_service/controller0.rb'), File.read("./spec/kern/assets/rest_service/config0.rb") 
    dump = ctx.evald %{
      base = _embed("my_controller", 0, {}, null);

      //Drain queue
      int_dispatch([]);
      int_dispatch([]);
    }
  end

  it "Can make a request on the rest service" do
    ctx = flok_new_user File.read('./spec/kern/assets/rest_service/controller1.rb'), File.read("./spec/kern/assets/rest_service/config0.rb") 
    dump = ctx.evald %{
      dump.base = _embed("my_controller", 0, {}, null);

      //Drain queue
      int_dispatch([]);
      int_dispatch([]);
    }

    @driver.ignore_up_to("if_net_req")
    @driver.mexpect("if_net_req", ["GET", "http://localhost:8080/test", {"hello" => "world"}, Integer], 1) #network priority
  end

  it "Does send the controller the rest_res when a response is returned" do
    ctx = flok_new_user File.read('./spec/kern/assets/rest_service/controller1.rb'), File.read("./spec/kern/assets/rest_service/config0.rb") 
    dump = ctx.evald %{
      dump.base = _embed("my_controller", 0, {}, null);

      //Drain queue
      int_dispatch([]);
      int_dispatch([]);
    }

    @driver.ignore_up_to("if_net_req")
    msg = @driver.mexpect("if_net_req", ["GET", "http://localhost:8080/test", {"hello" => "world"}, Integer], 1) #network priority

    #Last argument is teh tp_base for if_net_req
    tp_base = msg.last

    @driver.int "int_net_cb", [
      tp_base, 200, {"foo" => "bar"}
    ]

    dump = ctx.evald %{
      dump.rest_res_params = rest_res_params;
    }

    expect(dump["rest_res_params"]).to eq({
      "path" => "test",
      "code" => 200,
      "res" => {
        "foo" => "bar"
      }
    })
  end

  it "Does automatically retry a network request after a 2 second timeout for a failed request" do
    ctx = flok_new_user File.read('./spec/kern/assets/rest_service/controller1b.rb'), File.read("./spec/kern/assets/rest_service/config0.rb") 
    dump = ctx.evald %{
      dump.base = _embed("my_controller", 0, {}, null);

      //Drain queue
      int_dispatch([]);
      int_dispatch([]);
    }

    @driver.ignore_up_to("if_net_req")
    msg = @driver.mexpect("if_net_req", ["GET", "http://localhost:8080/test", {"hello" => "world"}, Integer], 1) #network priority

    #Last argument is teh tp_base for if_net_req
    tp_base = msg.last

    @driver.int "int_net_cb", [
      tp_base, -1, "Error",
    ]

    dump = ctx.evald %{
      dump.rest_res_params = rest_res_params;
    }

    expect(dump["rest_res_params"]).to eq({
      "path" => "test",
      "code" => -1,
      "res" => "Error"
    })

    #Increment the timers
    (4*2).times do
      @driver.int "int_timer", []
    end

    #Expect a signal for another network request
    @driver.ignore_up_to("if_net_req")
    msg = @driver.mexpect("if_net_req", ["GET", "http://localhost:8080/test", {"hello" => "world"}, Integer], 1) #network priority
    tp_base = msg.last

    @driver.int "int_net_cb", [
      tp_base, -1, "Error2",
    ]

    #Re-evaluate the results
    dump = ctx.evald %{ dump.rest_res_params = rest_res_params; }

    expect(dump["rest_res_params"]).to eq({
      "path" => "test",
      "code" => -1,
      "res" => "Error2"
    })
  end

  it "Does not automatically retry a network request after a 2 second timeout for a failed request where the view-controller is no longer available" do
    ctx = flok_new_user File.read('./spec/kern/assets/rest_service/controller1b.rb'), File.read("./spec/kern/assets/rest_service/config0.rb") 
    ctx.evald %{
      _embed("root_controller", 0, {}, null);

      //Drain queue
      int_dispatch([]);
      int_dispatch([]);
    }


    @driver.ignore_up_to("if_net_req")
    msg = @driver.mexpect("if_net_req", ["GET", "http://localhost:8080/test", {"hello" => "world"}, Integer], 1) #network priority

    #Last argument is teh tp_base for if_net_req
    tp_base = msg.last

    @driver.int "int_net_cb", [
      tp_base, -1, "Error",
    ]

    dump = ctx.evald %{
      dump.rest_res_params = rest_res_params;
      dump.base = root_base
    }

    expect(dump["rest_res_params"]).to eq({
      "path" => "test",
      "code" => -1,
      "res" => "Error"
    })

    @driver.int "int_event", [ dump["base"], "next_clicked", {} ] 

    #Increment the timers
    (4*2).times do
      @driver.int "int_timer", []
    end

    expect { @driver.ignore_up_to("if_net_req") }.to raise_error /Waited/

  end
end
