#!/bin/bash
# iOS Simulator Validation Script for Ralph
# Usage: ./ios-simulator-validate.sh <scheme> <bundle_id> [device_name]

set -e

SCHEME="${1:-}"
BUNDLE_ID="${2:-}"
DEVICE="${3:-iPhone 17 Pro}"
SCREENSHOT_DIR="${4:-/tmp/ralph-screenshots}"

if [ -z "$SCHEME" ] || [ -z "$BUNDLE_ID" ]; then
    echo "Usage: $0 <scheme> <bundle_id> [device_name] [screenshot_dir]"
    echo "Example: $0 LocalPhotosApp com.ralph.LocalPhotosApp 'iPhone 17 Pro'"
    exit 1
fi

# Create screenshot directory
mkdir -p "$SCREENSHOT_DIR"

echo "=== iOS Simulator Validation ==="
echo "Scheme: $SCHEME"
echo "Bundle ID: $BUNDLE_ID"
echo "Device: $DEVICE"
echo ""

# Step 1: Check if simulator runtime is available
echo "[1/7] Checking simulator availability..."
if ! xcrun simctl list runtimes | grep -q "iOS"; then
    echo "ERROR: No iOS simulator runtime found."
    echo "Please install iOS Simulator from Xcode > Settings > Platforms"
    exit 1
fi
echo "OK - iOS runtime available"

# Step 2: Check if device exists, create if not
echo "[2/7] Checking device '$DEVICE'..."
if ! xcrun simctl list devices | grep -q "$DEVICE"; then
    echo "Device not found, checking available devices..."
    xcrun simctl list devices available | head -20
    echo ""
    echo "Using first available iOS device..."
    DEVICE=$(xcrun simctl list devices available | grep "iPhone" | head -1 | sed 's/.*(\([A-F0-9-]*\)).*/\1/')
    if [ -z "$DEVICE" ]; then
        echo "ERROR: No iOS devices available"
        exit 1
    fi
fi
echo "OK - Using device: $DEVICE"

# Step 3: Boot simulator if not booted
echo "[3/7] Booting simulator..."
BOOTED=$(xcrun simctl list devices | grep "(Booted)" | head -1)
if [ -z "$BOOTED" ]; then
    xcrun simctl boot "$DEVICE" 2>/dev/null || true
    sleep 5
fi
echo "OK - Simulator booted"

# Step 4: Build the app
echo "[4/7] Building app..."
BUILD_OUTPUT=$(xcodebuild -scheme "$SCHEME" \
    -destination "platform=iOS Simulator,name=$DEVICE" \
    -configuration Debug \
    build 2>&1)

if echo "$BUILD_OUTPUT" | grep -q "BUILD SUCCEEDED"; then
    echo "OK - Build succeeded"
else
    echo "ERROR: Build failed"
    echo "$BUILD_OUTPUT" | tail -30
    exit 1
fi

# Step 5: Find and install app
echo "[5/7] Installing app..."
APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData \
    -name "${SCHEME}.app" \
    -path "*/Debug-iphonesimulator/*" \
    -type d \
    2>/dev/null | head -1)

if [ -z "$APP_PATH" ]; then
    echo "ERROR: Could not find built app at DerivedData"
    exit 1
fi

xcrun simctl install booted "$APP_PATH"
echo "OK - App installed from $APP_PATH"

# Step 6: Launch app
echo "[6/7] Launching app..."
xcrun simctl launch booted "$BUNDLE_ID"
echo "OK - App launched"

# Wait for app to fully load
sleep 3

# Step 7: Capture screenshot
echo "[7/7] Capturing screenshot..."
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
SCREENSHOT_PATH="$SCREENSHOT_DIR/${SCHEME}_${TIMESTAMP}.png"
xcrun simctl io booted screenshot "$SCREENSHOT_PATH"
echo "OK - Screenshot saved to: $SCREENSHOT_PATH"

echo ""
echo "=== Validation Complete ==="
echo "Screenshot: $SCREENSHOT_PATH"
echo ""
echo "To analyze the screenshot, use:"
echo "  Read tool with path: $SCREENSHOT_PATH"
echo ""
echo "To take additional screenshots:"
echo "  xcrun simctl io booted screenshot /tmp/screenshot_name.png"
