#!/bin/bash
# Switch between buggy and fixed versions of DebugSwift Example app

set -e

EXAMPLE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/Example"

show_usage() {
    echo "Usage: $0 [buggy|fixed|status]"
    echo ""
    echo "Commands:"
    echo "  buggy   - Switch to buggy version (enables console interception deadlock)"
    echo "  fixed   - Switch to fixed version (disables console interception)"
    echo "  status  - Show current version"
    echo ""
    echo "This script helps test the DebugSwift console interception deadlock bug"
}

show_status() {
    if [ -f "$EXAMPLE_DIR/ExampleAppBuggy.swift" ]; then
        echo "📊 Current version: FIXED (console interception disabled)"
        echo "   - ExampleApp.swift: Fixed version"
        echo "   - ExampleAppBuggy.swift: Original buggy version (backup)"
        echo ""
        echo "✅ Ready to test - should NOT freeze with deadlock test"
    else
        echo "📊 Current version: BUGGY (console interception enabled)"  
        echo "   - ExampleApp.swift: Original buggy version"
        echo "   - ExampleAppFixed.swift: Fixed version (available)"
        echo ""
        echo "⚠️  Ready to reproduce deadlock - WILL freeze with deadlock test"
    fi
}

switch_to_buggy() {
    if [ ! -f "$EXAMPLE_DIR/ExampleAppBuggy.swift" ]; then
        echo "❌ Already using buggy version"
        return 1
    fi
    
    echo "🔄 Switching to buggy version..."
    
    # Move files around
    mv "$EXAMPLE_DIR/ExampleApp.swift" "$EXAMPLE_DIR/ExampleAppTemp.swift"
    mv "$EXAMPLE_DIR/ExampleAppBuggy.swift" "$EXAMPLE_DIR/ExampleApp.swift"  
    mv "$EXAMPLE_DIR/ExampleAppTemp.swift" "$EXAMPLE_DIR/ExampleAppFixed.swift"
    
    echo "⚠️  BUGGY VERSION ACTIVE"
    echo "   Console interception is ENABLED - will cause deadlock!"
    echo "   Use 'Start Deadlock Test' to reproduce the UI freeze"
}

switch_to_fixed() {
    if [ -f "$EXAMPLE_DIR/ExampleAppBuggy.swift" ]; then
        echo "✅ Already using fixed version"
        return 1
    fi
    
    echo "🔄 Switching to fixed version..."
    
    # Move files around
    mv "$EXAMPLE_DIR/ExampleApp.swift" "$EXAMPLE_DIR/ExampleAppBuggy.swift"
    mv "$EXAMPLE_DIR/ExampleAppFixed.swift" "$EXAMPLE_DIR/ExampleApp.swift"
    
    echo "✅ FIXED VERSION ACTIVE"
    echo "   Console interception is DISABLED - no deadlock!"
    echo "   Use 'Start Deadlock Test' to verify the fix works"
}

# Check if we're in the right directory
if [ ! -f "$EXAMPLE_DIR/ExampleApp.swift" ]; then
    echo "❌ Error: Could not find ExampleApp.swift in $EXAMPLE_DIR"
    echo "Make sure you're running this script from the DebugSwift root directory"
    exit 1
fi

case "${1:-status}" in
    "buggy")
        switch_to_buggy
        ;;
    "fixed") 
        switch_to_fixed
        ;;
    "status")
        show_status
        ;;
    *)
        show_usage
        exit 1
        ;;
esac 