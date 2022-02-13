// swift-tools-version:5.5
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
            url: "https://github.com/IGRSoft/SimplePing.git",
            from: "0.1.1")
    ],
    targets: [
        .target(
            name: "SimpleTracer",
            dependencies: [.product(name: "SimplePing", package: "SimplePing")]
        )
    ],
    swiftLanguageVersions: [.v5]
)
