require 'therubyracer'
@ctx = V8::Context.new
@ctx.load "./products/#{ENV['PLATFORM']}/application.js"
