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
            url: "https://github.com/in2core/screenportsdk/releases/download/v0.1.0-alpha.4/ScreenPortSDK-0.1.0-alpha.4.zip",
            checksum: "1b1c09f6d0da7bfcced3f8c14dfd636efc2ae560f03aaef8576b747880195c1a"),
    ]
)
