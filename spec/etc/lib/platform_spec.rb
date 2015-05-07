Dir.chdir File.join File.dirname(__FILE__), '../../../'
require './lib/flok'

RSpec.describe "lib/platform" do
  it "can list drivers" do
    platforms = Flok.platforms
    expect(platforms.class).to eq(Array)
    expect(platforms.first.class).to eq(String)
    expect(platforms).to include("chrome")
  end
end
