require './spec/env/iface.rb'
RSpec.describe "kern:pipe" do
  include_context "kern"
  pipe_suite
end
