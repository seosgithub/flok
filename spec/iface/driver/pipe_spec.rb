Dir.chdir File.join File.dirname(__FILE__), '../../../'
require './spec/env/iface.rb'

RSpec.describe "driver:pipe_spec" do
  include_context "driver"
  pipe_suite
end
