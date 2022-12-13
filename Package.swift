// swift-tools-version: 5.7

import PackageDescription

let package = Package(
    name: "ScreenPortSDK",
    products: [
        .library(
            name: "ScreenPortSDK",
            targets: ["ScreenPortSDK"]),
    ],
    targets: [
        .binaryTarget(name: "ScreenPortSDK", path: "ScreenPortSDK.xcframework"),
    ]
)
