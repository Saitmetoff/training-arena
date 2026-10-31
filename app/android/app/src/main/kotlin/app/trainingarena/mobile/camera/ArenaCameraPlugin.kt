package app.trainingarena.mobile.camera

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import androidx.lifecycle.LifecycleOwner
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry
import io.flutter.view.TextureRegistry

/**
 * Flutter bridge for the on-device camera and pose pipeline.
 *
 * Channel contract (matching `app/lib/camera/bridge/camera_bridge.dart`):
 *
 * * `trainingarena/device` — MethodChannel: permission, lifecycle, torch,
 *   runtime info and disposal.
 * * `trainingarena/pose` — EventChannel: numeric landmarks, tracking loss and
 *   detector errors.
 * * `trainingarena/cues` — EventChannel: camera readiness and camera errors.
 *
 * Frames never cross this bridge in either direction; only landmark numbers,
 * luminance, monotonic timestamps and codes do. Camera access is requested
 * only in context, and the camera/detector are released when the session is
 * disposed or the route leaves the foreground.
 */
class ArenaCameraPlugin : FlutterPlugin,
    ActivityAware,
    MethodChannel.MethodCallHandler,
    PluginRegistry.RequestPermissionsResultListener {

    companion object {
        const val DEVICE_CHANNEL = "trainingarena/device"
        const val POSE_CHANNEL = "trainingarena/pose"
        const val CUES_CHANNEL = "trainingarena/cues"

        private const val REQUEST_CODE = 0x4152
        private const val PREFS = "trainingarena_camera"
        private const val KEY_REQUESTED = "camera_permission_requested"
    }

    private val mainHandler = Handler(Looper.getMainLooper())

    private var context: Context? = null
    private var activity: Activity? = null
    private var activityBinding: ActivityPluginBinding? = null
    private var textureRegistry: TextureRegistry? = null

    private var deviceChannel: MethodChannel? = null
    private var poseChannel: EventChannel? = null
    private var cuesChannel: EventChannel? = null

    private var poseSink: EventChannel.EventSink? = null
    private var cueSink: EventChannel.EventSink? = null
    private var pendingPermissionResult: MethodChannel.Result? = null

    private var controller: ArenaCameraController? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        textureRegistry = binding.textureRegistry
        deviceChannel = MethodChannel(binding.binaryMessenger, DEVICE_CHANNEL).apply {
            setMethodCallHandler(this@ArenaCameraPlugin)
        }
        poseChannel = EventChannel(binding.binaryMessenger, POSE_CHANNEL).apply {
            setStreamHandler(
                object : EventChannel.StreamHandler {
                    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                        poseSink = events
                    }

                    override fun onCancel(arguments: Any?) {
                        poseSink = null
                    }
                }
            )
        }
        cuesChannel = EventChannel(binding.binaryMessenger, CUES_CHANNEL).apply {
            setStreamHandler(
                object : EventChannel.StreamHandler {
                    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                        cueSink = events
                    }

                    override fun onCancel(arguments: Any?) {
                        cueSink = null
                    }
                }
            )
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        controller?.dispose()
        controller = null
        deviceChannel?.setMethodCallHandler(null)
        deviceChannel = null
        poseChannel?.setStreamHandler(null)
        poseChannel = null
        cuesChannel?.setStreamHandler(null)
        cuesChannel = null
        poseSink = null
        cueSink = null
        pendingPermissionResult = null
        context = null
        textureRegistry = null
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        activityBinding = binding
        binding.addRequestPermissionsResultListener(this)
        rebuildController()
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

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "checkPermission" -> result.success(currentPermissionStatus())
            "requestPermission" -> requestPermission(result)
            "openAppSettings" -> result.success(openAppSettings())
            "hasCamera" -> result.success(hasCamera())
            "startPreview" -> startPreview(result)
            "pause" -> {
                controller?.pause()
                result.success(true)
            }
            "resume" -> {
                controller?.resume()
                result.success(true)
            }
            "stop" -> {
                controller?.stop()
                result.success(true)
            }
            "setTorch" -> {
                controller?.setTorch(call.argument<Boolean>("enabled") ?: false)
                result.success(true)
            }
            "disposeSession" -> {
                // Drop the reference as well as disposing: a disposed
                // controller is permanently dead (texture released, executor
                // shut down), and reusing it made startPreview hand Dart a
                // valid texture id without ever binding the camera — a black
                // preview with no landmarks and no error.
                controller?.dispose()
                controller = null
                result.success(true)
            }
            "runtimeInfo" -> result.success(
                controller?.runtimeInfo() ?: mapOf(
                    "detector_sdk" to PoseAnalyzer.DETECTOR_SDK,
                    "detector_model" to PoseAnalyzer.DETECTOR_MODEL,
                    "camera_stack" to ArenaCameraController.CAMERAX_VERSION,
                    "min_sdk" to 24,
                    "api_level" to android.os.Build.VERSION.SDK_INT,
                    "device" to "",
                )
            )
            else -> result.notImplemented()
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ): Boolean {
        if (requestCode != REQUEST_CODE) {
            return false
        }
        val result = pendingPermissionResult ?: return true
        pendingPermissionResult = null
        result.success(currentPermissionStatus())
        return true
    }

    private fun detachActivity() {
        activityBinding?.removeRequestPermissionsResultListener(this)
        activityBinding = null
        controller?.dispose()
        controller = null
        activity = null
    }

    private fun rebuildController() {
        ensureController()
    }

    /**
     * Returns the live controller, creating one when none exists. A disposed
     * controller is never reused: the plugin drops its reference on dispose
     * and every start path rebuilds through here.
     */
    private fun ensureController(): ArenaCameraController? {
        val ctx = context ?: return null
        val registry = textureRegistry ?: return null
        val active = controller ?: ArenaCameraController(
            context = ctx,
            textureRegistry = registry,
            onPoseEvent = { event -> emitPose(event) },
            onCueEvent = { event -> emitCue(event) },
        ).also { controller = it }
        (activity as? LifecycleOwner)?.let { owner -> active.attach(owner) }
        return active
    }

    private fun startPreview(result: MethodChannel.Result) {
        if (activity == null || textureRegistry == null) {
            result.error("camera_unavailable", "camera is not attached to an activity", null)
            return
        }
        val active = ensureController()
        if (active == null) {
            result.error("camera_unavailable", "camera controller is not ready", null)
            return
        }
        try {
            result.success(active.start())
        } catch (error: Exception) {
            result.error("camera_unavailable", error.message ?: "camera start failed", null)
        }
    }

    private fun emitPose(event: Map<String, Any?>) {
        mainHandler.post {
            try {
                poseSink?.success(event)
            } catch (_: IllegalStateException) {
                // The Dart listener detached between the post and the call.
            }
        }
    }

    private fun emitCue(event: Map<String, Any?>) {
        mainHandler.post {
            try {
                cueSink?.success(event)
            } catch (_: IllegalStateException) {
                // The Dart listener detached between the post and the call.
            }
        }
    }

    private fun currentPermissionStatus(): String {
        val ctx = context ?: return "denied"
        val granted = ContextCompat.checkSelfPermission(ctx, Manifest.permission.CAMERA) ==
            PackageManager.PERMISSION_GRANTED
        if (granted) {
            return "granted"
        }
        val requested = ctx.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .getBoolean(KEY_REQUESTED, false)
        if (!requested) {
            return "unknown"
        }
        val host = activity
        val rationale = host != null &&
            ActivityCompat.shouldShowRequestPermissionRationale(host, Manifest.permission.CAMERA)
        return if (rationale) "denied" else "permanently_denied"
    }

    private fun requestPermission(result: MethodChannel.Result) {
        val status = currentPermissionStatus()
        if (status == "granted") {
            result.success("granted")
            return
        }
        val host = activity
        if (host == null) {
            result.success(status)
            return
        }
        if (pendingPermissionResult != null) {
            result.error("camera_permission", "a permission request is already pending", null)
            return
        }
        pendingPermissionResult = result
        context?.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            ?.edit()
            ?.putBoolean(KEY_REQUESTED, true)
            ?.apply()
        ActivityCompat.requestPermissions(
            host,
            arrayOf(Manifest.permission.CAMERA),
            REQUEST_CODE,
        )
    }

    private fun openAppSettings(): Boolean {
        val ctx = context ?: return false
        val intent = Intent(
            Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
            Uri.fromParts("package", ctx.packageName, null),
        )
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        return try {
            ctx.startActivity(intent)
            true
        } catch (_: Exception) {
            false
        }
    }

    private fun hasCamera(): Boolean {
        val ctx = context ?: return false
        return ctx.packageManager.hasSystemFeature(PackageManager.FEATURE_CAMERA_ANY)
    }
}
