#!/bin/bash
# To build, either place the IPA file in the project's root directory, or get the path to the IPA, then run `./build.sh`

set -e

error() { echo "❌ Error: $1"; exit 1; }

# Resolve IPA path
read -p $'\e[34m==> \e[1;39mPath to the decrypted YouTube.ipa or YouTube.app. If nothing is provided, any ipa/app in the project\'s root directory will be used: ' PATHTOYT

if [ -z "$PATHTOYT" ]; then
    IPAS=$(find . -maxdepth 1 -type f \( -name "*.ipa" -o -name "*.app" \))
    COUNT=$(echo "$IPAS" | grep -c .)

    if [ "$COUNT" -eq 0 ]; then
        error "No IPA/app file found in the project's root directory."
    elif [ "$COUNT" -gt 1 ]; then
        error "Multiple IPA/app files found in the project's root directory. Keep only one."
    fi

    PATHTOYT=$(echo "$IPAS" | head -1)
fi

[ -f "$PATHTOYT" ] || error "File not found: $PATHTOYT"
echo "Found IPA: $PATHTOYT"

# Prepare Payload
if [[ "$PATHTOYT" == *.ipa ]]; then
    mkdir -p tmp
    unzip -oq "$PATHTOYT" -d tmp
    APP_PATH="tmp/Payload/YouTube.app"
else
    APP_PATH="$PATHTOYT"
fi

[ -d "$APP_PATH" ] || error "Could not locate app bundle at $APP_PATH"

# Get YouTube version
youtube_version=$(defaults read "$(pwd)/$APP_PATH/Info" CFBundleVersion)

# Build
if make package SIDELOAD=1 THEOS_PACKAGE_SCHEME=rootless IPA="$APP_PATH" FINALPACKAGE=1 YOUTUBE_VERSION="$youtube_version"; then
    open packages
    echo "SHASUM256: $(shasum -a 256 packages/*.ipa)"
else
    error "Build failed"
fi

# Cleanup
rm -rf tmp