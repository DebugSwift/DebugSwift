#!/bin/bash

# DebugSwift XCFramework Build Script (Swift Package Manager)
# This script builds DebugSwift as an XCFramework using Swift Package Manager

set -e

# Configuration
FRAMEWORK_NAME="DebugSwift"
BUILD_DIR="$(pwd)/build"
XCFRAMEWORK_DIR="$(pwd)/XCFramework"
TEMP_DIR="/tmp/debugswift_build"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to clean up previous builds
cleanup() {
    print_status "Cleaning up previous builds..."
    rm -rf "$BUILD_DIR"
    rm -rf "$XCFRAMEWORK_DIR"
    rm -rf "$TEMP_DIR"
}

# Function to create directories
create_directories() {
    print_status "Creating build directories..."
    mkdir -p "$BUILD_DIR"
    mkdir -p "$XCFRAMEWORK_DIR"
    mkdir -p "$TEMP_DIR"
}

# Function to create a temporary Xcode project for building frameworks
create_temp_xcode_project() {
    print_status "Creating temporary Xcode project for framework building..."
    
    cd "$TEMP_DIR"
    
    # Create a simple iOS framework project
    cat > Package.swift << 'EOF'
// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "DebugSwiftFramework",
    platforms: [
        .iOS(.v14)
    ],
    products: [
        .library(
            name: "DebugSwift",
            targets: ["DebugSwift"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "DebugSwift",
            path: "../DebugSwift"
        )
    ]
)
EOF

    # Generate Xcode project
    swift package generate-xcodeproj
    
    cd - > /dev/null
    print_success "Temporary Xcode project created"
}

# Function to build framework for specific platform
build_framework_for_platform() {
    local platform=$1
    local destination=$2
    local sdk=$3
    local arch_suffix=$4
    
    print_status "Building framework for $platform ($arch_suffix)..."
    
    cd "$TEMP_DIR"
    
    local output_path="$BUILD_DIR/$platform-$arch_suffix"
    mkdir -p "$output_path"
    
    # Build the framework using xcodebuild
    xcodebuild -project DebugSwiftFramework.xcodeproj \
               -scheme DebugSwift-Package \
               -destination "$destination" \
               -configuration Release \
               -sdk "$sdk" \
               BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
               SKIP_INSTALL=NO \
               CONFIGURATION_BUILD_DIR="$output_path" \
               clean build
    
    if [[ $? -ne 0 ]]; then
        print_error "Failed to build framework for $platform"
        exit 1
    fi
    
    cd - > /dev/null
    print_success "Framework built for $platform"
}

# Function to create XCFramework
create_xcframework() {
    print_status "Creating XCFramework..."
    
    local ios_device_path="$BUILD_DIR/iOS-device/DebugSwift.framework"
    local ios_simulator_path="$BUILD_DIR/iOS-simulator/DebugSwift.framework"
    
    # Verify frameworks exist
    if [[ ! -d "$ios_device_path" ]]; then
        print_error "iOS device framework not found at $ios_device_path"
        
        # Try to find it in subdirectories
        local found_device=$(find "$BUILD_DIR" -name "DebugSwift.framework" -path "*device*" | head -1)
        if [[ -n "$found_device" ]]; then
            print_status "Found device framework at: $found_device"
            ios_device_path="$found_device"
        else
            print_error "Could not locate iOS device framework"
            exit 1
        fi
    fi
    
    if [[ ! -d "$ios_simulator_path" ]]; then
        print_error "iOS simulator framework not found at $ios_simulator_path"
        
        # Try to find it in subdirectories
        local found_simulator=$(find "$BUILD_DIR" -name "DebugSwift.framework" -path "*simulator*" | head -1)
        if [[ -n "$found_simulator" ]]; then
            print_status "Found simulator framework at: $found_simulator"
            ios_simulator_path="$found_simulator"
        else
            print_error "Could not locate iOS simulator framework"
            exit 1
        fi
    fi
    
    # Create the XCFramework
    xcodebuild -create-xcframework \
               -framework "$ios_device_path" \
               -framework "$ios_simulator_path" \
               -output "$XCFRAMEWORK_DIR/$FRAMEWORK_NAME.xcframework"
    
    if [[ $? -ne 0 ]]; then
        print_error "Failed to create XCFramework"
        exit 1
    fi
    
    print_success "XCFramework created successfully"
}

