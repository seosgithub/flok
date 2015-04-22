require 'open3'
require './spec/helpers.rb'

def driver_path
  return File.join("./app/drivers/", ENV['PLATFORM'])
end

def js_exec code
  #Remove newlines and replace them with semicolons
  code.strip!
  code.gsub!(/\n/, ";")

  @res = []
  Dir.chdir driver_path do
    begin
      Timeout.timeout(5) do
        IO.popen("rake pipe", "r+") do |p|
          begin
            p.puts code
            @res << p.readline
          ensure
            Process.kill(:KILL, p.pid)
          end
        end
      end
    rescue
      #Timeout completed, just use what ever we have for @res
    end
  end

  return @res
end

RSpec.describe "if_net" do
  it "can make a GET request" do
    web = Webbing.get "/" do |info|
      @called = true
    end

    js_exec %{
      if_net_request("GET", "http://localhost:#{web.port}", {})
    }
    expect(@called).to eq(true)
    Process.kill(:KILL, web.pid)
  end
end
