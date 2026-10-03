package com.example.auto_lock

import android.accessibilityservice.AccessibilityService
import android.app.Activity
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import android.view.accessibility.AccessibilityEvent

class ScreenLockAccessibilityService : AccessibilityService() {

    companion object {
        private const val TAG = "ScreenLockAccessibility"
        
        @Volatile
        var instance: ScreenLockAccessibilityService? = null

        /** Store a reference to the main activity so we can minimize it before locking */
        @Volatile
        var mainActivity: Activity? = null
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
     * Minimize the app (send to background) so that after the screen locks,
     * unlocking won't immediately re-trigger the app's resume listener.
     */
    private fun minimizeApp() {
        val activity = mainActivity
        if (activity != null && !activity.isFinishing) {
            val intent = Intent(Intent.ACTION_MAIN).apply {
                addCategory(Intent.CATEGORY_HOME)
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            }
            try {
                applicationContext.startActivity(intent)
                Log.d(TAG, "App minimized to home screen")
            } catch (e: Exception) {
                Log.e(TAG, "Failed to minimize app", e)
            }
        } else {
            Log.w(TAG, "No main activity reference to minimize")
        }
    }

    /**
     * Trigger screen lock using GLOBAL_ACTION_LOCK_SCREEN
     * First minimizes the app so that unlocking doesn't immediately re-lock.
     * This preserves biometric authentication (unlike DevicePolicyManager.lockNow())
     */
    fun triggerScreenLock() {
        minimizeApp()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            performGlobalAction(GLOBAL_ACTION_LOCK_SCREEN)
            Log.d(TAG, "GLOBAL_ACTION_LOCK_SCREEN triggered")
        } else {
            Log.e(TAG, "GLOBAL_ACTION_LOCK_SCREEN requires Android 9 (API 28) or higher")
        }
    }
}
