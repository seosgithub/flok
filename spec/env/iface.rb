require 'json'
require './spec/lib/rspec_extensions'
require 'open3'
require 'timeout'

shared_context "kern" do
  before(:each) do
    @pipe = IO.popen("rake pipe:kern", "r+")
    @pid = @pipe.pid
  end

  after(:each) do
    begin
      Process.kill(:KILL, @pid)
    rescue Errno::ESRCH
    end
  end
end

shared_context "driver" do
  before(:each) do 
    @pipe = IO.popen("rake pipe:driver", "r+") 
    @pid = @pipe.pid
  end

  after(:each) do
    begin
      Process.kill(:KILL, @pid)
    rescue Errno::ESRCH
    end
  end
end

#Testing the ping function as outlined in ./docs/messaging.md
def ping_suite
  it "supports ping" do
    @pipe.puts [0, "ping"].to_json
    expect(@pipe).to readline_and_equal_json_x_within_y_seconds([0, "pong"], 5.seconds)
  end

  it "supports ping1" do
    arg = SecureRandom.hex
    @pipe.puts [1, "ping1", arg].to_json
    expect(@pipe).to readline_and_equal_json_x_within_y_seconds([1, "pong1", arg], 5.seconds)
  end

  it "supports ping2" do
    arg1 = SecureRandom.hex
    arg2 = SecureRandom.hex
    @pipe.puts [2, "ping2", arg1, arg2].to_json

    res = @pipe.readline
    res = JSON.parse(res)
    expect(res).to eq([1, "pong2", arg1])

    res = @pipe.readline
    res = JSON.parse(res)
    expect(res).to eq([2, "pong2", arg1, arg2]) 
  end

  it "supports multi-ping" do
    @pipe.puts [0, "ping", 0, "ping"].to_json

    res = @pipe.readline
    res = JSON.parse(res)
    expect(res).to eq([0, "pong"])

    res = @pipe.readline
    res = JSON.parse(res)
    expect(res).to eq([0, "pong"])
  end

  it "supports multi-ping1" do
    secret1 = SecureRandom.hex
    secret2 = SecureRandom.hex
    @pipe.puts [1, "ping1", secret1, 1, "ping1", secret2].to_json

    res = @pipe.readline
    res = JSON.parse(res)
    expect(res).to eq([1, "pong1", secret1])

    res = @pipe.readline
    res = JSON.parse(res)
    expect(res).to eq([1, "pong1", secret2])
  end

  it "supports multi-ping2" do
    secret1 = SecureRandom.hex
    secret2 = SecureRandom.hex
    @pipe.puts [2, "ping2", secret1, secret2, 2, "ping2", secret2, secret1].to_json

    res = @pipe.readline
    res = JSON.parse(res)
    expect(res).to eq([1, "pong2", secret1])

    res = @pipe.readline
    res = JSON.parse(res)
    expect(res).to eq([2, "pong2", secret1, secret2])

    res = @pipe.readline
    res = JSON.parse(res)
    expect(res).to eq([1, "pong2", secret2])

    res = @pipe.readline
    res = JSON.parse(res)
    expect(res).to eq([2, "pong2", secret2, secret1])
  end
end

#Testing the pipe to make sure it matches the specs outlined in ./docs/interface.md
def pipe_suite 
  it "does close the read back pipe when when a syntax error occurs" do
    @pipe.puts "a"

    expect(@pipe).to raise_eof_from_readline_within(5.seconds)
  end

  it "does terminate the proccess when a syntax error occurs" do
    pid = @pipe.pid
    @pipe.puts "a"
    expect(pid).to die_within(5.seconds)
  end

  it "does terminate the proccess when the pipe is closed" do
    pid = @pipe.pid
    @pipe.close

    expect(pid).to die_within(5.seconds)
  end
end