# Function to create universal simulator framework
create_universal_simulator_framework() {
    print_status "Creating universal simulator framework..."
    
    # Build for both simulator architectures
    cd "$TEMP_DIR"
    
    # Build for x86_64 simulator
    print_status "Building for x86_64 simulator..."
    xcodebuild -project DebugSwiftFramework.xcodeproj \
               -scheme DebugSwift-Package \
               -destination "generic/platform=iOS Simulator" \
               -configuration Release \
               -sdk iphonesimulator \
               ARCHS="x86_64" \
               VALID_ARCHS="x86_64" \
               BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
               SKIP_INSTALL=NO \
               CONFIGURATION_BUILD_DIR="$BUILD_DIR/x86_64-simulator" \
               clean build
    
    # Build for arm64 simulator
    print_status "Building for arm64 simulator..."
    xcodebuild -project DebugSwiftFramework.xcodeproj \
               -scheme DebugSwift-Package \
               -destination "generic/platform=iOS Simulator" \
               -configuration Release \
               -sdk iphonesimulator \
               ARCHS="arm64" \
               VALID_ARCHS="arm64" \
               BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
               SKIP_INSTALL=NO \
               CONFIGURATION_BUILD_DIR="$BUILD_DIR/arm64-simulator" \
               clean build
    
    cd - > /dev/null
    
    # Create universal framework
    local x86_64_framework="$BUILD_DIR/x86_64-simulator/DebugSwift.framework"
    local arm64_framework="$BUILD_DIR/arm64-simulator/DebugSwift.framework"
    local universal_framework="$BUILD_DIR/iOS-simulator/DebugSwift.framework"
    
    # Find the actual framework locations
    local found_x86_64=$(find "$BUILD_DIR" -name "DebugSwift.framework" -path "*x86_64*" | head -1)
    local found_arm64=$(find "$BUILD_DIR" -name "DebugSwift.framework" -path "*arm64*simulator*" | head -1)
    
    if [[ -n "$found_x86_64" ]]; then
        x86_64_framework="$found_x86_64"
    fi
    
    if [[ -n "$found_arm64" ]]; then
        arm64_framework="$found_arm64"
    fi
    
    print_status "x86_64 framework: $x86_64_framework"
    print_status "arm64 framework: $arm64_framework"
    
    if [[ -d "$x86_64_framework" && -d "$arm64_framework" ]]; then
        mkdir -p "$BUILD_DIR/iOS-simulator"
        cp -R "$arm64_framework" "$universal_framework"
        
        # Create universal binary
        lipo -create \
             "$x86_64_framework/DebugSwift" \
             "$arm64_framework/DebugSwift" \
             -output "$universal_framework/DebugSwift"
        
        print_success "Universal simulator framework created"
    else
        print_error "Could not find both simulator frameworks"
        print_status "Available frameworks:"
        find "$BUILD_DIR" -name "DebugSwift.framework" -type d
        exit 1
    fi
}

# Function to validate XCFramework
validate_xcframework() {
    print_status "Validating XCFramework..."
    
    local xcframework_path="$XCFRAMEWORK_DIR/$FRAMEWORK_NAME.xcframework"
    
    if [[ ! -d "$xcframework_path" ]]; then
        print_error "XCFramework not found"
        exit 1
    fi
    
    print_status "XCFramework contents:"
    find "$xcframework_path" -name "*.framework" | while read framework; do
        echo "  Framework: $(basename "$framework")"
        if [[ -f "$framework/$FRAMEWORK_NAME" ]]; then
            echo "    Architectures: $(lipo -archs "$framework/$FRAMEWORK_NAME" 2>/dev/null || echo "Unknown")"
        fi
    done
    
    print_success "XCFramework validation completed"
}

# Main execution
main() {
    print_status "Starting DebugSwift XCFramework build (SPM version)..."
    
    # Check if we're in the right directory
    if [[ ! -f "Package.swift" ]]; then
        print_error "Package.swift not found. Please run this script from the project root directory."
        exit 1
    fi
    
    cleanup
    create_directories
    create_temp_xcode_project
    
    # Build for iOS Device (arm64)
    build_framework_for_platform "iOS Device" "generic/platform=iOS" "iphoneos" "device"
    
    # Create universal simulator framework
    create_universal_simulator_framework
    
    create_xcframework
    validate_xcframework
    
    # Create ZIP archive
    cd "$XCFRAMEWORK_DIR"
    zip -r "${FRAMEWORK_NAME}.xcframework.zip" "${FRAMEWORK_NAME}.xcframework"
    cd - > /dev/null
    
    print_success "Build completed successfully!"
    print_status "XCFramework: $XCFRAMEWORK_DIR/$FRAMEWORK_NAME.xcframework"
    print_status "ZIP archive: $XCFRAMEWORK_DIR/$FRAMEWORK_NAME.xcframework.zip"
    
    # Cleanup temp directory
    rm -rf "$TEMP_DIR"
}

# Execute main function
main "$@"
