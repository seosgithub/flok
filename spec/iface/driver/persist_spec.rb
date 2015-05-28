Dir.chdir File.join File.dirname(__FILE__), '../../../'
require './spec/env/iface.rb'
require './spec/lib/helpers.rb'
require './spec/lib/io_extensions.rb'
require './spec/lib/rspec_extensions.rb'

RSpec.describe "iface:driver:persist" do
  module_dep "persist"
  include_context "iface:driver"

 it "Can receive persist API messages without crashing" do
    #Disk is scheduling class 2
    @pipe.puts [[2, 3, "if_per_set", "my_ns", "my_key", "my_value"]].to_json
    @pipe.puts [[2, 3, "if_per_get", "session", "my_ns", "my_key"]].to_json
    @pipe.puts [[2, 2, "if_per_del", "my_ns", "my_key"]].to_json
    @pipe.puts [[2, 1, "if_per_del_ns", "my_ns"]].to_json

    #These are from the get requests
    @pipe.readline_timeout

    @pipe.puts [[0, 0, "ping"]].to_json; 
    expect(@pipe).to readline_and_equal_json_x_within_y_seconds([0, "pong"], 5.seconds)
  end

  it "Can set a persist, and then synchronously get" do
    key = SecureRandom.hex
    value = SecureRandom.hex

    #Disk is scheduling class 2
    @pipe.puts [[2, 3, "if_per_set", "my_ns", key, value]].to_json
    restart_driver_but_persist
    @pipe.puts [[0, 3, "if_per_get", "session", "my_ns", key]].to_json

    #Expect a response
    res = [2, "int_per_get_res", "session", value]
    expect(@pipe).to readline_and_equal_json_x_within_y_seconds(res, 5.seconds)
  end


 it "Can set a persist, and then asynchronously get" do
    key = SecureRandom.hex
    value = SecureRandom.hex

    #Disk is scheduling class 2
    @pipe.puts [[2, 3, "if_per_set", "my_ns", key, value]].to_json
    restart_driver_but_persist
    @pipe.puts [[2, 3, "if_per_get", "session", "my_ns", key]].to_json

    #Expect a response
    res = [2, "int_per_get_res", "session", value]
    expect(@pipe).to readline_and_equal_json_x_within_y_seconds(res, 5.seconds)
  end

it "Can set a persist, delete the key, and then synchronously get" do
    key = SecureRandom.hex
    value = SecureRandom.hex

    #Disk is scheduling class 2
    @pipe.puts [[2, 3, "if_per_set", "my_ns", key, value]].to_json
    @pipe.puts [[2, 2, "if_per_del", "my_ns", key]].to_json
    restart_driver_but_persist
    @pipe.puts [[0, 3, "if_per_get", "session", "my_ns", key]].to_json

    #Expect a response
    res = [2, "int_per_get_res", "session", nil]
    expect(@pipe).to readline_and_equal_json_x_within_y_seconds(res, 5.seconds)
  end

 it "Can set two persists, delete one key, and then synchronously get" do
    key = SecureRandom.hex
    key2 = SecureRandom.hex
    value = SecureRandom.hex
    value2 = SecureRandom.hex

    #Disk is scheduling class 2
    @pipe.puts [[2, 3, "if_per_set", "my_ns", key, value]].to_json
    @pipe.puts [[2, 3, "if_per_set", "my_ns", key2, value2]].to_json
    @pipe.puts [[2, 2, "if_per_del", "my_ns", key]].to_json
    restart_driver_but_persist
    @pipe.puts [[0, 3, "if_per_get", "session", "my_ns", key]].to_json
    @pipe.puts [[0, 3, "if_per_get", "session", "my_ns", key2]].to_json

    #Results for first key
    res = [2, "int_per_get_res", "session", nil]
    expect(@pipe).to readline_and_equal_json_x_within_y_seconds(res, 5.seconds)

    #Expect a response
    res = [2, "int_per_get_res", "session", value2]
    expect(@pipe).to readline_and_equal_json_x_within_y_seconds(res, 5.seconds)
  end

  it "Can set a persist, delete the key via ns, and then synchronously get" do
    key = SecureRandom.hex
    value = SecureRandom.hex

    #Disk is scheduling class 2
    @pipe.puts [[2, 3, "if_per_set", "my_ns", key, value]].to_json
    @pipe.puts [[2, 1, "if_per_del_ns", "my_ns"]].to_json
    restart_driver_but_persist
    @pipe.puts [[0, 3, "if_per_get", "session", "my_ns", key]].to_json

    #Expect a response
    res = [2, "int_per_get_res", "session", nil]
    expect(@pipe).to readline_and_equal_json_x_within_y_seconds(res, 5.seconds)
  end
end