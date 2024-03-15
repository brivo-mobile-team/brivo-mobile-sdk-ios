// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "BrivoMobileSDK",
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "BrivoMobileSDK",
            targets: ["BrivoAccess","BrivoNetworkCore","BrivoBLE","BrivoCore","BrivoLocalAuthentication","BrivoOnAir"]),
    ],
    targets: [
//        .binaryTarget(
//            name: "BrivoFluid",
//            url: "https://github.com/brivo-mobile-team/brivo-mobile-frameworks/raw/main/BrivoFluid.xcframework.zip",
//            checksum: "1ba7ea38735e19bcfbd38c2a416319f968b29e7e32bda2ef5e1f6c6df4a7d534"
//        ),
        .binaryTarget(
            name: "BrivoAccess",
            url: "https://github.com/brivo-mobile-team/brivo-mobile-frameworks/raw/main/BrivoAccess.xcframework.zip",
            checksum: "13db7c5be38317b7ebfcd6edaad5aef6904c0faaa785d5cdf94cdccb03024d37"
        ),
        .binaryTarget(
            name: "BrivoBLE",
            url: "https://github.com/brivo-mobile-team/brivo-mobile-frameworks/raw/main/BrivoBLE.xcframework.zip",
            checksum: "fe3db2a2bf5bf829f1bdccb9eff98ccae003fbbdf66f332e821ef96e030efd4d"
        ),
        .binaryTarget(
            name: "BrivoCore",
            url: "https://github.com/brivo-mobile-team/brivo-mobile-frameworks/raw/main/BrivoCore.xcframework.zip",
            checksum: "d5ca1010bffa38ff21703c979580c4269e411567d69f2a30ccd72657a588dc41"
        ),
        .binaryTarget(
            name: "BrivoLocalAuthentication",
            url: "https://github.com/brivo-mobile-team/brivo-mobile-frameworks/raw/main/BrivoLocalAuthentication.xcframework.zip",
            checksum: "65a05b897a3ad75c4c1941ad5e21a2d1cf925dca146e96f9c27f22ad4a2188a1"
        ),
        .binaryTarget(
            name: "BrivoOnAir",
            url: "https://github.com/brivo-mobile-team/brivo-mobile-frameworks/raw/main/BrivoOnAir.xcframework.zip",
            checksum: "fc1caca45c11a7c266396307989aa1dc58934006e023eb31ced547f5bffb23f5"
        ),
        .binaryTarget(
            name: "BrivoNetworkCore",
            url: "https://github.com/brivo-mobile-team/brivo-mobile-frameworks/raw/main/BrivoNetworkCore.xcframework.zip",
            checksum: "c86f5947b3b39ebef203440b78b1563a73e6a0a0ade37c25fdb90a92d06ef9e6"
        ),
    ]
)
