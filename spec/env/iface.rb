require 'json'
require 'open3'

shared_context "kern" do
  before(:each) { @pipe = IO.popen("rake pipe:kern", "r+") }
end

shared_context "driver" do
  before(:each) { @pipe = IO.popen("rake pipe:driver", "r+") }
end

def ping_suite
  it "supports ping" do
    @pipe.puts [0, "ping"].to_json
    res = @pipe.readline
    res = JSON.parse(res)
    expect(res).to eq([0, "pong"])
  end

  it "supports ping1" do
    arg = SecureRandom.hex
    @pipe.puts [1, "ping1", arg].to_json
    res = @pipe.readline
    res = JSON.parse(res)
    expect(res).to eq([1, "pong1", arg])
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
