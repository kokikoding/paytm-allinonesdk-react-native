require "json"
package = JSON.parse(File.read(File.join(__dir__, "package.json")))

Pod::Spec.new do |s|
  s.name         = "paytm_allinone_react-native"
  s.version      = package["version"]
  s.summary      = package["description"]
  s.homepage     = package["homepage"]
  s.license      = package["license"]
  s.authors      = package["author"]
  s.platforms    = { :ios => "11.0" }

  s.source       = { :git => "https://github.com/paytm/paytm_allinone_react-native.git",
                    :tag => "#{s.version}" }

  # Only use xcframework; ignore legacy .framework
  s.vendored_frameworks = 'ios/AppInvokeSDK.xcframework'
  s.static_framework = true
  s.swift_version = '5.0'
  s.source_files = "ios/**/*.{h,m,mm,swift}"

  # stop CocoaPods duplicating these headers
  s.exclude_files = [
    'ios/AppInvokeSDK.framework',
    'ios/AppInvokeSDK/AppInvokeSDK.h',
    'ios/AppInvokeSDK/AppInvokeSDK-Swift.h'
  ]

  s.user_target_xcconfig = {
    'EXCLUDED_SOURCE_FILE_NAMES' => 'AppInvokeSDK.h,AppInvokeSDK-Swift.h',
    'DEFINES_MODULE' => 'YES',
    'BUILD_LIBRARY_FOR_DISTRIBUTION' => 'YES'
  }

  s.dependency 'React-Core'
end