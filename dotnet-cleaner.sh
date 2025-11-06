#!/bin/bash

# .NET Version Manager for macOS ARM64
# Usage: ./dotnet-cleaner.sh [options]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if dotnet CLI is available
check_dotnet_cli() {
    if ! command -v dotnet &> /dev/null; then
        echo -e "${RED}Error: dotnet CLI not found in PATH${NC}"
        echo "Please ensure .NET is installed and available in your PATH"
        exit 1
    fi
}

# Get all installed SDK versions with their paths
get_installed_sdks() {
    dotnet --list-sdks 2>/dev/null | while read -r line; do
        if [[ $line =~ ^([0-9]+\.[0-9]+\.[0-9]+[^[:space:]]*)[[:space:]]+\[(.+)\]$ ]]; then
            echo "${BASH_REMATCH[1]}|${BASH_REMATCH[2]}"
        fi
    done
}

# Get all installed runtimes with their paths
get_installed_runtimes() {
    dotnet --list-runtimes 2>/dev/null | while read -r line; do
        if [[ $line =~ ^([^[:space:]]+)[[:space:]]+([0-9]+\.[0-9]+\.[0-9]+[^[:space:]]*)[[:space:]]+\[(.+)\]$ ]]; then
            echo "${BASH_REMATCH[1]}|${BASH_REMATCH[2]}|${BASH_REMATCH[3]}"
        fi
    done
}

# Parse version into components
parse_version() {
    local version="$1"
    if [[ $version =~ ^([0-9]+)\.([0-9]+)\.([0-9]+) ]]; then
        echo "${BASH_REMATCH[1]}.${BASH_REMATCH[2]}.${BASH_REMATCH[3]}"
    else
        echo ""
    fi
}

# Get major version number
get_major_version() {
    local version="$1"
    if [[ $version =~ ^([0-9]+)\. ]]; then
        echo "${BASH_REMATCH[1]}"
    else
        echo ""
    fi
}

# Remove a specific SDK version
remove_sdk_version() {
    local target_version="$1"
    local removed=false
    
    echo -e "${BLUE}Looking for SDK version: $target_version${NC}"
    
    while IFS='|' read -r version path; do
        if [[ "$version" == "$target_version" ]]; then
            local full_path="$path/$version"
            if [[ -d "$full_path" ]]; then
                echo "  Removing SDK: $full_path"
                sudo rm -rf "$full_path"
                removed=true
            fi
        fi
    done <<< "$(get_installed_sdks)"
    
    return $([[ "$removed" == true ]] && echo 0 || echo 1)
}

# Remove a specific runtime version
remove_runtime_version() {
    local target_version="$1"
    local removed=false
    
    echo -e "${BLUE}Looking for runtime version: $target_version${NC}"
    
    while IFS='|' read -r runtime_name version path; do
        if [[ "$version" == "$target_version" ]]; then
            local full_path="$path/$version"
            if [[ -d "$full_path" ]]; then
                echo "  Removing runtime $runtime_name: $full_path"
                sudo rm -rf "$full_path"
                removed=true
            fi
        fi
    done <<< "$(get_installed_runtimes)"
    
    return $([[ "$removed" == true ]] && echo 0 || echo 1)
}

# Remove a specific version (both SDK and runtime)
remove_specific_version() {
    local target_version="$1"
    local sdk_removed=false
    local runtime_removed=false
    
    echo -e "${BLUE}Removing .NET version: $target_version${NC}"
    
    # Remove SDK
    if remove_sdk_version "$target_version"; then
        sdk_removed=true
    fi
    
    # Remove runtimes
    if remove_runtime_version "$target_version"; then
        runtime_removed=true
    fi
    
    if [[ "$sdk_removed" == true || "$runtime_removed" == true ]]; then
        echo -e "${GREEN}Successfully removed .NET $target_version${NC}"
    else
        echo -e "${YELLOW}Version $target_version not found${NC}"
    fi
}

