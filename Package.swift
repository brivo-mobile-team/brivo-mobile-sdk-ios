// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let version = "1.20.0"
let package = Package(
    name: "BrivoMobileSDK",
    platforms: [.iOS(.v14)],
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
        .library(
            name: "BrivoMobileBLEAllegionSDK",
            targets: ["BrivoMobileBLEAllegionSDK"]
        )
    ],
    dependencies: [
        .package(url: "https://bitbucket.org/brivoinc/mobile-allegion-sdk-ios", branch: "feature/add-allegion-as-package-from-scratch-dynamic")
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

            .target(
                name: "BrivoMobileBLEAllegionSDK",
                dependencies: [
                    .byName(name: "BrivoBLEAllegion"),
                    .product(name: "Allegion-Access-MobileAccessSDK-iOS", package: "mobile-allegion-sdk-ios")
                ],
                path: "./Sources/BrivoAllegionSDK"
            ),
            .binaryTarget(
                name: "BrivoBLEAllegion",
                path: "./Sources/BrivoMobileSDK/BrivoBLEAllegion.xcframework"
            ),

    ]
)
