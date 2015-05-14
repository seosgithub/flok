Dir.chdir File.join File.dirname(__FILE__), '../../../'
require './spec/env/iface.rb'

RSpec.describe "iface:driver:debug_spec" do
  include_context "iface:driver"
  module_dep "debug"

  it "supports if_debug_set_kv" do
    secret = SecureRandom.hex
    @pipe.puts [[0, 2, "if_debug_set_kv", secret, {"secret" => secret}]].to_json
    @pipe.puts [[0, 1, "if_debug_spec_kv", secret]].to_json
    expect(@pipe).to readline_and_equal_json_x_within_y_seconds([1, "spec", {"secret" => secret}], 6.seconds)
  end
end
