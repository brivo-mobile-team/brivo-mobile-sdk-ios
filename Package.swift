// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription


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
                path: "./brivo-mobile-frameworks/BrivoAccess.xcframework"
            ),

            .binaryTarget(
                name: "BrivoBLE",
                path: "./brivo-mobile-frameworks/BrivoBLE.xcframework"
            ),

            .binaryTarget(
                name: "BrivoCore",
                path: "./brivo-mobile-frameworks/BrivoCore.xcframework"
            ),

            .binaryTarget(
                name: "BrivoLocalAuthentication",
                path: "./brivo-mobile-frameworks/BrivoLocalAuthentication.xcframework"
            ),

            .binaryTarget(
                name: "BrivoOnAir",
                path: "./brivo-mobile-frameworks/BrivoOnAir.xcframework"
            ),

            .binaryTarget(
                name: "BrivoNetworkCore",
                path: "./brivo-mobile-frameworks/BrivoNetworkCore.xcframework"
            ),

    ]
)

