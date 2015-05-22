require "flok/version"
require "flok/utilities"
require "flok/build"
require "flok/platform"
require "flok/project"

if ENV["FLOK_ENV"] == "DEBUG"
  require "flok/interactive"
  require "flok/user_compiler"
  require "flok/services_compiler"
end

module Flok
end
