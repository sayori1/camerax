package dev.yanshouwang.camerax

import android.Manifest
import android.annotation.SuppressLint
import android.app.Activity
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Environment
import android.view.Surface
import android.widget.Toast
import androidx.annotation.IntDef
import androidx.annotation.NonNull
import androidx.camera.core.*
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.camera.mlkit.vision.MlKitAnalyzer
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import androidx.lifecycle.LifecycleOwner
import com.google.mlkit.vision.face.FaceDetection
import com.google.mlkit.vision.face.FaceDetectorOptions
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry
import io.flutter.view.TextureRegistry
import java.io.File

class CameraXHandler(private val activity: Activity, private val textureRegistry: TextureRegistry) :
    MethodChannel.MethodCallHandler, EventChannel.StreamHandler, PluginRegistry.RequestPermissionsResultListener {
    companion object {
        private const val REQUEST_CODE = 19930430
    }

    private var sink: EventChannel.EventSink? = null
    private var listener: PluginRegistry.RequestPermissionsResultListener? = null

    private var cameraProvider: ProcessCameraProvider? = null
    private var camera: Camera? = null
    private var textureEntry: TextureRegistry.SurfaceTextureEntry? = null

    private var imageCapture: ImageCapture? = null;

    @AnalyzeMode
    private var analyzeMode: Int = AnalyzeMode.NONE

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: MethodChannel.Result) {
        when (call.method) {
            "state" -> stateNative(result)
            "request" -> requestNative(result)
            "start" -> startNative(call, result)
            "torch" -> torchNative(call, result)
            "analyze" -> analyzeNative(call, result)
            "stop" -> stopNative(result)
            "cameraCapture" -> cameraCapture(result)
            else -> result.notImplemented()
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        this.sink = events
    }

    override fun onCancel(arguments: Any?) {
        sink = null
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ): Boolean {
        return listener?.onRequestPermissionsResult(requestCode, permissions, grantResults) ?: false
    }

    private fun cameraCapture(result: MethodChannel.Result){
        val outputDir: File = ContextCompat.getExternalCacheDirs(activity)[0]
        val outputFile = File.createTempFile("image", ".jpg", outputDir)

        // Create output options object which contains file + metadata
        val outputOptions = ImageCapture.OutputFileOptions.Builder(outputFile).build()

        // Set up image capture listener, which is triggered after photo has
        // been taken
        imageCapture!!.takePicture(
                outputOptions,
                ContextCompat.getMainExecutor(activity),
                object : ImageCapture.OnImageSavedCallback {
                    override fun onError(exc: ImageCaptureException) {
                        sink?.success(mapOf("name" to "photoError", "data" to exc.toString() ));
                    }

                    override fun onImageSaved(output: ImageCapture.OutputFileResults) {
                        sink?.success(mapOf("name" to "photoSuccess", "data" to output.savedUri.toString() ));
                    }
                })
        result.success("Success");
    }

    private fun stateNative(result: MethodChannel.Result) {
        // Can't get exact denied or not_determined state without request. Just return not_determined when state isn't authorized
        val state =
            if (ContextCompat.checkSelfPermission(
                    activity,
                    Manifest.permission.CAMERA
                ) == PackageManager.PERMISSION_GRANTED
            ) 1
            else 0
        result.success(state)
    }

    private fun requestNative(result: MethodChannel.Result) {
        listener = PluginRegistry.RequestPermissionsResultListener { requestCode, _, grantResults ->
            if (requestCode != REQUEST_CODE) {
                false
            } else {
                val authorized = grantResults[0] == PackageManager.PERMISSION_GRANTED
                result.success(authorized)
                listener = null
                true
            }
        }
        val permissions = arrayOf(Manifest.permission.CAMERA)
        ActivityCompat.requestPermissions(activity, permissions, REQUEST_CODE)
    }

    private fun startNative(call: MethodCall, result: MethodChannel.Result) {
        val future = ProcessCameraProvider.getInstance(activity)
        val executor = ContextCompat.getMainExecutor(activity)
        future.addListener({
            cameraProvider = future.get()
            textureEntry = textureRegistry.createSurfaceTexture()
            val textureId = textureEntry!!.id()
            // Preview
            val surfaceProvider = Preview.SurfaceProvider { request ->
                val resolution = request.resolution
                val texture = textureEntry!!.surfaceTexture()
                texture.setDefaultBufferSize(resolution.width, resolution.height)
                val surface = Surface(texture)
                request.provideSurface(surface, executor) { }
            }
            val preview = Preview.Builder().build().apply { setSurfaceProvider(surfaceProvider) }
            // Analyzer
            val highAccuracyOpts = FaceDetectorOptions.Builder()
                    .setPerformanceMode(FaceDetectorOptions.PERFORMANCE_MODE_ACCURATE)
                    .setLandmarkMode(FaceDetectorOptions.LANDMARK_MODE_ALL)
                    .setClassificationMode(FaceDetectorOptions.CLASSIFICATION_MODE_ALL).setContourMode(FaceDetectorOptions.CONTOUR_MODE_ALL)
                    .build()

            val faceScanner = FaceDetection.getClient(highAccuracyOpts);
            val detectors = listOf(faceScanner);
            val analyser = MlKitAnalyzer(detectors, ImageAnalysis.COORDINATE_SYSTEM_ORIGINAL, executor){
                val faces = it.getValue(faceScanner);
                if (faces.isNullOrEmpty()) {
                    sink?.success(mapOf("name" to "no_face", "data" to "no_face" ));
                    return@MlKitAnalyzer
                }
                sink?.success(mapOf("name" to "face", "data" to faces.map {face -> face.data} ));
            }

            val analysis = ImageAnalysis.Builder()
                    .setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST)
                    .build().apply { setAnalyzer(executor, analyser) }

            // Bind to lifecycle.
            val owner = activity as LifecycleOwner
            val selector = CameraSelector.DEFAULT_FRONT_CAMERA
            camera = cameraProvider!!.bindToLifecycle(owner, selector, preview, analysis)
            camera!!.cameraInfo.torchState.observe(owner) { state ->
                // TorchState.OFF = 0; TorchState.ON = 1
                val event = mapOf("name" to "torchState", "data" to state)
                sink?.success(event)
            }

            imageCapture = ImageCapture.Builder().build()
            cameraProvider!!.bindToLifecycle(
                    owner, selector, preview, imageCapture)

            // TODO: seems there's not a better way to get the final resolution
            @SuppressLint("RestrictedApi")
            val resolution = preview.attachedSurfaceResolution!!
            val portrait = camera!!.cameraInfo.sensorRotationDegrees % 180 == 0
            val width = resolution.width.toDouble()
            val height = resolution.height.toDouble()
            val size = if (portrait) mapOf("width" to width, "height" to height) else mapOf(
                "width" to height,
                "height" to width
            )
            val answer = mapOf("textureId" to textureId, "size" to size, "torchable" to camera!!.torchable)
            result.success(answer)
        }, executor)
    }

    private fun torchNative(call: MethodCall, result: MethodChannel.Result) {
        val state = call.arguments == 1
        camera!!.cameraControl.enableTorch(state)
        result.success(null)
    }

    private fun analyzeNative(call: MethodCall, result: MethodChannel.Result) {
        analyzeMode = call.arguments as Int
        result.success(null)
    }

    private fun stopNative(result: MethodChannel.Result) {
        val owner = activity as LifecycleOwner
        camera!!.cameraInfo.torchState.removeObservers(owner)
        cameraProvider!!.unbindAll()
        textureEntry!!.release()

        analyzeMode = AnalyzeMode.NONE
        camera = null
        textureEntry = null
        cameraProvider = null

        result.success(null)
    }
}

@IntDef(AnalyzeMode.NONE, AnalyzeMode.BARCODE)
@Target(AnnotationTarget.FIELD)
@Retention(AnnotationRetention.SOURCE)
annotation class AnalyzeMode {
    companion object {
        const val NONE = 0
        const val BARCODE = 1
    }
}