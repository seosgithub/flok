#
# Be sure to run `pod lib lint flok.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "flok"
  s.version          = "0.1.0"
  s.summary          = "This driver allows you to run flok applications on iOS, OS X, Apple Watch, and Apple TV."

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!  
  s.description      = <<-DESC
                       DESC

  s.homepage         = "https://github.com/sotownsend/flok"
  # s.screenshots     = "www.example.com/screenshots_1", "www.example.com/screenshots_2"
  s.license          = 'MIT'
  s.author           = { "seo" => "seotownsend@icloud.com" }
  s.source           = { :git => "https://github.com/sotownsend/flok.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/seotownsend'

  s.platform     = :ios, '8.0'
  s.requires_arc = true

  s.source_files = 'Pod/Classes/**/*'
  s.resource_bundles = {
    'flok' => ['Pod/Assets/*.png']
  }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
  s.dependency 'Alamofire', '~> 3.0'
  s.dependency 'SnapKit'
  s.dependency 'Socket.IO-Client-Swift', '~> 4.1'
  s.dependency 'CocoaAsyncSocket', '~> 7.4'
end
