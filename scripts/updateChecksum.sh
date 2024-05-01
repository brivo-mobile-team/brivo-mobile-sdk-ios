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
rm -rf brivo-mobile-frameworks
git clone https://github.com/brivo-mobile-team/brivo-mobile-frameworks.git
cd brivo-mobile-frameworks
for FILE in *;
do unzip $FILE; done
find . -name \*.zip -delete
cd ..
# replace version information in package manifest
sed -E -i '' 's/let version = ".+"/let version = "'$NEW_VERSION\"/ Package.swift
