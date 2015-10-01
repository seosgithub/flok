#The dlink service

Dir.chdir File.join File.dirname(__FILE__), '../../'
require './spec/env/kern.rb'
require './spec/lib/helpers.rb'
require './spec/lib/io_extensions.rb'
require './spec/lib/rspec_extensions.rb'
require 'zlib'

RSpec.describe "kern:dlink_service" do
  include Zlib
  include_context "kern"

  it "Can use dlink service" do
    ctx = flok_new_user File.read('./spec/kern/assets/dlink_service/controller0.rb'), File.read("./spec/kern/assets/dlink_service/config0.rb") 
    dump = ctx.evald %{
      base = _embed("my_controller", 0, {}, null);

      //Drain queue
      int_dispatch([]);
    }
  end

  it "Does send the controller the dlink_req when a dlink interrupt is sent" do
    ctx = flok_new_user File.read('./spec/kern/assets/dlink_service/controller0.rb'), File.read("./spec/kern/assets/dlink_service/config0.rb") 
    dump = ctx.evald %{
      dump.base = _embed("my_controller", 0, {}, null);

      //Drain queue
      int_dispatch([]);
    }

    @driver.int "int_dlink_notify", [
      "http://google.com/test", {"foo" => "bar"}
    ]

    #Should not exist yet because of defered event
    dump = ctx.evald %{ dump.dlink_res_params = dlink_res_params; }
    expect(dump["dlink_res_params"]).to eq(nil)

    #Drain the defered queue and check again
    ctx.eval %{ for (var i = 0; i < 100; ++i) { int_dispatch([]); } }
    dump = ctx.evald %{ dump.dlink_res_params = dlink_res_params; }

    expect(dump["dlink_res_params"]).to eq({
      "url" => "http://google.com/test",
      "params" => {"foo" => "bar"}
    })
  end
end
