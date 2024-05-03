// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let version = "1.0.1"
let package = Package(
    name: "BrivoMobileSDK",
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "BrivoMobileSDK",
            targets: [
                "BrivoAccess",
                "BrivoNetworkCore",
                "BrivoBLE",
                "BrivoCore",
                "BrivoLocalAuthentication",
                "BrivoOnAir"
            ]
        ),
    ],
    targets: [

            .binaryTarget(
                name: "BrivoAccess",
                path: "./Sources/BrivoMobileSDK/BrivoAccess.xcframework"
            ),

            .binaryTarget(
                name: "BrivoBLE",
                path: "./Sources/BrivoMobileSDK/BrivoBLE.xcframework"
            ),

            .binaryTarget(
                name: "BrivoCore",
                path: "./Sources/BrivoMobileSDK/BrivoCore.xcframework"
            ),

            .binaryTarget(
                name: "BrivoLocalAuthentication",
                path: "./Sources/BrivoMobileSDK/BrivoLocalAuthentication.xcframework"
            ),

            .binaryTarget(
                name: "BrivoOnAir",
                path: "./Sources/BrivoMobileSDK/BrivoOnAir.xcframework"
            ),

            .binaryTarget(
                name: "BrivoNetworkCore",
                path: "./Sources/BrivoMobileSDK/BrivoNetworkCore.xcframework"
            ),

    ]
)
