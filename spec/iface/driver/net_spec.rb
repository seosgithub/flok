Dir.chdir File.join File.dirname(__FILE__), '../../../'
require './spec/env/iface.rb'
require './spec/lib/helpers.rb'
require './spec/lib/io_extensions.rb'
require './spec/lib/rspec_extensions.rb'

RSpec.describe "driver:net" do
  include_context "driver"

  it "Can call a network request" do
    web = Webbing.get "/" do
      @hit = true
      "{}"
    end

    @pipe.puts [3, "if_net_req", "GET", "http://127.0.0.1:#{web.port}", {}].to_json

    #Wait for response
    @pipe.puts [0, "ping"].to_json; @pipe.readline_timeout

    expect(@hit).to eq(true)

    web.kill
  end

  it "Can call a network request with parameters" do
    @secret = SecureRandom.hex
    web = Webbing.get "/" do |params|
      @rcv_secret = params['secret']
      "{}"
    end

    @pipe.puts [3, "if_net_req", "GET", "http://127.0.0.1:#{web.port}", {'secret' => @secret}].to_json

    #Wait for response
    @pipe.puts [0, "ping"].to_json; @pipe.readline_timeout

    expect(@rcv_secret).to eq(@secret)

    web.kill
  end

  it "Does send a network interupt int_net_cb with success and the correct payload" do
    @secret = SecureRandom.hex
    @secret2 = SecureRandom.hex
    @secret2msg = {"secret2" => @secret2}
    web = Webbing.get "/" do |params|
      @rcv_secret = params['secret']

      @secret2msg.to_json
    end

    #Wait for response
    @pipe.puts [3, "if_net_req", "GET", "http://127.0.0.1:#{web.port}", {'secret' => @secret}].to_json

    res = [3, "int_net_cb", true, @secret2msg]
    expect(@pipe).to readline_and_equal_json_x_within_y_seconds(res, 5.seconds)

    web.kill
  end
end
