Dir.chdir File.join File.dirname(__FILE__), '../../../'
require './spec/env/iface.rb'
require './spec/lib/helpers.rb'
require './spec/lib/io_extensions.rb'
require './spec/lib/rspec_extensions.rb'

RSpec.describe "iface:driver:persist" do
  module_dep "persist"
  include_context "iface:driver"

  it "Can receive persist API messages without crashing" do
    #Disk is scheduling class 2
    @pipe.puts [[2, 3, "if_per_set", "my_ns", "my_key", "my_value"]].to_json
    @pipe.puts [[2, 3, "if_per_get", "session", "my_ns", "my_key"]].to_json
    @pipe.puts [[0, 3, "if_per_get_sync", "session", "my_ns", "my_key"]].to_json
    @pipe.puts [[2, 2, "if_per_del", "my_ns", "my_key"]].to_json
    @pipe.puts [[2, 1, "if_per_del_ns", "my_ns"]].to_json
    @pipe.puts [[0, 0, "if_per_flush_sync"]].to_json

    #Wait for response
    @pipe.puts [[0, 0, "ping"]].to_json; @pipe.readline_timeout
  end
end
