require 'yaml'
require 'json'

##################################################################
#This file contains everything relating to compiling source files
##################################################################

module Flok
  #Merge a bunch of source files
  #Take everything in a DIR_PATH folder that matches the TYPE and put it in a file OUTPUT_PATH
  #Will also create the path if it dosen't exist
  def self.src_glob type, dir_path, output_path
    out = ""
    FileUtils.mkdir_p(dir_path)
    FileUtils.mkdir_p(File.dirname(output_path))
    Dir[File.join(dir_path, "*.#{type}")].each do |f|
      out << File.read(f) << "\n"
    end

    File.write(output_path, out)
  end

  #Build the whole world for a certain platform
  def self.build_world build_path, platform
    #What platform are we working with?
    `rm -rf #{build_path}`

    #1. `rake build` is run inside `./app/drivers/$platform`
    driver_build_path = File.expand_path("drivers", build_path)
    FileUtils.mkdir_p driver_build_path
    Dir.chdir("./app/drivers/#{platform}") do 
    system!("rake build BUILD_PATH=#{driver_build_path}")
    end

    #2. All js files in `./app/kern/config/*.js` are globbed togeather and sent to `./products/$platform/glob/1kern_config.js`
    Flok.src_glob("js", './app/kern/config', "#{build_path}/glob/1kern_config.js")

    #3. All js files in `./app/kern/*.js` are globbed togeather and sent to `./products/$platform/glob/2kern.pre_macro.js`
    Flok.src_glob("js", './app/kern', "#{build_path}/glob/2kern.pre_macro.js")

    #4. All js files in `./products/$PLATFORM/glob/2kern.pre_macro.js` are run through `./app/kern/macro.rb's macro_process` and then sent to ./products/$PLATFORM/glob/2kern.js 
    require './app/kern/macro.rb'
    File.write("#{build_path}/glob/2kern.pre_macro.js", macro_process(File.read("#{build_path}/glob/2kern.pre_macro.js")))

    #5. All js files are globbed from `./products/$platform/glob` and combined into `./products/$platform/application.js`
    Flok.src_glob("js", "#{build_path}/glob", "#{build_path}/application.js")

    #6. Add custom commands
    ################################################################################################################
    #MODS - List mods listed in config.yml
    #---------------------------------------------------------------------------------------
    #Load the driver config.yml
    driver_config = YAML.load_file("./app/drivers/#{platform}/config.yml")
    raise "No config.yml found in your 'platform: #{platform}' driver" unless  driver_config

    #Create array that looks like a javascript array with single quotes
    mods = driver_config['mods']
    mods_js_arr = "[" + mods.map{|e| "'#{e}'"}.join(", ") + "]"

    #Append this to our output file
    `echo "MODS = #{mods_js_arr};" >> #{build_path}/application.js`
    `echo "PLATFORM = \'#{platform}\';" >> #{build_path}/application.js`
    #---------------------------------------------------------------------------------------
    ################################################################################################################

    #7. Append relavent mods code in kernel
    mods.each do |mod|
      s = File.read("./app/kern/mod/#{mod}.js")
      open("#{build_path}/application.js", "a") do |f|
        f.puts s
      end

    end

    `rm -rf #{build_path}/glob`
  end
end
