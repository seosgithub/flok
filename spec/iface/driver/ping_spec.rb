Dir.chdir File.join File.dirname(__FILE__), '../../../'
require './spec/env/iface.rb'

RSpec.describe "driver:ping_spec" do
  include_context "driver"
  ping_suite
end
