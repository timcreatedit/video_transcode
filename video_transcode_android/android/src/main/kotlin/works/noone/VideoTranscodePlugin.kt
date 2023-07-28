package works.noone

import android.content.Context
import com.otaliastudios.transcoder.Transcoder
import com.otaliastudios.transcoder.source.FileDescriptorDataSource
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry
import java.io.File
import java.io.FileInputStream
import java.text.SimpleDateFormat
import java.util.*
import java.util.concurrent.Future

class VideoTranscodePlugin : FlutterPlugin, MethodCallHandler {
    private var _context: Context? = null
    private var _channel: MethodChannel? = null
    private var transcoder: works.noone.Transcoder? = null
    private var transcodeFuture: Future<Void>? = null
    private val utility = Utility(channelName)

    override fun onMethodCall(call: MethodCall, result: Result) {
        val context = _context;
        val channel = _channel;

        if (context == null || channel == null) {
            return
        }

        when (call.method) {
            "processVideo" -> {
                val sourcePath = call.argument<String>("sourcePath")!!
                val targetPath = call.argument<String>("targetPath")!!
                val targetWidth = call.argument<Int>("targetWidth")
                val targetHeight = call.argument<Int>("targetHeight")
                val startSeconds = call.argument<Double>("startSeconds")
                val durationSeconds = call.argument<Double>("durationSeconds")

                val size = if (targetWidth != null && targetHeight != null) {
                    Pair(targetWidth, targetHeight)
                } else {
                    null
                }
                transcoder!!.transcodeClip(
                    sourcePath,
                    targetPath,
                    VideoTransformationListener(channel, result, targetPath, context),
                    startSeconds = startSeconds,
                    durationSeconds = durationSeconds,
                    ensureAudioTrack = true,
                    size = size,
                )
            }
            "concatVideos" -> {
                val srcPaths = call.argument<List<String>>("sourcePaths")!!
                val targetPath = call.argument<String>("targetPath")!!
                val transcoder = Transcoder.into(targetPath)
                for (source in srcPaths) {
                    val inputStream = FileInputStream(source)
                    val datasource = FileDescriptorDataSource(inputStream.fd)
                    transcoder.addDataSource(datasource)
                }
                transcodeFuture = transcoder.setListener(
                    VideoTranscoderListener(
                        channel,
                        result,
                        targetPath,
                        context
                    )
                ).transcode()
            }
            "getMediaInfo" -> {
                val path = call.argument<String>("sourcePath")!!
                try {
                    val mediaInfo = utility.getMediaInfoJson(context, path)
                    result.success(mediaInfo)
                } catch (e: RuntimeException) {
                    result.success(null)
                }
            }
            "getThumbnail" -> {
                val path = call.argument<String>("sourcePath")
                val positionSeconds = call.argument<Double>("positionSeconds")!! // to long
                val quality = call.argument<Int>("quality")!!
                try {
                    result.success(utility.getByteThumbnail(
                        path!!,
                        quality,
                        positionSeconds,
                    ))
                } catch (e: RuntimeException) {
                    result.error(e.toString(), e.localizedMessage, null)
                }
            }
            "cancelProcess" -> {
                transcoder?.cancelTranscode()
                if (transcodeFuture?.isCancelled == false) {
                    transcodeFuture?.cancel(true)
                }
                result.success(null)
            }
            else -> {
                result.notImplemented()
            }
        }
    }


    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        init(binding.applicationContext, binding.binaryMessenger)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        _channel?.setMethodCallHandler(null)
        _context = null
        transcoder?.release()
        transcoder = null
        _channel = null
    }

    private fun init(context: Context, messenger: BinaryMessenger) {
        val channel = MethodChannel(messenger, channelName)
        channel.setMethodCallHandler(this)
        _context = context
        transcoder = Transcoder(context)
        _channel = channel
    }

    companion object {
        internal const val channelName = "video_transcode"

        @JvmStatic
        fun registerWith(registrar: PluginRegistry.Registrar) {
            val instance = VideoTranscodePlugin()
            instance.init(registrar.context(), registrar.messenger())
        }
    }
}