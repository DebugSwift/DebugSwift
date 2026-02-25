Pod::Spec.new do |s|
    s.name             = 'DebugSwift'
    s.version          = '0.0.1'
    s.summary          = 'A robust toolkit for simplifying and enhancing the debugging process in Swift applications.'
    s.description      = <<-DESC
      DebugSwift is a comprehensive toolkit designed to streamline and elevate the debugging experience for Swift-based applications. Whether you are troubleshooting issues or optimizing performance, DebugSwift offers a powerful set of features to make your debugging process more efficient and effective.

      This version now includes full Apple Silicon simulator support (arm64) and can be distributed as either source code or pre-built XCFramework.
    DESC
    s.homepage         = 'https://github.com/DebugSwift/DebugSwift'
    s.license          = { :type => 'MIT', :file => 'LICENSE' }
    s.author           = { 'Matheus Gois' => 'matheusgoislimasilva@gmail.com' }
    s.source           = { :git => 'https://github.com/DebugSwift/DebugSwift.git', :tag => s.version.to_s }
  
    s.ios.deployment_target = '14.0'
    s.swift_version = '5.7'
  
    # Source files for building from source
    s.source_files = 'DebugSwift/Sources/**/*'
    
    # Resource bundles
    s.resource_bundles = {
      'DebugSwift' => [
        'DebugSwift/Resources/*.lproj/*.strings',
      ]
    }
    
    s.user_target_xcconfig = {
      'LD_RUNPATH_SEARCH_PATHS' => '$(inherited) @executable_path/Frameworks'
    }
  end

# Alternative XCFramework-based podspec
# Uncomment the configuration below and comment out the source_files above
# to use pre-built XCFramework distribution:
#
# s.source = { 
#   :http => "https://github.com/DebugSwift/DebugSwift/releases/download/#{s.version}/DebugSwift.xcframework.zip"
# }
# s.vendored_frameworks = 'DebugSwift.xcframework'
# # Remove s.source_files when using XCFramework
