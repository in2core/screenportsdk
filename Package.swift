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
            url: "https://github.com/in2core/screenportsdk/releases/download/v0.3.0-alpha.1/ScreenPortSDK-0.3.0-alpha.1.zip",
            checksum: "9756f5118114581a0cae1e2c0c16c31c05af603243cb08fcd8c915d726fd3d89"),
    ]
)
