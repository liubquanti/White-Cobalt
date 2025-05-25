package com.example.whitecobalt

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.regex.Pattern

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.whitecobalt.share/url"
    private var sharedUrl: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        processIntent(intent)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getSharedUrl" -> {
                    result.success(sharedUrl)
                    sharedUrl = null
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        processIntent(intent)
    }

    private fun processIntent(intent: Intent) {
        val action = intent.action
        val type = intent.type
        
        if (Intent.ACTION_SEND == action && type?.startsWith("text/") == true) {
            val fullText = intent.getStringExtra(Intent.EXTRA_TEXT)
            sharedUrl = extractUrlFromText(fullText)
        }
    }

    private fun extractUrlFromText(text: String?): String? {
        if (text.isNullOrEmpty()) return null
        
        // Regex pattern to match URLs
        val pattern = "https?://[-a-zA-Z0-9@:%._+~#=]{1,256}\\.[a-zA-Z0-9()]{1,6}\\b[-a-zA-Z0-9()@:%_+.~#?&//=]*"
        val matcher = Pattern.compile(pattern, Pattern.CASE_INSENSITIVE).matcher(text)
        
        // Return the first URL found or null if none
        return if (matcher.find()) {
            matcher.group()
        } else {
            null
        }
    }
}
