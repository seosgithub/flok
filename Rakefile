require 'rspec/core/rake_task'
require "bundler/gem_tasks"
require "fileutils"
require 'tmpdir'
require './lib/flok'

# Default directory to look in is `/specs`
# Run with `rake spec`
RSpec::Core::RakeTask.new(:spec)

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
