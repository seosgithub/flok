require 'rspec/core/rake_task'
require "bundler/gem_tasks"
require "fileutils"
require './lib/flok'

#Testing
#############################################################################
#spec:core
core_spec = RSpec::Core::RakeTask.new('spec:core')
core_spec.pattern = './spec/*.rb'

#spec:iface, accepts PLATFORM
task 'spec:iface' do
  raise "No platform given" unless platform=ENV['PLATFORM']
  exit system("rspec ./spec/iface")
end

#spec
task :spec do
  #Get a list of platforms
  Dir.chdir('./app/drivers') { @platforms = Dir["*"]-["iface"]}

  #Run each platform specific spec
  @platforms.each do |p|
    Dir.chdir "./app/drivers/#{p}" do
      tasks = `rake -P`.split("\n").map{|e| e.split(" ")[1]}
      if tasks.include? 'spec'
        Flok.system!('rake spec')
      end
    end
  end
end
#############################################################################

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
#############################################################################

#Compliation
#############################################################################
task :build_world do
  #What platform are we working with?
  raise "No $PLATFORM given" unless platform = ENV["PLATFORM"]
  build_path = "./products/#{platform}"

  Flok.build_world(build_path, platform)
end
#############################################################################

#Pipes
#############################################################################
task 'pipe:server' do
  #Get the platform we are on
  platform = ENV["PLATFORM"]
  raise "No $PLATFORM given" unless platform

  #Build the platform
  Flok.system!('rake build_world')

  exec "ruby", "-e", %{
    require 'flok'
    platform = ENV["PLATFORM"]
    server = Flok::InteractiveServer.new File.join ['products', platform, 'application.js']
    server.begin_pipe
  }
end
#############################################################################
