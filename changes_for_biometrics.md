Yes, changes are required if you want users to be able to unlock the screen with their biometrics (fingerprint or face) instead of being forced to enter a passcode or PIN.
Why is this happening?
By default, when an app uses the Device Policy Manager (dpm.lockNow()) via a Device Administrator permission, the Android system treats this as a high-security lockdown event. Android's security architecture automatically disables biometrics after an administrator forces a lock, requiring the master PIN, pattern, or password to restore standard operations.
The Fix: Switch to AccessibilityService
To lock the screen like a physical power button press without breaking biometric unlocking, you must migrate your native Android code away from DevicePolicyManager and implement an AccessibilityService.
Accessibility services can execute the system-level global action GLOBAL_ACTION_LOCK_SCREEN, which mimics a natural lock timeout rather than a forced admin lockdown.
1. Create the Accessibility Service File
In your Android native code structure (android/app/src/main/java/your/package/), create a new service file:
java
package com.example.yourapp;

import android.accessibilityservice.AccessibilityService;
import android.view.accessibility.AccessibilityEvent;

public class ScreenLockService extends AccessibilityService {
    @Override
    public void onAccessibilityEvent(AccessibilityEvent event) {
        // Not needed for triggering actions
    }

    @Override
    public void onInterrupt() {
        // Not needed
    }

    // This method will be triggered via your method channel
    public void triggerScreenLock() {
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.P) {
            // GLOBAL_ACTION_LOCK_SCREEN requires Android 9 (API 28) or higher
            performGlobalAction(GLOBAL_ACTION_LOCK_SCREEN);
        }
    }
}
Use code with caution.
2. Declare the Service in AndroidManifest.xml
Add the service inside the <application> tag of your manifest:
xml
<service
    android:name=".ScreenLockService"
    android:permission="android.permission.BIND_ACCESSIBILITY_SERVICE"
    android:exported="true">
    <intent-filter>
        <action android:name="android.accessibilityservice.AccessibilityService" />
    </intent-filter>
    <meta-data
        android:name="android.accessibilityservice"
        android:resource="@xml/accessibility_service_config" />
</service>
Use code with caution.
3. Define the Configuration XML
Create a new file at android/app/src/main/res/xml/accessibility_service_config.xml:
xml
<accessibility-service xmlns:android="http://android.com"
    android:accessibilityFeedbackType="feedbackGeneric"
    android:accessibilityFlags="flagDefault"
    android:canPerformGestures="false"
    android:description="@string/accessibility_description" />
Use code with caution.
(Make sure to define a string named accessibility_description in your strings.xml explaining to the user why the app needs this control).
4. Update Flutter Channel Invocation
Call this service layer from your MainActivity file. When triggerScreenLock() runs via the framework, the screen will switch off gracefully, and biometrics will remain active when the user wakes up the phone.
⚠️ User Experience Note: Much like the Device Admin method, the user must manually navigate to Settings -> Accessibility on their device and toggle On your application's accessibility helper before this command will execute successfully.
Would you like the corresponding Kotlin/Java snippet for your MainActivity to handle the communication bridge, or do you need assistance generating the strings.xml resource description for the permissions page?
