require 'therubyracer'

shared_context "kern" do
  before(:each) do
    res=system('rake build:world')
    raise "Could not run build:world" unless res
    @ctx = V8::Context.new
    @ctx.load "./products/#{ENV['PLATFORM']}/application.js"

    if ENV['RUBY_PLATFORM'] =~ /darwin/
      `killall phantomjs`
      `killall rspec`
    end
  end
end
