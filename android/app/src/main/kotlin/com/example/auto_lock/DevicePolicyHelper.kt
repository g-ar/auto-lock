package com.example.auto_lock

import android.app.admin.DevicePolicyManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.util.Log

/**
 * Helper class to properly interact with Device Policy Manager
 * using the app's own DeviceAdminReceiver
 */
class DevicePolicyHelper(private val context: Context) {

    companion object {
        private const val TAG = "DevicePolicyHelper"
        private const val CHANNEL_NAME = "com.example.auto_lock/device_policy"
    }

    private val devicePolicyManager: DevicePolicyManager =
        context.getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager

    private val componentName = ComponentName(context, MyDeviceAdminReceiver::class.java)

    /**
     * Check if device admin is active for this app
     */
    fun isDeviceAdminActive(): Boolean {
        val isActive = devicePolicyManager.isAdminActive(componentName)
        Log.d(TAG, "isAdminActive: $isActive")
        return isActive
    }

    /**
     * Check if this app is the Device Owner
     */
    fun isDeviceOwner(): Boolean {
        val isOwner = devicePolicyManager.isDeviceOwnerApp(context.packageName)
        Log.d(TAG, "isDeviceOwner: $isOwner for package ${context.packageName}")
        return isOwner
    }

    /**
     * Request device admin permission
     */
    fun requestDeviceAdminPermission(activity: android.app.Activity, message: String) {
        val intent = Intent(DevicePolicyManager.ACTION_ADD_DEVICE_ADMIN).apply {
            putExtra(DevicePolicyManager.EXTRA_DEVICE_ADMIN, componentName)
            putExtra(DevicePolicyManager.EXTRA_ADD_EXPLANATION, message)
        }
        activity.startActivityForResult(intent, 1001)
    }

    /**
     * Lock the screen immediately
     * Returns true if successful, false if not device admin or not device owner
     */
    fun lockNow(): Boolean {
        if (!devicePolicyManager.isAdminActive(componentName)) {
            Log.e(TAG, "Cannot lock: device admin not active")
            return false
        }
        
        // lockNow() requires device admin, but on Android 10+ it also needs to be device owner
        try {
            devicePolicyManager.lockNow()
            Log.d(TAG, "lockNow() called successfully")
            return true
        } catch (e: SecurityException) {
            Log.e(TAG, "lockNow() failed: $e")
            return false
        } catch (e: Exception) {
            Log.e(TAG, "lockNow() error: $e")
            return false
        }
    }

    /**
     * Remove active admin
     */
    fun removeActiveAdmin() {
        devicePolicyManager.removeActiveAdmin(componentName)
    }
}
