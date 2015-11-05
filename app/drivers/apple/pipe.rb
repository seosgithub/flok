require 'file-tail'
require 'socket'
require 'json'
require 'tempfile'
require 'securerandom'
require 'open3'
$stdout.sync = true
PIPE_PORT=6969

#Interactive pipe for testing.
#Creates a server that routes $stdin into if_dispatch and $stdout to int_dispatch.

class AutoTCPSocket
  def initialize host, port
    @host = host
    @port = port
    @handshake = -> {}

    @pending_send_r, @pending_send_w = IO.pipe #Things that should be sent to the socket
    @has_received_r, @has_received_w = IO.pipe #Things that were received by the socket

    #Each start, this is incremented to signal to threads
    #to halt
    @launch_index = 0
  end

  def start
    Thread.new do
      launch_index = @launch_index
      loop do
        begin
          _start
        rescue Exception => e
          break if @launch_index != launch_index
          sleep 1
          $stderr.puts "AutoTCPSocket had exception: #{e.inspect}"
        end
      end
    end
  end

  def _start
    @socket = TCPSocket.new @host, @port
    @handshake.call(@socket)

    Thread.new do
      launch_index = @launch_index
      loop do
        begin
          data = @pending_send_r.gets
          @socket.print data
          @socket.flush
        rescue Exception => e
          break if @launch_index != launch_index
          $stderr.puts "AutoTCPSocket write event loop: #{e.inspect}"
          sleep 1
        end
      end
    end

    loop do
      line = @socket.gets
      @has_received_w.puts line.strip
      @has_received_w.flush
    end
  end

  def restart
    @socket.close
    @launch_index += 1

    system "ps -ax  | grep flok_Example | grep -v grep | awk '{print $1}' | xargs kill -9"
    system "xcrun simctl launch booted org.cocoapods.demo.flok-Example 1>&2"

    start
  end

  def hard_restart
    @socket.close
    @launch_index += 1

    system "ps -ax  | grep flok_Example | grep -v grep | awk '{print $1}' | xargs kill -9"

    #Re-install
    system "xcrun simctl uninstall booted org.cocoapods.demo.flok-Example"
    system "xcrun simctl install booted ./flok-pod/tmp/flok_Example.app 1>&2"

    system "xcrun simctl launch booted org.cocoapods.demo.flok-Example 1>&2"

    data_dir = File.expand_path("~/Library/Developer/CoreSimulator/Devices/#{$device_uuid}/data")

    start
  end

  #Socket interface
  ###############################################################
  def use_handshake &block
    @handshake = block
  end

  def gets
    #return @socket.gets
    @has_received_r.gets
  end

  def print str
    #@socket.print str
    #@socket.flush
    @pending_send_w.puts str
    @pending_send_w.flush
  end

  def flush
    #@socket.flush
  end

  def close
    #@socket.close
  end
  ###############################################################
end

class InteractiveServer
  def initialize
  end

  #Will take over any remaining IO
  def begin_pipe
    begin
      #Connect to the pipe server on iOS

      s = AutoTCPSocket.new 'localhost', PIPE_PORT
      s.use_handshake do |sock|
        $stderr.puts "waiting for HELLO..."
        line = sock.gets.strip
        raise "Pipe server for apple-client didn't receive the correct HELLO response" if line != "HELLO"
        $stderr.puts "got HELLO!"
      end
      s.start
      #sleep 1

      #$stderr.puts "waiting for HELLO..."
      #line = s.gets.strip
      #raise "Pipe server for apple-client didn't receive the correct HELLO response" if line != "HELLO"
      #$stderr.puts "got HELLO!"
      #$stderr.puts "connected"

      #Grab the device name
      device_uuid_info = `xcrun simctl list`.split("\n").detect{|e| e =~ /Booted/}
      raise "No booted device found via simctl list" unless device_uuid_info
      $stderr.puts "got uuid info = #{device_uuid_info.inspect}"
      device_uuid = device_uuid_info.split(" ")[2][1..-2].upcase
      $device_uuid = device_uuid
      $stderr.puts "Device uuid = #{device_uuid.inspect}"
      log_path = File.expand_path "~/Library/Logs/CoreSimulator/#{device_uuid}/system.log"
      $stderr.puts "log path = #{log_path}"

      Thread.new do
        begin
          File.open(log_path) do |log|
            log.extend(File::Tail)
            log.interval = 10
            log.backward(10)
            log.tail do |line|
              #if line =~ /flok_Example/
              $stderr.puts "[iOS Simulator]: #{line}"
              #end
            end
          end
        rescue => e
          $stderr.puts "Failed to read log: #{e.inspect}"
        end
      end

      puts "LOADED"

      #Enter a loop and forward to stdout, this should be int_dispatch requests
      Thread.new do
        begin
          while line = s.gets 
            puts line.strip
          end
        rescue => e
          $stderr.puts "int_dispatch forwarded was closed: #{e.inspect}."
        end
        s.close
      end

      while line = gets
        line = line.strip
        if line == "RESTART"
          s.restart
          puts "RESTART OK"
          sleep 2
        elsif line == "HARD_RESTART"
          s.hard_restart
          puts "RESTART OK"
          sleep 2
        else
          s.print line + "\r\n"
          s.flush
        end
      end
    rescue Errno::ECONNREFUSED => e
      $stderr.puts "Connection refused..."
      retry
    rescue => e
      $stderr.puts "Fatal pipe: #{e.inspect}"
    end
  end
end
