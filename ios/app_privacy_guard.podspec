#
# CocoaPods spec, kept for apps that have not yet migrated to Swift Package Manager.
# Sources are shared with Package.swift (ios/app_privacy_guard/).
#
Pod::Spec.new do |s|
  s.name             = 'app_privacy_guard'
  s.version          = '0.1.0'
  s.summary          = 'Blur in app switcher, Android secure flag, and iOS Dynamic Island watermark.'
  s.description      = <<-DESC
Protects sensitive UI: blurs the app in the app switcher, enables the Android secure flag,
and shows a watermark near the iOS Dynamic Island.
                       DESC
  s.homepage         = 'https://github.com/ShahzodAtabayev/app_privacy_guard'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Shahzod Atabayev' => 'https://github.com/ShahzodAtabayev' }
  s.source           = { :path => '.' }
  s.source_files     = 'app_privacy_guard/Sources/app_privacy_guard/**/*.swift'
  s.dependency 'Flutter'
  s.platform = :ios, '15.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'

  s.resource_bundles = {'app_privacy_guard_privacy' => ['app_privacy_guard/Sources/app_privacy_guard/PrivacyInfo.xcprivacy']}
end
