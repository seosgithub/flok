require 'rspec/core/rake_task'
require "bundler/gem_tasks"
require "fileutils"
require './lib/flok'

#Gem things
#############################################################################
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

task 'gem:push' do
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

#Will build and install the development GEM
#but will not push it out or upgrade the version
#WARNING: It will also remove any copies of flok you currently
task 'gem:install' do
  #Remove current version
  $stderr.puts "Removing gem if necessary... This may give a warning but it's ok"
  $stderr.puts "------------------------------------------------------"
  system('gem uninstall -xa flok')
  $stderr.puts "------------------------------------------------------\n\n"

  #Build gem
  $stderr.puts "Attempting to build gem..."
  $stderr.puts "------------------------------------------------------"
  res = system('gem build flok.gemspec')
  raise "Could not build gem" unless res
  $stderr.puts "------------------------------------------------------\n\n"

  #Install gem
  $stderr.puts "Attempting to install gem..."
  $stderr.puts "------------------------------------------------------"
  res = system("gem install flok-#{Flok::VERSION}.gem")
  raise "Could not install gem" unless res
  $stderr.puts "------------------------------------------------------"
end

#Compile
#############################################################################
namespace :build do
  task :world do
    #What platform are we working with?
    raise "No $PLATFORM given" unless platform = ENV["PLATFORM"]
    raise "No $FLOK_ENV given" unless environment = ENV["FLOK_ENV"]

    build_path = "./products/#{platform}"

    Flok.build_world(build_path, platform, environment)
  end
end

#Server Pipe
#############################################################################
namespace :pipe do
  task :kern => 'build:world' do
    #Get the platform we are on
    platform = ENV["PLATFORM"]
    raise "No $PLATFORM given" unless platform
    ENV["FLOK_ENV"] = "DEBUG"

    exec "ruby", "-e", %{
      require 'flok'
      platform = ENV["PLATFORM"]
      server = Flok::InteractiveServer.new File.join ['products', platform, 'application.js']
      server.begin_pipe
    }
  end

  task :driver do
    #Get the platform we are on
    platform = ENV["PLATFORM"]
    raise "No $PLATFORM given" unless platform 

    build_path = File.join ["../../../", "products", platform, "drivers"]
    exec "cd ./app/drivers/#{platform}; rake pipe BUILD_PATH=#{build_path}"
  end
end

#Testing
#############################################################################
namespace :spec do
  RSpec::Core::RakeTask.new(:_kern) do |t|
    t.pattern = "./spec/kern/*_spec.rb"
    ENV["FLOK_ENV"] = "DEBUG"
  end
  task :kern => ['build:world', :_kern]

  RSpec::Core::RakeTask.new(:_iface) do |t|
    t.pattern = "./spec/iface/**/*_spec.rb"
    ENV["FLOK_ENV"] = "DEBUG"
  end
  task :iface => ['build:world', :_iface]

  RSpec::Core::RakeTask.new(:_etc) do |t|
    t.pattern = "./spec/etc/*_spec.rb"
    ENV["FLOK_ENV"] = "DEBUG"
  end
  task :etc => ['build:world', :_etc] 

  #Nice helper link
  task :driver do
    #Get platform
    platform = ENV['PLATFORM']
    raise "No platform given" unless platform

    #Start the driver rake suite
    system "cd ./app/drivers/#{platform}/; rake spec BUILD_PATH=../../products/#{platform}/driver"
    raise "Driver spec for platform #{platform} has failed" if $? != 0
  end

  task :world => ['etc', 'kern', 'iface', 'driver'] do
  end
end

task :spec do
  Flok.platforms.each do |p|
    Flok.system! "rake spec:world PLATFORM=#{p} FLOK_ENV=DEBUG"
  end
end

task :list_platforms do
  puts Flok.platforms.inspect
end
