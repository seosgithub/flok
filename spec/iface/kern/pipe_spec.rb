Dir.chdir File.join File.dirname(__FILE__), '../../../'
require './spec/env/iface.rb'
RSpec.describe "kern:pipe" do
  include_context "kern"
  pipe_suite
end
