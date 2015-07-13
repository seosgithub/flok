# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'flok/version'

Gem::Specification.new do |spec|
  spec.name          = "flok"
  spec.version       = Flok::VERSION
  spec.authors       = ["seo"]
  spec.email         = ["seotownsend@icloud.com"]
  spec.summary       = "A boring javascript application framework"
  spec.description   = "Flok is a cross-platform application framework system that exports javascript files"
  spec.homepage      = "https://github.com/sotownsend/flok"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "execjs", "~> 2.5"
  spec.add_runtime_dependency "bundler", "~> 1.6"
  spec.add_runtime_dependency "rspec", "~> 3.2"
  spec.add_runtime_dependency 'webrick', '~> 1.3'
  spec.add_runtime_dependency "closure-compiler", "~> 1.1"
  spec.add_runtime_dependency "phantomjs", "~> 1.9"
  spec.add_runtime_dependency "pry", "~> 0.10"
  spec.add_runtime_dependency "rspec-wait", "~> 0.0"
  spec.add_runtime_dependency "os", "0.9.6"
  spec.add_runtime_dependency "boojs", "~> 0.0"
  spec.add_runtime_dependency "activesupport", "~> 4.2"
  spec.add_runtime_dependency "cakery", "~> 0.0"
  spec.add_runtime_dependency "thor", "~> 0.19"
  spec.add_runtime_dependency "rake", "~> 10.3"
  spec.add_development_dependency "therubyracer", "~> 0.12"
  spec.executables << 'flok'
end
