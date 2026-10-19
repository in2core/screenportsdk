// swift-tools-version:5.9

import PackageDescription

let package = Package(
    name: "ScreenPortSDK",
    platforms: [
        .iOS(.v13),
        .macCatalyst(.v13),
        .tvOS(.v13),
        .visionOS("2.0"),
    ],
    products: [
        .library(
            name: "ScreenPortSDK",
            targets: ["ScreenPortSDK"]
        ),
    ],
    targets: [
        .binaryTarget(
            name: "ScreenPortSDK",
            url: "https://github.com/in2core/screenportsdk/releases/download/v1.1.0-beta.1/ScreenPortSDK-1.1.0-beta.1.zip",
            checksum: "96c4918489266ab02a12ff3c4683db95176bfcc95448e812de67fd3bbb5be9e5"
        ),
    ]
)
