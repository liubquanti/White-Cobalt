package liubquanti.white.cobalt

import android.content.Intent
import android.os.Bundle
import android.os.Environment
import android.os.StatFs
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.regex.Pattern

class MainActivity: FlutterActivity() {
    private val SHARE_CHANNEL = "com.whitecobalt.share/url"
    private val STORAGE_CHANNEL = "com.whitecobalt.storage/info"
    private val NATIVE_SHARE_CHANNEL = "com.whitecobalt.native_share"
    private var sharedUrl: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        processIntent(intent)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SHARE_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getSharedUrl" -> {
                    result.success(sharedUrl)
                    sharedUrl = null
                }
                else -> result.notImplemented()
            }
        }
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, STORAGE_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getStorageStats" -> {
                    val stats = getStorageStats()
                    result.success(stats)
                }
                else -> result.notImplemented()
            }
        }
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, NATIVE_SHARE_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "shareText" -> {
                    val text = call.argument<String>("text")
                    shareText(text ?: "")
                    result.success(null)
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
        
        val pattern = "https?://[-a-zA-Z0-9@:%._+~#=]{1,256}\\.[a-zA-Z0-9()]{1,6}\\b[-a-zA-Z0-9()@:%_+.~#?&//=]*"
        val matcher = Pattern.compile(pattern, Pattern.CASE_INSENSITIVE).matcher(text)
        
        return if (matcher.find()) {
            matcher.group()
        } else {
            null
        }
    }
    
    private fun shareText(text: String) {
        val sendIntent = Intent().apply {
            action = Intent.ACTION_SEND
            putExtra(Intent.EXTRA_TEXT, text)
            type = "text/plain"
        }

        val shareIntent = Intent.createChooser(sendIntent, "Share media link")
        shareIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        startActivity(shareIntent)
    }
    
    private fun getStorageStats(): Map<String, Long> {
        try {
            val path = Environment.getDataDirectory()
            val stat = StatFs(path.path)

            val blockSize = stat.blockSizeLong
            val totalBlocks = stat.blockCountLong
            val availableBlocks = stat.availableBlocksLong

            val total = totalBlocks * blockSize
            val free = availableBlocks * blockSize
            val used = total - free

            return mapOf(
                "total" to total,
                "free" to free,
                "used" to used
            )
        } catch (e: Exception) {
            e.printStackTrace()
            return mapOf(
                "total" to 0L,
                "free" to 0L,
                "used" to 0L
            )
        }
    }
}
