package app.trainingarena.mobile.push

import android.Manifest
import android.app.Activity
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import androidx.core.app.ActivityCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import com.google.firebase.FirebaseApp
import com.google.firebase.messaging.FirebaseMessaging
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry

/**
 * Native Android host for the push bridge contract (task `11` / L06).
 *
 * Channels (exactly `app/lib/notifications/platform_push_transport.dart`):
 *
 * * `app.trainingarena.mobile/push` — MethodChannel: `permissionStatus`,
 *   `requestPermission`, `deviceToken`, `initialTap`, `dispose`.
 * * `.../push/messages` — foreground data payloads.
 * * `.../push/taps` — warm notification taps.
 * * `.../push/tokens` — FCM token rotation.
 *
 * Fail-closed rule: the Firebase default app only exists when the owner
 * supplied `google-services.json` and the Google Services plugin ran. Without
 * it every call degrades to "no push" (permission `notDetermined`, no token,
 * no streams) and the in-app inbox stays authoritative; no permission dialog
 * is shown for a capability that cannot deliver. Tokens are passed only to
 * the Dart layer and are never logged, stored in analytics or written to
 * evidence.
 */
class PushBridge : FlutterPlugin,
    ActivityAware,
    MethodChannel.MethodCallHandler,
    PluginRegistry.RequestPermissionsResultListener {

    companion object {
        const val METHOD_CHANNEL = "app.trainingarena.mobile/push"
        const val MESSAGES_CHANNEL = "app.trainingarena.mobile/push/messages"
        const val TAPS_CHANNEL = "app.trainingarena.mobile/push/taps"
        const val TOKENS_CHANNEL = "app.trainingarena.mobile/push/tokens"

        /** Channels fixed by docs/notifications/ANDROID_PUSH_SETUP.md §2. */
        const val CHANNEL_REQUESTS = "arena_requests"
        const val CHANNEL_MATCHES = "arena_matches"

        /** Marker + data key carried by a notification tap intent. */
        const val EXTRA_FROM_NOTIFICATION = "arena_notification"
        const val EXTRA_KIND = "kind"

        private const val REQUEST_CODE = 0x5055
        private const val PREFS = "trainingarena_push"
        private const val KEY_REQUESTED = "notifications_permission_requested"

        private const val GRANTED = "granted"
        private const val DENIED = "denied"
        private const val NOT_DETERMINED = "notDetermined"

        @Volatile
        private var active: PushBridge? = null

        /** Creates both notification channels; idempotent. */
        fun ensureChannels(context: Context) {
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
                return
            }
            val manager = context.getSystemService(NotificationManager::class.java)
                ?: return
            manager.createNotificationChannel(
                NotificationChannel(
                    CHANNEL_REQUESTS,
                    "Challenge requests",
                    NotificationManager.IMPORTANCE_HIGH,
                ).apply {
                    description = "Incoming challenge requests and declines."
                }
            )
            manager.createNotificationChannel(
                NotificationChannel(
                    CHANNEL_MATCHES,
                    "Battle updates",
                    NotificationManager.IMPORTANCE_HIGH,
                ).apply {
                    description = "Accepted challenges, ready battles and results."
                }
            )
        }

        /** Called by [ArenaMessagingService]; safe without an attached engine. */
        fun deliverMessage(data: Map<String, String>) {
            active?.emitMessage(data)
        }

        /** Called by [ArenaMessagingService]; never logged. */
        fun deliverToken(token: String) {
            active?.emitToken(token)
        }
    }

    private val mainHandler = Handler(Looper.getMainLooper())

    private var context: Context? = null
    private var activity: Activity? = null
    private var activityBinding: ActivityPluginBinding? = null

    private var methodChannel: MethodChannel? = null
    private var messagesChannel: EventChannel? = null
    private var tapsChannel: EventChannel? = null
    private var tokensChannel: EventChannel? = null

    private var messageSink: EventChannel.EventSink? = null
    private var tapSink: EventChannel.EventSink? = null
    private var tokenSink: EventChannel.EventSink? = null

    private var pendingPermissionResult: MethodChannel.Result? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        val appContext = binding.applicationContext
        context = appContext
        if (firebaseConfigured()) {
            ensureChannels(appContext)
        }
        methodChannel = MethodChannel(binding.binaryMessenger, METHOD_CHANNEL).apply {
            setMethodCallHandler(this@PushBridge)
        }
        messagesChannel = eventChannel(binding, MESSAGES_CHANNEL) { sink ->
            messageSink = sink
        }
        tapsChannel = eventChannel(binding, TAPS_CHANNEL) { sink ->
            tapSink = sink
        }
        tokensChannel = eventChannel(binding, TOKENS_CHANNEL) { sink ->
            tokenSink = sink
        }
        active = this
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        if (active === this) {
            active = null
        }
        methodChannel?.setMethodCallHandler(null)
        methodChannel = null
        messagesChannel?.setStreamHandler(null)
        messagesChannel = null
        tapsChannel?.setStreamHandler(null)
        tapsChannel = null
        tokensChannel?.setStreamHandler(null)
        tokensChannel = null
        messageSink = null
        tapSink = null
        tokenSink = null
        pendingPermissionResult = null
        context = null
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        activityBinding = binding
        binding.addRequestPermissionsResultListener(this)
        binding.addOnNewIntentListener { intent ->
            tapPayload(intent)?.let { emitTap(it) }
            true
        }
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
            "permissionStatus" -> result.success(currentPermissionStatus())
            "requestPermission" -> requestPermission(result)
            "deviceToken" -> deviceToken(result)
            "initialTap" -> result.success(tapPayload(activity?.intent))
            "dispose" -> result.success(null)
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
        activity = null
        pendingPermissionResult?.success(currentPermissionStatus())
        pendingPermissionResult = null
    }

    private fun eventChannel(
        binding: FlutterPlugin.FlutterPluginBinding,
        name: String,
        onSink: (EventChannel.EventSink?) -> Unit,
    ): EventChannel = EventChannel(binding.binaryMessenger, name).apply {
        setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    onSink(events)
                }

                override fun onCancel(arguments: Any?) {
                    onSink(null)
                }
            }
        )
    }

    private fun emitMessage(data: Map<String, String>) {
        mainHandler.post {
            try {
                messageSink?.success(data)
            } catch (_: IllegalStateException) {
                // The Dart listener detached between the post and the call.
            }
        }
    }

    private fun emitTap(data: Map<String, String>) {
        mainHandler.post {
            try {
                tapSink?.success(data)
            } catch (_: IllegalStateException) {
                // The Dart listener detached between the post and the call.
            }
        }
    }

    private fun emitToken(token: String) {
        mainHandler.post {
            try {
                tokenSink?.success(token)
            } catch (_: IllegalStateException) {
                // The Dart listener detached between the post and the call.
            }
        }
    }

    /** True only when the owner's Firebase configuration is present. */
    private fun firebaseConfigured(): Boolean {
        val ctx = context ?: return false
        return try {
            FirebaseApp.getApps(ctx).isNotEmpty()
        } catch (_: Exception) {
            false
        }
    }

    private fun currentPermissionStatus(): String {
        val ctx = context ?: return NOT_DETERMINED
        if (!firebaseConfigured()) {
            return NOT_DETERMINED
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            val granted = ContextCompat.checkSelfPermission(
                ctx,
                Manifest.permission.POST_NOTIFICATIONS,
            ) == PackageManager.PERMISSION_GRANTED
            if (granted) {
                return GRANTED
            }
            val requested = ctx.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
                .getBoolean(KEY_REQUESTED, false)
            return if (requested) DENIED else NOT_DETERMINED
        }
        return if (NotificationManagerCompat.from(ctx).areNotificationsEnabled()) {
            GRANTED
        } else {
            DENIED
        }
    }

    private fun requestPermission(result: MethodChannel.Result) {
        val status = currentPermissionStatus()
        if (status != NOT_DETERMINED || Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
            result.success(status)
            return
        }
        val host = activity
        if (host == null || pendingPermissionResult != null) {
            result.success(status)
            return
        }
        pendingPermissionResult = result
        context?.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            ?.edit()
            ?.putBoolean(KEY_REQUESTED, true)
            ?.apply()
        ActivityCompat.requestPermissions(
            host,
            arrayOf(Manifest.permission.POST_NOTIFICATIONS),
            REQUEST_CODE,
        )
    }

    private fun deviceToken(result: MethodChannel.Result) {
        if (!firebaseConfigured()) {
            result.success(null)
            return
        }
        try {
            FirebaseMessaging.getInstance().token.addOnCompleteListener { task ->
                // The token is handed to the Dart layer only; never logged.
                result.success(if (task.isSuccessful) task.result else null)
            }
        } catch (_: Exception) {
            result.success(null)
        }
    }

    /** Notification data extras, or null for a normal launcher intent. */
    private fun tapPayload(intent: Intent?): Map<String, String>? {
        val extras = intent?.extras ?: return null
        val kind = extras.getString(EXTRA_KIND)
        if (kind.isNullOrEmpty()) {
            return null
        }
        val data = HashMap<String, String>()
        for (key in extras.keySet()) {
            if (key == EXTRA_FROM_NOTIFICATION || key.startsWith("google.")) {
                continue
            }
            val value = extras.getString(key) ?: continue
            data[key] = value
        }
        return data
    }
}
