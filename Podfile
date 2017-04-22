# Uncomment this line to define a global platform for your project
platform :ios, '10.2'
use_frameworks!

target 'Mogeste' do
  pod 'MetaWear'
  pod 'MBProgressHUD'
  pod 'StaticDataTableViewController'
  pod 'iOSDFULibrary'
  pod 'SigmaSwiftStatistics', '~> 5.0'
  pod 'RealmSwift'
end

post_install do |installer|
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings['SWIFT_VERSION'] = '3.1'
        end
    end
end

