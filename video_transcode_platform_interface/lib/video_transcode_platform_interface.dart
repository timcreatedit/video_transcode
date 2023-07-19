import 'dart:io';
import 'dart:typed_data';

import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:video_transcode_platform_interface/src/method_channel_video_transcode.dart';
import 'package:video_transcode_platform_interface/src/models/media_info.dart';
import 'package:video_transcode_platform_interface/src/models/transcode_process.dart';

export 'package:video_transcode_platform_interface/src/models/media_info.dart';
export 'package:video_transcode_platform_interface/src/models/transcode_process.dart';

/// The interface that implementations of video_transcode must implement.
///
/// Platform implementations should extend this class
/// rather than implement it as `VideoTranscode`.
/// Extending this class (using `extends`) ensures that the subclass will get
/// the default implementation, while platform implementations that `implements`
///  this interface will be broken by newly added [VideoTranscodePlatform] methods.
abstract class VideoTranscodePlatform extends PlatformInterface {
  /// Constructs a VideoTranscodePlatform.
  VideoTranscodePlatform() : super(token: _token);

  static final Object _token = Object();

  static VideoTranscodePlatform _instance = MethodChannelVideoTranscode();

  /// The default instance of [VideoTranscodePlatform] to use.
  ///
  /// Defaults to [MethodChannelVideoTranscode].
  static VideoTranscodePlatform get instance => _instance;

  /// Platform-specific plugins should set this with their own platform-specific
  /// class that extends [VideoTranscodePlatform] when they register themselves.
  static set instance(VideoTranscodePlatform instance) {
    PlatformInterface.verify(instance, _token);
    _instance = instance;
  }

  /// Process a clip from a video [sourceFile].
  ///
  /// The [start] and [duration] parameters can be used to specify a time range.
  /// [start] has to be a non negative duration within the range of the source
  /// clip and defaults to [Duration.zero] (the beginning of the clip).
  /// [duration] has to be a non negative duration that does not exceed
  /// the duration of the source clip minus the start time. If [duration] is
  /// omitted, the source clip will be processed from [start] to the end.
  /// [targetSize] can be used to specify a target resolution for the processed
  /// clip. If the aspect ratio of [targetSize] does not match the aspect ratio
  /// of the source clip, the processed clip will be cropped to match the target
  /// aspect ratio. If [targetSize] is omitted, the resulting clip will keep
  /// the same resolution as the source clip.
  TranscodeProcess<MediaInfo?> processVideo({
    required File source,
    required File target,
    Duration start = Duration.zero,
    Duration? duration,
    ({int width, int height})? targetSize,
  });

  /// Concatenate multiple videos from [sourcePaths] into a single video file.
  ///
  /// The resulting video will be written to [destination].
  TranscodeProcess<MediaInfo?> concatVideos({
    required List<File> sources,
    required File target,
  });

  /// Get information about a media file.
  Future<MediaInfo?> getMediaInfo({
    required File source,
  });

  /// Get a thumbnail from a video [sourceFile] as png bytes.
  Future<Uint8List?> getThumbnail({
    required File source,
    Duration position = Duration.zero,
    int quality = 100,
  });
}
