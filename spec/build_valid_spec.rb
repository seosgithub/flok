#This spec checks to make sure that for each driver, the emitted javascript file actually executes correctly
#In addition, it runs a sanity check by calling flok()

require 'execjs'
require 'helpers'
require 'flok/build'

def build_world_for_platform platform
  Flok.system!("rake build_world PLATFORM=#{platform}")
end

RSpec.describe "Emitted build products are valid for all platforms" do
  it "can run application.js on execjs environment without runtime initial failure" do
    #get a list of the platforms based on the drev folder names
    platforms = (Dir["./app/drivers/*"]).map!{|e| File.basename(e)} - ["mods"]

    platforms.each do |p|
      build_world_for_platform(p)

      ctx = ExecJS.compile(File.read("./products/#{p}/application.js"))
    end
  end

  it "supports mods global" do
    #get a list of the platforms based on the drev folder names
    platforms = (Dir["./app/drivers/*"]).map!{|e| File.basename(e)} - ["mods"]

    platforms.each do |p|
      build_world_for_platform(p)

      #mods
      ctx = ExecJS.compile(File.read("./products/#{p}/application.js"))
      mods = ctx.eval("mods")
      driver_mods = YAML.load_file("./app/drivers/#{p}/config.yml")["mods"]
      expect(mods).to eq(driver_mods)
    end
  end

  it "supports PLATFORM global" do
    #get a list of the platforms based on the drev folder names
    platforms = (Dir["./app/drivers/*"]).map!{|e| File.basename(e)} - ["mods"]

    platforms.each do |p|
      build_world_for_platform(p)

      ctx = ExecJS.compile(File.read("./products/#{p}/application.js"))
      platform = ctx.eval("PLATFORM")
      expect(platform).to eq(p)
    end
  end

  it "Supports only interfaces that exist in ./app/drivers/mods/$mods.js and ./app/kern/int/$mods.js" do
    #get a list of the platforms based on the drev folder names
    platforms = (Dir["./app/drivers/*"]).map!{|e| File.basename(e)} - ["mods"]

    platforms.each do |p|
      build_world_for_platform(p)

      ctx = ExecJS.compile(File.read("./products/#{p}/application.js"))
      driver_mods = YAML.load_file("./app/drivers/#{p}/config.yml")["mods"]

      #Load each javascript file
      driver_mods.each do |mods|
        begin
          js = File.open("./app/drivers/mods/#{mods}.js")
        rescue Errno::ENOENT => e
          raise "The interface called #{mods} does not exist. Tried to use this in #{p.inspect}, it's defined in config.yml under mods"
        end

        begin
          js = File.open("./app/kern/int/#{mods}.js")
        rescue Errno::ENOENT => e
          raise "Your interface '#{mods}' does not contain a complementary interrupt file in './app/kern/int/#{mods}.js'. Please make a blank one for now"
        end

      end
    end
  end

  it "The outputted code has all the code located in ./app/kern/int/ for relavent interfaces" do
    #get a list of the platforms based on the drev folder names
    platforms = (Dir["./app/drivers/*"]).map!{|e| File.basename(e)} - ["mods"]

    platforms.each do |p|
      build_world_for_platform(p)

      app_output = File.read "./products/#{p}/application.js"

      mods = YAML.load_file("./app/drivers/#{p}/config.yml")["mods"]

      mods.each do |mods|
        intf = File.read("./app/kern/int/#{mods}.js")
        expect(app_output).to include(intf)
      end
    end
  end
end
