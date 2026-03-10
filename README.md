[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fbrivo-mobile-team%2Fbrivo-mobile-sdk-ios%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/brivo-mobile-team/brivo-mobile-sdk-ios)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fbrivo-mobile-team%2Fbrivo-mobile-sdk-ios%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/brivo-mobile-team/brivo-mobile-sdk-ios)

# [<img src="brivo_logo.png" width="25"/>](brivo_logo.png) Brivo Mobile SDK iOS

A set of reusable libraries, services and components for Swift iOS apps.

 **Table of content:**

 - [Installation (SPM)](#installation)
    - [BrivoBLEAllegion (Cocoapods)](#installation_allegion)
 - [Configuration](#configuration)
 - [Issues](#issues)

 <a id="installation"></a>
### Installation (SPM)
The BrivoSDK is available for use using Swift Package Manager. It can be found on Swift Package Index here: https://swiftpackageindex.com/brivo-mobile-team/brivo-mobile-sdk-ios.
It can be also found on Github here: https://github.com/brivo-mobile-team/brivo-mobile-sdk-ios.
In order to add the BrivoSDK one needs to to the following:
- When working with an Xcode project:
```
1. Go to the Xcode project section for Package Dependencies
2. Click the "+" button
3. Enter in the search field called "Search or Enter Package URL" this url: https://github.com/brivo-mobile-team/brivo-mobile-sdk-ios.git
4. Select Add Package and add it to the needed target
```
- When working with a Swift Package Manager manifest:
```
1. Go to the manifest file
2. Add the reference to the BrivoSDK:
    - if the main branch is needed use this: .package(url: "https://github.com/brivo-mobile-team/brivo-mobile-sdk-ios.git", branch: "main")
    - if a specific version is needed use this: .package(url: "https://github.com/brivo-mobile-team/brivo-mobile-sdk-ios.git", from: "1.22.1")
3. Select a product using this: .product(name: "BrivoMobileSDK", package: "brivo-mobile-sdk-ios")
```

The BrivoSDK components were built using the target version iOS 17.0, Apple Swift version required is 5 and Xcode version 16.1

<a id="installation_allegion"></a>
#### BrivoBLEAllegion (Cocoapods)
To use this framework you'll need access to https://github.com/Allegion-Plc/AllegionCocoaPods for fetching AllegionSDK.
There are 2 steps involved:
1. Obtain a github personal token from Allegion Team
2. Use the github token to download dependencies
    - Replace<br/>
    `source "https://github.com/Allegion-Plc/AllegionCocoaPods"`<br/>
with<br/>
    `source "https://{github_personal_token}@github.com/Allegion-Plc/AllegionCocoaPods"`
      in [Podfile](BrivoSampleApp/Podfile)
    - Use `gh auth login` to store the token locally (see [Docs](https://docs.github.com/en/get-started/getting-started-with-git/caching-your-github-credentials-in-git))


### Sample project
This repository comes with a sample project inside the folder BrivoSampleApp.
Here we show how the SDK can be used using SPM and fetching the main branch of our SDK.

<a id="configuration"></a>
## Configuration
Before using the Brivo Mobile SDK it is mandatory to configure (through instance) of `BrivoSDK` class with a `BrivoSDKConfiguration` object.

#### BrivoSDK configuration usage 
```
    do {
        let brivoConfiguration = try BrivoSDKConfiguration.Builder(
            clientId: "CLIENT_ID",
            clientSecret: "CLIENT_SECRET",
            useSDKStorage: true/false)
            .region(.eu/.us)
            .authUrl("Brivo_OnAir_Auth_URL")
            .apiUrl("Brivo_OnAir_API_URL")
            .brivoBLEAllegionConfiguration() // required for BrivoBLEAllegion, otherwise optional
            .build()
            BrivoSDK.instance.configure(brivoConfiguration: brivoConfiguration)
    } catch let error {
        //Handle BrivoSDK configuration exception
    }

```

The exception is thrown if the BrivoSDKConfiguration class is not initialized correctly.
For example one of the parameters is nil or empty string.

Examples of usage:
#### BrivoSDKAccess unlock access point usage with internal stored credentials
```
    for try await result in await BrivoSDKAccess.instance().unlockAccessPoint(passId: "PASS_ID",
                                                                              accessPointId: "ACCESS_POINT_ID",
                                                                              unlockStrategy: UnlockStrategy?,
                                                                              cancellationSignal: CancellationSignal) {
        // Handle the result received throught AsyncThrowingStream
    }
```

#### BrivoSDKAccess unlock access point usage with external credentials 
```
    let selectedAccessPoint = BrivoSelectedAccessPoint(accessPointId: ...,
                                                       userId: ...,
                                                       readerUid: ...,
                                                       bleCredentials: ...,
                                                       timeframe: ...,
                                                       passId: ...,
                                                       brivoApiTokens: BrivoTokens(...)) 
    
    for try await result in await BrivoSDKAccess.instance().unlockAccessPoint(selectedAccessPoint: selectedAccessPoint,
                                                                              unlockStrategy: UnlockStrategy?,
                                                                              cancellationSignal: CancellationSignal)  {
        // Handle the result received throught AsyncThrowingStream
    }
```

#### BrivoSDKAccess refresh credentials used for optional modules
```
    let brivoOnAirPass = BrivoOnairPass() // Brivo credential received after redeeming a Brivo mobile pass 

    let refreshCredentialsResult = await BrivoSDKAccess.instance().refreshCredentials(passes: [brivoOnAirPass])
        // This method initializes the optional modules (e.g. BrivoBLEAllegion) and refreshes the credentials for unlocking non-Brivo type doors (e.g. Allegion, RealSync)
```

<a id="brivo_ble_allegion"></a>
#### BrivoBLEAllegion - Optional 
This module acts as wrapper for AllegionSDKs and is an optional dependendency for BrivoAccess to unlock Allegion devices.
> [!NOTE]
> Using this module requires access to Allegion SDKs (see [Podfile](BrivoSampleApp/Podfile)).\
> Allegion SDKs come with a limitation: arm64 architecture is excluded so the app runs only on simulators with Rosetta.

## Issues
If you run into any bugs or issues, feel free to post an [Issues](https://github.com/brivo-mobile-team/Brivo-Mobile-SDK/issues) to discuss further.
<p align="center">
Made with ❤️¸ at <img src="brivo.png" width="60"/>
</p>
