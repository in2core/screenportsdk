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
            url: "https://github.com/in2core/screenportsdk/releases/download/v1.0.0/ScreenPortSDK-1.0.0.zip",
            checksum: "0229b4bc301f05cf4c8fad8fd316ca82085def43cde267510ca3f1f4d85c199f"),
    ]
)
