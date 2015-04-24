require 'timeout'
require 'rspec/expectations'
require 'active_support'
require 'active_support/core_ext/numeric'

#Useful RSpec helpers

#Make sure that a PROCESS at some PID is no longer active within N seconds
RSpec::Matchers.define :die_within do |seconds|
  match do |pid|
    begin
      Timeout::timeout(seconds) { Process.waitpid(pid) }
    rescue Timeout::Error
      return false
    rescue Errno::ECHILD => e
      $stderr.puts "Process with pid: #{pid} does not exist (or may be part of another process group)"
      raise e
    ensure
      begin
        Process.kill(:KILL, pid)
      rescue Errno::ESRCH
      end
    end

    return true
  end

  description do
    "die within #{seconds.inspect}"
  end
end

RSpec::Matchers.define :raise_within do |seconds|
  match do |pid|
    begin
      Timeout::timeout(seconds) { Process.waitpid(pid) }
    rescue Timeout::Error
      return false
    rescue Errno::ECHILD => e
      $stderr.puts "Process with pid: #{pid} does not exist (or may be part of another process group)"
      raise e
    ensure
      Process.kill(:KILL, pid)
    end

    return true
  end

  description do
    "die within #{seconds.inspect}"
  end
end
