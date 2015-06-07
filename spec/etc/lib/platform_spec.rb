Dir.chdir File.join File.dirname(__FILE__), '../../../'
require './lib/flok'
require './spec/lib/temp_dir'

#We are using the CHROME module as a test because it's fairly standardized

RSpec.describe "lib/platform" do
  it "can list drivers" do
    platforms = Flok.platforms
    expect(platforms.class).to eq(Array)
    expect(platforms.first.class).to eq(String)
    expect(platforms).to include("chrome")
  end

  it "can list specific config_yml" do
    debug_yml = Flok::Platform.config_yml("DEBUG")
    release_yml = Flok::Platform.config_yml("RELEASE")

    expect(debug_yml.keys.count).not_to eq(0)

    #Should not have same modules (at least for chrome)
    expect(release_yml["mods"].count).not_to eq(release_yml.keys.count)
  end

  it "can list modules specific to an environment" do
    config_yml = File.read("./spec/etc/lib/assets/config.yml")
    Dir.chdir new_temp_dir do
      File.write "config.yml", config_yml
      ENV['FLOK_CONFIG'] = './config.yml'

      debug_mods = Flok::Platform.mods("DEBUG")

      expect(debug_mods).to include("hello")
      ENV['FLOK_CONFIG'] = nil
    end
  end
end
