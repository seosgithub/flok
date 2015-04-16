require 'securerandom'
require 'phantomjs'

#Duplex pipe
###################################################################################################################
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
###################################################################################################################

#RESTful mock
###################################################################################################################
module Webbing
  def self.get path, &block
    Webbing.new "GET", path, &block
  end

  class Webbing
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
          @pipe.puts req.query.to_json
          res.body = @pipe.readline
          res.header["Access-Control-Allow-Origin"] = "*"
          res.header["Content-Type"] = "json/text"
        end
        @server.mount_proc '/404' do |req, res|
          res.header["Access-Control-Allow-Origin"] = "*"

          raise WEBrick::HTTPStatus::NotFound
        end
        @server.start
      end

      @pipe.claim_low
      @pipe.readline #Wait for 'ready'
      Thread.new do
        begin
          loop do
            params = JSON.parse(@pipe.readline)
            res = @block.call(params)
            @pipe.puts res.to_json
          end
        rescue => e
          puts "Exception: #{e.inspect}"
        end
      end
    end
  end
end
###################################################################################################################

#Mock chrome javascript running  (Will not do anything until you run commit)
#Meant to be for one shot tests
#(1) load with                       --- cr = ChromeRunner.new('code.js')
#(2) queue execute with              --- cr.eval('console.log("hello world");')
#(3) run in it's own process via     --- cr.commit
###################################################################################################################
class ChromeRunner
  #Load a javascript file
  def initialize fn
    @code = File.read(fn)
    @code << "\n"
    @@phantomjs_path ||= Phantomjs.path
  end

  def eval(code)
    @code << code
    @code << "\n"
  end

  def commit
    file = Tempfile.new SecureRandom.hex
    file.write @code

    @pid = fork do
      system("#{@@phantomjs_path} #{file.path}")
    end
  end

  def kill
    Process.kill("KILL", @pid)
  end
end
###################################################################################################################

###################################################################################################################
#Execute a system command, will throw an exception on error
###################################################################################################################
