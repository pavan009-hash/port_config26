# Uncomment the next line to define a global platform for your project
platform :ios, '15.0'

inhibit_all_warnings!
use_frameworks!

# Replace with your actual app target name if different
project 'P_test1.xcodeproj'

target 'P_test1' do
  # No external dependencies for demo mode
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      # Ensure Swift concurrency warnings are not overly strict for third-party pods
      config.build_settings['SWIFT_VERSION'] = '5.10'
    end
  end
end
