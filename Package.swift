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
                "BrivoFluid",
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
            name: "BrivoFluid",
            url: "https://github.com/brivo-mobile-team/brivo-mobile-frameworks/raw/main/BrivoFluid.xcframework.zip",
            checksum: "b693fa0160da4763af39defd42002fc93c22ef461bc872be0f6f577a0a7dde61"
        ),
        .binaryTarget(
            name: "BrivoAccess",
            url: "https://github.com/brivo-mobile-team/brivo-mobile-frameworks/raw/main/BrivoAccess.xcframework.zip",
            checksum: "41932efac55555847ed0f44ac8fcdfa9165da896fb4dd9646e5313951c518dbd"
        ),
        .binaryTarget(
            name: "BrivoBLE",
            url: "https://github.com/brivo-mobile-team/brivo-mobile-frameworks/raw/main/BrivoBLE.xcframework.zip",
            checksum: "ea3844aaf8571bc9c8e04a41b5299059dd915358f2164a1a96bdb0ef5f306f3b"
        ),
        .binaryTarget(
            name: "BrivoCore",
            url: "https://github.com/brivo-mobile-team/brivo-mobile-frameworks/raw/main/BrivoCore.xcframework.zip",
            checksum: "1706bdfa60ec138026e2a6a6cb3da3317137a9cc6bb19cc3d451f9398583bf50"
        ),
        .binaryTarget(
            name: "BrivoLocalAuthentication",
            url: "https://github.com/brivo-mobile-team/brivo-mobile-frameworks/raw/main/BrivoLocalAuthentication.xcframework.zip",
            checksum: "b3a8f508592bdbd13b6fc4d17839f12300608901c721929d758564d0276bb3f8"
        ),
        .binaryTarget(
            name: "BrivoOnAir",
            url: "https://github.com/brivo-mobile-team/brivo-mobile-frameworks/raw/main/BrivoOnAir.xcframework.zip",
            checksum: "a5f2615351e537c95757f584e8afebeacb60a4dcfd62897a15a26db648cc5bac"
        ),
        .binaryTarget(
            name: "BrivoNetworkCore",
            url: "https://github.com/brivo-mobile-team/brivo-mobile-frameworks/raw/main/BrivoNetworkCore.xcframework.zip",
            checksum: "60805def2a940041217e2407c3e7f3fd58a46f673913f22d1164d84ab5cdea06"
        ),
    ]
)
