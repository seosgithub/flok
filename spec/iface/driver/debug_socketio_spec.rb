Dir.chdir File.join File.dirname(__FILE__), '../../../'
require './spec/env/iface.rb'

#Relates to the debug server for drivers that declare "socket_io" in their debug_attach

RSpec.describe "iface:driver:debug_server_ws_spec" do
  include_context "iface:driver"
  module_dep "debug"

  #it "does attach to socket.io server when one is present" do
    #settings_dep "debug_attach", "socket_io"

    ##Start up the node server and wait for a CLIENT CONNECTED response
    #sh2 "node", "./spec/iface/driver/assets/debug_socket_server.js", /STARTED/ do |inp, out|
      #expect(out).to readline_and_equal_x_within_y_seconds("CLIENT CONNECTED", 10.seconds)
    #end
  #end

  #it "does redirect traffic from 'server' to driver via socket.io server after it receives an attach event" do
    #settings_dep "debug_attach", "socket_io"

    ##Start up the node server and wait for a CLIENT_CONNECTED response
    #sh2 "node", "./spec/iface/driver/assets/debug_socket_server.js", /STARTED/ do |inp, out|
      ##Still expect a connect message
      #expect(out).to readline_and_equal_x_within_y_seconds("CLIENT CONNECTED", 10.seconds)

      ##Send an attach request
      #inp.puts({:type => "attach", :msg => {}}.to_json)

      ##Send a message to the driver
      #@pipe.puts [[0, 0, "ping"]].to_json

      ##Expect that message on the debug server
      #expect(out).to readline_and_equal_x_within_y_seconds("if_dispatch", 5.seconds)
      #expect(out).to readline_and_equal_json_x_within_y_seconds([[0, 0, "ping"]], 5.seconds)
    #end
  #end

  #it "does NOT redirect traffic from 'server' to driver via socket.io server after it DOES NOT receives an attach event" do
    #settings_dep "debug_attach", "socket_io"

    ##Start up the node server and wait for a CLIENT_CONNECTED response
    #sh2 "node", "./spec/iface/driver/assets/debug_socket_server.js", /STARTED/ do |inp, out|
      ##Still expect a connect message
      #expect(out).to readline_and_equal_x_within_y_seconds("CLIENT CONNECTED", 10.seconds)

      ##Send a message to the driver
      #@pipe.puts [[0, 0, "ping"]].to_json

      ##Expect that message on the debug server
      #expect(out).not_to readline_and_equal_x_within_y_seconds("if_dispatch", 5.seconds)
    #end
  #end

  it "can send int_dispatch to the socket.io server, have that go to the driver, who should try to signal the kernel" do
    settings_dep "debug_attach", "socket_io"

    #Start up the node server and wait for a CLIENT_CONNECTED response
    sh2 "node", "./spec/iface/driver/assets/debug_socket_server.js", /STARTED/ do |inp, out|
      #Still expect a connect message
      expect(out).to readline_and_equal_x_within_y_seconds("CLIENT CONNECTED", 10.seconds)

      #Send an attach request
      inp.puts({:type => "attach", :msg => {}}.to_json)

      #Tell the socket.io server to forward a ping request via int_dispatch
      #stdin => server => driver client
      inp.puts({:type => 'int_dispatch', :msg => [0, 0, "ping"]}.to_json) #Single array because it's going to the kernel

      #Driver should forward message as-is
      expect(@pipe).to readline_and_equal_json_x_within_y_seconds([0, 0, "ping"], 5.seconds)
    end
  end

  #it "can send if_dispatch to the socket.io server, have that go to the driver, who should act on it" do
    #settings_dep "debug_attach", "socket_io"

    ##Request attachment (should periodically attempt to connect)
    #@pipe.puts [[0, 0, "if_debug_attach"]].to_json

    ##Start up the node server and wait for a CLIENT_CONNECTED response
    #sh2 "node", "./spec/iface/driver/assets/debug_socket_server.js", /STARTED/ do |inp, out|
      ##Still expect a connect message
      #expect(out).to readline_and_equal_x_within_y_seconds("CLIENT CONNECTED", 10.seconds)

      ##Tell the socket.io server to forward a ping request via int_dispatch
      ##stdin => server => driver client
      #inp.puts({:type => 'if_dispatch', :msg => [[0, 0, "ping"]]}.to_json) #Double array as it's going to driver

      ##Expect that the driver replies
      #expect(@pipe).to readline_and_equal_json_x_within_y_seconds([0, "pong"], 5.seconds)
    #end
  #end

  #it "does relay the second if_event through back to the debug server, the first will be sent to the kernel and the second attempt should be captured" do
    #settings_dep "debug_attach", "socket_io"

    ##Request attachment (should periodically attempt to connect)
    #@pipe.puts [[0, 0, "if_debug_attach"]].to_json

    ##Start up the node server and wait for a CLIENT_CONNECTED response
    #sh2 "node", "./spec/iface/driver/assets/debug_socket_server.js", /STARTED/ do |inp, out|
      ##Still expect a connect message
      #expect(out).to readline_and_equal_x_within_y_seconds("CLIENT CONNECTED", 10.seconds)

      ##Send a message to the driver
      #@pipe.puts [[0, 0, "if_2"]].to_json

      ##Expect that message on the debug server
      #expect(out).to readline_and_equal_x_within_y_seconds("if_dispatch", 5.seconds)
      #expect(out).to readline_and_equal_json_x_within_y_seconds([[0, 0, "ping"]], 5.seconds)

      ##Expect that the actual driver does not emit pong at this time, it should just forward to debug
      ##server and ignore it for the time being
      #expect(@pipe).not_to readline_and_equal_json_x_within_y_seconds([0, "pong"], 6.seconds)
    #end
  #end

  #it "does send traffic origanating from the driver via int to the debug server" do
    #settings_dep "debug_attach", "socket_io"

    ##Request attachment (should periodically attempt to connect)
    #@pipe.puts [[0, 0, "if_debug_attach"]].to_json

    ##Start up the node server and wait for a CLIENT_CONNECTED response
    #sh2 "node", "./spec/iface/driver/assets/debug_socket_server.js", /STARTED/ do |inp, out|
      ##Still expect a connect message
      #expect(out).to readline_and_equal_x_within_y_seconds("CLIENT CONNECTED", 10.seconds)

      ##Send a message to the driver that should tell the driver directly to trigger an int_event named spec
      #inp.puts({:type => "if_dispatch", :msg => [[0, 0, "if_debug_spec_send_int_event"]]}.to_json)

      ##Expect that message on the debug server
      #expect(out).to readline_and_equal_x_within_y_seconds("int_dispatch", 5.seconds)
      #expect(out).to readline_and_equal_json_x_within_y_seconds([0, "spec"], 5.seconds)

      ##Ensure it dosen't crash, which would happen if it's not being rerouted and simplpy duplicated
      #sleep 4
    #end
  #end
end
