Dir.chdir File.join File.dirname(__FILE__), '../../../'
require './spec/env/iface.rb'

RSpec.describe "iface:driver:dispatch_spec" do
  include_context "iface:driver"

  it "Does automatically dispatch a blank array (signaling int_disptach) when a bulk queue is received prefixed with 'i' indicating incomplete-ness" do
    @pipe.puts ['i', [0, 0, "ping_nothing"]].to_json
    expect(@pipe).to readline_and_equal_json_x_within_y_seconds([], 6.seconds)
  end

  it "Does automatically dispatch a blank array (signaling int_disptach) when a blank queue is received prefixed with 'i' indicating incomplete-ness" do
    @pipe.puts ['i'].to_json
    expect(@pipe).to readline_and_equal_json_x_within_y_seconds([], 6.seconds)
  end


  it "Does not dispatch a blank array (signaling int_disptach) when a bulk queue is received prefixed without 'i' indicating incomplete-ness" do
    @pipe.puts [[0, 0, "ping_nothing"]].to_json
    expect(@pipe).not_to readline_and_equal_json_x_within_y_seconds([], 6.seconds)
  end

  #While at first you might think we need to test that int_dispatch called intra-respond of our if_event needs to test whether or not we still send
  #out blank [] to int_dispatch; this is not the case. In the real world, flok is supposed to also make any necessary if_disptach calls during all
  #int_dispatch calls. We would always receive back if_dispatch; and thus it would follow the same rules as layed out here
end
