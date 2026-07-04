// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "DebugSwiftPortable",
    products: [
        .library(
            name: "DebugSwiftPortable",
            targets: ["DebugSwiftPortable"]
        )
    ],
    targets: [
        .target(name: "DebugSwiftPortable"),
        .target(
            name: "DebugSwiftPortableC",
            dependencies: ["DebugSwiftPortable"]
        ),
        .testTarget(
            name: "DebugSwiftPortableTests",
            dependencies: ["DebugSwiftPortable"]
        )
    ],
    swiftLanguageModes: [.v6]
)
