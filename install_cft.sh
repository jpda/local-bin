#!/bin/bash

# Configuration
INSTALL_DIR="$HOME/.local/apps/chrome"
PROFILE_DIR="$INSTALL_DIR/profiles"
PLATFORM="mac-arm64" # Change to 'mac-x64' if on Intel
JSON_URL="https://googlechromelabs.github.io/chrome-for-testing/last-known-good-versions-with-downloads.json"
VERSION_FILE="$INSTALL_DIR/version.txt"

# Ensure directories exist
mkdir -p "$INSTALL_DIR"
mkdir -p "$PROFILE_DIR"

echo "🔍 Checking for latest Stable version of Chrome for Testing..."
JSON_DATA=$(curl -s "$JSON_URL")
LATEST_VERSION=$(echo "$JSON_DATA" | jq -r '.channels.Stable.version')

DOWNLOAD_URL=$(echo "$JSON_DATA" | jq -r --arg PLATFORM "$PLATFORM" \
  '.channels.Stable.downloads.chrome[] | select(.platform == $PLATFORM) | .url')

if [[ -z "$LATEST_VERSION" || -z "$DOWNLOAD_URL" || "$DOWNLOAD_URL" == "null" ]]; then
    echo "❌ Error: Could not fetch version or URL. Check internet connection or JSON structure."
    exit 1
fi

CURRENT_VERSION=""
if [[ -f "$VERSION_FILE" ]]; then
    CURRENT_VERSION=$(cat "$VERSION_FILE")
fi

if [[ "$CURRENT_VERSION" == "$LATEST_VERSION" ]]; then
    echo "✅ You already have the latest version ($LATEST_VERSION)."
    exit 0
fi

echo "⬇️  New version found: $LATEST_VERSION (Current: ${CURRENT_VERSION:-None})"
echo "   Downloading from: $DOWNLOAD_URL"

TEMP_DIR=$(mktemp -d)

curl -L -o "$TEMP_DIR/chrome.zip" "$DOWNLOAD_URL"
unzip -q "$TEMP_DIR/chrome.zip" -d "$TEMP_DIR"

EXTRACTED_APP=$(find "$TEMP_DIR" -name "Google Chrome for Testing.app" | head -n 1)

if [[ -d "$EXTRACTED_APP" ]]; then
    echo "📦 Installing..."
    rm -rf "$INSTALL_DIR/Google Chrome for Testing.app"
    mv "$EXTRACTED_APP" "$INSTALL_DIR/"
    echo "$LATEST_VERSION" > "$VERSION_FILE"
    echo "🎉 Success! Installed to: $INSTALL_DIR/Google Chrome for Testing.app"
else
    echo "❌ Error: App bundle not found after extraction."
    rm -rf "$TEMP_DIR"
    exit 1
fi

rm -rf "$TEMP_DIR"
