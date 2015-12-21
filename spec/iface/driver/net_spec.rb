Dir.chdir File.join File.dirname(__FILE__), '../../../'
require './spec/env/iface.rb'
require './spec/lib/helpers.rb'
require './spec/lib/io_extensions.rb'
require './spec/lib/rspec_extensions.rb'

RSpec.describe "iface:driver:net" do
  module_dep "net"
  include_context "iface:driver"

  it "Can call a network request" do
    begin
      web = Webbing.get "/" do
        @hit = true
        {}
      end

      @ptr = rand(9999999)
      @pipe.puts [[1, 4, "if_net_req","GET", "http://127.0.0.1:#{web.port}", {}, @ptr]].to_json


      #Wait for response
      @pipe.puts [[0, 0, "ping"]].to_json; @pipe.readline_timeout
      sleep 1

      expect(@hit).to eq(true)
    ensure
      web.kill
    end
  end

  it "Can call a network request with parameters" do
    begin
      @secret = SecureRandom.hex
      web = Webbing.get "/" do |params|
        @rcv_secret = params['secret']
        {}
      end

      @ptr = rand(9999999)
      @pipe.puts [[1, 4, "if_net_req", "GET", "http://127.0.0.1:#{web.port}", {'secret' => @secret}, @ptr]].to_json

      #Wait for response
      @pipe.puts [[0, 0, "ping"]].to_json; @pipe.readline_timeout
      sleep 1

      expect(@rcv_secret).to eq(@secret)
    ensure
      web.kill
    end
  end

  it "Does send a network interupt int_net_cb with success and the correct payload" do
    begin
      @secret = SecureRandom.hex
      @secret2 = SecureRandom.hex
      @secret2msg = {"secret2" => @secret2}
      web = Webbing.get "/" do |params|
        @rcv_secret = params['secret']

        @secret2msg
      end

      #Wait for response
      @ptr = rand(9999999)
      @pipe.puts [[1, 4, "if_net_req", "GET", "http://127.0.0.1:#{web.port}", {'secret' => @secret}, @ptr]].to_json

      res = [3, "int_net_cb", @ptr, 200, @secret2msg]
      expect(@pipe).to readline_and_equal_json_x_within_y_seconds(res, 5.seconds)
    ensure
      web.kill
    end
  end

  it "Does send a network interupt int_net_cb with error and the correct payload" do
    #Wait for response
      @ptr = rand(9999999)
    @pipe.puts [[1, 4, "if_net_req", "GET", "http://no_such_url#{SecureRandom.hex}.com", {}, @ptr]].to_json

    matcher = proc do |x|
      x = JSON.parse(x)
      a = ->(e){e.class == String && e.length > 0} #Error message should be a string that's not blank
      expect(x).to look_like [3, "int_net_cb", @ptr, -1, a]
      true
    end

    expect(@pipe).to readline_and_equal_proc_x_within_y_seconds(matcher, 5.seconds)
  end

  it "Can call a network request with headers" do
    begin
      web = Webbing.get "/" do |params, headers|
        expect(headers["content-type"]).to eq("json")
        @hit = true
        {}
      end

      @ptr = rand(9999999)
      @pipe.puts [[1, 5, "if_net_req2", "GET", {"content-type" => "json"}, "http://127.0.0.1:#{web.port}", {}, @ptr]].to_json


      #Wait for response
      @pipe.puts [[0, 0, "ping"]].to_json; @pipe.readline_timeout
      sleep 1

      expect(@hit).to eq(true)
    ensure
      web.kill
    end
  end


  it "Can call a network request with parameters and a header" do
    begin
      @secret = SecureRandom.hex
      web = Webbing.get "/" do |params, headers|
        @headers = headers
        @rcv_secret = params['secret']
        {}
      end

      @ptr = rand(9999999)
      @pipe.puts [[1, 5, "if_net_req2", "GET", {"content-type" => "blah"}, "http://127.0.0.1:#{web.port}", {'secret' => @secret}, @ptr]].to_json

      #Wait for response
      @pipe.puts [[0, 0, "ping"]].to_json; @pipe.readline_timeout
      sleep 2

      expect(@rcv_secret).to eq(@secret)
      expect(@headers["content-type"]).to eq(["blah"])
    ensure
      web.kill
    end
  end


  it "Does send a network interupt int_net_cb with success and the correct payload with headers" do
    begin
      @secret = SecureRandom.hex
      @secret2 = SecureRandom.hex
      @secret2msg = {"secret2" => @secret2}
      web = Webbing.get "/" do |params, headers|
        $stderr.puts headers
        expect(headers["content-type"]).to eq("json")
        @rcv_secret = params['secret']

        @secret2msg
      end

      #Wait for response
      @ptr = rand(9999999)
      @pipe.puts [[1, 5, "if_net_req2", "GET", {"content-type" => "json"}, "http://127.0.0.1:#{web.port}", {'secret' => @secret}, @ptr]].to_json

      res = [3, "int_net_cb", @ptr, 200, @secret2msg]
      expect(@pipe).to readline_and_equal_json_x_within_y_seconds(res, 5.seconds)
    ensure
      web.kill
    end
  end


  it "Does send a network interupt int_net_cb with error and the correct payload and headers" do
    #Wait for response
      @ptr = rand(9999999)
    @pipe.puts [[1, 5, "if_net_req2", "GET", {}, "http://no_such_url#{SecureRandom.hex}.com", {}, @ptr]].to_json

    matcher = proc do |x|
      x = JSON.parse(x)
      a = ->(e){e.class == String && e.length > 0} #Error message should be a string that's not blank
      expect(x).to look_like [3, "int_net_cb", @ptr, -1, a]
      true
    end

    expect(@pipe).to readline_and_equal_proc_x_within_y_seconds(matcher, 5.seconds)
  end


end
