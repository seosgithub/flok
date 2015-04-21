require 'open3'
require './spec/helpers.rb'

def js_exec cmd
  q = Queue.new

  cmd.strip!.gsub!("\n", ";")
  #Go into the correct directory
  Dir.chdir "./app/drivers/#{ENV['PLATFORM']}" do
    #You have 5 seconds
    Timeout.timeout(10) do
      #Start the pipe task
      IO.popen("rake pipe", "r+") do |p|
        begin
          cmd.each_line do |l|
            puts "Executing #{l.inspect}"
            p.puts l
            $stderr.puts p.readline
          end
        ensure
          Process.kill 9, p.pid
        end
      end
    end
  end

  return @res
end

RSpec.describe "if_net" do
  before(:each) do
    @pids ||= []
  end

  after(:each) do
    @pids.each { |e| Process.kill(:TERM, e)}
  end

  #it "can make a GET request" do
    #web = Webbing.get "/" do |info|
      #@called = true
    #end

    #port = web.port
    #@pids << web.pid

    #js_exec %{if_net_request("GET", "http://localhost:#{port}", {})}
    #expect(@called).to eq(true)
  #end

  #it "can make a GET request with parameters" do
    #web = Webbing.get "/" do |info|
      #@called = true
      #@info = info
    #end

    #port = web.port
    #@pids << web.pid

    #value = SecureRandom.hex
    #js_exec %{if_net_request("GET", "http://localhost:#{port}", {key:"#{value}"})}
    #expect(@called).to eq(true)
    #expect(@info["key"]).to eq(value)
  #end

  #it "does return a socket descriptor that's different on two sucessive calls" do
    #web = Webbing.get "/" do |info|
      #@called = true
      #@info = info
    #end

    #port = web.port
    #@pids << web.pid

    #value = SecureRandom.hex
    #s = js_exec %{console.log(if_net_request("GET", "http://localhost:#{port}", {key:"#{value}"}), if_net_request("GET", "http://localhost:#{port}", {key:"#{value}"}))}
    #expect(@called).to eq(true)
    #ss = s.split " "
    #expect(ss[0]).not_to eq(ss[1])
  #end

  it "does receive a response back" do
    secret = SecureRandom.hex

    #First server will reply with a secret
    web1 = Webbing.get "/" do |info|
      {:hello => "world"}
    end
    port = web1.port
    @pids << web1.pid

    #Second server must be told the secret
    web2 = Webbing.get "/" do |info|
      @response_secret = info["secret"]
    end
    port2 = web2.port
    @pids << web2.pid

    sleep 1;

    fd = js_exec %{
      function int_net_callback(fd, success, info) {
        system.stderr.writeLine("hit")
      }
      if_net_request("GET", "http://localhost:#{port}", {})
    }

    $stderr.puts fd
    expect(fd).not_to eq("") and expect(fd).not_to eq(nil)
    expect(@response_secret).to eq(secret)
  end
end
