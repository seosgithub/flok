require 'phantomjs'
require 'rspec/wait'
require 'webrick'

module Spek
  def self.get path, &block
    Spek.new "GET", path, &block
  end

  class Spek
    attr_accessor :pid
    attr_accessor :port

    def initialize verb, path, &block
      @verb = verb
      @path = path
      @block = block
      @port = rand(30000)+3000

      @r, @w = IO.pipe
      @pid = fork do
        @server = WEBrick::HTTPServer.new :Port => @port, :DocumentRoot => "."
        @server.mount_proc '/' do |req, res|
          res.body = "Hello"
          @r.close
          @w.write "hey"
          @w.close
          puts "WRITITTTTTTTTTTTTEN"
        end
        @server.start
      end

      begin
        @w.close
        res = @r.read
        @r.close
        @block.call(res)
      rescue => e
        puts "Exception: #{e.inspect}"
      end
    end
  end
end

RSpec.describe "Drivers::Net" do
  before(:each) do
    @pids = []
  end

  after(:each) do
    @pids ||= []
    @pids.each {|p| Process.kill(:TERM, p)}
  end

  it "can make a get request" do
    x = 1
    #Build driver
    #`cd ./app/drivers/browser; rake build`
    #`echo "console.log(\"hello\");" >> ./products/drivers/browser.js`
    #`echo "phantom.exit();" >> ./products/drivers/browser.js`

    #code = File.read("./products/drivers/browser.js")

    #Setup rspec test server
    called = false
    spek = Spek.get "blah" do |params|
      called = true
      puts "CALLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLED"
    end
    @pids << spek.pid
    puts "PORT = #{spek.port}"

    sleep 3
    `curl http://localhost:#{spek.port}`

    #Load synchronously, but execute the code asynchronously, quit after it's been running for 3 seconds
    #browze = Browze.new
    #browze.evalf("./products/drivers/browser.js", timeout:3)
    wait(50).for { x }.to eq(0)
  end
end
