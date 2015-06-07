require 'yaml'
require 'json'
require 'erb'

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

  def self.src_glob_r type, dir_path, output_path
    out = ""
    Dir.chdir dir_path do
      FileUtils.mkdir_p(dir_path)
      FileUtils.mkdir_p(File.dirname(output_path))
      nodes = []
      nodes += Dir["./init/**/*.#{type}"].select{|e| File.file?(e)} 
      nodes += Dir["./config/**/*.#{type}"].select{|e| File.file?(e)} 
      final_nodes = Dir["./final/**/*.#{type}"].select{|e| File.file?(e)} 
      nodes += Dir["./*.#{type}"].select{|e| File.file?(e)}
      nodes += (Dir["./**/*"] - nodes - final_nodes).select{|e| File.file?(e)}
      nodes += final_nodes
      nodes.each do |f|
        out << File.read(f) << "\n"
      end
    end

    File.write(output_path, out)
  end

  #Build the whole world for a certain platform
  def self.build_world build_path, platform, environment
    #Environment must be either DEBUG or RELEASE
    raise "$FLOK_ENV must either be DEBUG or RELEASE, got #{environment.inspect}" unless %w{DEBUG RELEASE}.include? environment

    #Clean up previous build
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

    #5. All js files are globbed from `./products/$platform/glob` and combined into `./products/$platform/glob/application.js.erb`
    Flok.src_glob("js", "#{build_path}/glob", "#{build_path}/glob/application.js.erb")

    #6. Add custom commands
    ################################################################################################################
    #MODS - List mods listed in config.yml
    #---------------------------------------------------------------------------------------
    #Load the driver config.yml
    driver_config = YAML.load_file("./app/drivers/#{platform}/config.yml")
    raise "No config.yml found in your 'platform: #{platform}' driver" unless  driver_config

    #Create array that looks like a javascript array with single quotes
    mods = Flok::Platform.mods(environment)
    mods_js_arr = "[" + mods.map{|e| "'#{e}'"}.join(", ") + "]"

    #Append this to our output file
    `echo "MODS = #{mods_js_arr};" >> #{build_path}/glob/application.js.erb`
    `echo "PLATFORM = \'#{platform}\';" >> #{build_path}/glob/application.js.erb`
    #---------------------------------------------------------------------------------------
    ################################################################################################################

    #7. Append relavent mods code in kernel with macros
    mods.each do |mod|
      s = File.read("./app/kern/mod/#{mod}.js")
      open("#{build_path}/glob/application.js.erb", "a") do |f|
        f.puts macro_process(s)
      end
    end

    #8. The compiled `glob/application.js.erb` file is run through the ERB compiler and formed into `application.js`
    erb_src = File.read "#{build_path}/glob/application.js.erb"
    renderr = ERB.new(erb_src)
    context = ApplicationJSERBContext.new()
    new_src = renderr.result(context.get_binding)
    File.write "#{build_path}/application.js", new_src
  end

  class ApplicationJSERBContext
    def get_binding
      return binding
    end

    def initialize
      #Debug / Release
      @debug = (ENV['FLOK_ENV'] == "DEBUG")
      @release = (ENV['FLOK_ENV'] == "RELEASE")
      @mods = Flok::Platform.mods(ENV['FLOK_ENV'])
      @defines = Flok::Platform.defines(ENV['FLOK_ENV'])
    end
  end
end
