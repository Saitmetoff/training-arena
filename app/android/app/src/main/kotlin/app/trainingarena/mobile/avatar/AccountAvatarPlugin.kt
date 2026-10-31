package app.trainingarena.mobile.avatar

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.net.Uri
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry
import java.io.File
import java.io.FileOutputStream
import java.util.UUID

/**
 * Avatar document picker bridge for task 06.
 *
 * Opens the Android document picker (`ACTION_OPEN_DOCUMENT`) restricted to
 * JPEG/PNG/WebP and copies the chosen image into the app cache. It never
 * opens the camera, never requests a camera permission and never accepts
 * camera frames as avatar input. Files above the backend limit (2 MiB) are
 * rejected before they reach Dart.
 *
 * Channel: `app.trainingarena.mobile/avatar`
 *   `pickFromLibrary` -> `{"path": <cache file>}` or null when cancelled.
 */
class AccountAvatarPlugin :
    FlutterPlugin,
    ActivityAware,
    MethodChannel.MethodCallHandler,
    PluginRegistry.ActivityResultListener {

    private var context: Context? = null
    private var activity: Activity? = null
    private var activityBinding: ActivityPluginBinding? = null
    private var channel: MethodChannel? = null
    private var pendingResult: MethodChannel.Result? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, CHANNEL).apply {
            setMethodCallHandler(this@AccountAvatarPlugin)
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel?.setMethodCallHandler(null)
        channel = null
        context = null
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        activityBinding = binding
        binding.addActivityResultListener(this)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        detachActivity()
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        onAttachedToActivity(binding)
    }

    override fun onDetachedFromActivity() {
        detachActivity()
    }

    private fun detachActivity() {
        pendingResult?.error("cancelled", "Photo picking was interrupted.", null)
        pendingResult = null
        activityBinding?.removeActivityResultListener(this)
        activityBinding = null
        activity = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        if (call.method != METHOD) {
            result.notImplemented()
            return
        }
        pick(result)
    }

    private fun pick(result: MethodChannel.Result) {
        if (pendingResult != null) {
            result.error("busy", "A photo picker is already open.", null)
            return
        }
        val current = activity
        if (current == null) {
            result.error("unavailable", "Photo picking is unavailable.", null)
            return
        }
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = "image/*"
            putExtra(
                Intent.EXTRA_MIME_TYPES,
                arrayOf("image/jpeg", "image/png", "image/webp"),
            )
        }
        pendingResult = result
        try {
            current.startActivityForResult(intent, REQUEST_CODE)
        } catch (_: Exception) {
            pendingResult = null
            result.error("unavailable", "No document picker is available.", null)
        }
    }

    override fun onActivityResult(
        requestCode: Int,
        resultCode: Int,
        data: Intent?,
    ): Boolean {
        if (requestCode != REQUEST_CODE) {
            return false
        }
        val result = pendingResult ?: return true
        pendingResult = null
        if (resultCode != Activity.RESULT_OK) {
            result.success(null)
            return true
        }
        val uri: Uri = data?.data ?: run {
            result.success(null)
            return true
        }
        val appContext = context
        if (appContext == null) {
            result.error("unavailable", "Storage is unavailable.", null)
            return true
        }
        var target: File? = null
        try {
            val dir = File(appContext.cacheDir, CACHE_DIR)
            if (!dir.exists()) {
                dir.mkdirs()
            }
            target = File(dir, "avatar_${UUID.randomUUID()}")
            appContext.contentResolver.openInputStream(uri)?.use { input ->
                FileOutputStream(target).use { output ->
                    val buffer = ByteArray(64 * 1024)
                    var total = 0L
                    while (true) {
                        val read = input.read(buffer)
                        if (read <= 0) {
                            break
                        }
                        total += read
                        if (total > MAX_BYTES) {
                            throw SizeLimitException()
                        }
                        output.write(buffer, 0, read)
                    }
                }
            } ?: throw IllegalStateException("Image stream is unavailable.")
            if (!target.exists() || target.length() == 0L) {
                target.delete()
                result.success(null)
                return true
            }
            result.success(mapOf("path" to target.absolutePath))
        } catch (_: SizeLimitException) {
            target?.delete()
            result.error("too_large", "Photo exceeds 2 MB.", null)
        } catch (_: Exception) {
            target?.delete()
            result.error("unreadable", "Photo could not be read.", null)
        }
        return true
    }

    private class SizeLimitException : Exception()

    companion object {
        private const val CHANNEL = "app.trainingarena.mobile/avatar"
        private const val METHOD = "pickFromLibrary"
        private const val REQUEST_CODE = 0x4156
        private const val CACHE_DIR = "avatar_pick"
        private const val MAX_BYTES = 2L * 1024 * 1024
    }
}
