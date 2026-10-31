package app.trainingarena.mobile.camera

import android.content.Context
import android.graphics.Matrix
import android.graphics.RectF
import android.os.SystemClock
import android.util.Size
import android.util.Rational
import android.view.OrientationEventListener
import android.view.Surface
import androidx.camera.core.Camera
import androidx.camera.core.CameraSelector
import androidx.camera.core.CameraState
import androidx.camera.core.ImageAnalysis
import androidx.camera.core.Preview
import androidx.camera.core.SurfaceRequest
import androidx.camera.core.UseCaseGroup
import androidx.camera.core.ViewPort
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.core.content.ContextCompat
import androidx.lifecycle.DefaultLifecycleObserver
import androidx.lifecycle.LifecycleOwner
import androidx.lifecycle.Observer
import io.flutter.view.TextureRegistry
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

/**
 * Owns the CameraX pipeline and the ML Kit analyzer for one app process.
 *
 * Lifecycle rules:
 * * the camera binds only while the activity is started and not paused;
 * * backgrounding the app unbinds the camera and emits a `paused` tracking
 *   event; coming back rebinds only when the session wanted to be active;
 * * [dispose] releases the analyzer, the preview surface, the texture and the
 *   analysis executor. It also runs from the activity lifecycle so route exits
 *   never leak the camera.
 */
