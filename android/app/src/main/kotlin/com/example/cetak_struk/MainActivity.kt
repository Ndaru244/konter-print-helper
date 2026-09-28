package com.example.cetak_struk

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

class MainActivity : FlutterActivity() {
    private val CHANNEL = "app.share"
    private var pendingShareUri: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "getInitialShared") {
                    result.success(pendingShareUri)
                    pendingShareUri = null
                } else {
                    result.notImplemented()
                }
            }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent?) {
        if (intent == null) return
        if (intent.action == Intent.ACTION_SEND && intent.type?.startsWith("image/") == true) {
            val uri = intent.getParcelableExtra<Uri>(Intent.EXTRA_STREAM)
            uri?.let {
                val path = cacheFromUri(it)
                if (path.isNotEmpty()) {
                    pendingShareUri = path
                    
                    Handler(Looper.getMainLooper()).postDelayed({
                        flutterEngine?.dartExecutor?.binaryMessenger?.let { messenger ->
                            MethodChannel(messenger, CHANNEL).invokeMethod("onShare", path)
                        }
                    }, 800)
                }
            }
        }
    }

    private fun cacheFromUri(uri: Uri): String {
        return try {
            cacheDir.listFiles()?.forEach { if (it.name.startsWith("shared_")) it.delete() }
            val fileName = "shared_${System.currentTimeMillis()}.jpg"
            val dest = File(cacheDir, fileName)
            contentResolver.openInputStream(uri)?.use { input ->
                FileOutputStream(dest).use { output ->
                    input.copyTo(output)
                }
            }
            dest.absolutePath
        } catch (e: Exception) {
            ""
        }
    }
}
