// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SimpleTracer",
    platforms: [.macOS(.v11), iOS(.14)],
    products: [
        .library(
            name: "SimpleTracer",
            targets: ["SimpleTracer"]),
    ],
    targets: [
        .target(
            name: "SimpleTracer"
        ),
        .testTarget(
            name: "SimpleTracerTests",
            dependencies: ["SimpleTracer"]
        ),
    ],
    swiftLanguageVersions: [.v5]
)
