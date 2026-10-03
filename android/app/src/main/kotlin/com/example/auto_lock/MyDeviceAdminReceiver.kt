package com.example.auto_lock

import android.app.admin.DeviceAdminReceiver
import android.content.Intent
import android.util.Log

class MyDeviceAdminReceiver : DeviceAdminReceiver() {

    companion object {
        private const val TAG = "MyDeviceAdminReceiver"
    }

    override fun onEnabled(context: android.content.Context, intent: Intent) {
        super.onEnabled(context, intent)
        Log.d(TAG, "onEnabled: Device admin has been ENABLED")
    }

    override fun onDisabled(context: android.content.Context, intent: Intent) {
        super.onDisabled(context, intent)
        Log.d(TAG, "onDisabled: Device admin has been DISABLED")
    }

    override fun onReceive(context: android.content.Context, intent: Intent) {
        super.onReceive(context, intent)
        Log.d(TAG, "onReceive: ${intent.action}")
    }
}
