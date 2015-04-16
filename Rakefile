require 'rspec/core/rake_task'
require "bundler/gem_tasks"

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
