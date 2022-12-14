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
            url: "https://github.com/in2core/screenportsdk/releases/download/v0.1.0-alpha.3/ScreenPortSDK-0.1.0-alpha.3.zip",
            checksum: "1ef4fcdf1b450983bb0fac7f02e55160e40c70369312e4818d0ed844160332ad"),
    ]
)
