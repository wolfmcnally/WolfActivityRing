// swift-tools-version:5.9

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
