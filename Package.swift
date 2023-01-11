// swift-tools-version: 5.5

import PackageDescription

let package = Package(
    name: "ScreenPortSDK",
    platforms: [
        .iOS(.v13),
        .macCatalyst(.v13),
        .tvOS(.v13),
    ],
    products: [
        .library(
            name: "ScreenPortSDK",
            targets: ["ScreenPortSDK"]),
    ],
    targets: [
        .binaryTarget(
            name: "ScreenPortSDK",
            url: "https://github.com/in2core/screenportsdk/releases/download/v0.2.0-alpha.2/ScreenPortSDK-0.2.0-alpha.2.zip",
            checksum: "e23f582983a5556ff2b09c80241b9495f0fac5cce044d452053d2ac81b84fb05"),
    ]
)
