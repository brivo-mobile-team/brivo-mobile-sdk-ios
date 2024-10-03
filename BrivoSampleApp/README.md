#Brivo iOS Sample App
===========================================
A basic iOS sample app that demonstrates how to configure and use the BrivoSDK.
> **_INFO:_**  The sample app requires Cocoapods setup.

### Installation
> [!NOTE]
>  The Podfile requires access to Allegion SDKs (see [Podfile](BrivoSampleApp/Podfile))\
> Allegion SDKs come with a limitation: arm64 architecture is excluded so the app runs only on simulators with Rosetta.
1. Run `pod install` in `BrivoSampleApp` folder.
2. Open the iOS sample app in Xcode (`BrivoSampleApp.xcworkspace`).
3. On the left side of the Swift Packages inside the Xcode IDE right click the BrivoMobileSDK and select "Update Package" (this will assude we get the latest main version).
4. If needed to load a specific SDK version we need to 
	- Go to the Xcode top menu: File -> Add Package Dependencies
	- Enter in the search field called "Search or Enter Package URL" this url: https://github.com/brivo-mobile-team/brivo-mobile-sdk-ios.git and select the needed tag
5. Select Add Package and add it to the needed target.
6. Press the Build and Run button in Xcode to run the sample app in your simulator of choice.
7. Once the app runs in the simulator, press the top right Add button to add a pass.
8. Enter a valid pass ID and a pass code in the form to redeem a pass.
