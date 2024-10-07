[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fbrivo-mobile-team%2Fbrivo-mobile-sdk-ios%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/brivo-mobile-team/brivo-mobile-sdk-ios)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fbrivo-mobile-team%2Fbrivo-mobile-sdk-ios%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/brivo-mobile-team/brivo-mobile-sdk-ios)

# [<img src="brivo_logo.png" width="25"/>](brivo_logo.png) Brivo Mobile SDK iOS

A set of reusable libraries, services and components for Swift iOS apps.

 **Table of content:**

 - [Installation (SPM)](#installation)
    - [BrivoBLEAllegion (Cocoapods)](#installation_allegion)
 - [Usage](#usage)
 - [Brivo Mobile SDK Modules](#brivo_mobile_sdk_modules)
    - [BrivoCore](#brivo_core)
    - [BrivoOnAir](#brivo_on_air)
    - [BrivoAccess](#brivo_access)
        - [BrivoBLEAllegion - Optional](#brivo_ble_allegion)
    - [BrivoBLE](#brivo_ble)
    - [BrivoLocalAuthentication](#brivo_local_authentication)
    - [BrivoNetworkCore](#brivo_network_core)
 - [BrivoSDK Errors](#brivo_errors)
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

The BrivoSDK components were built using the target version iOS 14.0, Apple Swift version required is 5 and Xcode version 15.4

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

<a id="usage"></a>
## Usage
Before using the Brivo Mobile SDK it is mandatory to configure (through instance) of `BrivoSDK` class with a `BrivoSDKConfiguration` object.\
The `BrivoSDKConfiguration` object requires a set of parameters listed bellow:
```
/**
 Defines the configuration object needed by the BrivoSDK in order to function properly.
 - Parameter clientId: Brivo client id
 - Parameter clientSecret: Brivo Client secret
 - Parameter useSDKStorage: if the SDK should use internal storage for  the passes
 - Parameter region: the region where the SDK base urls should point in the case apiUrl or authUrl are not provided.
    Defaults to Region.us
 - Parameter shouldPromptForContinuation: if the SDK should promt for continuation
 - Parameter authUrl:the Brivo authentication server base url
 - Parameter apiUrl:the Brivo OnAir API base url
 - Parameter smartHomeUrl: the Brivo Smart Home base url
 - Parameter refreshTokenDelegate: a refresh token delegate that can handle token refresh in case of a HTTP 401 unauthorised
 - Parameter sessionRequestTimeout: the HTTP session request timeout
 */
```
#### BrivoSDK configuration usage 
```
   do {
        let brivoConfiguration = try BrivoSDKConfiguration(
            clientId: "CLIENT_ID",
            clientSecret: "CLIENT_SECRET",
            useSDKStorage: true/false,
            region: true/false)
        BrivoSDK.instance.configure(brivoConfiguration: brivoConfiguration)
        } catch let error {
            // Handle BrivoSDK configuration exception
        }
```

The exception is thrown if the BrivoSDKConfiguration class is not initialized correctly.
For example one of the parameters is nil or empty string.

 <a id="brivo_mobile_sdk_modules"></a>
## Brivo Mobile SDK Modules

 <a id="brivocore"></a>
#### BrivoCore
This module implements the BrivoSDK class that is accessible through 'instance' property. It has the following interface:
```
/**
Configure the Brivo SDK.
 - Parameter brivoConfiguration: Brivo configuration.
 */
func configure(brivoConfiguration: BrivoSDKConfiguration)

/**
Returns the Brivo SDK configuration.
 */
func getBrivoConfiguration() throws -> BrivoSDKConfiguration

/**
Returns the device ID.
 It also persists the device ID first time it is returned so that succesive calls get the same value.
 */
func getDeviceId() -> String
```

 <a id="brivo_on_air"></a>
#### BrivoOnAir
This module manages the connection between the application and the Brivo environment. It has the following interface:
```
/**
 Returns the Brivo http request that can be use to work with the Brivo Backend.
 - Returns: the Brivo HTTP request
 */
var brivoOnAirHTTPSRequest: BrivoHTTPSRequest? { get }

/**
 Completion handler called whn the refresh token fails.
 Typically used so that the application can take actions.
 */
var onRefreshTokenFailed: OnRefreshTokenFailureType? {get set}

/**
 Authenticate using a Brivo Onair Account.

 - Parameter credential: Credentials used to authenticate in Brivo Onair
 - Parameter onSuccess: completion block that handles the success
 - Parameter onFailure: completion block that handles the failure

 */

func authenticate(credential: BrivoOnAirCredentials,
                  onSuccess: AuthenticateCompletionType?,
                  onFailure: OnAuthenticationFailureType?)

/**
 Redeem a Brivo Onair Pass. Brivo Onair Pass allows you to open doors with your smartphone.

 - Parameter passId: Email received from Brivo
 - Parameter passCode: Token received from Brivo
 - Parameter onSuccess: completion block that handles the success
 - Parameter onFailure: completion block that handles the failure

 */
func redeemPass(passId: String, passCode: String, onSuccess: RedeemPassOnSuccessType?, onFailure: OnFailureType?)

/**
 Refresh a Brivo Onair Pass. Brivo Onair Pass allows you to open doors with your smartphone.
 - Parameter brivoTokens: accessToken received from Brivo
 */
func refreshPass(brivoTokens: BrivoTokens,
                 onSuccess: RefreshPassOnSuccessType?,
                 onFailure: OnFailureType?)

/**
 Sends a request to unlock an access-point.

 The request will be granted if the card holder has permission to access this door based on their groups affiliation.
 Available only to digital credential users
 This method should be used when handing the credentials outside of the SDK

 - Parameter tokens: Access Token received from Brivo
 - Parameter passId : Brivo passId
 - Parameter accessPointId: The id associated with the accesspoint
 - Parameter onSuccess: completion block that handles success
 - Parameter onFailure: completion block that handles  failure
 */
func unlockAccessPoint(tokens: BrivoTokens?,
                       passId: String,
                       accessPointId: String,
                       accessPointPath: AccessPointPath?,
                       onResult: OnResult?)

/**
 Sends a request to unlock an access-point.

 The request will be granted if the card holder has permission to access this door based on their groups affiliation.
 Available only to digital credential users
 This method should be used when handing the credentials outside of the SDK

 - Parameter passId: Brivo passId
 - Parameter accessPointId: The id associated with the accesspoint
 - Parameter onSuccess: completion block that handles success
 - Parameter onFailure: completion block that handles  failure
 */
func unlockAccessPoint(passId: String,
                       accessPointId: String,
                       onResult: OnResult?)


/**
 Retrieve SDK locally stored passes

 - Parameter onSuccess:  completion block that handles success
 - Parameter onFailure:  completion block that handles failure

 */
func retrieveSDKLocallyStoredPasses(onSuccess: RetrieveSDKLocallyStoredPassesOnSuccess?,
                                    onFailure: OnFailureType?)
/**
 Sends a request to unlock an access-point that is using a third party lock.


 The request will be granted if the card holder has permission to access this door based on their groups affiliation.
 Available only to digital credential users

 - Parameter tokens: Access Token received from Brivo
 - Parameter accessPointId: The id associated with the accesspoint
 - Parameter body: BrivoControlLockUnlockStatusRequestBody:
 unlockStatus;
 providerTypeId;
 deviceModelId;
 - Parameter onSuccess: completion block that handles success
 - Parameter onFailure: completion block that handles failure
 */
func controlLockUnlock(tokens: BrivoTokens,
                       accessPointId: String,
                       body: BrivoControlLockUnlockRequestBody,
                       onSuccess: ControlLockUnlockOnSuccessType?,
                       onFailure: OnFailureType?)

/**
 Sends a request to specify the response status of the previous unlock access-point request that is using a third party lock.


 The request will be granted if the card holder has permission to access this door based on their groups affiliation.
 Available only to digital credential users

 - Parameter tokens: Access Token received from Brivo
 - Parameter accessPointId: The id associated with the accesspoint
 - Parameter body: BrivoControlLockUnlockStatusRequestBody:
 unlockStatus;
 providerTypeId;
 deviceModelId;
 - Parameter onSuccess: completion block that handles success
 - Parameter onFailure: completion block that handles failure
 */
func controlLockUnlockStatus(tokens: BrivoTokens,
                             accessPointId: String,
                             body: BrivoControlLockUnlockStatusRequestBody,
                             onSuccess: ControlLockUnlockOnSuccessType?,
                             onFailure: OnFailureType?)

/**
 Sends a request to get all the sites from OnAir


 The request will be granted if the tokens are valid

 - Parameter tokens: Access Token received from Brivo
 - Parameter siteName: value for retrieving by site name
 - Parameter onSuccess: completion block that handles success
 - Parameter onFailure: completion block that handles failure
 */
func retrieveSites(tokens: BrivoTokens,
                   siteName: String?,
                   onSuccess: RetrieveSitesOnSuccessType?,
                   onFailure: OnFailureType?)

/**
 Sends a request to get details about a site from OnAir


 The request will be granted if the tokens are valid

 - Parameter tokens: Access Token received from Brivo
 - Parameter siteId: The id of the site, can be obtained from retrieveSites request
 - Parameter onSuccess: completion block that handles success
 - Parameter onFailure: completion block that handles failure
 */
func retrieveSiteDetails(tokens: BrivoTokens,
                         siteId: Int,
                         onSuccess: RetrieveSiteDetailsOnSuccessType?,
                         onFailure: OnFailureType?)

/**
 Sends a request to get all the access points from a site


 The request will be granted if the tokens are valid

 - Parameter tokens: Access Token received from Brivo
 - Parameter siteId: The id of the site, can be obtained from retrieveSites request
 - Parameter accessPointName: The name of the accessPoint used to filter the accessPoints list
 - Parameter onSuccess: completion block that handles success
 - Parameter onFailure: completion block that handles failure
 */
func retrieveSiteAccessPoints(tokens: BrivoTokens,
                              siteId: Int,
                              accessPointName: String?,
                              onSuccess: RetrieveSiteAccessPointsOnSuccessType?,
                              onFailure: OnFailureType?)

/**
 Sends a request to get details about an access point


 The request will be granted if the tokens are valid

 - Parameter tokens: Access Token received from Brivo
 - Parameter accessPointId: The id of the access point, can be obtained from retrieveSiteAccessPoints request
 - Parameter onSuccess: completion block that handles success
 - Parameter onFailure: completion block that handles failure
 */
func retrieveAccessPointDetails(tokens: BrivoTokens,
                                accessPointId: Int,
                                onSuccess: RetrieveAccessPointDetailsOnSuccessType?,
                                onFailure: OnFailureType?)

/**
 Sends a request to unlock an access-point that is using a third party lock.


 The request will be granted if the card holder has permission to access this door based on their groups affiliation.
 Available only to digital credential users

 - Parameter tokens: Access Token received from Brivo
 - Parameter accessPointId : The id associated with the accesspoint
 - Parameter body: BrivoControlLockConfigRequestBody:
 {
 "db": {
 "usrRcrd": {
 "deleteAll": 1,
 "delete": [],
 "update": [],
 "add": []
 },
 "schedules": [
 {
 "days": [
 "Mo",
 "Tu",
 "We",
 "Th",
 "Fr",
 "Sa",
 "Su"
 ],
 "lngth": 1439,
 "strtHr": 0,
 "strtMn": 0
 }
 ]
 }
 }
 - Parameter onSuccess: completion block that handles success
 - Parameter onFailure: completion block that handles failure
 */
func controlLockConfig(tokens: BrivoTokens,
                       accessPointId: String,
                       body: BrivoControlLockConfigRequestBody,
                       onSuccess: ControlLockConfigOnSuccessType?,
                       onFailure: OnFailureType?)

/**
 Sends a request to specify the response status of the previous config access-point request that is using a third party lock.


 The request will be granted if the card holder has permission to access this door based on their groups affiliation.
 Available only to digital credential users

 - Parameter tokens: Access Token received from Brivo
 - Parameter accessPointId : The id associated with the accesspoint
 - Parameter controlLockConfigSave : The payload that was received from control lock config + the first fragment in the encrypedConfig field
 - Parameter onSuccess: completion block that handles success
 - Parameter onFailure: completion block that handles failure
 */
func controlLockConfigSave(tokens: BrivoTokens,
                           accessPointId: String,
                           controlLockConfigSave: BrivoControlLockConfigSaveResponse,
                           onSuccess: ControlLockConfigSaveOnSuccessType?,
                           onFailure: OnFailureType?)


/**
 Sends a request to get the current administrator


 The on success call will provide the administrator information

 - Parameter tokens: Access Token received from Brivo
 - Parameter onSuccess: completion block that handles success
 - Parameter onFailure: completion block that handles failure
 */
func getCurrentAdministrator(tokens: BrivoTokens,
                             onSuccess: CurrentAdministratorOnSuccessType?,
                             onFailure: OnFailureType?)

/**
 Retrieve the list of reader commands

 The on success call will provide the reader commands
 - Parameter tokens: Access Token received from Brivo
 - Parameter accessPointIds: An array which contains the access point id's for which to fetch the reader commands
 - Parameter onSuccess: completion block that handles success
 - Parameter onFailure: completion block that handles failure
 */
func getReaderCommands(tokens: BrivoTokens,
                       accessPointIds: [String],
                       onSuccess: OnGetReaderCommandCompletionType?,
                       onFailure: OnFailureType?)

/**
 Engage reader command

 The on success call will provide the reader commands
 - Parameter tokens: Access Token received from Brivo
 - Parameter readerId : The id associated with the reader command
 - Parameter passId : Brivo passId
 - Parameter option : The option for the reader command
 - Parameter onSuccess: completion block that handles success
 - Parameter onFailure: completion block that handles failure
 */
func engageReaderCommand(tokens: BrivoTokens,
                         readerId: String,
                         passId: String,
                         option: String,
                         onSuccess: OnSuccessType?,
                         onFailure: OnFailureType?)

/**
 Get Allegion SDK Tokens

 The on success closure will provide the allegion SDK tokens
 - Parameter accessToken: Access Token received from Brivo
 - Parameter onSuccess: completion block that handles success
 - Parameter onFailure: completion block that handles failure
 */
func getAllegionSDKTokens(accessToken: String,
                          onSuccess: @escaping  OnGetAllegionSDKTokensSuccessType,
                          onFailure: @escaping  OnFailureType)
```

Examples of usage:
#### BrivoSDKOnair redeem pass usage 
```
do {
    try BrivoSDKOnAir.instance().redeemPass(passId: "PASS_ID",
                                            passCode: "PASS_CODE",
                                            onSuccess: { [weak self] (brivoOnAirPass) in
                                                //Manage pass
                                            }) {[weak self] (responseStatus) in
                                                //Handle redeem pass error case
                                            }
} catch let error {
    //Handle BrivoSDK initialization exception
}
```
#### BrivoSDKOnair refresh pass usage 
```
do {
   try BrivoSDKOnAir.instance().refreshPass(brivoTokens: tokens, 
                                            onSuccess: {[weak self] (refreshedPass) in
                                                //Manage refreshed pass
                                            }) {[weak self] (responseStatus) in
                                                //Handle refresh pass error case
                                            }
} catch let error {
   //Handle BrivoSDK initialization exception
}
```

#### BrivoSDKOnair retrieve locally stored passes usage
```
do {
    try BrivoSDKOnAir.instance().retrieveSDKLocallyStoredPasses(onSuccess: { [weak self] (brivoOnAirPasses) in
                                                                    //Manage retrieved passes
                                                                }) { [weak self] (status) in
                                                                    //Handle passes retrieval error case
                                                                }
} catch let error {
    //Handle BrivoSDK initialization exception
}
```

 <a id="brivo_access"></a>
#### BrivoAccess
This module provides a simplified interface of unlocking access points either Bluetooth type or Internet type. It has the following interface:
```
static func instance() -> BrivoSDKAccess

/**
 Unlocks an access-point.
 This method should be used when handing the credentials outside of the SDK

 The request will be granted if the card holder has permission to access this door based on their groups affiliation.
 Available only to digital credential users

 - Parameter selectedAccessPoint: BrivoSelectedAccessPoint can be created from BrivoAccessPoint.
                                  The class BrivoSDKOnAirHelper from BrivoOnAir has methods to help with the creation of the object.
 - Parameter onSuccess: completion block that handles success
 - Parameter onFailure: completion block that handles  failure
 - Parameter cancellationSignal: can be used to cancel the unlocking process
 */
func unlockAccessPoint(selectedAccessPoint: BrivoSelectedAccessPoint,
                       onResult: OnResultType?,
                       cancellationSignal: CancellationSignal?)

/**
 Unlocks an access-point.
 This method should be used when the SDK handles the credentials.

 The request will be granted if the card holder has permission to access this door based on their groups affiliation.
 Available only to digital credential users

 - Parameter passId : Brivo passId
 - Parameter accessPointId: The id associated with the accesspoint
 - Parameter onSuccess: completion block that handles success
 - Parameter onFailure: completion block that handles  failure
 - Parameter cancellationSignal: can be used to cancel the unlocking process
 */
func unlockAccessPoint(passId: String,
                       accessPointId: String,
                       onResult: OnResult?,
                       cancellationSignal: CancellationSignal?)

/**
 Locks an access-point.
 This method should be used when handing the credentials outside of the SDK

 Only a few access-points support the locking process.
 The request will be granted if the card holder has permission to access this door based on their groups affiliation.
 Available only to digital credential users

 - Parameter selectedAccessPoint: BrivoSelectedAccessPoint can be created from BrivoAccessPoint.
                                  The class BrivoSDKOnAirHelper from BrivoOnAir has methods to help with the creation of the object.
 - Parameter onSuccess: completion block that handles success
 - Parameter onFailure: completion block that handles failure
 - Parameter cancellationSignal: can be used to cancel the locking process
 */
func lockAccessPoint(selectedAccessPoint: BrivoSelectedAccessPoint,
                     onResult: OnResult?,
                     cancellationSignal: CancellationSignal?)


/**
 Locks an access-point.
 This method should be used when the SDK handles the credentials.

 Only a few access-points support the locking process.
 The request will be granted if the card holder has permission to access this door based on their groups affiliation.
 Available only to digital credential users

 - Parameter passId : Brivo passId
 - Parameter accessPointId: The id associated with the accesspoint
 - Parameter onSuccess: completion block that handles success
 - Parameter onFailure: completion block that handles failure
 - Parameter cancellationSignal: can be used to cancel the locking process
 */
func lockAccessPoint(passId: String,
                     accessPointId: String,
                     onFailure: OnFailureType?,
                     onResult: OnResult?,
                     cancellationSignal: CancellationSignal?)


/**
 Unlocks the nearest Bluetooth access point from the list of passes.
 This method should be used when handing the credentials outside of the SDK

 The request will be granted if the card holder has permission to access this door based on their groups affiliation.
 Available only to digital credential users

 - Parameter passes: A list that contains BrivoOnairPasses from which the access points will be searched
 - Parameter onSuccess: completion block that handles success
 - Parameter onFailure: completion block that handles  failure
 - Parameter cancellationSignal: can be used to cancel the unlocking process
 */
func unlockNearestBLEAccessPoint(passes: [BrivoOnairPass],
                                 onResult: OnResult?,
                                 cancellationSignal: CancellationSignal?)

/**
 Unlocks the nearest Bluetooth access point from the list of passes.
 This method should be used when handing the credentials outside of the SDK

 The request will be granted if the card holder has permission to access this door based on their groups affiliation.
 Available only to digital credential users

 - Parameter pass: A  BrivoOnairPass from which the access points will be searched
 - Parameter siteId: The id of the site that will be used to search the access points from
 - Parameter onSuccess: completion block that handles success
 - Parameter onFailure: completion block that handles  failure
 - Parameter cancellationSignal: can be used to cancel the unlocking process
 */
func unlockNearestBLEAccessPoint(pass: BrivoOnairPass,
                                 siteId: Int,
                                 onResult: OnResult?,
                                 cancellationSignal: CancellationSignal?)

/**
 Unlocks the nearest Bluetooth access point from the ones that are currently available.
 This method should be used when the SDK handles the credentials.

 The request will be granted if the card holder has permission to access this door based on their groups affiliation.
 Available only to digital credential users

 - Parameter onSuccess: completion block that handles success
 - Parameter onFailure: completion block that handles  failure
 - Parameter cancellationSignal: can be used to cancel the unlocking process
 */
func unlockNearestBLEAccessPoint(onResult: OnResult?,
                                 cancellationSignal: CancellationSignal?)
```

Examples of usage:
#### BrivoSDKAccess unlock access point usage with internal stored credentials
```
do {
    try BrivoSDKAccess.instance().unlockAccessPoint(passId: "PASS_ID",
                                                    accessPointId: "ACCESS_POINT_ID",
                                                    onResult: { [weak self] (brivoResult) in
                                                        //Handle unlock access point success case
                                                    }, cancellationSignal: cancellationSignal)
} catch let error {
    //Handle BrivoSDK initialization exception
}
```

#### BrivoSDKAccess unlock access point usage with external credentials 
```
do {
    let selectedAccessPoint = BrivoSelectedAccessPoint(accessPointId: ...,
                                                       userId: ...,
                                                       readerUid: ...,
                                                       bleCredentials: ...,
                                                       timeframe: ...,
                                                       passId: ...,
                                                       brivoApiTokens: BrivoTokens(...)) 
    
    try BrivoSDKAccess.instance().unlockAccessPoint(selectedAccessPoint: selectedAccessPoint,
                                                    onResult: { [weak self] (brivoResult) in
                                                        //Handle unlock access point success case
                                                    }, cancellationSignal: cancellationSignal)
} catch let error {
    //Handle BrivoSDK initialization exception
}
```


<a id="brivo_ble_allegion"></a>
#### BrivoBLEAllegion - Optional 
This module acts as wrapper for AllegionSDKs and is an optional dependendency for [BrivoAccess](#brivo_access) to unlock Allegion devices.
> [!NOTE]
> Using this module requires access to Allegion SDKs (see [Podfile](BrivoSampleApp/Podfile)).\
> Allegion SDKs come with a limitation: arm64 architecture is excluded so the app runs only on simulators with Rosetta.

It has the following interface:
```
/**
     Initialise BrivoSDKBLEAllegion
     - Parameter configuration: credentials to setup AllegionSDK
     */
    init(configuration: BrivoBLEAllegion.BrivoBLEAllegionConfiguration)

    /**
     Setup initial comunication with AllegionSDK and restores local credentials if possible
     - Throws: an error if parameters from ``BrivoBLEAllegionConfiguration`` are rejected by AllegionSDK
     */
    func initialise() async throws

    /**
     Retrieve and store the allegion tokens required for authenticating using AllegionSDK
     - Parameter brivoOnAirPass: BrivoOnAir pass
     - Note: ``IBrivoSDKBLEAllegion/initialise()`` must be called  before.
     */
    func refreshCredentials(brivoOnAirPass: BrivoOnAir.BrivoOnairPass) async throws

    /**
     Unlock access point with allegion door type
     - Parameter accessPoint: BrivoSelectedAccessPoint
     - Parameter onResult: BrivoResult for unlocking the access point
     - Parameter cancellationSignal: can be used to cancel the unlocking process
     - Note: ``IBrivoSDKBLEAllegion/initialise()`` must be before.
     */
    func unlockAccessPoint(accessPoint: BrivoOnAir.BrivoSelectedAccessPoint, onResult: BrivoCore.OnResultType?, cancellationSignal: BrivoCore.CancellationSignal?)
```


<a id="brivo_ble"></a>
#### BrivoBLE
This module manages the connection between an access point and a panel through bluetooth.
Everything related with BLE communication is handled here.

 <a id="brivo_local_authentication"></a>
#### BrivoLocalAuthentication
This module manages the local authenication on a device. It is avaiale through a shared ```instance```.
It has the following interface:
```
/**
 Cancels an on going authentication process.
 */
func cancelAuthentication()

/**
 Checks if a local authentication can be performed.
 - Parameter onSuccess: completion block that handles success
 - Parameter onFailure: completion block that handles failure
 */
func canAuthenticate(onSucces: OnLocalAuthenticationSuccessType?, onFailure: OnFailureType?)

/**
 Performs the local authentication on the device.
 - Parameter onSuccess: completion block that handles success
 - Parameter onFailure: completion block that handles failure
 */
func authenticate(onSucces: OnLocalAuthenticationSuccessType?, onFailure: OnFailureType?)
```

 <a id="brivo_network_core"></a>
#### BrivoNetworkCore
This module manages the main classes for HTTP communication with Brivo Backends.
Main classes are:
```
public class HTTPSRequest { ... }
public class BrivoHTTPSRequest: NSObject { ... }

```

 <a id="brivo_errors"></a>
## BrivoSDK errors
Each module returns errors through its completion handlers.
All the errors are BrivoError. Some errors of type BrivoError are sent inline like this:
```
let brivoError = BrivoError(statusCode: response?.status?.statusCode ?? refreshTokenError.statusCode, errorDescription: 
response?.status?.error?.errorDescription ?? refreshTokenError.localizedDescription)
                        onRefreshTokenFailed?(brivoError)
```
, other errors are grouped per module like detailed bellow:

#### BrivoOnAirErrors
```
@objc public class BrivoOnAirErrors: NSObject {
    @objc public static let serverCallError = BrivoError(statusCode: -3001, errorDescription: "Server call failed.")
    @objc public static let authenticationMissingDataError = BrivoError(statusCode: -3002, errorDescription: "Authentication missing data.")
    @objc public static let redeemPassMissingDataError = BrivoError(statusCode: -3003, errorDescription: "Redeem pass missing data")
    @objc public static let sdkIsNotUsingDefaultStorageError = BrivoError(statusCode: -3004, errorDescription: "SDK is set to not use SDK storage")
    @objc public static let getSitesMissingDataError = BrivoError(statusCode: -3005, errorDescription: "Get sites missing data")
    @objc public static let getAccessPointsMissingDataError = BrivoError(statusCode: -3006, errorDescription: "Get access points missing data")
    @objc public static let controlLockConfigMissingDataError = BrivoError(statusCode: -3007, errorDescription: "Control Lock config missing data")
    @objc public static let refreshTokenError = BrivoError(statusCode: HttpStatusCodes.refreshTokenFailed, errorDescription: "Refresh token failed.")

    @objc public static func brivoOnAirErrorWithDescription(_ description: String) -> BrivoError {
        return BrivoError(statusCode: -3010, errorDescription: description)
    }
}
```

#### BrivoConfigurationErrors
```
@objc public class BrivoConfigurationErrors: NSObject {
    @objc public static let unknownError = BrivoError(statusCode: -1000, errorDescription: "Unknown error.")
    @objc public static let notInitializedError = BrivoError(statusCode: -1001, errorDescription: "BrivoSDK init failed. SDK not configured")
    @objc public static let notConfiguredForLocalStorageError = BrivoError(statusCode: -1002, errorDescription: "SDK not configured to use local storage")
    @objc public static let noPassesFoundInLocalStorageError = BrivoError(statusCode: -1003, errorDescription: "There are no passes on local storage")
    @objc public static let accessPointNotFoundInLocalStorageError = BrivoError(statusCode: -1004, errorDescription: "Acess point not found in local storage")
    @objc public static let passNotFoundInLocalStorageError = BrivoError(statusCode: -1005, errorDescription: "Pass not found in local storage")
    @objc public static let missingBLECredentialError = BrivoError(statusCode: -1006, errorDescription: "Missing ble credential")
    @objc public static let accessPointInvalidDoorType = BrivoError(statusCode: -1007, errorDescription: "Access point invalid door type")
    @objc public static let missingNetworkConnectionError = BrivoError(statusCode: -1008, errorDescription: "Missing internet connection")

    @objc public static func brivoErrorWithDescription(_ description: String) -> BrivoError {
        return BrivoError(statusCode: -1010, errorDescription: description)
    }
}
```

#### BrivoLocalAuthenticationErrors
```
@objc public class BrivoLocalAuthenticationErrors: NSObject {
    @objc public static let unknownError = BrivoError(statusCode: -4000, errorDescription: "Incorrect Passcode.")
    @objc public static let localHardwareUnavailableError = BrivoError(statusCode: -4001, errorDescription: "Hardware unavailable for local authentication")
    @objc public static let timeOutError = BrivoError(statusCode: -4002, errorDescription: "Local authentication timed out.")
    @objc public static let localHardwareNotPresentError = BrivoError(statusCode: -4003, errorDescription: "Hardware doesn't exist for local authentication")
    @objc public static let notEnroledError = BrivoError(statusCode: -4004, errorDescription: "Biometric or passcode verification is required to unlock this door. Please enable one of these security options to continue.")
    @objc public static let contextNotSetError = BrivoError(statusCode: -4005, errorDescription: "Context not set for local authentication")
    @objc public static let applicationCanceledError = BrivoError(statusCode: -4006, errorDescription: "Authentication was cancelled by application")
    @objc public static let notInteractiveError = BrivoError(statusCode: -4007, errorDescription: "Authentication failed because interaction is disabled")
    @objc public static let biometryLockoutError = BrivoError(statusCode: -4008, errorDescription: "Biometry is now locked because of too many failed attempts. Passcode is required to unlock biometry")
}
```

#### BrivoSDKAccessErrors
```
@objc public class BrivoSDKAccessErrors: NSObject {
    @objc public static let unknownError = BrivoError(statusCode: -1000, errorDescription: "Unknown error.")
    @objc public static let notInitializedError = BrivoError(statusCode: -1001, errorDescription: "BrivoSDK init failed. SDK not configured")
    @objc public static let notConfiguredForLocalStorageError = BrivoError(statusCode: -1002, errorDescription: "SDK not configured to use local storage")
    @objc public static let noPassesFoundInLocalStorageError = BrivoError(statusCode: -1003, errorDescription: "There are no passes on local storage")
    @objc public static let accessPointNotFoundInLocalStorageError = BrivoError(statusCode: -1004, errorDescription: "Acess point not found in local storage")
    @objc public static let passNotFoundInLocalStorageError = BrivoError(statusCode: -1005, errorDescription: "Pass not found in local storage")
    @objc public static let missingBLECredentialError = BrivoError(statusCode: -1006, errorDescription: "Missing ble credential")
    @objc public static let accessPointInvalidDoorType = BrivoError(statusCode: -1007, errorDescription: "Access point invalid door type")
    @objc public static let missingNetworkConnectionError = BrivoError(statusCode: -1008, errorDescription: "Missing internet connection")
    @objc public static let missingReaderUUIDError = BrivoError(statusCode: -1009, errorDescription: "Missing reader UUID")

    @objc public static func brivoErrorWithDescription(_ description: String) -> BrivoError {
        return BrivoError(statusCode: -1010, errorDescription: description)
    }
}
```

#### BrivoBLEErrors
```
public struct BrivoBLEErrors {
   public static let unknownError = BrivoError(statusCode: -2000,  errorDescription: "Failed to unlock bluetooth door")
   public static let poweredOffError = BrivoError(statusCode: -2001,  errorDescription: "BLE disabled on device")
   public static let failedTransmissionError = BrivoError(statusCode: -2004,  errorDescription: "Failed BLE transmission")
   public static let unauthorizedError = BrivoError(statusCode: -2005, errorDescription: "Access Denied")
   public static let authenticationTimedOut = BrivoError(statusCode: -2006, errorDescription: "BLE Authentication timed out")
   public static let unsupportedError = BrivoError(statusCode: -2007, errorDescription: "Bluetooth unsupported")
   public static let peripheralError = BrivoError(statusCode: -2008, errorDescription: "BLE peripheral error")
    public static let confirmError = BrivoError(statusCode: -2009, errorDescription: "Failed to call API")

    public static func brivoBleErrorWithDescription(_ description: String) -> BrivoError {
        return BrivoError(statusCode: -2010, errorDescription: description)
    }
}
```

## Issues
If you run into any bugs or issues, feel free to post an [Issues](https://github.com/brivo-mobile-team/Brivo-Mobile-SDK/issues) to discuss further.
<p align="center">
Made with ❤️ at <img src="brivo.png" width="60"/>
</p>