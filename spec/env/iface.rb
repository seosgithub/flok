require 'json'
require './spec/lib/rspec_extensions'
require 'open3'
require 'timeout'
require 'securerandom'

shared_context "iface:kern" do
  before(:each) do
    @pipe = IO.popen("rake pipe:kern", "r+")
    @pid = @pipe.pid
  end

  after(:each) do
    begin
      Process.kill(:KILL, @pid)
    rescue Errno::ESRCH
    end
  end
end

shared_context "iface:driver" do
  before(:each) do 
    @pipe = IO.popen("rake pipe:driver", "r+") 
    @pid = @pipe.pid
    
    $stderr.puts "starting, PID = #{@pid}"
    if ENV['RUBY_PLATFORM'] =~ /darwin/
      `killall phantomjs`
      `killall rspec`
    end
  end

  after(:each) do
    $stderr.puts "killing, PID = #{@pid}"
    begin
      Process.kill(:INT, @pid)
    rescue Errno::ESRCH
      $stderr.puts "err, no process"
    end
  end
end
