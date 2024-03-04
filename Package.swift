// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "BrivoFluidFramework",
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "BrivoFluidFramework",
            targets: ["BrivoFluidFramework","BrivoAccess","BrivoNetworkCore","BrivoBLE","BrivoCore","BrivoLocalAuthentication","BrivoOnAir"]),
    ],
    targets: [
        .binaryTarget(
            name: "BrivoFluidFramework",
            url: "https://github.com/brivo-mobile-team/Test-Brivo-Framework/raw/main/BrivoFluid.xcframework.zip",
            checksum: "1ba7ea38735e19bcfbd38c2a416319f968b29e7e32bda2ef5e1f6c6df4a7d534"
        ),
        .binaryTarget(
            name: "BrivoAccess",
            url: "https://github.com/brivo-mobile-team/Test-Brivo-Framework/raw/main/BrivoAccess.xcframework.zip",
            checksum: "54f1ac33e44ece03fdb6c03f5636efdc98a46e2f953589ead4270eb123fe189c"
        ),
        .binaryTarget(
            name: "BrivoBLE",
            url: "https://github.com/brivo-mobile-team/Test-Brivo-Framework/raw/main/BrivoBLE.xcframework.zip",
            checksum: "ea34e34d8af5370631da23eb731e9490824acd8e463af979fe56e52134f68b94"
        ),
        .binaryTarget(
            name: "BrivoCore",
            url: "https://github.com/brivo-mobile-team/Test-Brivo-Framework/raw/main/BrivoCore.xcframework.zip",
            checksum: "e3d7b9879cc1ec5e960c51a988f87fc46e7038cdd55e99a389a5f8586d3cf982"
        ),
        .binaryTarget(
            name: "BrivoLocalAuthentication",
            url: "https://github.com/brivo-mobile-team/Test-Brivo-Framework/raw/main/BrivoLocalAuthentication.xcframework.zip",
            checksum: "3e38b46657fbc7f00a4478c57612242ab6bd68cdd290c1aa56683a9eb5119036"
        ),
        .binaryTarget(
            name: "BrivoOnAir",
            url: "https://github.com/brivo-mobile-team/Test-Brivo-Framework/raw/main/BrivoOnAir.xcframework.zip",
            checksum: "461f8563430787a7e9801a7be145b729249db250b3817178d9977e157c8e9c71"
        ),
        .binaryTarget(
            name: "BrivoNetworkCore",
            url: "https://github.com/brivo-mobile-team/Test-Brivo-Framework/raw/main/BrivoNetworkCore.xcframework.zip",
            checksum: "89df80180b846cfa598220a4e73f03d183c4333c10f5a16199305225e2b3177e"
        ),
    ]
)
