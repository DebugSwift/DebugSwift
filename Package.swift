// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "DebugSwift",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "DebugSwift",
            targets: ["DebugSwift"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "DebugSwiftSignalCapture",
            path: "DebugSwiftSignalCapture",
            publicHeadersPath: "include"
        ),
        .target(
            name: "DebugSwift",
            dependencies: ["DebugSwiftSignalCapture"],
            path: "DebugSwift",
            resources: [
                .process("Resources")
            ]
        )
    ],
    swiftLanguageModes: [.v6]
)
