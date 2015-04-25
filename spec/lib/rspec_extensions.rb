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
    rescue Errno::ECHILD
      #Process no longer exists (waitpid)
    end

    return true
  end

  description do
    "die within #{seconds.inspect}"
  end
end

#Attempt to readline from IO, it should throw an EOF within N seconds
RSpec::Matchers.define :raise_eof_from_readline_within do |seconds|
  match do |pipe|
    begin
      Timeout::timeout(seconds) do
        pipe.readline
      end
    rescue Timeout::Error
      return false
    rescue Errno::ECHILD
      #Process no longer exists (waitpid)
    rescue EOFError
      return true
    end

    return false
  end

  match_when_negated do |pipe|
    begin
      Timeout::timeout(seconds) do
        pipe.readline
      end
    rescue Timeout::Error
      return true
    rescue Errno::ECHILD
      #Process no longer exists (waitpid)
    rescue EOFError
      return false
    end

    return true
  end

  description do
    "raise EOF within #{seconds.inspect}"
  end
end

#Attempt to readline from IO, it should return an STR within SECONDS
RSpec::Matchers.define :readline_and_equal_x_within_y_seconds do |str, seconds|
  match do |pipe|
    begin
      Timeout::timeout(seconds) do
        @res = pipe.readline.strip
        return true if @res == str
      end
    rescue Timeout::Error #Time out
    rescue EOFError #Couldn't read pipe
    end

    return false
  end

  failure_message do |actual|
    "expected that #{@res.inspect} to equal #{str.inspect}"
  end

  description do
    "readline and equal #{str.inspect} within #{seconds.inspect}"
  end
end

#Attempt to readline from IO, it should return an JSON object within SECONDS
RSpec::Matchers.define :readline_and_equal_json_x_within_y_seconds do |json, seconds|
  match do |pipe|
    begin
      Timeout::timeout(seconds) do
        @res = JSON.parse(pipe.readline.strip)
        return true if @res == json
      end
    rescue Timeout::Error #Time out
    rescue EOFError #Couldn't read pipe
    end

    return false
  end

  failure_message do |actual|
    "expected that the decoded JSON of #{@res.inspect} to equal #{json.inspect}"
  end

  description do
    "readline and equal #{str.inspect} within #{seconds.inspect}"
  end
end