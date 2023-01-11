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
            url: "https://github.com/in2core/screenportsdk/releases/download/v0.2.0-alpha.1/ScreenPortSDK-0.2.0-alpha.1.zip",
            checksum: "08393c06714d6cf4da312bbf5c15d07cc54e8d43ed385d634bd5063ffc478afc"),
    ]
)
