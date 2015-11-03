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

class InteractiveServer
  def initialize
  end

  #Will take over any remaining IO
  def begin_pipe
    begin
      #Connect to the pipe server on iOS
      s = TCPSocket.new 'localhost', PIPE_PORT
      $stderr.puts "waiting for HELLO..."
      line = s.gets.strip
      raise "Pipe server for apple-client didn't receive the correct HELLO response" if line != "HELLO"
      $stderr.puts "got HELLO!"
      $stderr.puts "connected"

      #Grab the device name
      device_uuid_info = `xcrun simctl list`.split("\n").detect{|e| e =~ /Booted/}
      raise "No booted device found via simctl list" unless device_uuid_info
      $stderr.puts "got uuid info = #{device_uuid_info.inspect}"
      device_uuid = device_uuid_info.split(" ")[2][1..-2].upcase
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
        s.print line + "\r\n"
        s.flush
      end
    rescue Errno::ECONNREFUSED => e
      $stderr.puts "Connection refused..."
      retry
    rescue => e
      $stderr.puts "Fatal pipe: #{e.inspect}"
    end
  end
end
