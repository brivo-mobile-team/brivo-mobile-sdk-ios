#!/bin/sh

# Opiniated shell script to update version and checksum information for a binary target in a Swift Package
# Script assumes that a Swift Package has
# - a statement `let version = "<version>"`
# - only 1 binary target

# also the paths and naming pattern of the zip file is hard-coded so shell script needs to be adjusted for other packages

# Check for arguments
if [ $# -eq 0 ]; then
    echo "No arguments provided. First argument has to be version, e.g. '1.0.0'"
    exit 1
fi
# assuming this script is executed from directory which contains Package.Swift
# take version (e.g. 1.0.0) as argument
NEW_VERSION=$1
# download new zip file
curl -L -O https://eidinger.info/PLCrashReporterXCFrameworks/$NEW_VERSION/CrashReporter.xcframework.zip --silent
# calculate new checksum
NEW_CHECKSUM=$(swift package compute-checksum CrashReporter.xcframework.zip)
# print out new shasum for convenience reasons
echo "New checksum is $NEW_CHECKSUM"
# replace version information in package manifest
sed -E -i '' 's/let version = ".+"/let version = "'$NEW_VERSION\"/ Package.swift
# replace checksum information in package manifest
sed -E -i '' 's/checksum: ".+"/checksum: "'$NEW_CHECKSUM\"/ Package.swift
# print out package manifes for convenience reasons
cat Package.swift
# delete downloaded zip file
rm CrashReporter.xcframework.zip
