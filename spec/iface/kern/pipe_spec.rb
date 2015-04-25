Dir.chdir File.join File.dirname(__FILE__), '../../../'
require './spec/env/iface.rb'
RSpec.describe "iface:kern:pipe" do
  include_context "iface:kern"
  pipe_suite
end
