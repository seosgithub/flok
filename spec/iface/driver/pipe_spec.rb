require './spec/env/iface.rb'

RSpec.describe "driver:pipe_spec" do
  include_context "driver"
  pipe_suite
end
