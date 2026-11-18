package com.persona5.videodownloader

import android.annotation.SuppressLint
import android.app.DownloadManager
import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Environment
import android.provider.MediaStore
import android.webkit.JavascriptInterface
import android.webkit.WebView
import android.webkit.WebViewClient
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import com.chaquo.python.Python
import com.chaquo.python.android.AndroidPlatform
import org.json.JSONObject
import java.io.File

interface DownloadCallback {
    fun onProgress(percent: Double, speed: String, eta: String, status: String)
    fun onComplete(success: Boolean, message: String)
}

class MainActivity : AppCompatActivity() {

    private lateinit var webView: WebView

    @SuppressLint("SetJavaScriptEnabled")
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Inicializar Python embebido local
        if (!Python.isStarted()) {
            Python.start(AndroidPlatform(this))
        }

        // Permisos de almacenamiento para Android 9 o inferior si fuera necesario
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && Build.VERSION.SDK_INT <= Build.VERSION_CODES.Q) {
            if (checkSelfPermission(android.Manifest.permission.WRITE_EXTERNAL_STORAGE) != android.content.pm.PackageManager.PERMISSION_GRANTED) {
                requestPermissions(arrayOf(android.Manifest.permission.WRITE_EXTERNAL_STORAGE), 100)
            }
        }

        webView = WebView(this)
        setContentView(webView)

        webView.settings.apply {
            javaScriptEnabled = true
            domStorageEnabled = true
            allowFileAccess = true
            allowContentAccess = true
            mediaPlaybackRequiresUserGesture = false
        }

        webView.webViewClient = object : WebViewClient() {
            override fun onPageFinished(view: WebView?, url: String?) {
                super.onPageFinished(view, url)
                // Si la app se abrió compartiendo un video desde YouTube/TikTok
                handleSharedIntent(intent)
            }
        }

        webView.addJavascriptInterface(AndroidBridge(this, webView), "AndroidBridge")
        webView.loadUrl("file:///android_asset/index.html")
    }

    override fun onNewIntent(intent: Intent?) {
        super.onNewIntent(intent)
        intent?.let { handleSharedIntent(it) }
    }

    private fun handleSharedIntent(intent: Intent) {
        if (intent.action == Intent.ACTION_SEND && intent.type == "text/plain") {
            val sharedText = intent.getStringExtra(Intent.EXTRA_TEXT) ?: return
            val url = extractUrl(sharedText)
            webView.post {
                val script = "if (window.setSharedUrl) { window.setSharedUrl(${JSONObject.quote(url)}); }"
                webView.evaluateJavascript(script, null)
            }
        }
    }

    private fun extractUrl(text: String): String {
        val parts = text.split("\\s+".toRegex())
        for (part in parts) {
            if (part.startsWith("http://") || part.startsWith("https://")) {
                return part
            }
        }
        return text
    }

    inner class AndroidBridge(private val activity: MainActivity, private val webView: WebView) {

        @JavascriptInterface
        fun download(optsJson: String) {
            try {
                val opts = JSONObject(optsJson)
                val url = opts.getString("url")
                val mode = opts.optString("mode", "allout")
                val threads = opts.optInt("threads", 8)
                val playlist = opts.optBoolean("playlist", false)

                // Directorio interno seguro de la app donde Python tiene 100% permisos POSIX sin restricciones
                val stagingDir = File(activity.getExternalFilesDir(Environment.DIRECTORY_DOWNLOADS) ?: activity.filesDir, "Staging")
                if (!stagingDir.exists()) {
                    stagingDir.mkdirs()
                }

                Thread {
                    val py = Python.getInstance()
                    val module = py.getModule("downloader")

                    val callback = object : DownloadCallback {
                        override fun onProgress(percent: Double, speed: String, eta: String, status: String) {
                            activity.runOnUiThread {
                                val script = "if (window.updateAndroidProgress) { window.updateAndroidProgress($percent, ${JSONObject.quote(speed)}, ${JSONObject.quote(eta)}, ${JSONObject.quote(status)}); }"
                                webView.evaluateJavascript(script, null)
                            }
                        }

                        override fun onComplete(success: Boolean, message: String) {
                            activity.runOnUiThread {
                                if (success) {
                                    // Exportar los archivos descargados a la carpeta pública Descargas/Persona5_Descargas
                                    val exportedCount = this@MainActivity.exportFilesToPublicDownloads(stagingDir)
                                    val finalMsg = if (exportedCount > 0) {
                                        "¡Video guardado con éxito en tu carpeta Descargas / Persona5_Descargas!"
                                    } else {
                                        message
                                    }
                                    webView.evaluateJavascript("if (window.onAndroidComplete) { window.onAndroidComplete(true, ${JSONObject.quote(finalMsg)}); }", null)
                                } else {
                                    webView.evaluateJavascript("if (window.onAndroidComplete) { window.onAndroidComplete(false, ${JSONObject.quote(message)}); }", null)
                                }
                            }
                        }
                    }

                    module.callAttr("run_download", url, mode, threads, stagingDir.absolutePath, playlist, callback)
                }.start()

            } catch (e: Exception) {
                activity.runOnUiThread {
                    Toast.makeText(activity, "Error: " + e.message, Toast.LENGTH_LONG).show()
                }
            }
        }

        @JavascriptInterface
        fun openFolder() {
            try {
                val intent = Intent(DownloadManager.ACTION_VIEW_DOWNLOADS)
                activity.startActivity(intent)
            } catch (e: Exception) {
                activity.runOnUiThread {
                    Toast.makeText(activity, "Archivos guardados en Descargas/Persona5_Descargas", Toast.LENGTH_LONG).show()
                }
            }
        }

        @JavascriptInterface
        fun isNativeAndroid(): Boolean {
            return true
        }

        @JavascriptInterface
        fun showToast(msg: String) {
            activity.runOnUiThread {
                Toast.makeText(activity, msg, Toast.LENGTH_SHORT).show()
            }
        }
    }

    fun exportFilesToPublicDownloads(sourceDir: File): Int {
        val files = sourceDir.listFiles() ?: return 0
        var count = 0
        for (file in files) {
            if (file.isFile && file.length() > 0) {
                val ok = saveToPublicDownloads(this, file)
                if (ok) {
                    file.delete()
                    count++
                }
            }
        }
        return count
    }

    fun saveToPublicDownloads(context: Context, sourceFile: File): Boolean {
        val fileName = sourceFile.name
        val resolver = context.contentResolver
        val mimeType = when {
            fileName.endsWith(".mp4", ignoreCase = true) -> "video/mp4"
            fileName.endsWith(".mkv", ignoreCase = true) -> "video/x-matroska"
            fileName.endsWith(".mp3", ignoreCase = true) -> "audio/mpeg"
            fileName.endsWith(".m4a", ignoreCase = true) -> "audio/mp4"
            fileName.endsWith(".webm", ignoreCase = true) -> "video/webm"
            else -> "video/*"
        }

        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                val contentValues = ContentValues().apply {
                    put(MediaStore.MediaColumns.DISPLAY_NAME, fileName)
                    put(MediaStore.MediaColumns.MIME_TYPE, mimeType)
                    put(MediaStore.MediaColumns.RELATIVE_PATH, Environment.DIRECTORY_DOWNLOADS + "/Persona5_Descargas")
                    put(MediaStore.MediaColumns.IS_PENDING, 1)
                }
                val uri = resolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, contentValues)
                if (uri != null) {
                    resolver.openOutputStream(uri)?.use { out ->
                        sourceFile.inputStream().use { input ->
                            input.copyTo(out)
                        }
                    }
                    contentValues.clear()
                    contentValues.put(MediaStore.MediaColumns.IS_PENDING, 0)
                    resolver.update(uri, contentValues, null, null)
                    true
                } else {
                    false
                }
            } else {
                val downloadsDir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
                val p5Folder = File(downloadsDir, "Persona5_Descargas")
                if (!p5Folder.exists()) p5Folder.mkdirs()
                val destFile = File(p5Folder, fileName)
                sourceFile.copyTo(destFile, overwrite = true)
                val mediaScanIntent = Intent(Intent.ACTION_MEDIA_SCANNER_SCAN_FILE)
                mediaScanIntent.data = Uri.fromFile(destFile)
                context.sendBroadcast(mediaScanIntent)
                true
            }
        } catch (e: Exception) {
            false
        }
    }
}
