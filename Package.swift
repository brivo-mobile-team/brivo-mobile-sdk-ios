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
            checksum: "741d9b437c1838061eb724b33af51e758d7ed000695a9362dfadd670dd0b72cd"
        ),
        .binaryTarget(
            name: "BrivoBLE",
            url: "https://github.com/brivo-mobile-team/brivo-mobile-frameworks/raw/main/BrivoBLE.xcframework.zip",
            checksum: "4589178b5ed0263733705df5530ae7b2412e2c1c70010b552959213fd743b107"
        ),
        .binaryTarget(
            name: "BrivoCore",
            url: "https://github.com/brivo-mobile-team/brivo-mobile-frameworks/raw/main/BrivoCore.xcframework.zip",
            checksum: "efcf6a688f39b55ae11983b2bd389d0dc1b8a7d7d3efd6c65d47d015087ba43c"
        ),
        .binaryTarget(
            name: "BrivoLocalAuthentication",
            url: "https://github.com/brivo-mobile-team/brivo-mobile-frameworks/raw/main/BrivoLocalAuthentication.xcframework.zip",
            checksum: "7fd55c9502352e0efdd5787cfcb412e1237054bc4befeb1b30f131c3ee464c07"
        ),
        .binaryTarget(
            name: "BrivoOnAir",
            url: "https://github.com/brivo-mobile-team/brivo-mobile-frameworks/raw/main/BrivoOnAir.xcframework.zip",
            checksum: "5fc3d1a971c3310f2aedddbae71597f7507b20d4f42a4374745dcd138c9a7e47"
        ),
        .binaryTarget(
            name: "BrivoNetworkCore",
            url: "https://github.com/brivo-mobile-team/brivo-mobile-frameworks/raw/main/BrivoNetworkCore.xcframework.zip",
            checksum: "993ce83adf77f48040c6bb202ba7c5b9890c51a452156cb61353568343e67b93"
        ),
    ]
)
