import 'dart:io';

import 'dart:typed_data';

import 'package:video_transcode_platform_interface/video_transcode_platform_interface.dart';
export 'package:video_transcode_platform_interface/src/models/media_info.dart';
export 'package:video_transcode_platform_interface/src/models/transcode_process.dart';

VideoTranscodePlatform get _platform => VideoTranscodePlatform.instance;

/// The singleton class to access all video transcoding methods.
class VideoTranscode {
  static final VideoTranscode _instance = VideoTranscode();

  /// The singleton instance
  static VideoTranscode get instance => _instance;

  /// Process a clip from a video [source].
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
  TranscodeProcess<MediaInfo?> processClip({
    required File source,
    required File target,
    Duration start = Duration.zero,
    Duration? duration,
    ({int width, int height})? targetSize,
  }) =>
      _platform.processVideo(
        source: source,
        target: target,
        start: start,
        duration: duration,
        targetSize: targetSize,
      );

  /// Concatenate multiple videos from [sources] into a single video file.
  ///
  TranscodeProcess<MediaInfo?> concatVideos({
    required List<File> sources,
    required File target,
  }) =>
      _platform.concatVideos(
        sources: sources,
        target: target,
      );

  /// Get information about a media [source] if it can be extracted.
  Future<MediaInfo?> getMediaInfo(File source) =>
      _platform.getMediaInfo(source: source);

  /// Get a thumbnail from a video [source] as png bytes.
  Future<Uint8List?> getThumbnail({
    required File source,
    Duration position = Duration.zero,
    int quality = 100,
  }) =>
      _platform.getThumbnail(
        source: source,
        position: position,
        quality: quality,
      );
}
