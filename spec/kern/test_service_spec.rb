#The test service

Dir.chdir File.join File.dirname(__FILE__), '../../'
require './spec/env/kern.rb'
require './spec/lib/helpers.rb'
require './spec/lib/io_extensions.rb'
require './spec/lib/rspec_extensions.rb'
require 'zlib'

RSpec.describe "kern:test_service" do
  include Zlib
  include_context "kern"

  it "Can use test service" do
    ctx = flok_new_user File.read('./spec/kern/assets/test_service/controller0.rb'), File.read("./spec/kern/assets/test_service/config0.rb") 
    dump = ctx.evald %{
      base = _embed("my_controller", 0, {}, null);

      //Drain queue
      int_dispatch([]);

      dump.my_action_entered = my_action_entered;
    }

    expect(dump["my_action_entered"]).to eq(true)
  end

  it "Can use test service to make a test_sync request" do
    ctx = flok_new_user File.read('./spec/kern/assets/test_service/controller1.rb'), File.read("./spec/kern/assets/test_service/config0.rb") 
    dump = ctx.evald %{
      base = _embed("my_controller", 0, {}, null);

      //Drain queue
      int_dispatch([]);

      dump.test_sync_res_params = test_sync_res_params;
    }

    expect(dump["test_sync_res_params"]).to eq({
      "foo" => "bar"
    })
  end

  it "Can use test service to make a test_sync request and should still succeed if int_dispatch isnt called" do
    ctx = flok_new_user File.read('./spec/kern/assets/test_service/controller1.rb'), File.read("./spec/kern/assets/test_service/config0.rb") 
    dump = ctx.evald %{
      base = _embed("my_controller", 0, {}, null);
      dump.test_sync_res_params = test_sync_res_params;
    }

    expect(dump["test_sync_res_params"]).to eq({
      "foo" => "bar"
    })
  end


  it "Can use test service to make a test_async request, and this request will fail unless int_dispatch is called (which triggers the async reply)" do
    ctx = flok_new_user File.read('./spec/kern/assets/test_service/controller2.rb'), File.read("./spec/kern/assets/test_service/config0.rb") 
    expect {
      ctx.evald %{
        base = _embed("my_controller", 0, {}, null);
        dump.test_async_res_params = test_async_res_params;
      }
    }.to raise_exception(V8::Error)
  end

  it "Can use test service to make a test_async request, and should succeed after int_dispatch is called (dispatching the async reply)" do
    ctx = flok_new_user File.read('./spec/kern/assets/test_service/controller2.rb'), File.read("./spec/kern/assets/test_service/config0.rb") 
    dump = ctx.evald %{
      base = _embed("my_controller", 0, {}, null);

      //Drain queue
      int_dispatch([]);

      dump.test_async_res_params = test_async_res_params;
    }

    expect(dump["test_async_res_params"]).to eq({
      "foo" => "bar"
    })
  end

end
