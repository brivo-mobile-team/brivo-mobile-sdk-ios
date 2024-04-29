// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let version = "1.0.0"
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


//#!/bin/sh
//
//# Opiniated shell script to update version and checksum information for a binary target in a Swift Package
//# Script assumes that a Swift Package has
//# - a statement `let version = "<version>"`
//# - only 1 binary target
//
//# also the paths and naming pattern of the zip file is hard-coded so the shell script needs to be adjusted for other packages
//
//# Check for arguments
//if [ $# -eq 0 ]; then
//    echo "No arguments provided. First argument has to be version, e.g. '1.8.1'"
//    exit 1
//fi
//# assuming this script is executed from directory which contains Package.Swift
//# take version (e.g. 1.8.1) as argument
//NEW_VERSION=$1
//# download new zip file
//curl -L -O https://eidinger.info/PLCrashReporterXCFrameworks/$NEW_VERSION/CrashReporter.xcframework.zip --silent
//# calculate new checksum
//NEW_CHECKSUM=$(swift package compute-checksum CrashReporter.xcframework.zip)
//# print out new shasum for convenience reasons
//echo "New checksum is $NEW_CHECKSUM"
//# replace version information in package manifest
//sed -E -i '' 's/let version = ".+"/let version = "'$NEW_VERSION\"/ Package.swift
//# replace checksum information in package manifest
//sed -E -i '' 's/checksum: ".+"/checksum: "'$NEW_CHECKSUM\"/ Package.swift
//# print out package manifes for convenience reasons
//cat Package.swift
//# delete downloaded zip file
//rm CrashReporter.xcframework.zip
