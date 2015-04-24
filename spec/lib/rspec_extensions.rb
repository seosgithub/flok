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
      #Process no longer exists (waitpid)
    ensure
      begin
        Process.kill(:KILL, pid)
      rescue Errno::ESRCH
        #Process no longer exists (tried signal)
      end
    end

    return true
  end

  description do
    "die within #{seconds.inspect}"
  end
end

RSpec::Matchers.define :raise_eof_within do |seconds|
  match do |pipe|
    pid = pipe.pid

    begin
      Timeout::timeout(seconds) do
        pipe.readline
      end
    rescue Timeout::Error
      return false
    rescue Errno::ECHILD => e
      #Process no longer exists (waitpid)
    rescue EOFError
      return true
    ensure
      begin
        Process.kill(:KILL, pid)
      rescue Errno::ESRCH
        #Process no longer exists (tried signal)
      end
    end

    return false
  end

  description do
    "raise EOF within #{seconds.inspect}"
  end
end
