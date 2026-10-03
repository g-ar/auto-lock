#!/bin/bash
# Setup script to make auto_lock the Device Owner via ADB
# Device Owner can call lockNow() on Android 10+

set -e

PACKAGE="com.example.auto_lock"
ACTIVITY="$PACKAGE/.MainActivity"

echo "=========================================="
echo "  Auto Lock - Device Owner Setup"
echo "=========================================="
echo ""

# Check if device is connected
echo "Checking ADB connection..."
if ! adb devices | grep -q "device$"; then
    echo "❌ ERROR: No Android device connected via ADB"
    echo "   Connect your device with USB debugging enabled"
    exit 1
fi

DEVICE=$(adb get-serialno)
echo "✓ Device connected: $DEVICE"
echo ""

# Check if app is installed
echo "Checking if app is installed..."
if ! adb shell pm list packages | grep -q "$PACKAGE"; then
    echo "❌ ERROR: App not installed"
    echo "   Run: flutter build apk && adb install build/app/outputs/flutter-apk/app-release.apk"
    exit 1
fi
echo "✓ App is installed"
echo ""

# Check current device owner
echo "Current device owner:"
adb shell dpm get-device-owner || echo "   (none)"
echo ""

# Set device owner
echo "Setting $PACKAGE as Device Owner..."
echo "This requires the device to be in a clean state (no existing device owner)"
echo ""

# Clear existing device owner if any
EXISTING_OWNER=$(adb shell dpm get-device-owner 2>/dev/null | tail -1)
if [ -n "$EXISTING_OWNER" ] && [ "$EXISTING_OWNER" != "null" ]; then
    echo "Clearing existing device owner: $EXISTING_OWNER"
    adb shell dpm clear-device-owner || {
        echo "❌ Failed to clear existing device owner"
        exit 1
    }
    echo "✓ Cleared"
    echo ""
fi

# Set the new device owner
echo "Setting device owner to: $PACKAGE/.MyDeviceAdminReceiver"
adb shell dpm set-device-owner $PACKAGE/.MyDeviceAdminReceiver

if [ $? -eq 0 ]; then
    echo ""
    echo "=========================================="
    echo "  ✓ Device Owner set successfully!"
    echo "=========================================="
    echo ""
    echo "Verify with: adb shell dpm get-device-owner"
    echo ""
    echo "Now when you press 'Grant Admin & Lock Screen',"
    echo "the screen will lock immediately."
    echo ""
    echo "To remove device owner later:"
    echo "  adb shell dpm clear-device-owner"
else
    echo ""
    echo "❌ Failed to set device owner"
    echo ""
    echo "Common issues:"
    echo "  1. Device already has a device owner:"
    echo "     Clear it first: adb shell dpm clear-device-owner"
    echo ""
    echo "  2. Not on user 0:"
    echo "     adb shell pm set-user 0"
    echo ""
    echo "  3. Device has restrictions:"
    echo "     Check with: adb shell dpm get-active-admins"
    exit 1
fi
