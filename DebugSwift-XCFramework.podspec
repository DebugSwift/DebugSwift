Pod::Spec.new do |s|
    s.name             = 'DebugSwift'
    s.version          = '1.8.1'
    s.summary          = 'A robust toolkit for simplifying and enhancing the debugging process in Swift applications.'
    s.description      = <<-DESC
      DebugSwift is a comprehensive toolkit designed to streamline and elevate the debugging experience for Swift-based applications. Whether you are troubleshooting issues or optimizing performance, DebugSwift offers a powerful set of features to make your debugging process more efficient and effective.
    DESC
    s.homepage         = 'https://github.com/DebugSwift/DebugSwift'
    s.license          = { :type => 'MIT', :file => 'LICENSE' }
    s.author           = { 'Matheus Gois' => 'matheusgoislimasilva@gmail.com' }
    s.source           = { 
      :http => "https://github.com/DebugSwift/DebugSwift/releases/download/#{s.version}/DebugSwift.xcframework.zip"
    }
  
    s.ios.deployment_target = '14.0'
    s.swift_version = '5.7'
  
    # Use pre-built XCFramework
    s.vendored_frameworks = 'DebugSwift.xcframework'
    
    # Resource bundle for localization files
    s.resource_bundles = {
      'DebugSwift' => [
        'DebugSwift.xcframework/ios-arm64/DebugSwift.framework/DebugSwift_DebugSwift.bundle/**/*',
        'DebugSwift.xcframework/ios-arm64_x86_64-simulator/DebugSwift.framework/DebugSwift_DebugSwift.bundle/**/*'
      ]
    }
    
    # No architecture exclusions needed - XCFramework handles this automatically
    s.pod_target_xcconfig = {
      # XCFramework automatically selects the correct slice based on the build destination
    }
    s.user_target_xcconfig = {
      'LD_RUNPATH_SEARCH_PATHS' => '$(inherited) @executable_path/Frameworks'
    }
end
