Dir.chdir File.join File.dirname(__FILE__), '../../../'
require './spec/env/iface.rb'
require 'securerandom'

RSpec.describe "kern:ping_spec" do
  include_context "kern"
  ping_suite
end
