Dir.chdir File.join File.dirname(__FILE__), '../../../'
require './spec/env/iface.rb'
require './spec/lib/helpers.rb'
require './spec/lib/io_extensions.rb'
require './spec/lib/rspec_extensions.rb'

RSpec.describe "iface:driver:hook" do
  module_dep "hook"
  include_context "iface:driver"

  it "Can receive a hook event request with parameters" do
    @ptr = SecureRandom.hex

    #Simulate a hook event on the main queue
    @pipe.puts [[0, 3, "if_hook_event", "test", {foo: "bar"}]].to_json

    #Wait for response
    @pipe.puts [[0, 0, "ping"]].to_json; @pipe.readline_timeout

    #Get the value of the received event
    @pipe.puts [[0, 1, "if_hook_spec_dump_rcvd_events"]].to_json

    json = [
      1,
      "if_hook_spec_dump_rcvd_events_res",
      [{
        "name" => "test",
        "info" => {"foo" => "bar"}
      }]
    ]
    expect(@pipe).to readline_and_equal_json_x_within_y_seconds(json, 5.seconds)
  end
end
