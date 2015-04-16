require 'rspec/core/rake_task'
require "bundler/gem_tasks"
require "fileutils"

# Default directory to look in is `/specs`
# Run with `rake spec`
RSpec::Core::RakeTask.new(:spec)

task :default => :spec

#Upgrade version of gem
def upgrade_version
  versionf = './lib/flok/version.rb'
  require versionf

  #Upgrade version '0.0.1' => '0.0.2'
  version = Flok::VERSION
  new_version = version.split(".")
  new_version[2] = new_version[2].to_i + 1
  new_version = new_version.join(".")

  sreg = "s/#{version}/#{new_version}/"
  puts `sed #{sreg} #{versionf} > tmp; cp tmp #{versionf}`
  `rm tmp`

  return new_version
end

task :push do
  version = upgrade_version
  `git add .`
  `git commit -a -m 'gem #{version}'`
  `git push`
  `git tag #{version}`
  `git push origin #{version}`
  `gem build flok.gemspec`
  `gem push flok-#{version}.gem`
  `rm flok-#{version}.gem`
end

task :compile do
  `rm ./products/application.js`
  `ruby -Ilib ./bin/flok build`
  `osascript -e 'tell application "Keyboard Maestro Engine" to do script "3B15D84D-30B0-4DC5-91BA-91BBE0AA340B"'`
end

task :test_env do
  puts ENV["FUCK"]
end

#Update documents to github
task :udocs do
  `git add ./docs/*`
  `git add README.md`
  `git commit -a -m "Update docs"`
  `git push`
end

#Compliation
#######################################################################################################################################################
#Accepts a folder and will mix all those files into one file
def glob type, dir_path, output_path
  out = ""
  FileUtils.mkdir_p(dir_path)
  FileUtils.mkdir_p(File.dirname(output_path))
  Dir[File.join(dir_path, "*.#{type}")].each do |f|
    out << File.read(f) << "\n"
  end

  File.write(output_path, out)
end

require 'yaml'
require 'json'
def add_etc_commands output
  #Add the lsiface() command
  raise "No config.yml found in your 'platform: #{PLATFORM}' driver" unless driver_config = YAML.load_file("./app/drivers/#{PLATFORM}/config.yml")
  iface_arr = "[" + driver_config['ifaces'].map!{|e| "'#{e}'"}.join(", ") + "]"
  puts `echo "function lsiface() { return #{iface_arr}; }" >> #{output}`
end

task :build_world do
  #What platform are we working with?
  raise "No $PLATFORM given" unless PLATFORM = ENV["PLATFORM"]
  BUILD_PATH = "./products/#{PLATFORM}"
  `rm -rf #{BUILD_PATH}`

  #1. `rake build` is run inside `./app/drivers/$PLATFORM` with the environmental variables set to BUILD_PATH=`./produts/$PLATFORM/driver` (and folder
  driver_build_path = File.expand_path("drivers", BUILD_PATH)
  FileUtils.mkdir_p driver_build_path
  Dir.chdir("./app/drivers/#{PLATFORM}") do 
   `rake build BUILD_PATH=#{driver_build_path}`
  end

  #2. All js files in `./app/kern/config/*.js` are globbed togeather and sent to `./products/$PLATFORM/glob/1kern_config.js`
  glob("js", './app/kern/config', "#{BUILD_PATH}/glob/1kern_config.js")

  #3. All js files in `./app/kern/*.js` are globbed togeather and sent to `./products/$PLATFORM/glob/2kern.js`
  glob("js", './app/kern', "#{BUILD_PATH}/glob/2kern.js")

  #4. All js files are globbed from `./products/$PLATFORM/glob` and combined into `./products/$PLATFORM/application.js`
  glob("js", "#{BUILD_PATH}/glob", "#{BUILD_PATH}/application.js")

  #5. Add custom commands
  add_etc_commands "#{BUILD_PATH}/application.js"

  `rm -rf #{BUILD_PATH}/glob`
end
#######################################################################################################################################################