# Remove all versions of a major number
remove_major_versions() {
    local target_major="$1"
    local versions_to_remove=()
    
    echo -e "${BLUE}Removing all .NET $target_major.x versions${NC}"
    
    # Collect SDK versions
    while IFS='|' read -r version path; do
        if [[ -n "$version" ]]; then
            local major=$(get_major_version "$version")
            if [[ "$major" == "$target_major" ]]; then
                versions_to_remove+=("$version")
            fi
        fi
    done <<< "$(get_installed_sdks)"
    
    # Collect runtime versions
    while IFS='|' read -r runtime_name version path; do
        if [[ -n "$version" ]]; then
            local major=$(get_major_version "$version")
            if [[ "$major" == "$target_major" ]]; then
                if [[ ! " ${versions_to_remove[*]} " =~ " $version " ]]; then
                    versions_to_remove+=("$version")
                fi
            fi
        fi
    done <<< "$(get_installed_runtimes)"
    
    if [[ ${#versions_to_remove[@]} -eq 0 ]]; then
        echo -e "${YELLOW}No versions found for major version $target_major${NC}"
        return
    fi
    
    # Sort and remove duplicates
    local unique_versions=($(printf '%s\n' "${versions_to_remove[@]}" | sort -u))
    
    for version in "${unique_versions[@]}"; do
        remove_specific_version "$version"
    done
}

# Keep only latest minor versions
keep_latest_minors() {
    echo -e "${BLUE}Keeping only the latest minor version for each major version${NC}"
    
    # Get all unique versions from both SDKs and runtimes
    local all_versions=()
    
    # Add SDK versions
    while IFS='|' read -r version path; do
        if [[ -n "$version" ]]; then
            all_versions+=("$version")
        fi
    done <<< "$(get_installed_sdks)"
    
    # Add runtime versions
    while IFS='|' read -r runtime_name version path; do
        if [[ -n "$version" ]]; then
            all_versions+=("$version")
        fi
    done <<< "$(get_installed_runtimes)"
    
    # Get unique versions and group by major
    local unique_versions=($(printf '%s\n' "${all_versions[@]}" | sort -u))
    local major_versions=()
    
    # Collect all major versions
    for version in "${unique_versions[@]}"; do
        local major=$(get_major_version "$version")
        if [[ -n "$major" ]] && [[ ! " ${major_versions[*]} " =~ " $major " ]]; then
            major_versions+=("$major")
        fi
    done
    
    # For each major version, find the latest and remove the rest
    for major in "${major_versions[@]}"; do
        local major_versions_list=()
        
        # Collect all versions for this major
        for version in "${unique_versions[@]}"; do
            local version_major=$(get_major_version "$version")
            if [[ "$version_major" == "$major" ]]; then
                major_versions_list+=("$version")
            fi
        done
        
        # Sort and get the latest
        local latest_version=$(printf '%s\n' "${major_versions_list[@]}" | sort -V | tail -n1)
        
        echo -e "${GREEN}Keeping latest version for $major.x: $latest_version${NC}"
        
        # Remove all others
        for version in "${major_versions_list[@]}"; do
            if [[ "$version" != "$latest_version" ]]; then
                echo -e "${YELLOW}Removing older version: $version${NC}"
                remove_specific_version "$version"
            fi
        done
    done
}

# List installed versions
list_versions() {
    echo -e "${BLUE}Installed .NET SDKs:${NC}"
    
    local sdk_found=false
    while IFS='|' read -r version path; do
        if [[ -n "$version" ]]; then
            local major=$(get_major_version "$version")
            echo -e "  ${GREEN}$version${NC} (major: $major) at $path"
            sdk_found=true
        fi
    done <<< "$(get_installed_sdks)"
    
    if [[ "$sdk_found" == false ]]; then
        echo -e "  ${YELLOW}No SDKs found${NC}"
    fi
    
    echo ""
    echo -e "${BLUE}Installed .NET Runtimes:${NC}"
    
    local runtime_found=false
    while IFS='|' read -r runtime_name version path; do
        if [[ -n "$version" ]]; then
            local major=$(get_major_version "$version")
            echo -e "  ${GREEN}$runtime_name $version${NC} (major: $major) at $path"
            runtime_found=true
        fi
    done <<< "$(get_installed_runtimes)"
    
    if [[ "$runtime_found" == false ]]; then
        echo -e "  ${YELLOW}No runtimes found${NC}"
    fi
}

# Show usage
show_usage() {
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  -l, --list                    List all installed .NET versions"
    echo "  -r, --remove VERSION         Remove specific version (e.g., 8.0.1)"
    echo "  -m, --major VERSION          Remove all versions of major number (e.g., 8)"
    echo "  -k, --keep-latest            Keep only latest minor for each major version"
    echo "  -h, --help                   Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 --list"
    echo "  $0 --remove 8.0.1"
    echo "  $0 --major 8"
    echo "  $0 --keep-latest"
}

# Main function
main() {
    # Check if dotnet CLI is available
    check_dotnet_cli
    
    # Parse command line arguments
    case "${1:-}" in
        -l|--list)
            list_versions
            ;;
        -r|--remove)
            if [[ -z "${2:-}" ]]; then
                echo -e "${RED}Error: Version number required${NC}"
                show_usage
                exit 1
            fi
            remove_specific_version "$2"
            ;;
        -m|--major)
            if [[ -z "${2:-}" ]]; then
                echo -e "${RED}Error: Major version number required${NC}"
                show_usage
                exit 1
            fi
            remove_major_versions "$2"
            ;;
        -k|--keep-latest)
            keep_latest_minors
            ;;
        -h|--help)
            show_usage
            ;;
        "")
            show_usage
            ;;
        *)
            echo -e "${RED}Error: Unknown option $1${NC}"
            show_usage
            exit 1
            ;;
    esac
}

# Check if running as root for certain operations
if [[ $EUID -eq 0 ]]; then
    echo -e "${YELLOW}Warning: Running as root${NC}"
fi

# Run main function
main "$@"

