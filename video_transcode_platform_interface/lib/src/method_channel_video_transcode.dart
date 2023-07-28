import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/services.dart';
import 'package:video_transcode_platform_interface/video_transcode_platform_interface.dart';

/// An implementation of [VideoTranscodePlatform] that uses method channels.
class MethodChannelVideoTranscode extends VideoTranscodePlatform {
  /// Constructs a [MethodChannelVideoTranscode].
  MethodChannelVideoTranscode() {
    methodChannel.setMethodCallHandler(_methodCallHandler);
  }

  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('video_transcode');

  final Map<int, TranscodeProcess<MediaInfo?>> _processes = {};

  /// Make sure there is no active process.
  ///
  /// TODO support multiple processes
  void _verifyAllProcessesEnded() {
    if (_processes.values.any((process) => process.isRunning)) {
      throw StateError("Only one process can be running at a time!");
    }
  }

  /// Make sure the target file extension is supported
  /// TODO support more file types
  void _verifyExtension(File target) {
    switch (target.path.split(".").last) {
      case "mp4":
        break;
      default:
        throw ArgumentError.value(
          target,
          "target",
          "Only mp4 and mov files are supported!",
        );
    }
  }

  TranscodeProcess<MediaInfo?> _startNewProcess({
    Future<MediaInfo?>? fromFuture,
  }) {
    final uids = _processes.keys.toList()..sort();
    final uid = switch (uids) {
      [] => 0,
      [..., final last] => last + 1,
    };
    onCancel() => methodChannel.invokeMethod("cancelProcess");
    _processes[uid] = fromFuture != null
        ? TranscodeProcess.guardFuture(
            uid: uid,
            future: fromFuture,
            onCancel: onCancel,
          )
        : TranscodeProcess(uid, onCancel: onCancel);
    return _processes[uid]!;
  }

  TranscodeProcess<MediaInfo?>? get _activeProcess =>
      _processes.values.where((element) => element.isRunning).firstOrNull;

  @override
  TranscodeProcess<MediaInfo?> processVideo({
    required File source,
    required File target,
    Duration start = Duration.zero,
    Duration? duration,
    ({int width, int height})? targetSize,
  }) {
    _verifyAllProcessesEnded();
    _verifyExtension(target);

    final future = methodChannel.invokeMethod<Map>(
      "processVideo",
      {
        "sourcePath": source.path,
        "targetPath": target.path,
        "startSeconds": start.inMilliseconds / 1000,
        "durationSeconds":
            duration == null ? null : duration.inMilliseconds / 1000,
        "targetWidth": targetSize?.width.toInt(),
        "targetHeight": targetSize?.height.toInt(),
      },
    ).then((value) => value.jsonParse(MediaInfo.fromJson));
    return _startNewProcess(fromFuture: future);
  }

  @override
  TranscodeProcess<MediaInfo?> concatVideos({
    required List<File> sources,
    required File target,
  }) {
    _verifyAllProcessesEnded();
    _verifyExtension(target);

    final future = methodChannel.invokeMethod<Map>(
      "concatVideos",
      {
        "sourcePaths": sources.map((e) => e.path).toList(),
        "targetPath": target.path,
      },
    ).then((value) => value.jsonParse(MediaInfo.fromJson));

    return _startNewProcess(
      fromFuture: future,
    );
  }

  @override
  Future<MediaInfo?> getMediaInfo({required File source}) {
    return methodChannel.invokeMethod<Map>(
      "getMediaInfo",
      {
        "sourcePath": source.path,
      },
    ).then((value) => value.jsonParse(MediaInfo.fromJson));
  }

  @override
  Future<Uint8List?> getThumbnail({
    required File source,
    Duration position = Duration.zero,
    int quality = 100,
  }) async {
    return await methodChannel.invokeMethod(
      "getThumbnail",
      {
        "sourcePath": source.path,
        "positionSeconds": position.inMilliseconds / 1000,
        "quality": quality,
      },
    );
  }

  Future<void> _methodCallHandler(MethodCall call) async {
    final args = double.tryParse(call.arguments);

    if (call.method == "updateProgress" && args != null) {
      _activeProcess?.addProgress(args);
    }
  }
}

extension on Map<dynamic, dynamic>? {
  T? jsonParse<T>(T Function(Map<String, dynamic>) parser) {
    if (this == null) return null;
    return parser(Map<String, dynamic>.from(this!));
  }
}
