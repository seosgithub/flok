require './spec/env/iface.rb'

RSpec.describe "driver:ping_spec" do
  include_context "driver"
  ping_suite
end
