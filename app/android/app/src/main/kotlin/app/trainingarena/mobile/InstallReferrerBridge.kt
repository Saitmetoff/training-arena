package app.trainingarena.mobile

import android.content.Context
import android.os.Handler
import android.os.Looper
import com.android.installreferrer.api.InstallReferrerClient
import com.android.installreferrer.api.InstallReferrerStateListener
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Play Install Referrer bridge for challenge link recovery (task 05).
 *
 * The web landing page sends installs to Play with
 * `referrer=challenge%3D<token>`. This bridge returns the raw referrer, or
 * null when the service is unavailable, not installed by Play, or times out.
 * It never throws to Dart and never blocks startup.
 */
class InstallReferrerBridge(
    context: Context,
    messenger: BinaryMessenger,
) : MethodChannel.MethodCallHandler {

    private val appContext = context.applicationContext
    private val mainHandler = Handler(Looper.getMainLooper())
    private val channel = MethodChannel(messenger, CHANNEL).also {
        it.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        if (call.method != METHOD) {
            result.notImplemented()
            return
        }
        fetch(result)
    }

    private fun fetch(result: MethodChannel.Result) {
        var replied = false
        var timeout: Runnable? = null
        val client: InstallReferrerClient
        try {
            client = InstallReferrerClient.newBuilder(appContext).build()
        } catch (_: Exception) {
            result.success(null)
            return
        }

        fun reply(value: String?) {
            if (replied) {
                return
            }
            replied = true
            timeout?.let { mainHandler.removeCallbacks(it) }
            try {
                client.endConnection()
            } catch (_: Exception) {
                // Connecting may already have failed; nothing to close.
            }
            result.success(value)
        }

        timeout = Runnable { reply(null) }
        mainHandler.postDelayed(timeout, TIMEOUT_MS)

        try {
            client.startConnection(object : InstallReferrerStateListener {
                override fun onInstallReferrerSetupFinished(responseCode: Int) {
                    if (responseCode != InstallReferrerClient.InstallReferrerResponse.OK) {
                        reply(null)
                        return
                    }
                    try {
                        reply(client.installReferrer.installReferrer)
                    } catch (_: Exception) {
                        reply(null)
                    }
                }

                override fun onInstallReferrerServiceDisconnected() {
                    reply(null)
                }
            })
        } catch (_: Exception) {
            reply(null)
        }
    }

    fun dispose() {
        channel.setMethodCallHandler(null)
    }

    companion object {
        private const val CHANNEL = "app.trainingarena.mobile/install_referrer"
        private const val METHOD = "getInstallReferrer"
        private const val TIMEOUT_MS = 4_000L
    }
}
