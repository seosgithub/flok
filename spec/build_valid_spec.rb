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
    platforms = (Dir["./app/drivers/*"]).map!{|e| File.basename(e)} - ["iface"]

    platforms.each do |p|
      build_world_for_platform(p)

      ctx = ExecJS.compile(File.read("./products/#{p}/application.js"))
    end
  end

  it "supports IFACES global" do
    #get a list of the platforms based on the drev folder names
    platforms = (Dir["./app/drivers/*"]).map!{|e| File.basename(e)} - ["iface"]

    platforms.each do |p|
      build_world_for_platform(p)

      #IFACES
      ctx = ExecJS.compile(File.read("./products/#{p}/application.js"))
      ifaces = ctx.eval("IFACES")
      driver_ifaces = YAML.load_file("./app/drivers/#{p}/config.yml")["ifaces"]
      expect(ifaces).to eq(driver_ifaces)
    end
  end

  it "supports PLATFORM global" do
    #get a list of the platforms based on the drev folder names
    platforms = (Dir["./app/drivers/*"]).map!{|e| File.basename(e)} - ["iface"]

    platforms.each do |p|
      build_world_for_platform(p)

      ctx = ExecJS.compile(File.read("./products/#{p}/application.js"))
      platform = ctx.eval("PLATFORM")
      expect(platform).to eq(p)
    end
  end

  it "Supports only interfaces that exist in ./app/drivers/iface/$iface.js and ./app/kern/int/$iface.js" do
    #get a list of the platforms based on the drev folder names
    platforms = (Dir["./app/drivers/*"]).map!{|e| File.basename(e)} - ["iface"]

    platforms.each do |p|
      build_world_for_platform(p)

      ctx = ExecJS.compile(File.read("./products/#{p}/application.js"))
      driver_ifaces = YAML.load_file("./app/drivers/#{p}/config.yml")["ifaces"]

      #Load each javascript file
      driver_ifaces.each do |iface|
        begin
          js = File.open("./app/drivers/iface/#{iface}.js")
        rescue Errno::ENOENT => e
          raise "The interface called #{iface} does not exist. Tried to use this in #{p.inspect}, it's defined in config.yml under ifaces"
        end

        begin
          js = File.open("./app/kern/int/#{iface}.js")
        rescue Errno::ENOENT => e
          raise "Your interface '#{iface}' does not contain a complementary interrupt file in './app/kern/int/#{iface}.js'. Please make a blank one for now"
        end

      end
    end

  end
end
