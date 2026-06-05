[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fbrivo-mobile-team%2Fbrivo-mobile-sdk-ios%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/brivo-mobile-team/brivo-mobile-sdk-ios)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fbrivo-mobile-team%2Fbrivo-mobile-sdk-ios%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/brivo-mobile-team/brivo-mobile-sdk-ios)

# [<img src="brivo_logo.png" width="25"/>](brivo_logo.png) Brivo Mobile SDK iOS

A set of reusable libraries, services and components for Swift iOS apps.

Ships six SDK frameworks — `BrivoAccess`, `BrivoBLE`, `BrivoCore`,
`BrivoLocalAuthentication`, `BrivoNetworkCore`, `BrivoOnAir` — entirely
via Swift Package Manager. No CocoaPods, no extra setup.

> **Need Allegion lock integration?** Use the Allegion distribution at
> [`brivo-mobile-sdk-allegion-ios`](https://github.com/brivo-mobile-team/brivo-mobile-sdk-allegion-ios)
> instead. It ships the same 6 frameworks plus `BrivoBLEAllegion`.

**Table of contents**

- [Installation (SPM)](#installation)
- [Configuration](#configuration)
- [Sample app](#sample)
- [Issues](#issues)

<a id="installation"></a>
## Installation (SPM)

Add the package to your Xcode project:

1. **Xcode → File → Add Packages…**
2. Enter the URL: `https://github.com/brivo-mobile-team/brivo-mobile-sdk-ios.git`
3. Pin to a release version (e.g. `3.4.0`)
4. Add the `BrivoMobileSDK` product to your target

**Or via `Package.swift`:**

```swift
dependencies: [
    .package(
        url: "https://github.com/brivo-mobile-team/brivo-mobile-sdk-ios.git",
        from: "3.4.0"
    )
],
targets: [
    .target(
        name: "YourApp",
        dependencies: [
            .product(name: "BrivoMobileSDK", package: "brivo-mobile-sdk-ios"),
        ]
    )
]
```

**Requirements:** iOS 17.0+, Swift 5.9+, Xcode 16.1+.

<a id="configuration"></a>
## Configuration

Configure `BrivoSDK` with a `BrivoSDKConfiguration` before use:

```swift
do {
    let brivoConfiguration = try BrivoSDKConfiguration.Builder(
            clientId: "CLIENT_ID",
            clientSecret: "CLIENT_SECRET",
            useSDKStorage: true)
        .region(.us)                          // or .eu
        .build()
    BrivoSDK.instance.configure(brivoConfiguration: brivoConfiguration)
} catch {
    // Handle BrivoSDK configuration exception
}
```

The configuration throws if a required parameter is missing.

### Unlocking an access point

```swift
for try await event in await BrivoSDKAccess
    .instance()
    .unlockAccessPoint(
        selectedAccessPoint: selectedAccessPoint,
        cancellationSignal: cancellationSignal
    )
{
    // Handle the AsyncThrowingStream events
}
```

<a id="sample"></a>
## Sample app

`BrivoSampleApp/` contains a working sample that demonstrates the SDK
end-to-end. To run it:

1. Open `BrivoSampleApp/BrivoSampleApp.xcodeproj`
2. Fill in `clientId` and `clientSecret` in
   `BrivoSampleApp/BrivoSampleApp/Configuration.swift`
3. Build & run

No `pod install`, no extra setup — the SDK is resolved via SPM from the
package at the repo root.

<a id="issues"></a>
## Issues

If you run into bugs, please open an issue at
<https://github.com/brivo-mobile-team/Brivo-Mobile-SDK/issues>.

<p align="center">
Made with ❤️ at <img src="brivo.png" width="60"/>
</p>
