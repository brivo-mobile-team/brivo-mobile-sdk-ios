[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fbrivo-mobile-team%2FBrivo-Mobile-SDK%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/brivo-mobile-team/Brivo-Mobile-SDK)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fbrivo-mobile-team%2FBrivo-Mobile-SDK%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/brivo-mobile-team/Brivo-Mobile-SDK)

# [<img src="brivo_logo.png" width="25"/>](brivo_logo.png) Brivo Mobile SDK iOS

A set of reusable libraries, services and components for Swift iOS apps.
### Installation
#### Swift Package Manager (SPM) ❤️

Add Brivo Mobile SDK as a dependency using Swift Package Manager.

   - In an app project or framework, in Xcode:

     - Select the menu: **File → Swift Packages → Add Package Dependency...**
     - Enter this URL: `https://github.com/brivo-mobile-team/brivo-mobile-sdk-ios`

### Usage
Before using the Brivo Mobile SDK it is mandatory to configure (through instance) of BrivoSDK class with a BrivoConfiguration object
The BrivoConfiguration object requires a set of parameters listed bellow:

```swift
do {
    let brivoConfiguration = try BrivoConfiguration(
        clientId: "CLIENT_ID",
        clientSecret: "CLIENT_SECRET",
        useSDKStorage: USE_SDK_STORAGE
    )
    BrivoSDK.instance.configure(brivoConfigurationbrivoConfiguration)
} catch let error {
    // Handle BrivoSDK configuration exception
}
```

The exception is thrown if the BrivoConfiguration class is not initialized correctly.
For example one of the parameters is nil or empty string.

## Brivo Mobile SDK Modules

### BrivoCore
This module implements the Brivo SDK class that is accessible through 'instance' property. It has the following responsibilities:
```swift
func getBrivoConfiguration() throws -> BrivoConfiguration
var version: String
```

### BrivoOnAir
This module manages the connection between the application and the Brivo environment. It has the following responsibilities:
```swift

/// Redeeming a Brivo Onair Pass. Brivo Onair Pass gives you theaccess to a site and allows you to open access points.
///
/// Parameters:
/// passId     Pass ID (email) received from Brivo
/// passCode   Pass Code received from Brivo
/// onSuccess  Completion block that handles the success of operation
/// onFailure  Completion block that handles the failure of operation
///

func redeemPass(
    passId: String,
    passCode: String,
    onSuccess: RedeemPassOnSuccessType?,
    onFailure: OnFailureType?
)
                            
/// Refreshing a Brivo Onair Pass.
///
/// Parameters:
/// brivoTokens accessToken received from Brivo
///             refreshToken received from Brivo
/// onSuccess   Completion block that handles the success of operation
/// onFailure   Completion block that handles the failure of operation

func refreshPass(
    brivoTokens: BrivoTokens,
    onSuccess: RefreshPassOnSuccessType?,
    onFailure: OnFailureType?
)

/// Retrieving the BrivoSDK locally stored passes.
///
/// Parameters:
/// onSuccess   Completion block that handles the success of operation
/// onFailure   Completion block that handles the failure of operation

func retrieveSDKLocallyStoredPasses(
    onSuccess: RetrieveSDKLocallyStoredPassesOnSuccess?,
    onFailure: OnFailureType?
) throws
```

### BrivoSDKOnair 
This module is used to redeem pass usage 
```swift
do {
    try BrivoSDKOnAir.instance().redeemPass(
        passId: "PASS_ID",
        passCode: "PASS_CODE",
        onSuccess: { brivoOnAirPass in
            // Manage pass
        },
        onFailure: { responseStatus in
            // Handle redeem pass error case
        }
    )
} catch let error {
    // Handle BrivoSDK initialization exception
}
```
### BrivoSDKOnair 
This module is used to refresh pass usage 
```swift
do {
    try BrivoSDKOnAir.instance().refreshPass(
    brivoTokens: tokens,
    onSuccess: { refreshedPass in
        // Manage refreshed pass
    },
    onFailure: { responseStatus in
        // Handle refresh pass error case
    })
} catch let error {
    //Handle BrivoSDK initialization exception
}
```

