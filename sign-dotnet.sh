#!/bin/bash
set -euo pipefail

# tracking issue: https://github.com/dotnet/runtime/issues/116545

# unset (to empty string) if using regular VS Code
insiders=""
# Find the extension directory
ext_path=$(find ~/.vscode$insiders/extensions -type d -name "ms-dotnettools.csharp-*-darwin-arm64" | sort -V | tail -n1)

# Extract version from the path
version=$(basename "$ext_path" | sed -E 's/ms-dotnettools\.csharp-([0-9]+\.[0-9]+\.[0-9]+)-darwin-arm64/\1/')

echo "Detected C# extension version: $version"

# Construct paths to the two files
vsdbg="$ext_path/.debugger/arm64/vsdbg"
vsdbg_ui="$ext_path/.debugger/arm64/vsdbg-ui"

# Check if files exist
if [[ ! -f "$vsdbg" ]]; then
  echo "Missing file: $vsdbg"
  exit 1
fi

if [[ ! -f "$vsdbg_ui" ]]; then
  echo "Missing file: $vsdbg_ui"
  exit 1
fi

# Function to run codesign and capture the result
codesign_file() {
  local file="$1"
  echo "Signing $file"
  result=$(codesign --force -s - "$file" 2>&1)
  if [[ $? -eq 0 ]]; then
    echo "Successfully signed $file"
  else
    echo "Error signing $file: $result"
  fi
}

# Run codesign on both files and print the results
codesign_file "$vsdbg"
codesign_file "$vsdbg_ui"

echo "Codesigning completed for version $version"
