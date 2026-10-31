package app.trainingarena.mobile.camera

import android.os.SystemClock
import androidx.camera.core.ImageAnalysis
import androidx.camera.core.ImageProxy
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.pose.Pose
import com.google.mlkit.vision.pose.PoseDetection
import com.google.mlkit.vision.pose.PoseDetector
import com.google.mlkit.vision.pose.PoseDetectorOptionsBase
import com.google.mlkit.vision.pose.defaults.PoseDetectorOptions

/**
 * CameraX analyzer that runs ML Kit Pose Detection on-device.
 *
 * Frames are converted to an [InputImage], processed in memory and immediately
 * closed. Only numeric landmarks, a mean luminance and a monotonic timestamp
 * are forwarded to the Flutter side; no image, buffer or bitmap is ever
 * returned, stored or uploaded. This is the only place the pose model runs.
 */
internal class PoseAnalyzer(
    private val onFrame: (Map<String, Any?>) -> Unit,
    private val onTracking: (Map<String, Any?>) -> Unit,
    private val onError: (Map<String, Any?>) -> Unit,
    private val previewGeometry: (ImageProxy) -> Map<String, Any?>?,
) : ImageAnalysis.Analyzer {

    companion object {
        const val DETECTOR_SDK = "ML Kit pose-detection 18.0.0-beta5"
        const val DETECTOR_MODEL = "base"

        /** ~15 analysed frames per second is enough for rep counting. */
        private const val MIN_INFERENCE_INTERVAL_MS = 66L

        /** Tracking-loss signals are throttled; landmarks are not. */
        private const val TRACKING_SIGNAL_INTERVAL_MS = 200L
        private const val ERROR_THROTTLE_MS = 1000L

        /** Below this mean luminance with no pose we report a low-light cue. */
        private const val LOW_LIGHT_LUMINANCE = 0.18
    }

    private val detector: PoseDetector = PoseDetection.getClient(
        PoseDetectorOptions.Builder()
            .setDetectorMode(PoseDetectorOptionsBase.STREAM_MODE)
            .build()
    )

    private var lastInferenceMs = 0L
    private var lastTrackingSignalMs = 0L
    private var lastErrorMs = 0L

    @Volatile
    private var closed = false

    override fun analyze(imageProxy: ImageProxy) {
        if (closed) {
            imageProxy.close()
            return
        }
        val now = SystemClock.elapsedRealtime()
        if (now - lastInferenceMs < MIN_INFERENCE_INTERVAL_MS) {
            imageProxy.close()
            return
        }
        lastInferenceMs = now

        val mediaImage = imageProxy.image
        if (mediaImage == null) {
            imageProxy.close()
            reportError("detector_failure", "analysis frame had no image", now)
            return
        }

        val luminance = meanLuminance(imageProxy)
        val rotation = imageProxy.imageInfo.rotationDegrees
        // The detector sees the rotated (upright) image, so its landmark
        // pixels live in that frame. Report its size so the Dart bridge can
        // normalise; a 90/270 rotation swaps the buffer dimensions.
        val uprightWidth: Int
        val uprightHeight: Int
        if (rotation == 90 || rotation == 270) {
            uprightWidth = imageProxy.height
            uprightHeight = imageProxy.width
        } else {
            uprightWidth = imageProxy.width
            uprightHeight = imageProxy.height
        }
        val input = InputImage.fromMediaImage(mediaImage, rotation)
        val geometry = previewGeometry(imageProxy)
        detector.process(input)
            .addOnSuccessListener { pose ->
                if (closed) return@addOnSuccessListener
                geometry?.let(onFrame)
                handlePose(pose, luminance, uprightWidth, uprightHeight)
            }
            .addOnFailureListener { error ->
                reportError(
                    "detector_failure",
                    error.message ?: "pose detection failed",
                    SystemClock.elapsedRealtime(),
                )
            }
            .addOnCompleteListener { imageProxy.close() }
    }

    /** Closes the detector. Safe to call more than once. */
    fun close() {
        if (closed) {
            return
        }
        closed = true
        detector.close()
    }

    private fun handlePose(
        pose: Pose,
        luminance: Double,
        frameWidth: Int,
        frameHeight: Int,
    ) {
        val landmarks = pose.allPoseLandmarks
        val timestamp = nowMicros()
        if (landmarks.isNullOrEmpty()) {
            val now = SystemClock.elapsedRealtime()
            if (now - lastTrackingSignalMs >= TRACKING_SIGNAL_INTERVAL_MS) {
                lastTrackingSignalMs = now
                val reason = if (luminance < LOW_LIGHT_LUMINANCE) "lowLight" else "noPerson"
                onTracking(
                    mapOf(
                        "type" to "tracking",
                        "state" to "lost",
                        "reason" to reason,
                        "luminance" to luminance,
                        "timestamp_us" to timestamp,
                    )
                )
            }
            return
        }

        lastTrackingSignalMs = 0L
        val mapped = ArrayList<Map<String, Any?>>(landmarks.size)
        for (landmark in landmarks) {
            mapped.add(
                mapOf(
                    "t" to landmark.landmarkType,
                    "x" to landmark.position.x.toDouble(),
                    "y" to landmark.position.y.toDouble(),
                    "z" to landmark.position3D.z.toDouble(),
                    "l" to landmark.inFrameLikelihood.toDouble(),
                )
            )
        }
        onFrame(
            mapOf(
                "type" to "pose",
                "timestamp_us" to timestamp,
                "luminance" to luminance,
                // Upright (post-rotation) analysis frame the pixel coordinates
                // are relative to.
                "frame_width" to frameWidth,
                "frame_height" to frameHeight,
                "landmarks" to mapped,
            )
        )
    }

    /** Mean luminance of the Y plane, sampled sparsely; never persisted. */
    private fun meanLuminance(imageProxy: ImageProxy): Double {
        val plane = imageProxy.planes.firstOrNull() ?: return 1.0
        val buffer = plane.buffer
        val rowStride = plane.rowStride
        val pixelStride = plane.pixelStride
        var sum = 0L
        var count = 0
        var row = 0
        while (row < imageProxy.height) {
            val rowStart = row * rowStride
            var column = 0
            while (column < imageProxy.width) {
                val index = rowStart + column * pixelStride
                if (index < buffer.limit()) {
                    sum += buffer.get(index).toInt() and 0xFF
                    count++
                }
                column += 8
            }
            row += 8
        }
        if (count == 0) {
            return 1.0
        }
        return (sum.toDouble() / count) / 255.0
    }

    private fun reportError(code: String, message: String, nowMs: Long) {
        if (nowMs - lastErrorMs < ERROR_THROTTLE_MS) {
            return
        }
        lastErrorMs = nowMs
        onError(
            mapOf(
                "type" to "error",
                "code" to code,
                "message" to message,
                "timestamp_us" to nowMicros(),
            )
        )
    }

    private fun nowMicros(): Long = SystemClock.elapsedRealtimeNanos() / 1000
}
