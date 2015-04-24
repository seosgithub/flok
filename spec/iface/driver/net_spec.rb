require './spec/env/iface.rb'
require './spec/lib/helpers.rb'

RSpec.describe "driver:net" do
  include_context "driver"

  #it "Can call a network request" do
    #@pipe.puts [3, "if_net_req", "GET", "http://some_url.com", {}].to_json
    #sleep 3

    #Timeout.timeout(1) { @pipe.eof? } rescue "ok"
  #end

  #it "Can make a network request" do
    #begin
      #@called = false
      #web = Webbing.get "/" do
        #@called = true
      #end

      #@pipe.puts [3, "if_net_req", "GET", "http://localhost:#{web.port}", {}].to_json
      #select [@pipe], [], [], 12
      #expect(@called).to eq(true)
    #ensure
      #Process.kill(:KILL, web.pid)
    #end
  #end
end
