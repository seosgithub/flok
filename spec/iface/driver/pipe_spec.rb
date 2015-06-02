Dir.chdir File.join File.dirname(__FILE__), '../../../'
require './spec/env/iface.rb'

RSpec.describe "iface:driver:pipe_spec" do
  include_context "iface:driver"

  it "does close the read back pipe when when a syntax error occurs" do
    @pipe.puts "a"

    expect(@pipe).to raise_eof_from_readline_within(6.seconds)
  end

  it "does not close the read back pipe when when no syntax error occurs" do
    @pipe.puts "[]"

    expect(@pipe).not_to raise_eof_from_readline_within(6.seconds)
  end

  it "does terminate the proccess when a syntax error occurs" do
    pid = @pipe.pid
    @pipe.puts "a"
    expect(pid).to die_within(6.seconds)
  end

  it "does terminate the proccess when the pipe is closed" do
    pid = @pipe.pid
    @pipe.close

    expect(pid).to die_within(6.seconds)
  end

  it "does have the ability to receive a RESTART command" do
    @pipe.puts "RESTART"
    expect(@pipe).to readline_and_equal_x_within_y_seconds("RESTART OK", 5.seconds)
  end
end
