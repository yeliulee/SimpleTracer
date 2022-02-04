// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SimpleTracer",
    platforms: [.macOS(.v11), .iOS(.v14)],
    products: [
        .library(
            name: "SimpleTracer",
            targets: ["SimpleTracer"]),
    ],
    dependencies: [
        .package(
            url: "https://github.com/IGRSoft/SimplePing",
            .branch("master")
        )
    ],
    targets: [
        .target(
            name: "SimpleTracer",
            dependencies: ["SimplePing"]
        )
    ],
    swiftLanguageVersions: [.v5]
)
