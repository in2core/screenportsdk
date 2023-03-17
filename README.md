# ScreenPort SDK

The ScreenPort SDK allows app developers to receive video and audio from [ScreenPort](https://screenport.io) devices over USB or network.

## Supported Platforms

The SDK is currently available for the following Apple platforms:

- iOS and iPadOS
- macOS (via Mac Catalyst)
- tvOS (network connections only)

## Usage

The SDK is available as a Swift Package.
To add it to your project, follow these steps:

1. Navigate to *Project Settings* in Xcode, then *Package Dependencies*.
2. Click the plus button to add a dependency and paste the URL of this repository into the search field: `https://github.com/in2core/screenportsdk.git`
3. Select a *Dependency Rule*, either:
    - *Up to Next Major Version*, entering `1.0.0` into the left text field and leaving the right field blank (recommended), or
    - *Branch*, entering `main` into the branch name field.
4. Click *Add Package* and wait for package resolution.
5. Select the target to add the package product to, then click *Add Package* again.
6. Add the `NSLocalNetworkUsageDescription` and `NSBonjourServices` keys from [Info.plist](Demo/ScreenPortSDKDemo/Info.plist) into your project’s Info.plist. Due to a [known issue](https://github.com/in2core/screenportsdk/issues/4), this step is currently required even if you only plan to use USB connections.
7. Add the following [entitlements](Demo/ScreenPortSDKDemo/ScreenPortSDKDemo.entitlements) into your project’s entitlements file:
    - `com.apple.security.device.usb`
    - `com.apple.security.network.client`
    - `com.apple.security.network.server`
8. Use `import ScreenPortSDK` in your code.

See [the documentation](https://in2core.github.io/screenportsdk/documentation/screenportsdk/) for details on how to use the SDK.
This package includes a [demo project](Demo) showing how to stream from ScreenPort devices using [SwiftUI](Demo/ScreenPortSDKDemo/SwiftUI) and [UIKit](Demo/ScreenPortSDKDemo/UIKit).
