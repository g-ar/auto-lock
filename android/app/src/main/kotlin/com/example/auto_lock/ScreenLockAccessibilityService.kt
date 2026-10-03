package com.example.auto_lock

import android.accessibilityservice.AccessibilityService
import android.os.Build
import android.util.Log
import android.view.accessibility.AccessibilityEvent

class ScreenLockAccessibilityService : AccessibilityService() {

    companion object {
        private const val TAG = "ScreenLockAccessibility"
        
        @Volatile
        var instance: ScreenLockAccessibilityService? = null
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        instance = this
        Log.d(TAG, "Accessibility service connected")
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        // Not needed for this service
    }

    override fun onInterrupt() {
        // Not needed
    }

    /**
     * Trigger screen lock using GLOBAL_ACTION_LOCK_SCREEN
     * This preserves biometric authentication (unlike DevicePolicyManager.lockNow())
     */
    fun triggerScreenLock() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            performGlobalAction(GLOBAL_ACTION_LOCK_SCREEN)
            Log.d(TAG, "GLOBAL_ACTION_LOCK_SCREEN triggered")
        } else {
            Log.e(TAG, "GLOBAL_ACTION_LOCK_SCREEN requires Android 9 (API 28) or higher")
        }
    }
}
