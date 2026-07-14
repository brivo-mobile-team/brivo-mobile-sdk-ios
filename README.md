# Brivo Mobile SDK for iOS

The Brivo Mobile SDK is a set of reusable Swift libraries that let your iOS app redeem Brivo
mobile passes and unlock doors over the internet and over Bluetooth (BLE). This guide is written
for external integrators and walks through everything from installation to unlocking a door.

## Table of contents

1. [Overview](#1-overview)
2. [Requirements & compatibility](#2-requirements--compatibility)
3. [Installation (Swift Package Manager)](#3-installation-swift-package-manager)
4. [Initialization & configuration](#4-initialization--configuration)
5. [Permissions](#5-permissions)
6. [Managing mobile passes](#6-managing-mobile-passes)
7. [Using the SDK without SDK storage](#7-using-the-sdk-without-sdk-storage)
8. [Unlocking doors](#8-unlocking-doors)
9. [Error reference](#9-error-reference)
10. [Keeping up to date & good practices](#10-keeping-up-to-date--good-practices)

---

## 1. Overview

The SDK is organized as a single Swift Package product, `BrivoMobileSDK`, composed of several
internal modules. As an integrator you interact with a small set of singleton entry points:

| Entry point | Module | Responsibility |
|-------------|--------|----------------|
| `BrivoSDK.instance` | BrivoCore | One-time configuration, device ID, SDK version |
| `BrivoSDKOnAir.instance()` | BrivoOnAir | Redeem/refresh passes, OnAir authentication, internet unlocks |
| `BrivoSDKAccess.instance()` | BrivoAccess | Unified unlock entry point (internet, BLE), continuous scanning |
| `BrivoSDKLocalAuthentication.instance` | BrivoLocalAuthentication | Two-factor / biometric (Face ID, Touch ID, passcode) |

A typical lifecycle:

1. **Configure** `BrivoSDK` once at app launch.
2. **Redeem** a Brivo mobile pass with the credentials your backend hands the user.
3. **Unlock** access points through `BrivoSDKAccess`.

> [!NOTE]
> Brivo offers integrations with additional third-party lock providers beyond what is covered
> here. Contact Brivo if you need one that is not documented in this guide.

---

## 2. Requirements & compatibility

| Requirement | Value |
|-------------|-------|
| Minimum iOS deployment target | **iOS 17.0** |
| Swift | Built with **Swift 5.9** (`swift-tools-version: 5.9`) |
| Distribution | Swift Package Manager (binary `.xcframework` targets) |
| Xcode | **Confirm with Brivo** — published references are inconsistent |

> [!NOTE]
> The recommended Xcode version is unconfirmed (Brivo's published material disagrees on the exact
> version). The package itself declares Swift tools version 5.9; use a current Xcode that ships
> with Swift 5.9 or newer and confirm the exact supported version with Brivo.

You can read the SDK version at runtime:

```swift
let version = BrivoSDK.sdkVersion   // e.g. "v3.4.0", or "Not available"
```

---

## 3. Installation (Swift Package Manager)

The Brivo Mobile SDK ships as a Swift Package containing prebuilt `.xcframework` binaries.

### Adding the package in Xcode

1. In Xcode, open **File ▸ Add Package Dependencies…**
2. In the search field, enter the package URL:
   `https://github.com/brivo-mobile-team/brivo-mobile-sdk-ios.git`
3. Choose the latest/desired version (e.g. **3.4.0**).
4. Select the **BrivoMobileSDK** product.

### Adding the package in a `Package.swift` manifest

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
            .product(name: "BrivoMobileSDK", package: "brivo-mobile-sdk-ios")
        ]
    )
]
```

Then import the modules you need:

```swift
import BrivoCore
import BrivoOnAir
import BrivoAccess
import BrivoLocalAuthentication   // only if you use two-factor unlocks
```

---

## 4. Initialization & configuration

Before calling any other SDK API you must configure `BrivoSDK` exactly once, typically at app
launch (for example in your `App` initializer or `application(_:didFinishLaunchingWithOptions:)`).
Configuration is built with `BrivoSDKConfiguration.Builder` and applied via
`BrivoSDK.instance.configure(brivoConfiguration:)`.

```swift
import BrivoCore

do {
    let configuration = try BrivoSDKConfiguration.Builder(
        clientId: "YOUR_CLIENT_ID",
        clientSecret: "YOUR_CLIENT_SECRET",
        useSDKStorage: true            // let the SDK persist redeemed passes
    )
    .region(.us)                       // .us (default) or .eu
    .build()

    BrivoSDK.instance.configure(brivoConfiguration: configuration)
} catch {
    // build() throws EmptyPropertyError if clientId / clientSecret are empty
    print("Brivo SDK configuration failed: \(error)")
}
```

`Builder.build()` throws an [`EmptyPropertyError`](#configuration-errors) if `clientId` or
`clientSecret` is an empty string.

> [!IMPORTANT]
> Configure the SDK before calling `BrivoSDKOnAir.instance()` or `BrivoSDKAccess.instance()`.
> `BrivoSDKOnAir.instance()` throws `EmptyPropertyError.emptyConfiguration` if no configuration
> has been applied yet.

### Client ID & secret

`clientId` and `clientSecret` are the OAuth credentials Brivo provisions for your application.
They are required positional arguments of the `Builder` initializer.

### Regions

The `region` selects the Brivo data center and resolves the default authentication and API URLs:

```swift
public enum Region: Int {
    case us   // default
    case eu
}
```

For non-default environments you can override the resolved URLs explicitly:

```swift
.region(.eu)
.authUrl("https://auth.example.brivo.com")
.apiUrl("https://api.example.brivo.com")
```

### Configuration options

All builder methods (except the `clientId` / `clientSecret` / `useSDKStorage` constructor
arguments) are optional and chainable.

| Builder method | Type / default | Purpose |
|----------------|----------------|---------|
| `init(clientId:clientSecret:useSDKStorage:)` | required | OAuth credentials; whether the SDK persists passes |
| `region(_:)` | `Region` (`.us`) | Selects data center / default URLs |
| `authUrl(_:)` | `String?` | Override the auth base URL |
| `apiUrl(_:)` | `String?` | Override the API base URL |
| `tokenRefresher(_:)` | `TokenRefresher?` | Delegate invoked to refresh tokens on HTTP 401 |
| `sessionRequestTimeout(_:)` | `SessionRequestTimeout?` | HTTP request timeout (`nil` = system default) |
| `isConsoleLoggingEnabled(_:)` | `Bool` (`true`) | Toggles SDK console logging |
| `brivoBLEConfiguration(_:)` | `BrivoBLEConfiguration` | BLE scan/connect/communication timeouts |

`BrivoBLEConfiguration` lets you tune the native Brivo BLE unlock timeouts:

```swift
let bleConfig = BrivoBLEConfiguration(
    scanTimeout: .seconds(10),          // find a matching reader
    connectionTimeout: .seconds(3),     // establish the GATT connection
    communicationTimeout: .seconds(10)  // complete the BLE transaction
)
// .brivoBLEConfiguration(bleConfig)
```

### Device ID & SDK version

```swift
let deviceId = BrivoSDK.instance.getDeviceId()   // stable per-install UUID (dashes stripped)
let version  = BrivoSDK.sdkVersion               // "v3.4.0"
```

`getDeviceId()` generates and persists a UUID on first call and returns the same value thereafter.

---

## 5. Permissions

> [!WARNING]
> **Permissions are owned by the host app.** The SDK does **not** vend any `Info.plist` usage
> description strings. If your app is missing the keys below, iOS will not present the permission
> prompt and the corresponding feature will silently fail. You must add them to *your* app's
> `Info.plist`.

| Capability | Required `Info.plist` key | When it's needed |
|------------|---------------------------|------------------|
| Bluetooth | `NSBluetoothAlwaysUsageDescription` | Any BLE unlock (native Brivo BLE, continuous scanning) |
| Wi-Fi / trusted networks | `NSLocationWhenInUseUsageDescription` | Reading the connected Wi-Fi SSID for trusted-network unlocks (iOS gates SSID access behind Location) |
| Two-factor (biometric) | `NSFaceIDUsageDescription` | Two-factor unlocks that use Face ID |

You will typically also declare the relevant background modes for BLE and location, for example
in `Info.plist`:

```xml
<key>UIBackgroundModes</key>
<array>
    <string>bluetooth-central</string>
    <string>bluetooth-peripheral</string>
    <string>location</string>
</array>
```

---

## 6. Managing mobile passes

### What is a mobile pass?

A **mobile pass** (`BrivoOnairPass`) is a redeemed Brivo OnAir credential that lets a device open
doors. It carries the OAuth tokens used for internet unlocks, optional BLE credentials, and the
sites/access points the holder can reach. Key public properties include:

```swift
public class BrivoOnairPass: NSObject, Codable {
    public var pass: String?        // the pass identifier (also exposed as `passId`)
    public var bleCredential: String?
    public var bleAuthTimeFrame: Int32
    public var accountName: String?
    public var sites: [BrivoSite]?
    public var brivoOnairPassCredentials: BrivoOnairPassCredentials?  // userId + tokens
    public var firstName: String?
    public var lastName: String?
    // …
}
```

`BrivoSDKOnAir.instance()` is the entry point for pass management. It is `throws` because it
requires the SDK to have been configured first.

### Redeem a pass

`passId` is the email Brivo issued to the user, and `passCode` is the corresponding token.

```swift
import BrivoOnAir

let onAir = try BrivoSDKOnAir.instance()
let result = await onAir.redeemPass(passId: "user@example.com", passCode: "ONE_TIME_TOKEN")

switch result {
case .success(let pass):
    // pass is a BrivoOnairPass? — persisted automatically when useSDKStorage == true
    print("Redeemed pass for \(pass?.accountName ?? "user")")
case .failure(let error):
    print("Redeem failed: \(error.localizedDescription)")
}
```

### Refresh a pass

Refreshing returns a pass with fresh OAuth tokens. Pass in the tokens you already hold (for
example from `pass.brivoOnairPassCredentials?.tokens`).

```swift
let onAir = try BrivoSDKOnAir.instance()

guard let tokens = pass.brivoOnairPassCredentials?.tokens else { return }
let refreshed = await onAir.refreshPass(brivoTokens: tokens)

if case .success(let freshPass) = refreshed {
    // freshPass now carries refreshed tokens
}
```

### Retrieve passes from SDK storage

When `useSDKStorage == true`, redeemed and refreshed passes are persisted automatically and can
be retrieved later:

```swift
let onAir = try BrivoSDKOnAir.instance()
let stored = await onAir.retrieveSDKLocallyStoredPasses()

if case .success(let passes) = stored {
    // [BrivoOnairPass]
}
```

### Using SDK storage

`useSDKStorage` is a required argument of the `Builder` initializer:

- **`true`** — the SDK persists passes for you. Redeem/refresh automatically store them, you read
  them back with `retrieveSDKLocallyStoredPasses()`, and you can unlock by `passId` /
  `accessPointId` without holding tokens yourself.
- **`false`** — you are responsible for persisting passes and tokens. See
  [§7](#7-using-the-sdk-without-sdk-storage).

> [!NOTE]
> The SDK does not expose a public "delete pass from storage" API to integrators. If your flow
> requires removing stored passes, confirm the supported approach with Brivo.

---

## 7. Using the SDK without SDK storage

If you configured the SDK with `useSDKStorage: false`, you manage pass data and tokens yourself
and unlock with externally held credentials. This requires building a `BrivoSelectedAccessPoint`.

### Obtain access tokens

You can obtain tokens from `redeemPass` / `refreshPass` (via
`pass.brivoOnairPassCredentials?.tokens`), or by authenticating directly with OnAir credentials:

```swift
let onAir = try BrivoSDKOnAir.instance()
let credentials = BrivoOnAirCredentials(userName: "user@example.com", password: "••••••••")
let result = await onAir.authenticate(credential: credentials)

if case .success(let tokens) = result {
    // tokens: BrivoTokens? — accessToken + optional refreshToken
}
```

`BrivoTokens` is a simple value carrier:

```swift
public class BrivoTokens: NSObject, Codable {
    public var accessToken: String
    public var refreshToken: String?
    public init(accessToken: String, refreshToken: String?)
}
```

### Custom token refresher

You can plug in your own token-refresh logic by conforming an object to `TokenRefresher` and
injecting it at configuration time:

```swift
final class MyTokenRefresher: TokenRefresher {
    func refreshToken(brivoTokens: BrivoTokens) async throws -> BrivoTokens {
        // return refreshed tokens
    }
}

// at configuration:
.tokenRefresher(MyTokenRefresher())
```

### Provide pass data for an unlock

To unlock without SDK storage, build a `BrivoSelectedAccessPoint` and pass it to
`unlockAccessPoint(selectedAccessPoint:...)`. The tokens live **inside** `passCredential`
(a `BrivoOnairPassCredentials`), not as a separate argument. There are two ways to build one, in
order of preference.

#### Recommended: from a pass you already hold

If you hold the `BrivoOnairPass` (the passes you fetched and persist yourself), let the SDK resolve
the matching site and access point and assemble a fully populated `BrivoSelectedAccessPoint` for
you — it fills in `doorType`, `readerUid`, BLE credentials, `timeframe`, `hasTrustedNetwork`, and the
two-factor flag automatically:

```swift
let pass: BrivoOnairPass = /* the pass you manage */

do {
    let selected = try BrivoSelectedAccessPoint(pass: pass, accessPointId: "123")

    let access = BrivoSDKAccess.instance()
    for try await result in await access.unlockAccessPoint(
        selectedAccessPoint: selected,
        cancellationSignal: nil
    ) {
        // handle result — see §8
    }
} catch {
    // BrivoOnAirErrors.accessPointNotFoundError    — id not found in the pass(es)
    // BrivoOnAirErrors.passMissingCredentialsError — matched pass lacks credentials
}
```

If you hold several passes and don't know which one owns the access point, pass the array — the
first pass that contains the id wins:

```swift
let selected = try BrivoSelectedAccessPoint(passes: passes, accessPointId: "123")
```

Both initializers live on `BrivoSelectedAccessPoint` and are `throws(BrivoError)` — see
[§9](#9-error-reference) for the error codes.

> [!NOTE]
> The array helper `passes.getBrivoSelectedAccessPoint(accessPointId:passId:)` is **deprecated** in
> favour of these initializers:
> - `passes.getBrivoSelectedAccessPoint(accessPointId: id)` → `try BrivoSelectedAccessPoint(passes: passes, accessPointId: id)`
> - to scope the search to one pass, pass that single pass instead → `try BrivoSelectedAccessPoint(pass: pass, accessPointId: id)`

#### Advanced: field-by-field

When you don't hold a `BrivoOnairPass` (for example, you assemble access-point data from your own
backend model), build the descriptor directly:

```swift
public class BrivoSelectedAccessPoint: NSObject {
    public required init(
        name: String,
        accessPointPath: AccessPointPath,
        doorType: DoorType,
        passCredential: BrivoOnairPassCredentials,
        isTwoFactorEnabled: Bool = false,
        readerUid: String? = nil,
        bleCredentials: String? = nil,
        timeframe: Int32 = 0,
        deviceModelId: String?,
        controlLockId: Int? = nil,
        sendEvents: Bool = true
    )
}
```

```swift
let tokens = BrivoTokens(accessToken: "ACCESS_TOKEN", refreshToken: "REFRESH_TOKEN")
let passCredential = BrivoOnairPassCredentials(userId: "USER_ID", tokens: tokens)

let path = AccessPointPath(
    accessPointId: 123,
    siteId: 456,
    passId: "PASS_ID",
    hasTrustedNetwork: false    // set true for trusted-network sites
)

let selectedAccessPoint = BrivoSelectedAccessPoint(
    name: "Front Door",
    accessPointPath: path,
    doorType: .internet,        // see DoorType in §8
    passCredential: passCredential,
    deviceModelId: nil
)

// then unlock via access.unlockAccessPoint(selectedAccessPoint:...) as shown above
```

> [!NOTE]
> Earlier documentation showed an initializer such as
> `BrivoSelectedAccessPoint(accessPointId:userId:readerUid:bleCredentials:timeframe:passId:brivoApiTokens:)`.
> That signature is **stale** — use the `init(name:accessPointPath:doorType:passCredential:…)`
> shown above.

---

## 8. Unlocking doors

`BrivoSDKAccess` is the unified unlock entry point. It routes to the correct channel (internet,
native Brivo BLE) based on the door type. Results are
delivered as an `AsyncThrowingStream<BrivoResult, Error>` you consume with `for try await`.

> [!NOTE]
> `BrivoSDKAccess.instance()` is `@MainActor`; call it from the main actor.

### Unlock with SDK-stored credentials

```swift
import BrivoAccess

let access = BrivoSDKAccess.instance()

for try await result in await access.unlockAccessPoint(
    passId: "PASS_ID",
    accessPointId: "ACCESS_POINT_ID",
    cancellationSignal: nil
) {
    switch result.accessPointCommunicationState {
    case .success:
        print("Unlocked")
    case .failed:
        print("Failed: \(result.error?.localizedDescription ?? "unknown")")
    default:
        break   // scanning / connecting / communicating — progress states
    }
}
```

A convenience overload omits `unlockStrategy`. The full signature is
`unlockAccessPoint(passId:accessPointId:unlockStrategy:cancellationSignal:)`.

### Reading results

Each emitted `BrivoResult` carries an `accessPointCommunicationState`, an optional
`accessPointPath`, and (on failure) a `BrivoError`:

| State | Meaning |
|-------|---------|
| `scanning` | Searching for a matching reader (BLE) |
| `connecting` | Establishing a connection to the reader |
| `communicating` | Exchanging the unlock transaction |
| `nearestReaderFound` | The unlock operation picked the closest reader (see below) |
| `success` | The door was unlocked |
| `failed` | The unlock failed; inspect `result.error` |

> [!NOTE]
> `AccessPointCommunicationState` also contains a legacy `shouldContinue` case that is deprecated
> and should be ignored — do not branch on it.

### Door types

The unified call resolves the channel from the door type. The in-scope values are:

| `DoorType` | Channel |
|------------|---------|
| `.internet` | Internet / OnAir unlock |
| `.wavelynx` | Native Brivo Bluetooth (BLE) |

Other `DoorType` cases exist in the enum for additional providers that are outside the scope of
this guide.

### Cancelling an unlock

Pass a `CancellationSignal` and trigger it to cancel an in-flight unlock:

```swift
let signal = CancellationSignal()

Task {
    for try await result in await access.unlockAccessPoint(
        passId: "PASS_ID",
        accessPointId: "ACCESS_POINT_ID",
        cancellationSignal: signal
    ) { /* … */ }
}

// elsewhere, to abort:
signal.cancel()
```

### Internet vs Bluetooth, and multi-channel doors

When a door supports more than one channel, the SDK selects the channel automatically. The only
public override is to force the internet path for Brivo doors that also support BLE:

```swift
public enum UnlockStrategy {
    case forceInternetUnlockforBrivoDoors
}
```

```swift
for try await result in await access.unlockAccessPoint(
    passId: "PASS_ID",
    accessPointId: "ACCESS_POINT_ID",
    unlockStrategy: .forceInternetUnlockforBrivoDoors,
    cancellationSignal: nil
) { /* … */ }
```

> [!NOTE]
> There is no public "force BLE" counterpart. Channel selection is otherwise internal to the SDK.

### Continuous scanning

Continuous scanning runs a **foreground** BLE scan that discovers nearby readers and streams them to
you as they come and go. You rank the discovered devices (typically by signal strength), pick one,
and unlock it with `unlockDiscoveredAccessPoint(device:)`. It's delivered as an `AsyncStream`, so the
scan stays active only while you consume it — **end the iterating task to stop** and the SDK tears the
scan down automatically (there's no need to call `stopScanForNearbyDevices()`). The flow is the same
whether the SDK stores your passes or you manage them yourself — only the call that *seeds* the scan
differs.

> [!WARNING]
> The "nearest" reader is chosen by **RSSI (Bluetooth signal strength), not true physical
> distance**. RSSI is affected by phone positioning, obstacles and interference, and reader/phone
> hardware, so the closest reader by signal is not guaranteed to be the closest by distance.

**With SDK storage** — seed the scan from the passes the SDK has stored (`useSDKStorage: true`):

```swift
let access = BrivoSDKAccess.instance()

// Scanning lives only while this task consumes the stream.
let scanTask = Task {
    let events = try await access.startScanForNearbyDevicesWithSDKStorage()
    for await event in events {
        switch event {
        case .devicesUpdated(let devices):
            // devices: [NearbyDevice], each with a `.rssi` (signal strength)
            if let nearest = devices.max(by: { $0.rssi < $1.rssi }) {
                for try await result in access.unlockDiscoveredAccessPoint(device: nearest) {
                    // handle result
                }
                break   // unlocked — the loop ends, and the scan ends with it
            }
        case .stateChanged(let state):
            print("Scanner state: \(state)")
        case .error(let error):
            print("Scanner error: \(error)")
        }
    }
}

// To stop earlier (e.g. the user leaves the screen), just cancel the task:
scanTask.cancel()
```

**With external credentials** — when you manage passes yourself (`useSDKStorage: false`), seed the
scan from the passes you hold. Everything after the first line is identical to the example above:

```swift
let passes: [BrivoOnairPass] = /* the passes you manage */
let events = try access.startScanForNearbyDevices(passes: passes)
// …then drive `events` with the same `for await` loop inside a task you can cancel to stop.
```

> [!NOTE]
> `startScanForNearbyDevicesWithSDKStorage()` is `async` — it loads the stored passes before
> scanning. `startScanForNearbyDevices(passes:)` is `@MainActor` and synchronous. Both return an
> `AsyncStream<ContinuousScannerEvent>`.

The stream yields `ContinuousScannerEvent` values:

| Event | Payload | Meaning |
|-------|---------|---------|
| `.devicesUpdated` | `[NearbyDevice]` | The set of nearby readers changed — re-read and re-rank |
| `.stateChanged` | `ScannerState` | The scanner's lifecycle state changed (see below) |
| `.error` | `ScannerError` | A scan error occurred (see below) |

**`ScannerState`** (carried by `.stateChanged`):

| State | Meaning |
|-------|---------|
| `.scanning` | Scanning is active — emitted when the scan starts and when it resumes after returning to the foreground |
| `.paused` | Scanning paused because the app entered the background; it resumes (`→ .scanning`) on foreground |
| `.idle` | Initial/terminal state — **not emitted as an event**; the scanner returns to idle when the stream terminates (you end the consuming task, or call `stopScanForNearbyDevices()` explicitly) |

**`ScannerError`** (carried by `.error`):

| Error | Meaning |
|-------|---------|
| `.scanAlreadyInProgress` | A scan is already running — stop it before starting another |
| `.missingValidAccessPointsForContinuousScan` | None of the passes contained a scannable BLE access point; the stream finishes |
| `.providerFailed(provider:underlyingError:)` | The native Brivo BLE scanner hit a permanent error |

`NearbyDevice` exposes the signal strength used for ranking:

```swift
public struct NearbyDevice: Identifiable, Equatable {
    public let name: String
    public let type: DoorType
    public let rssi: Int                 // signal strength (not distance)
    public let accessPointPath: AccessPointPath
    public var id: Int                   // == accessPointPath.accessPointId
}
```

### Two-factor / biometric unlocks

Two-factor uses on-device biometrics (Face ID / Touch ID) or the device passcode via
`BrivoSDKLocalAuthentication`, which wraps `LAPolicy.deviceOwnerAuthentication`.

```swift
public class BrivoSDKLocalAuthentication {
    public static let instance: BrivoSDKLocalAuthentication
    public func canAuthenticate() async -> Result<Void, BrivoError>
    public func authenticate() async -> Result<Void, BrivoError>
    public func cancelAuthentication()
}
```

You can probe availability up front:

```swift
let auth = BrivoSDKLocalAuthentication.instance
if case .failure(let error) = await auth.canAuthenticate() {
    // biometrics/passcode unavailable — see BrivoLocalAuthenticationErrors (§9)
}
```

> [!IMPORTANT]
> When an access point is two-factor enabled (`BrivoSelectedAccessPoint.isTwoFactorEnabled == true`),
> the biometric prompt is performed **internally by the unlock flow** — you do not call
> `authenticate()` yourself during a normal unlock. There is **no `.authenticate`
> communication state**: the unlock stream emits the usual progress states and resolves to
> `.success` or `.failed` after authentication completes (a cancelled/failed biometric surfaces as
> a `.failed` result carrying a `BrivoLocalAuthenticationErrors` error).

Remember to add `NSFaceIDUsageDescription` to your app's `Info.plist` (see [§5](#5-permissions)).

---

## 9. Error reference

Most asynchronous SDK calls return either `Result<…, BrivoError>` or stream `BrivoResult` values
whose `error` is a `BrivoError`. `BrivoError` is an `NSError` subclass; read `code` and
`localizedDescription`.

> [!NOTE]
> `BrivoError` exposes several deprecated members (`statusCode`, `errorDescription`, `context`,
> `accessPointAdditionalInfo`, and the `init(statusCode:…)` initializers). Prefer `code`,
> `localizedDescription`, and `userInfo`.

### Configuration errors

`EmptyPropertyError` is thrown by `BrivoSDKConfiguration.Builder.build()` and by
`BrivoSDKOnAir.instance()`:

| Case | Meaning |
|------|---------|
| `emptyClientId` | `clientId` was empty |
| `emptyClientSecret` | `clientSecret` was empty |
| `emptyConfiguration` | The SDK was used before `configure(...)` was called |

### Local authentication errors

`BrivoLocalAuthenticationErrors` exposes `BrivoError` constants for two-factor / biometric:

| Code | Constant | Meaning |
|------|----------|---------|
| `-4000` | `authenticationFailureError` | Authentication failed |
| `-4001` | `localHardwareUnavailableError` | Biometric hardware unavailable |
| `-4002` | `timeOutError` | Local authentication timed out |
| `-4003` | `localHardwareNotPresentError` | No biometric hardware present |
| `-4004` | `passcodeNotSetError` | No device passcode is set |
| `-4005` | `contextNotSetError` | Authentication context not set |
| `-4006` | `authenticationCancelledError` | Cancelled by the application |
| `-4007` | `notInteractiveError` | Interaction is disabled |
| `-4008` | `biometryLockoutError` | Biometry locked out (too many attempts; passcode required) |
| `-4009` | `biometryNotEnrolledError` | No enrolled biometric identities |

### Access-point resolution errors

Building a `BrivoSelectedAccessPoint` from passes (see
[§7](#7-using-the-sdk-without-sdk-storage)) throws `BrivoError` constants from `BrivoOnAirErrors`:

| Code | Constant | Meaning |
|------|----------|---------|
| `-3012` | `accessPointNotFoundError` | The access point id was not found in the provided pass(es) |
| `-3013` | `passMissingCredentialsError` | The matched pass is missing the credentials required to build the descriptor |

### Other error domains

Beyond the banks above, other failures surface as `BrivoError` (an `NSError` subclass) in a
module-specific domain. These ranges are largely diagnostic — handle them generically by reading
`error.code` and `error.localizedDescription` rather than branching on individual values:

- **Access** — `BrivoSDKAccessErrors`, domain `com.brivo.sdk.BrivoAccess`, codes **`-1000…-1015`**.
  Unlock-orchestration failures: SDK not configured, pass / access point not found in local storage,
  missing BLE credentials, unsupported door type, no network, etc.
- **Native BLE** — `BrivoBLEError`, domain `com.brivo.sdk.BrivoBLE`, codes **`-2000…-2024`**. Brivo
  BLE scan / connect / transaction failures. A few you may want to act on: `poweredOffError`
  (`-2001`), `unauthorizedError` (`-2005`), `scanTimeoutError` (`-2011`), `scannerBusy` (`-2012`).
- **OnAir** — `BrivoOnAirErrors`, domain `BrivoError`, codes **`-3001…-3013`**. Networking, pass, and
  token failures: server call failed, missing response data, token refresh failed, SDK storage
  disabled, etc. (`-3012` / `-3013` are the access-point-resolution errors listed above.)

> [!NOTE]
> These codes are **iOS-specific**. The Android SDK reuses the same numeric ranges for *different*
> errors, so don't share error-code handling across platforms.

---

## 10. Keeping up to date & good practices

- **Pin a version.** Depend on a specific release (e.g. `from: "3.4.0"`) rather than a branch, and
  bump deliberately. Read `BrivoSDK.sdkVersion` at runtime to confirm which version is shipping.
- **Configure once, early.** Call `BrivoSDK.instance.configure(...)` at app launch before any
  OnAir/Access call. Calling SDK APIs before configuration throws
  `EmptyPropertyError.emptyConfiguration`.
- **Own your permissions.** The SDK does not vend `Info.plist` usage strings. Add
  `NSBluetoothAlwaysUsageDescription`, `NSLocationWhenInUseUsageDescription`,
  `NSFaceIDUsageDescription`, and the relevant `UIBackgroundModes` yourself (see [§5](#5-permissions)).
- **Treat RSSI as approximate.** Continuous scanning ranks readers by signal strength, not distance;
  design your UX accordingly (see [§8](#8-unlocking-doors)).
- **Avoid deprecated APIs.** Do not branch on `AccessPointCommunicationState.shouldContinue`, and do
  not use the deprecated `BrivoError` members.
- **Handle the full result stream.** Consume the `AsyncThrowingStream` to completion and switch on
  `accessPointCommunicationState`, reading `result.error` on `.failed`.

If you run into a bug or have a question, open an issue on the SDK repository
(`brivo-mobile-sdk-ios`) or contact Brivo.
