// swift-tools-version: 5.9
//
// BrivoMobileSDK — Standard distribution.
//
// 6 SDK modules. No BLEAllegion, no Allegion-stack third-party deps.
// Consumers who don't need Allegion lock integration ship the smallest
// possible binary by integrating this package.

import PackageDescription

let package = Package(
    name: "BrivoMobileSDK",
    products: [
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
        )
    ],
    targets: [
        .binaryTarget(name: "BrivoAccess",              path: "./Sources/BrivoMobileSDK/BrivoAccess.xcframework"),
        .binaryTarget(name: "BrivoBLE",                 path: "./Sources/BrivoMobileSDK/BrivoBLE.xcframework"),
        .binaryTarget(name: "BrivoCore",                path: "./Sources/BrivoMobileSDK/BrivoCore.xcframework"),
        .binaryTarget(name: "BrivoLocalAuthentication", path: "./Sources/BrivoMobileSDK/BrivoLocalAuthentication.xcframework"),
        .binaryTarget(name: "BrivoOnAir",               path: "./Sources/BrivoMobileSDK/BrivoOnAir.xcframework"),
        .binaryTarget(name: "BrivoNetworkCore",         path: "./Sources/BrivoMobileSDK/BrivoNetworkCore.xcframework")
    ]
)
