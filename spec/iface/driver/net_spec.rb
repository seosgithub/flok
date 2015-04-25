Dir.chdir File.join File.dirname(__FILE__), '../../../'
require './spec/env/iface.rb'
require './spec/lib/helpers.rb'

RSpec.describe "driver:net" do
  include_context "driver"

  it "Can call a network request" do
    web = Webbing.get "/" do
      @hit = true
    end

    @pipe.puts [3, "if_net_req", "GET", "http://127.0.0.1:#{web.port}", {}].to_json

    #Wait for response
    @pipe.puts [0, "ping"].to_json; @pipe.readline

    expect(@hit).to eq(true)

    web.kill
  end

  it "Can call a network request with parameters" do
    @secret = SecureRandom.hex
    web = Webbing.get "/" do |params|
      @rcv_secret = params['secret']
    end

    @pipe.puts [3, "if_net_req", "GET", "http://127.0.0.1:#{web.port}", {'secret' => @secret}].to_json

    #Wait for response
    @pipe.puts [0, "ping"].to_json; @pipe.readline

    expect(@rcv_secret).to eq(@secret)

    web.kill
  end
end
