package com.example.auto_lock

import android.app.Activity
import android.content.ComponentName
import android.content.Intent
import android.os.Bundle
import android.provider.Settings
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    companion object {
        private const val TAG = "MainActivity"
        private const val CHANNEL_NAME = "com.example.auto_lock/device_policy"
        private const val REQUEST_CODE_DEVICE_ADMIN = 1001
    }

    private var devicePolicyHelper: DevicePolicyHelper? = null
    private var methodChannel: MethodChannel? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        devicePolicyHelper = DevicePolicyHelper(this)

        // Register method channel
        val binaryMessenger = flutterEngine?.dartExecutor?.binaryMessenger
        if (binaryMessenger != null) {
            methodChannel = MethodChannel(binaryMessenger, CHANNEL_NAME)
            methodChannel?.setMethodCallHandler { call, result ->
                when (call.method) {
                    "isDeviceAdminActive" -> {
                        result.success(devicePolicyHelper?.isDeviceAdminActive() ?: false)
                    }
                    "isDeviceOwner" -> {
                        result.success(devicePolicyHelper?.isDeviceOwner() ?: false)
                    }
                    "lockNow" -> {
                        // DEPRECATED: kept for backward compat, but we now use accessibility
                        Log.w(TAG, "lockNow() called but app should use lockViaAccessibility()")
                        val success = devicePolicyHelper?.lockScreenAllowBiometric() ?: false
                        result.success(success)
                    }
                    "lockViaAccessibility" -> {
                        val success = tryLockViaAccessibility()
                        result.success(success)
                    }
                    "isAccessibilityServiceEnabled" -> {
                        val enabled = isAccessibilityServiceEnabled()
                        result.success(enabled)
                    }
                    "openAccessibilitySettings" -> {
                        openAccessibilitySettings()
                        result.success(null)
                    }
                    "removeActiveAdmin" -> {
                        devicePolicyHelper?.removeActiveAdmin()
                        result.success(null)
                    }
                    else -> {
                        result.notImplemented()
                    }
                }
            }
        }
    }

    /**
     * Lock screen via AccessibilityService GLOBAL_ACTION_LOCK_SCREEN.
     * This mimics a natural power-button press, preserving biometric auth.
     */
    private fun tryLockViaAccessibility(): Boolean {
        val service = ScreenLockAccessibilityService.instance
        if (service != null) {
            service.triggerScreenLock()
            return true
        } else {
            Log.w(TAG, "ScreenLockAccessibilityService instance is null – service likely not enabled")
            return false
        }
    }

    /**
     * Check whether the accessibility service is enabled and bound for this app.
     */
    private fun isAccessibilityServiceEnabled(): Boolean {
        val serviceComponent = ComponentName(this, ScreenLockAccessibilityService::class.java)
        val enabledServices = Settings.Secure.getString(
            contentResolver,
            Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
        ) ?: return false

        // Services are colon-separated in the format package/service
        val colonSeparated = enabledServices.split(":")
        return colonSeparated.any {
            it.trim() == "$packageName/${ScreenLockAccessibilityService::class.java.name}"
        }
    }

    /**
     * Open system Accessibility settings so the user can enable our service.
     */
    private fun openAccessibilitySettings() {
        val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        startActivity(intent)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == REQUEST_CODE_DEVICE_ADMIN) {
            Log.d(TAG, "Device admin permission result: $resultCode")
        }
    }

    override fun onResume() {
        super.onResume()
        Log.d(TAG, "MainActivity onResume")
    }
}
