require 'phantomjs'
require 'rspec/wait'
require 'webrick'

class IO
  def self.duplex_pipe
    return DuplexPipe.new
  end
end

class DuplexPipe
  def initialize
    @r0, @w0 = IO.pipe
    @r1, @w1 = IO.pipe
  end

  #Choose arbitrary side, just different ones for forked processes
  def claim_low
    @r = @r0
    @w = @w1
  end

  def claim_high
    @r = @r1
    @w = @w0
  end

  def write msg
    @w.write msg
  end

  def puts msg
    @w.puts msg
  end

  def readline
    @r.readline
  end
end

module Restwell
  def self.get path, &block
    Restwell.new "GET", path, &block
  end

  class Restwell
    attr_accessor :pid
    attr_accessor :port

    def kill
      Process.kill("KILL", @pid)
    end

    def initialize verb, path, &block
      @verb = verb
      @path = path
      @block = block
      @port = rand(30000)+3000

      @pipe = IO.duplex_pipe
      @pid = fork do
        @pipe.claim_high
        @server = WEBrick::HTTPServer.new :Port => @port, :DocumentRoot => ".", :StartCallback => Proc.new {
          @pipe.puts("ready")
        }
        @server.mount_proc '/' do |req, res|
          @pipe.puts req.query
          body = @pipe.readline
          res.body = body
          puts "Got back #{body}"
        end
        @server.start
      end

      @pipe.claim_low
      @pipe.readline #Wait for 'ready'
      Thread.new do
        begin
          loop do
            params = @pipe.readline
            res = @block.call(params)
            @pipe.puts res
          end
        rescue => e
          puts "Exception: #{e.inspect}"
        end
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
    @pids.each {|p| Process.kill("KILL", p)}
  end

  it "can make a get request" do
    #Build driver
    #`cd ./app/drivers/browser; rake build`
    #`echo "console.log(\"hello\");" >> ./products/drivers/browser.js`
    #`echo "phantom.exit();" >> ./products/drivers/browser.js`

    #code = File.read("./products/drivers/browser.js")

    #Setup rspec test server
    called = false
    spek = Restwell.get "blah" do |params|
      called = true
    end
    @pids << spek.pid
    puts "PORT = #{spek.port}"

    `curl http://localhost:#{spek.port}?fuck=true`

    #Load synchronously, but execute the code asynchronously, quit after it's been running for 3 seconds
    #browze = Browze.new
    #browze.evalf("./products/drivers/browser.js", timeout:3)
    wait(2).for { called }.to eq(true)
  end
end
