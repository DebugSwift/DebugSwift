#!/bin/bash

# DebugSwift CocoaPods Validation Script
# This script validates the podspec file for common issues

echo "🔍 Validating DebugSwift.podspec..."

# Check if podspec file exists
if [ ! -f "DebugSwift.podspec" ]; then
    echo "❌ DebugSwift.podspec not found!"
    exit 1
fi

echo "✅ Podspec file found"

# Validate podspec syntax (requires CocoaPods to be installed)
if command -v pod &> /dev/null; then
    echo "🔍 Running pod spec lint..."
    
    # Basic syntax validation
    pod spec lint DebugSwift.podspec --quick --allow-warnings
    
    if [ $? -eq 0 ]; then
        echo "✅ Podspec validation passed!"
    else
        echo "❌ Podspec validation failed. Please check the errors above."
        exit 1
    fi
else
    echo "⚠️  CocoaPods not installed. Skipping pod spec lint."
    echo "   To install CocoaPods: sudo gem install cocoapods"
fi

# Check if required files exist
echo "🔍 Checking required files..."

required_files=(
    "LICENSE"
    "README.md"
    "DebugSwift/Sources"
    "DebugSwift/Resources"
)

for file in "${required_files[@]}"; do
    if [ -e "$file" ]; then
        echo "✅ $file exists"
    else
        echo "❌ $file is missing!"
        exit 1
    fi
done

# Check source file structure
echo "🔍 Checking source file structure..."

source_dirs=(
    "DebugSwift/Sources/Settings"
    "DebugSwift/Sources/Base"
    "DebugSwift/Sources/Helpers"
    "DebugSwift/Sources/Features/Network"
    "DebugSwift/Sources/Features/Performance"
    "DebugSwift/Sources/Features/Interface"
    "DebugSwift/Sources/Features/App"
    "DebugSwift/Sources/Features/Resources"
)

for dir in "${source_dirs[@]}"; do
    if [ -d "$dir" ]; then
        echo "✅ $dir exists"
    else
        echo "❌ $dir is missing!"
        exit 1
    fi
done

echo ""
echo "🎉 All validation checks passed!"
echo ""
echo "📋 Next steps:"
echo "1. Create a git tag: git tag v1.0.0"
echo "2. Push the tag: git push origin v1.0.0"
echo "3. Submit to CocoaPods: pod trunk push DebugSwift.podspec"
echo ""
echo "📚 For more information:"
echo "   - CocoaPods Guides: https://guides.cocoapods.org/"
echo "   - Trunk Setup: pod trunk register your-email@example.com" 