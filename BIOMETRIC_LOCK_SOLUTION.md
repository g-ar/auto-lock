# Biometric Lock Screen Solution

## Problem
The app was using `DevicePolicyManager.lockNow()` which triggers a high-security lockdown that disables biometric authentication, forcing users to enter PIN/password every time.

## Solution
Switched to using `AccessibilityService` with `GLOBAL_ACTION_LOCK_SCREEN` which mimics the system's standard lock action and preserves biometric authentication.

## Changes Made

### 1. New File: `ScreenLockAccessibilityService.kt`
- Created an AccessibilityService that can trigger `GLOBAL_ACTION_LOCK_SCREEN`
- This is the key change - it uses the system's standard lock mechanism instead of device admin lockdown

### 2. Updated: `DevicePolicyHelper.kt`
- Modified `lockScreenAllowBiometric()` to use the AccessibilityService
- Added `getLockScreenInfo()` to check accessibility service status
- Falls back to DevicePolicyManager if accessibility is not available

### 3. Updated: `MainActivity.kt`
- Added method channel handler for `openAccessibilitySettings`
- Opens system accessibility settings when user needs to enable the service

### 4. Updated: `AndroidManifest.xml`
- Registered the ScreenLockAccessibilityService
- Added required permission and intent filter

### 5. New File: `accessibility_service_config.xml`
- Configuration for the accessibility service
- Specifies it can perform global actions

### 6. New File: `strings.xml`
- Added description for the accessibility service (required by Android)

### 7. Updated: `main.dart` (Flutter)
- Added "Enable Accessibility Service" button
- Updated UI to show accessibility status
- Added method to open accessibility settings

## User Flow

1. **First Time Setup:**
   - User opens app
   - Taps "Enable Accessibility Service"
   - System opens Accessibility settings
   - User enables "Auto Lock" accessibility service
   - User returns to app

2. **Normal Usage:**
   - Tap "Lock Screen (Preserve Biometrics)"
   - Screen locks using system standard lock
   - When user wakes phone, fingerprint/face unlock works normally

## Why This Works

- `DevicePolicyManager.lockNow()` = High-security lockdown (disables biometrics)
- `AccessibilityService.GLOBAL_ACTION_LOCK_SCREEN` = Standard system lock (preserves biometrics)

The accessibility service approach mimics what happens when you press the physical power button, which is what users expect.

## Testing

```bash
# Build
cd /home/gar/temp3/auto_lock
flutter build apk

# Install
adb install build/app/outputs/flutter-apk/app-release.apk

# Set as device owner (optional, for full functionality)
./setup_device_owner.sh

# Run the app and test
adb shell am start -n com.example.auto_lock/.MainActivity
```

## Notes

- Accessibility service must be manually enabled by user (Android security requirement)
- Works on Android 9+ (API 28+) for `GLOBAL_ACTION_LOCK_SCREEN`
- Falls back to DevicePolicyManager on older devices
- Device Owner status still recommended for best results
