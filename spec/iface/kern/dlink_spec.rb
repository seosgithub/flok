Dir.chdir File.join File.dirname(__FILE__), '../../../'
require './spec/env/iface.rb'
require './spec/lib/helpers.rb'
require './spec/lib/io_extensions.rb'
require './spec/lib/rspec_extensions.rb'

RSpec.describe "iface:kern:net" do
  module_dep "net"
  include_context "iface:kern"

  #A callback was registered in the kernel for testing purposes
  it "A mock URL notify does receive the correct information" do
    @secret = SecureRandom.hex

    #Wait for response
    @pipe.puts [0, "ping"].to_json; @pipe.readline_timeout

    @pipe.puts [2, "int_dlink_notify", "http://test.com/foo", {"foo" => "bar"}].to_json
    @pipe.puts [0, "get_int_dlink_spec"].to_json

    res = [
      [0, 1, "get_int_dlink_spec", ["http://test.com/foo", {"secret"=>@secret}]]
    ]

    expect(@pipe).to readline_and_equal_json_x_within_y_seconds(res, 5.seconds)
  end
end
