package works.noone

import android.content.Context
import android.graphics.Bitmap
import android.media.MediaMetadataRetriever
import android.net.Uri
import android.util.Log
import java.io.ByteArrayOutputStream
import java.io.File
import java.io.FileDescriptor
import java.io.FileInputStream
import java.lang.Long.parseLong
import kotlin.math.max
import kotlin.math.roundToInt

class Utility(private val channelName: String) {

    fun getMediaInfoJson(context: Context, path: String): Map<String, Any?>? {
        val file = File(path)
        val inputStream: FileInputStream = FileInputStream(file.absolutePath)
        val retriever = MediaMetadataRetriever()
        try {

            retriever.setDataSource(inputStream.fd)

            val durationStr = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_DURATION)
            val title = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_TITLE) ?: ""
            val author = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_AUTHOR) ?: ""
            val widthStr = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_WIDTH)
            val heightStr = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_HEIGHT)
            val duration = durationStr?.let { parseLong(it) }
            var width = widthStr?.toLongOrNull()
            var height = heightStr?.toLongOrNull()
            val fileSize = file.length()
            val orientation =
                retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_ROTATION)

            val ori = orientation?.toIntOrNull()
            if (ori != null && isLandscapeImage(ori)) {
                val tmp = width
                width = height
                height = tmp
            }

            retriever.release()
            return mapOf(
                "path" to path,
                "width" to width,
                "height" to height,
                "duration" to duration?.toDouble()?.div(1000),
                "fileSize" to fileSize,
                "title" to title,
                "author" to author,
                "orientation" to ori
            )
        } catch (e: RuntimeException) {
            Log.e("getMediaInfo", e.localizedMessage, e)
            return null
        }

    }

    fun getByteThumbnail(
        path: String,
        quality: Int,
        positionSeconds: Double,
    ): ByteArray? {
        val bmp = getBitmap(path, positionSeconds)
        return bmp?.let {
            val stream = ByteArrayOutputStream()
            it.compress(Bitmap.CompressFormat.JPEG, quality, stream)
            it.recycle()
            return stream.toByteArray()
        }

    }

    private fun isLandscapeImage(orientation: Int) = orientation != 90 && orientation != 270

    private fun getBitmap(
        path: String,
        positionSeconds: Double,
        maxDimension: Int = 512,
    ): Bitmap? {

        val retriever = MediaMetadataRetriever()

        try {
            retriever.setDataSource(path)
            val bitmap = retriever.getFrameAtTime(
                (positionSeconds * 1_000_000).toLong(), MediaMetadataRetriever.OPTION_CLOSEST_SYNC
            ) ?: return null
            val max = max(bitmap.width, bitmap.height)
            return if (max > maxDimension) {
                val scaleFactor = maxDimension.toFloat() / max
                return Bitmap.createScaledBitmap(
                    bitmap,
                    bitmap.width * scaleFactor.roundToInt(),
                    (bitmap.height * scaleFactor).roundToInt(),
                    true,
                )
            } else null

        } catch (ex: IllegalArgumentException) {
            throw IllegalArgumentException("Assume this is a corrupt video file")
        } catch (ex: RuntimeException) {
            throw IllegalArgumentException("Assume this is a corrupt video file")
        } finally {
            try {
                retriever.release()
            } catch (_: RuntimeException) {
            }
        }
    }
}