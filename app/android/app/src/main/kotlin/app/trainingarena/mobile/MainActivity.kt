package app.trainingarena.mobile

import app.trainingarena.mobile.avatar.AccountAvatarPlugin
import app.trainingarena.mobile.camera.ArenaCameraPlugin
import app.trainingarena.mobile.push.PushBridge
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {

    private var installReferrerBridge: InstallReferrerBridge? = null
    private var pushBridge: PushBridge? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // The camera/pose bridge lives in this module, so it is registered
        // manually instead of through generated plugin registrants.
        flutterEngine.plugins.add(ArenaCameraPlugin())
        // Avatar document picker for task 06 (never the camera).
        flutterEngine.plugins.add(AccountAvatarPlugin())
        // Play Install Referrer recovery for challenge links (task 05).
        installReferrerBridge = InstallReferrerBridge(
            this,
            flutterEngine.dartExecutor.binaryMessenger,
        )
        // Native FCM host (task 11 / L06): permission, token, taps and
        // foreground messages. Degrades to "no push" without the owner's
        // google-services.json.
        val push = PushBridge()
        pushBridge = push
        flutterEngine.plugins.add(push)
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        installReferrerBridge?.dispose()
        installReferrerBridge = null
        pushBridge = null
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
