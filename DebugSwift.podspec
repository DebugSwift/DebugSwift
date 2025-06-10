Pod::Spec.new do |spec|
  spec.name             = 'DebugSwift'
  spec.version          = '1.0.0'
  spec.summary          = 'A comprehensive toolkit to simplify and enhance debugging for Swift apps.'
  spec.description      = <<-DESC
DebugSwift is a comprehensive toolkit designed to simplify and enhance the debugging process for Swift-based applications.
Whether you're troubleshooting network issues, monitoring WebSocket connections, optimizing performance, or testing push notifications,
DebugSwift provides a powerful set of features to make your debugging experience more efficient.

Features:
• Network Inspector with HTTP and WebSocket monitoring
• Performance monitoring (CPU, Memory, FPS, Memory Leaks)
• Interface debugging tools (Grid overlay, Touch indicators, View debugger)
• App debugging (Crash reports, Console logs, Location simulation)
• Resource inspection (Files, Keychain, UserDefaults, Database)
• Push notification testing and APNS token management
• Swift 6 ready with strict concurrency checking
DESC

  spec.homepage         = 'https://github.com/DebugSwift/DebugSwift'
  spec.license          = { type: 'MIT', file: 'LICENSE' }
  spec.authors          = { 'Matheus Gois' => 'matheusgoislimasilva@gmail.com' }
  spec.social_media_url = 'https://github.com/DebugSwift'

  spec.platform         = :ios, '14.0'
  spec.swift_versions   = ['6.0']

  spec.source           = { git: 'https://github.com/DebugSwift/DebugSwift.git', tag: "v#{spec.version}" }

  spec.source_files     = 'DebugSwift/Sources/**/*.{swift,h,m}'
  spec.public_header_files = 'DebugSwift/Sources/**/*.h'

  # Exclude resources to avoid sandbox issues - DebugSwift will work without localization
  # spec.resources = []

  # Ensure Swift compiler settings
  spec.pod_target_xcconfig = {
    'SWIFT_VERSION'              => '6.0',
    'SWIFT_STRICT_CONCURRENCY'   => 'complete'
  }
end
