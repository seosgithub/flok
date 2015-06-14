Dir.chdir File.join File.dirname(__FILE__), '../../../'
require './lib/flok'
require './spec/env/etc'

RSpec.describe "lib/project" do
  it "can list project_template files" do
    ls = Flok::Project.list
    #Subject to change but it's just a basic test
    expect(ls).to include("Gemfile")
    expect(ls).to include("app/controllers")
  end

  it "can create project_template files" do
    dir = new_temp_dir
    Dir.chdir dir do
      Flok::Project.create "test"
      Dir.chdir "test" do
        #This is subject to change, but it's just a basic test
        expect(dirs).to include("app")
        expect(dirs).to include("app/controllers")
        expect(files).to include("Gemfile")
      end
    end
  end

  it "Does contain a copy of the config.yml for the currently active platform in ./config/platforms/$PLATFORM/config.yml" do
    platform = ENV['PLATFORM']

    dir = new_temp_dir
    Dir.chdir dir do
      Flok::Project.create "test"
      Dir.chdir "test" do
        #Directory ./config/platforms/$PLATFORM should exist
        expect(dirs).to include("config/platforms/#{platform}")
        
        #File ./config/platforms/$PLATFORM/config.yml should exist
        Dir.chdir "./config/platforms/#{platform}" do
          expect(files).to include("config.yml")
        end

        #Files should match in config
        platform_config_path = File.join(File.dirname(__FILE__), "../../../app/drivers/#{platform}/config.yml")
        expect(File.read("./config/platforms/#{platform}/config.yml").strip).to eq(File.read(platform_config_path).strip)
      end
    end
  end
end
