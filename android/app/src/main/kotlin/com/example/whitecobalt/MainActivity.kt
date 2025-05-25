package com.example.whitecobalt

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.whitecobalt.share/url"
    private var sharedUrl: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Process and store share intent data when app is created or intent is received
        processIntent(intent)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getSharedUrl" -> {
                    result.success(sharedUrl)
                    // Clear the shared URL after it's been retrieved to prevent processing it again
                    sharedUrl = null
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        // Handle new intents (when app is already running)
        processIntent(intent)
    }

    private fun processIntent(intent: Intent) {
        val action = intent.action
        val type = intent.type
        
        if (Intent.ACTION_SEND == action && type?.startsWith("text/") == true) {
            sharedUrl = intent.getStringExtra(Intent.EXTRA_TEXT)
        }
    }
}
