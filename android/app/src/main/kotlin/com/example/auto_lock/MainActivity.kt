package com.example.auto_lock

import android.app.Activity
import android.content.Intent
import android.os.Bundle
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.plugins.FlutterPlugin
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
                        val success = devicePolicyHelper?.lockScreenAllowBiometric() ?: false
                        result.success(success)
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
