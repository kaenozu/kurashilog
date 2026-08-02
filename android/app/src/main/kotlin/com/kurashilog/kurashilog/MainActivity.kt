package com.kurashilog.kurashilog

import android.content.Intent
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

/**
 * くらしログ MainActivity。
 *
 * - SAF（ACTION_OPEN_DOCUMENT）による JSON 選択
 * - ACTION_SEND 共有受信（application/json）
 * - content:// URI の一時キャッシュへのコピー
 *
 * プライバシー方針（設計書 8）に従い、ネットワーク権限を宣言しない。
 * 元データは一時キャッシュへコピーし、Flutter 側で解析後に削除する。
 */
class MainActivity : FlutterActivity() {
    private companion object {
        const val CHANNEL = "kurashilog/platform"
        const val PICK_REQUEST = 1001
        const val SHARE_TAG = "kurashilog_share"
    }

    private var pendingSharedUris = mutableListOf<String>()
    private var pickResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "pickJsonFile" -> pickJsonFile(result)
                    "takeSharedFile" -> takeSharedFile(result)
                    "clearShared" -> {
                        pendingSharedUris.clear()
                        result.success(null)
                    }
                    "copyUriToCache" -> {
                        val uri = call.argument<String>("uri")
                        if (uri == null) {
                            result.error("INVALID", "uri is null", null)
                        } else {
                            copyToCache(Uri.parse(uri), result)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
        collectSharedIntent()
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        collectSharedIntent()
    }

    override fun onResume() {
        super.onResume()
        collectSharedIntent()
    }

    private fun collectSharedIntent() {
        val intent = intent ?: return
        val action = intent.action ?: return
        if (action != Intent.ACTION_SEND && action != Intent.ACTION_SEND_MULTIPLE) return

        val uris = mutableListOf<Uri>()
        if (action == Intent.ACTION_SEND) {
            intent.getParcelableExtra<Uri>(Intent.EXTRA_STREAM)?.let { uris.add(it) }
        } else {
            intent.getParcelableArrayListExtra<Uri>(Intent.EXTRA_STREAM)?.let { uris.addAll(it) }
        }
        if (uris.isEmpty()) {
            intent.clipData?.let { clip ->
                for (i in 0 until clip.itemCount) {
                    clip.getItemAt(i).uri?.let { uris.add(it) }
                }
            }
        }
        if (uris.isNotEmpty()) {
            pendingSharedUris.addAll(uris.map { it.toString() })
            intent.removeExtra(Intent.EXTRA_STREAM)
            intent.clipData = null
            intent.action = Intent.ACTION_MAIN
        }
    }

    private fun pickJsonFile(result: MethodChannel.Result) {
        pickResult = result
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = "application/json"
            putExtra(
                Intent.EXTRA_MIME_TYPES,
                arrayOf("application/json", "application/octet-stream", "text/*"),
            )
        }
        try {
            startActivityForResult(intent, PICK_REQUEST)
        } catch (e: Exception) {
            pickResult = null
            result.error("PICK_FAILED", e.message, null)
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != PICK_REQUEST) return
        val r = pickResult ?: return
        pickResult = null
        if (resultCode != RESULT_OK || data?.data == null) {
            r.success(null) // キャンセル
            return
        }
        copyToCache(data.data!!, r)
    }

    private fun takeSharedFile(result: MethodChannel.Result) {
        if (pendingSharedUris.isEmpty()) {
            result.success(null)
            return
        }
        val uri = pendingSharedUris.removeAt(0)
        copyToCache(Uri.parse(uri), result)
    }

    private fun copyToCache(uri: Uri, result: MethodChannel.Result) {
        try {
            val resolver = contentResolver
            val input = resolver.openInputStream(uri)
                ?: throw IllegalStateException("cannot open $uri")
            val fileName = "${SHARE_TAG}_${System.currentTimeMillis()}.json"
            val outFile = File(cacheDir, fileName)
            FileOutputStream(outFile).use { fos ->
                input.use { ins ->
                    ins.copyTo(fos)
                }
            }
            result.success(outFile.absolutePath)
        } catch (e: Exception) {
            result.error("IO_ERROR", e.message, null)
        }
    }
}
