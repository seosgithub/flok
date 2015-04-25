#Anything and everything to do with networking above the driver level

Dir.chdir File.join File.dirname(__FILE__), '../../'
require './spec/env/kern.rb'
require './spec/lib/helpers.rb'
require './spec/lib/io_extensions.rb'
require './spec/lib/rspec_extensions.rb'

RSpec.describe "kern:net_spec" do
  include_context "kern"

  it "can call get_req() and returns to the correct callback" do
    @secret = SecureRandom.hex
   
    function "test_complete" do |info|
      @info = info.to_h
    end

    #External loopback
    external_function "if_net_req" do |verb, url, params, tp_base|
      external_int "int_net_cb", tp_base, true, {"secret" => @secret}
    end
    
    puts @ctx.eval %{
      get_req("http://test_url", {}, function(info) {
        test_complete(info);
      });
    }

    expect(@info).to eq({"secret" => @secret})
  end
end
