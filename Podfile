source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '11.0'
use_frameworks!

target 'ARKit+CoreLocation' do
    pod 'ARCL', :path => '.'

    target 'ARCLTests' do

    end
end


target 'Node Demos' do
    pod 'ARCL', :path => '.'

    target 'Node DemosTests' do

    end
end


post_install do |installer|
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings['ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES'] = 'YES'
        end
    end
end
