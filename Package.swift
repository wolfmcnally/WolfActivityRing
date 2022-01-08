// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "WolfActivityRing",
    platforms: [
        .iOS(.v15),
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "WolfActivityRing",
            targets: ["WolfActivityRing"]),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "WolfActivityRing",
            dependencies: [])
    ]
)
