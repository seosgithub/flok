Dir.chdir File.join File.dirname(__FILE__), '../../../'
require './spec/env/iface.rb'

RSpec.describe "iface:driver:about" do
  include_context "iface:driver"

  it "supports about" do
    @pipe.puts [[0, 0, "if_about_poll"]].to_json
    res =  @pipe.readline
    expect(res["platform"].class).to eq(String)
    expect(res["language"].class).to eq(String)
    expect(res["udid"].class).to eq(String)
  end
end
