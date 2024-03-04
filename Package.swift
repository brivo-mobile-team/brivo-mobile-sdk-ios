// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "BrivoFluidFramework",
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "BrivoFluidFramework",
            targets: ["BrivoFluidFramework"]),
    ],
    targets: [
        .binaryTarget(
            name: "BrivoFluidFramework",
            url: "https://github.com/brivo-mobile-team/Test-Brivo-Framework/raw/main/BrivoFluid.xcframework.zip",
            checksum: "1ba7ea38735e19bcfbd38c2a416319f968b29e7e32bda2ef5e1f6c6df4a7d534"
        )
    ]
)
