#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint flutter_traceroute.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'SimpleTracer'
  s.version          = '0.1.1'
  s.summary          = 'SimpleTracer plugin'
  s.description      = <<-DESC
  SimpleTracer plugin
                       DESC
  s.homepage         = 'https://github.com/youssef-fk/SimpleTracer.git'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'FRI' => 'filali.khattabi.youssef@gmail.com' }
  s.source           = { :git => "https://github.com/youssef-fk/SimpleTracer.git", :tag => "#{s.version}" }

  s.source_files = 'Sources/**/*'
  s.dependency 'SimplePing'
  s.platform = :ios, '14.0'
  
  s.requires_arc     = true
  s.static_framework = true
  s.swift_version = '5.0'
end
