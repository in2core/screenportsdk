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
            url: "https://github.com/in2core/screenportsdk/releases/download/v0.1.0-alpha.1/ScreenPortSDK-0.1.0-alpha.1.zip",
            checksum: "02b08ac4bf194afb3f92580e0bca4ffec3f6e10f7998ee78457b420f1752f52a"),
    ]
)
