Dir.chdir File.join File.dirname(__FILE__), '../../../'
require './spec/env/iface.rb'

RSpec.describe "iface:driver:debug_spec" do
  include_context "iface:driver"
  module_dep "debug"

  #it "supports if_debug_set_kv" do
    #secret0 = SecureRandom.hex
    #secret1 = SecureRandom.hex
    #secret2 = SecureRandom.hex
    #@pipe.puts [[0, 3, "if_debug_assoc", secret0, secret1, {"secret" => secret2}]].to_json
    #@pipe.puts [[0, 2, "if_debug_spec_assoc", secret0, secret1]].to_json
    #expect(@pipe).to readline_and_equal_json_x_within_y_seconds([1, "spec", {"secret" => secret2}], 6.seconds)
  #end

  #it "supports if_debug_attach" do
    #@pipe.puts [[0, 0, "if_debug_attach"]].to_json

    ##Wait for response
    #@pipe.puts [[0, 0, "ping"]].to_json; @pipe.readline_timeout
  #end

  it "does attach to socket.io server" do
    settings_dep "debug_attach", "socket_io"

    @pipe.puts [[0, 0, "if_debug_attach"]].to_json

    #Wait for response
    @pipe.puts [[0, 0, "ping"]].to_json; @pipe.readline_timeout
  end
end