internal class ArenaCameraController(
    private val context: Context,
    private val textureRegistry: TextureRegistry,
    private val onPoseEvent: (Map<String, Any?>) -> Unit,
    private val onCueEvent: (Map<String, Any?>) -> Unit,
) : DefaultLifecycleObserver {

    companion object {
        const val CAMERAX_VERSION = "CameraX 1.4.1"
        private const val ANALYSIS_WIDTH = 640
        private const val ANALYSIS_HEIGHT = 480
    }

    private val mainExecutor = ContextCompat.getMainExecutor(context)
    private val analysisExecutor: ExecutorService = Executors.newSingleThreadExecutor()

    private var cameraProvider: ProcessCameraProvider? = null
    private var camera: Camera? = null
    private var preview: Preview? = null
    private var imageAnalysis: ImageAnalysis? = null
    private var analyzer: PoseAnalyzer? = null
    private var textureEntry: TextureRegistry.SurfaceProducer? = null
    @Volatile private var previewInfo: PreviewInfo? = null

    private data class PreviewInfo(
        val size: Size,
        val transform: SurfaceRequest.TransformationInfo,
        val handlesRotation: Boolean,
    )

    private var lifecycleOwner: LifecycleOwner? = null
    private var orientationListener: OrientationEventListener? = null
    private var cameraStateObserver: Observer<CameraState>? = null

    private var started = false
    private var paused = false
    private var desiredActive = false
    private var autoPaused = false
    private var targetRotation = Surface.ROTATION_0
    private var disposed = false

    fun attach(owner: LifecycleOwner) {
        if (disposed) {
            return
        }
        lifecycleOwner = owner
        owner.lifecycle.addObserver(this)
    }

    /** Binds the camera pipeline. Returns the Flutter texture id immediately. */
    fun start(): Long {
        // A disposed controller can never bind again; the plugin must create a
        // fresh one. Fail loudly instead of returning a texture id that will
        // stay black forever.
        check(!disposed) { "camera controller is disposed" }
        val entry = textureEntry ?: textureRegistry.createSurfaceProducer().also {
            textureEntry = it
            it.setCallback(object : TextureRegistry.SurfaceProducer.Callback {
                override fun onSurfaceAvailable() {
                    if (started && !paused && !disposed) cameraProvider?.let(::bindAll)
                }
                override fun onSurfaceCleanup() {
                    cameraProvider?.unbindAll()
                    previewInfo = null
                }
            })
        }
        started = true
        desiredActive = true
        paused = false
        autoPaused = false
        startOrientationListener()
        val provider = cameraProvider
        if (provider != null) {
            bindAll(provider)
        } else {
            val future = ProcessCameraProvider.getInstance(context)
            future.addListener(
                {
                    try {
                        val resolved = future.get()
                        cameraProvider = resolved
                        if (started && !paused && !disposed) {
                            bindAll(resolved)
                        }
                    } catch (error: Exception) {
                        reportCameraError(error)
                    }
                },
                mainExecutor,
            )
        }
        return entry.id()
    }

    /** Unbinds the camera and tells the session that tracking is paused. */
    fun pause() {
        desiredActive = false
        if (!paused) {
            paused = true
            autoPaused = false
            cameraProvider?.unbindAll()
        }
        emitTrackingPaused()
    }

    /** Rebinds the camera when permission and lifecycle allow it. */
    fun resume() {
        desiredActive = true
        if (disposed) {
            return
        }
        if (paused) {
            paused = false
            autoPaused = false
            val provider = cameraProvider
            if (provider != null) {
                bindAll(provider)
            } else {
                start()
            }
        }
    }

    fun stop() {
        desiredActive = false
        paused = true
        started = false
        cameraProvider?.unbindAll()
    }

    fun setTorch(enabled: Boolean) {
        camera?.cameraControl?.enableTorch(enabled)
    }

    fun runtimeInfo(): Map<String, Any?> = mapOf(
        "detector_sdk" to PoseAnalyzer.DETECTOR_SDK,
        "detector_model" to PoseAnalyzer.DETECTOR_MODEL,
        "camera_stack" to CAMERAX_VERSION,
        "min_sdk" to 24,
        "api_level" to android.os.Build.VERSION.SDK_INT,
        "device" to (android.os.Build.MANUFACTURER + " " + android.os.Build.MODEL).trim(),
    )

    fun dispose() {
        if (disposed) {
            return
        }
        disposed = true
        started = false
        desiredActive = false
        cameraProvider?.unbindAll()
        cameraStateObserver?.let { observer ->
            camera?.cameraInfo?.cameraState?.removeObserver(observer)
        }
        cameraStateObserver = null
        analyzer?.close()
        analyzer = null
        orientationListener?.disable()
        orientationListener = null
        previewInfo = null
        preview = null
        imageAnalysis = null
        camera = null
        textureEntry?.release()
        textureEntry = null
        analysisExecutor.shutdown()
        lifecycleOwner?.lifecycle?.removeObserver(this)
        lifecycleOwner = null
    }

    override fun onStop(owner: LifecycleOwner) {
        if (!disposed && started && !paused) {
            autoPaused = true
            paused = true
            cameraProvider?.unbindAll()
            emitTrackingPaused()
        }
    }

    override fun onStart(owner: LifecycleOwner) {
        if (!disposed && autoPaused && desiredActive) {
            autoPaused = false
            paused = false
            val provider = cameraProvider
            if (provider != null) {
                bindAll(provider)
            } else {
                start()
            }
        }
    }

    private fun bindAll(provider: ProcessCameraProvider) {
        val owner = lifecycleOwner ?: return
        if (disposed || !started || paused) {
            return
        }
        try {
            cameraStateObserver?.let { observer ->
                camera?.cameraInfo?.cameraState?.removeObserver(observer)
            }
            cameraStateObserver = null
            previewInfo = null
            provider.unbindAll()
            // The athlete watches themselves while training, so the front
            // camera is the default and the back camera is the fallback for
            // devices without one.
            val selector = if (provider.hasCamera(CameraSelector.DEFAULT_FRONT_CAMERA)) {
                CameraSelector.DEFAULT_FRONT_CAMERA
            } else {
                CameraSelector.DEFAULT_BACK_CAMERA
            }
            val previewUseCase = Preview.Builder()
                .setTargetRotation(targetRotation)
                .build()
            val analysisUseCase = ImageAnalysis.Builder()
                .setTargetResolution(Size(ANALYSIS_WIDTH, ANALYSIS_HEIGHT))
                .setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST)
                .setOutputImageFormat(ImageAnalysis.OUTPUT_IMAGE_FORMAT_YUV_420_888)
                .setTargetRotation(targetRotation)
                .build()

            previewUseCase.setSurfaceProvider { request ->
                val entry = textureEntry ?: return@setSurfaceProvider
                entry.setSize(
                    request.resolution.width,
                    request.resolution.height,
                )
                request.setTransformationInfoListener(mainExecutor) { info ->
                    previewInfo = PreviewInfo(request.resolution, info,
                        entry.handlesCropAndRotation())
                }
                request.provideSurface(entry.surface, mainExecutor) {}
            }

            val poseAnalyzer = analyzer ?: PoseAnalyzer(
                onFrame = onPoseEvent,
                onTracking = onPoseEvent,
                onError = onPoseEvent,
                previewGeometry = ::previewGeometry,
            ).also { analyzer = it }
            analysisUseCase.setAnalyzer(analysisExecutor, poseAnalyzer)

            val group = UseCaseGroup.Builder()
                .addUseCase(previewUseCase).addUseCase(analysisUseCase)
                .setViewPort(ViewPort.Builder(Rational(3, 4), targetRotation)
                    .setScaleType(ViewPort.FILL_CENTER).build())
                .build()
            camera = provider.bindToLifecycle(owner, selector, group)
            preview = previewUseCase
            imageAnalysis = analysisUseCase
            observeCameraState()
            onCueEvent(
                mapOf(
                    "code" to "cameraReady",
                    "timestamp_us" to nowMicros(),
                )
            )
        } catch (error: Exception) {
            reportCameraError(error)
        }
    }

    private fun observeCameraState() {
        val owner = lifecycleOwner ?: return
        val activeCamera = camera ?: return
        val observer = Observer<CameraState> { state ->
            val error = state.error ?: return@Observer
            if (state.type == CameraState.Type.CLOSED) {
                return@Observer
            }
            onCueEvent(
                mapOf(
                    "code" to "cameraError",
                    "message" to "camera error code ${error.code}",
                    "timestamp_us" to nowMicros(),
                )
            )
        }
        cameraStateObserver = observer
        activeCamera.cameraInfo.cameraState.observe(owner, observer)
    }

    private fun startOrientationListener() {
        if (orientationListener != null) {
            return
        }
        val listener = object : OrientationEventListener(context) {
            override fun onOrientationChanged(orientation: Int) {
                if (orientation == ORIENTATION_UNKNOWN || disposed) {
                    return
                }
                val rotation = when (orientation) {
                    in 45..134 -> Surface.ROTATION_270
                    in 135..224 -> Surface.ROTATION_180
                    in 225..314 -> Surface.ROTATION_90
                    else -> Surface.ROTATION_0
                }
                if (rotation != targetRotation) {
                    targetRotation = rotation
                    // Recreate the shared ViewPort as well as the use cases.
                    if (started && !paused) cameraProvider?.let(::bindAll)
                }
            }
        }
        if (listener.canDetectOrientation()) {
            listener.enable()
            orientationListener = listener
        } else {
            listener.disable()
        }
    }

    private fun emitTrackingPaused() {
        onPoseEvent(
            mapOf(
                "type" to "tracking",
                "state" to "paused",
                "reason" to "paused",
                "luminance" to 1.0,
                "timestamp_us" to nowMicros(),
            )
        )
    }

    private fun rotationMatrix(width: Int, height: Int, degrees: Int): Matrix =
        Matrix().apply {
            setValues(when (degrees) {
                90 -> floatArrayOf(0f, -1f, height.toFloat(), 1f, 0f, 0f, 0f, 0f, 1f)
                180 -> floatArrayOf(-1f, 0f, width.toFloat(), 0f, -1f, height.toFloat(), 0f, 0f, 1f)
                270 -> floatArrayOf(0f, 1f, 0f, -1f, 0f, width.toFloat(), 0f, 0f, 1f)
                else -> floatArrayOf(1f, 0f, 0f, 0f, 1f, 0f, 0f, 0f, 1f)
            })
        }

    /** Same sensor mapping and crop for the texture and skeleton; numbers only. */
    private fun previewGeometry(image: androidx.camera.core.ImageProxy): Map<String, Any?>? {
        val preview = previewInfo ?: return null
        val info = preview.transform
        val rotation = image.imageInfo.rotationDegrees
        val analysisRotation = rotationMatrix(image.width, image.height, rotation)
        val transform = Matrix()
        if (!analysisRotation.invert(transform)) return null
        val swapAnalysis = rotation == 90 || rotation == 270
        transform.preScale(
            (if (swapAnalysis) image.height else image.width).toFloat(),
            (if (swapAnalysis) image.width else image.height).toFloat(),
        )
        val bufferToSensor = Matrix()
        if (!image.imageInfo.sensorToBufferTransformMatrix.invert(bufferToSensor)) return null
        transform.postConcat(bufferToSensor)
        transform.postConcat(info.sensorToBufferTransform)
        val previewRotation = rotationMatrix(preview.size.width, preview.size.height,
            info.rotationDegrees)
        transform.postConcat(previewRotation)
        val crop = RectF(info.cropRect)
        previewRotation.mapRect(crop)
        if (crop.width() <= 0 || crop.height() <= 0) return null
        transform.postTranslate(-crop.left, -crop.top)
        transform.postScale(1f / crop.width(), 1f / crop.height())
        val values = FloatArray(9)
        transform.getValues(values)
        val swapPreview = info.rotationDegrees == 90 || info.rotationDegrees == 270
        return mapOf(
            "type" to "preview", "timestamp_us" to nowMicros(),
            "width" to if (swapPreview) preview.size.height else preview.size.width,
            "height" to if (swapPreview) preview.size.width else preview.size.height,
            "crop" to listOf(crop.left.toDouble(), crop.top.toDouble(),
                crop.right.toDouble(), crop.bottom.toDouble()),
            "texture_quarter_turns" to if (preview.handlesRotation && info.hasCameraTransform())
                info.targetRotation else info.rotationDegrees / 90,
            "mirrored" to info.isMirroring,
            "analysis_to_preview" to values.take(6).map { it.toDouble() },
        )
    }

    private fun reportCameraError(error: Exception) {
        onCueEvent(
            mapOf(
                "code" to "cameraError",
                "message" to (error.message ?: error.javaClass.simpleName),
                "timestamp_us" to nowMicros(),
            )
        )
    }

    private fun nowMicros(): Long = SystemClock.elapsedRealtimeNanos() / 1000
}
