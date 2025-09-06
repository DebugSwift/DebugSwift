Pod::Spec.new do |s|
    s.name             = 'DebugSwift'
    s.version          = '1.7.19'
    s.summary          = 'A robust toolkit for simplifying and enhancing the debugging process in Swift applications.'
    s.description      = <<-DESC
      DebugSwift is a comprehensive toolkit designed to streamline and elevate the debugging experience for Swift-based applications. Whether you are troubleshooting issues or optimizing performance, DebugSwift offers a powerful set of features to make your debugging process more efficient and effective.
    DESC
    s.homepage         = 'https://github.com/DebugSwift/DebugSwift'
    s.license          = { :type => 'MIT', :file => 'LICENSE' }
    s.author           = { 'Matheus Gois' => 'matheusgoislimasilva@gmail.com' }
    s.source           = { :git => 'https://github.com/DebugSwift/DebugSwift.git', :tag => s.version.to_s }
  
    s.ios.deployment_target = '14.0'
    s.swift_version = '5.7'
  
    s.source_files = 'DebugSwift/Sources/**/*'
    s.resource_bundles = {
      'DebugSwift' => [
        'DebugSwift/Resources/*.lproj/*.strings',
      ]
    }
    
    s.pod_target_xcconfig = {
      'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64'
    }
    s.user_target_xcconfig = {
      'LD_RUNPATH_SEARCH_PATHS' => '$(inherited) @executable_path/Frameworks'
    }
  end