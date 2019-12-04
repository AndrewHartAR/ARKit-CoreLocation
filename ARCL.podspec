Pod::Spec.new do |s|
  s.name         = "ARCL"
  s.version      = "1.3.1"
  s.summary      = "ARKit + CoreLocation combines the high accuracy of AR with the scale of GPS data."
  s.homepage     = "https://github.com/ProjectDent/arkit-corelocation"
  s.author       = { "Andrew Hart" => "Andrew@ProjectDent.com" }
  s.license      = { :type => 'MIT', :file => 'LICENSE'  }
  s.source       = { :git => "https://ProjectDent@github.com/ProjectDent/ARKit-CoreLocation.git", :tag => s.version.to_s, :submodules => false }
  s.platform     = :ios, '9.0'
  s.swift_version = "5.0"
  s.requires_arc = true
  s.source_files = 'Sources/**/*.{swift}'
  s.frameworks   = 'Foundation', 'UIKit', 'CoreLocation', 'MapKit', 'SceneKit'
  s.weak_frameworks   = 'ARKit'
  s.ios.deployment_target = '9.0'
end
