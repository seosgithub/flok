Dir.chdir File.join File.dirname(__FILE__), '../../../'
require './spec/env/iface.rb'
require './spec/lib/helpers.rb'
require './spec/lib/io_extensions.rb'
require './spec/lib/rspec_extensions.rb'

RSpec.describe "iface:driver:rtc" do
  module_dep "rtc"
  include_context "iface:driver"

  it "Does update epoch every second" do
    #Wait for response
    @pipe.puts [[0, 0, "ping"]].to_json; @pipe.readline_timeout

    @pipe.puts [[0, 1, "if_rtc_init"]].to_json

    #Wait to start until after the 1st event fires to make sure timer started up
    @pipe.readline
    expect(@pipe).to readline_and_equal_json_x_within_y_seconds([1, "int_rtc", Fixnum], 5.seconds)
    start_time = Time.now.to_i
    5.times do
      expect(@pipe).to readline_and_equal_json_x_within_y_seconds([1, "int_rtc", Fixnum], 2.seconds)
    end
    end_time = Time.now.to_i

    #Just leave some room for connection latency, etc.
    expect(end_time - start_time).to be < 7
    expect(end_time - start_time).to be > 4

    #Now let's compare one-to-three 'ticks'
    a = JSON.parse(@pipe.readline_timeout)
    sleep 1
    b = JSON.parse(@pipe.readline_timeout)

    #They should be at least 1 second apart and not more than 3
    a_timestamp = a[2]
    b_timestamp = b[2]
    expect(b_timestamp - a_timestamp).to be > 0
    expect(b_timestamp - a_timestamp).to be < 4

    #Should match the current epoch within 1 minute
    current_epoch = Time.now.to_i
    expect((b_timestamp - current_epoch).abs).to be < 60
  end
end
