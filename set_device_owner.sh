#!/bin/bash
# Script to set auto_lock as Device Owner via ADB
# Run this after installing the app

echo "=== Auto Lock - Device Owner Setup ==="
echo ""

# Check if device is connected
if ! adb devices | grep -q "device$"; then
    echo "ERROR: No Android device connected via ADB"
    exit 1
fi

echo "Device connected: $(adb get-serialno)"
echo ""

# Package name
PACKAGE="com.example.auto_lock"
ACTIVITY="$PACKAGE/.MainActivity"

echo "Step 1: Creating device owner..."
echo "This will set $PACKAGE as the Device Owner"
echo ""

# Create device owner
# The --owner-name parameter is optional but recommended
adb shell dpm set-device-owner \
    $PACKAGE/.MyDeviceAdminReceiver

if [ $? -eq 0 ]; then
    echo ""
    echo "✓ Device owner set successfully!"
    echo ""
    echo "Your app is now a Device Owner."
    echo "When you press 'Grant Admin & Lock Screen', lockNow() will work immediately."
    echo ""
    echo "To verify:"
    echo "  adb shell dpm get-device-owner"
else
    echo ""
    echo "✗ Failed to set device owner"
    echo "Common issues:"
    echo "  1. App not installed: adb install auto_lock.apk"
    echo "  2. Not the same user profile:adb shell pm set-user 0"
    echo "  3. Already has device owner: need to clear first with:"
    echo "     adb shell dpm clear-device-owner"
    exit 1
fi
