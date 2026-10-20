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
            url: "https://github.com/in2core/screenportsdk/releases/download/v1.1.0-beta.2/ScreenPortSDK-1.1.0-beta.2.zip",
            checksum: "3e8902b07699b43a6272c7f965a9dfc9d49f1d5f8eafe88a8eb6d6859c4fd802"
        ),
    ]
)
