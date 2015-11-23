Dir.chdir File.join File.dirname(__FILE__), '../../../'
require './spec/env/iface.rb'
require './spec/lib/helpers.rb'
require './spec/lib/io_extensions.rb'
require './spec/lib/rspec_extensions.rb'

RSpec.describe "iface:driver:hook" do
  module_dep "hook"
  include_context "iface:driver"

  it "Can receive a single hook event request with parameters and respond with the test handler" do
    @ptr = SecureRandom.hex

    #Wait for response
    @pipe.puts [[0, 0, "ping"]].to_json; @pipe.readline_timeout

    #Simulate a hook event on the main queue
    @pipe.puts [[0, 2, "if_hook_event", "test", {foo: "bar"}]].to_json

    json = [
      1,
      "hook_dump_res",
      {
        "name" => "test",
        "info" => {"foo" => "bar"}
      }
    ]
    expect(@pipe).to readline_and_equal_json_x_within_y_seconds(json, 5.seconds)
  end

  it "Can receive two hook event requests with parameters and respond with the test handler twice" do
    @ptr = SecureRandom.hex

    #Wait for response
    @pipe.puts [[0, 0, "ping"]].to_json; @pipe.readline_timeout

    #Simulate a hook event on the main queue
    @pipe.puts [[0, 2, "if_hook_event", "test", {foo: "bar"}]].to_json

    json = [
      1,
      "hook_dump_res",
      {
        "name" => "test",
        "info" => {"foo" => "bar"}
      }
    ]
    expect(@pipe).to readline_and_equal_json_x_within_y_seconds(json, 5.seconds)

    #Simulate a hook event on the main queue
    @pipe.puts [[0, 2, "if_hook_event", "test", {foo: "bar2"}]].to_json

    json = [
      1,
      "hook_dump_res",
      {
        "name" => "test",
        "info" => {"foo" => "bar2"}
      }
    ]
    expect(@pipe).to readline_and_equal_json_x_within_y_seconds(json, 5.seconds)
  end

  it "Can receive two hook event requests with parameters and respond with the test and test2 handler" do
    @ptr = SecureRandom.hex

    #Wait for response
    @pipe.puts [[0, 0, "ping"]].to_json; @pipe.readline_timeout

    #Simulate a hook event on the main queue
    @pipe.puts [[0, 2, "if_hook_event", "test", {foo: "bar"}]].to_json

    json = [
      1,
      "hook_dump_res",
      {
        "name" => "test",
        "info" => {"foo" => "bar"}
      }
    ]
    expect(@pipe).to readline_and_equal_json_x_within_y_seconds(json, 5.seconds)

    #Simulate a hook event on the main queue
    @pipe.puts [[0, 2, "if_hook_event", "test2", {foo: "bar2"}]].to_json

    json = [
      1,
      "hook_dump_res",
      {
        "name" => "test2",
        "info" => {"foo" => "bar2"}
      }
    ]
    expect(@pipe).to readline_and_equal_json_x_within_y_seconds(json, 5.seconds)
  end

  it "Can receive a hook without a handler and not crash" do
    @ptr = SecureRandom.hex

    #Wait for response
    @pipe.puts [[0, 0, "ping"]].to_json; @pipe.readline_timeout

    #Simulate a hook event on the main queue
    @pipe.puts [[0, 2, "if_hook_event", "test3", {foo: "bar"}]].to_json

    #Wait for response
    @pipe.puts [[0, 0, "ping"]].to_json; @pipe.readline_timeout
  end
end
