package com.persona5.videodownloader

import android.annotation.SuppressLint
import android.app.DownloadManager
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Environment
import android.webkit.JavascriptInterface
import android.webkit.WebView
import android.webkit.WebViewClient
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import com.chaquo.python.PyObject
import com.chaquo.python.Python
import com.chaquo.python.android.AndroidPlatform
import org.json.JSONObject
import java.io.File

class MainActivity : AppCompatActivity() {

    private lateinit var webView: WebView

    @SuppressLint("SetJavaScriptEnabled")
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Inicializar Python embebido local
        if (!Python.isStarted()) {
            Python.start(AndroidPlatform(this))
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
            // Extraer URL si viene con texto adicional
            val url = extractUrl(sharedText)
            webView.post {
                webView.evaluateJavascript("if (window.setSharedUrl) { window.setSharedUrl('$url'); }", null)
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
                val threads = opts.optInt("threads", 16)

                // Carpeta pública de Descargas de Android
                val downloadsDir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
                val p5Folder = File(downloadsDir, "Persona5_Descargas")
                if (!p5Folder.exists()) {
                    p5Folder.mkdirs()
                }

                Thread {
                    val py = Python.getInstance()
                    val module = py.getModule("downloader")

                    val callback = object {
                        fun onProgress(percent: Double, speed: String, eta: String, status: String) {
                            activity.runOnUiThread {
                                val script = "if (window.updateAndroidProgress) { window.updateAndroidProgress($percent, '$speed', '$eta', '$status'); }"
                                webView.evaluateJavascript(script, null)
                            }
                        }

                        fun onComplete(success: Boolean, message: String) {
                            activity.runOnUiThread {
                                val escapedMsg = message.replace("'", "\\'")
                                val script = "if (window.onAndroidComplete) { window.onAndroidComplete($success, '$escapedMsg'); }"
                                webView.evaluateJavascript(script, null)
                            }
                        }
                    }

                    module.callAttr("run_download", url, mode, threads, p5Folder.absolutePath, callback)
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
                    Toast.makeText(activity, "Guardado en la carpeta Descargas", Toast.LENGTH_SHORT).show()
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
}
