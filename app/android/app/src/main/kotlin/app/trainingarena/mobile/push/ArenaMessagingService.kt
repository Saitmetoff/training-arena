package app.trainingarena.mobile.push

import android.Manifest
import android.app.PendingIntent
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage
import app.trainingarena.mobile.MainActivity
import app.trainingarena.mobile.R

/**
 * FCM entry point for the arena push contract (task `11` / L06).
 *
 * * [onNewToken] forwards the rotated token to the Dart `tokens` stream. The
 *   token is never logged, analysed or written to evidence.
 * * [onMessageReceived] (foreground messages; background notification
 *   messages are shown by the SDK tray) forwards the data map to the Dart
 *   `messages` stream and posts a local notification on the channel named by
 *   `channel_id` (default `arena_requests`).
 *
 * The notification `PendingIntent` reuses the `singleTop` [MainActivity] with
 * the data map as extras, so a warm tap arrives through `onNewIntent` and a
 * cold tap through the launch intent; both end at the Dart `taps` stream or
 * `initialTap()`.
 */
class ArenaMessagingService : FirebaseMessagingService() {

    override fun onNewToken(token: String) {
        PushBridge.deliverToken(token)
    }

    override fun onMessageReceived(message: RemoteMessage) {
        val data = message.data
        PushBridge.ensureChannels(this)
        PushBridge.deliverMessage(data)
        postLocalNotification(message)
    }

    private fun postLocalNotification(message: RemoteMessage) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
            ContextCompat.checkSelfPermission(
                this,
                Manifest.permission.POST_NOTIFICATIONS,
            ) != PackageManager.PERMISSION_GRANTED
        ) {
            // The inbox remains authoritative; a denied permission only means
            // no OS notification.
            return
        }
        if (!NotificationManagerCompat.from(this).areNotificationsEnabled()) {
            return
        }

        val data = message.data
        val channelId = resolveChannelId(message)
        val notificationId = notificationId(message)
        val intent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                Intent.FLAG_ACTIVITY_SINGLE_TOP or
                Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra(PushBridge.EXTRA_FROM_NOTIFICATION, true)
            for ((key, value) in data) {
                putExtra(key, value)
            }
        }
        val pendingIntent = PendingIntent.getActivity(
            this,
            notificationId,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val notification = NotificationCompat.Builder(this, channelId)
            .setSmallIcon(R.drawable.ic_arena_notification)
            .setContentTitle(message.notification?.title ?: "Fault")
            .setContentText(message.notification?.body ?: "You have an update.")
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)
            .setContentIntent(pendingIntent)
            .build()
        try {
            NotificationManagerCompat.from(this).notify(notificationId, notification)
        } catch (_: SecurityException) {
            // The permission can be revoked between the check and the post.
        }
    }

    private fun resolveChannelId(message: RemoteMessage): String {
        val named = message.notification?.channelId ?: message.data["channel_id"]
        return if (named == PushBridge.CHANNEL_MATCHES) {
            PushBridge.CHANNEL_MATCHES
        } else {
            PushBridge.CHANNEL_REQUESTS
        }
    }

    /** Stable per message so a duplicate delivery replaces its notification. */
    private fun notificationId(message: RemoteMessage): Int {
        val key = message.messageId
            ?: "${message.data[PushBridge.EXTRA_KIND]}:${
                message.data["request_id"] ?: message.data["match_id"] ?: ""
            }"
        return key.hashCode()
    }
}
