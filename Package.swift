// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CodeGenSample",
    platforms: [.macOS(.v10_11)],
    products: [
        .library(
            name: "CodeGenSample",
            targets: ["CodeGenSample"]),
    ],
    dependencies: [
        .package(url: "https://github.com/jpsim/SourceKitten.git", exact: "0.32.0"),
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "CodeGenSample",
            dependencies: [],
            plugins: ["SourceKitPlugin"]
        ),
        .plugin(
            name: "SourceKitPlugin",
            capability: .buildTool(),
            dependencies: [.target(name: "PluginExecutable")]
        ),
        .executableTarget(
            name: "PluginExecutable",
            dependencies: [
                .product(name: "SourceKittenFramework", package: "SourceKitten"),
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ]
        )
    ]
)
