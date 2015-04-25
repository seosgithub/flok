Dir.chdir File.join File.dirname(__FILE__), '../../../'
require './spec/env/iface.rb'

RSpec.describe "iface:driver:ping_spec" do
  include_context "iface:driver"
  ping_suite
end