### BrivoSDKOnair 
This module is used to retrieve locally stored passes usage
```swift
do {
    trBrivoSDKOnAir.instance.retrieveSDKLocallyStoredPasses(
        onSuccess: { brivoOnAirPasses in
            // Manage retrieved passes
        },
        onFailure: { status in
            // Handle passes retrieval error case
        }
    )
} catch let error {
    // Handle BrivoSDK initialization exception
}
```

### BrivoAccess
This module provides a simplified interface of unlocking access points either Bluetooth type or Internet type. It has the following responsibilities:
```swift

/// Sends a request to BrivoSDK to unlock an access point.
/// This method is called when credentials and data are managedinside of BrivoSDK.
///
/// Parameters:
/// passId                   Brivo pass id
/// accessPointId            Brivo access point id
/// onSuccess                Completion block that handles thesuccess of operation
/// onFailure                Completion block that handles thefailure of operation
/// cancellationSignal       Cancellation signal for a customized BLEunlock timeout
/// if a null cancellation signal isprovided the default timeout of 30 seconds will be used

func unlockAccessPoint(
    passId: String,
    accessPointId: String,
    onSuccess: OnUnlockAccessPointSuccessType?,
    onFailure: OnFailureType?,
    cancellationSignal: CancellationSignal?
)
                    
/// Sends a request to BrivoSDK to unlock an access point.
/// This method is called when credentials and data are managedoutside of BrivoSDK.
///
/// Parameters:
/// selectedAccessPoint      Brivo Selected Access Point to unlock
/// onSuccess                Completion block that handles thesuccess of operation
/// onFailure                Completion block that handles thefailure of operation
/// cancellationSignal       Cancellation signal for a customized BLEunlock timeout
/// if a null cancellation signal isprovided the default timeout of 30 seconds will be used

func unlockAccessPoint(
    selectedAccessPoint: BrivoSelectedAccessPoint,
    onSuccess: OnUnlockAccessPointSuccessType?,
    onFailure: OnFailureType?,
    cancellationSignal: CancellationSignal?
)
```

### BrivoSDKAccess 
This module is used to unlock access point usage with internal stored credentials
```swift
do {
    try BrivoSDKAccess.instance().unlockAccessPoint(
        passId: "PASS_ID",
        accessPointId: "ACCESS_POINT_ID",
        onSuccess: { _ in
            // Handle unlock access point success case
        },
        onFailure: { brivoError in
            // Handle unlock access point error case
        }
    )
} catch let error {
    // Handle BrivoSDK initialization exception
}
```

### BrivoSDKAccess 
This module is used to unlock access point usage with external credentials 
```swift
do {
    let selectedAccessPoint = BrivoSelectedAccessPoint(
        accessPointId: ...,
        userId: ...,
        readerUid: ...,
        bleCredentials: ...,
        timeframe: ...,
        passId: ...,
        brivoApiTokens: BrivoTokens(...)
    )
    
    try BrivoSDKAccess.instance().unlockAccessPoint(
        selectedAccessPoint: selectedAccessPoint,
        onSuccess: { brivoOnAirPass in
            // Handle unlock access point success case
        },
        onFailure: { responseStatus in
            // Handle unlock access point error case
        }
    )
} catch let error {
    // Handle BrivoSDK initialization exception
}
```

### BrivoBLE
This module manages the connection between an access point and a panel through bluetooth.

## Issues
If you run into any bugs or issues, feel free to post an [Issues](https://github.com/brivo-mobile-team/Brivo-Mobile-SDK/issues) to discuss further.




<p align="center">
Made with ❤️ at <img src="brivo.png" width="60"/>
</p>
