import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/services.dart';
import 'package:video_transcode_platform_interface/src/models/media_info.dart';
import 'package:video_transcode_platform_interface/src/models/process_value.dart';
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

  final Map<int, Process<MediaInfo?>> _processes = {};

  /// Make sure there is no active process.
  ///
  /// TODO support multiple processes
  void _verifyAllProcessesEnded() {
    if (_processes.values.any((process) => process.isRunning)) {
      throw StateError("Only one process can be running at a time!");
    }
  }

  Process<MediaInfo?> _startNewProcess({
    Future<MediaInfo?>? fromFuture,
  }) {
    final uids = _processes.keys.toList()..sort();
    final uid = switch (uids) {
      [] => 0,
      [..., final last] => last + 1,
    };
    _processes[uid] = fromFuture != null
        ? Process.guardFuture(uid: uid, future: fromFuture)
        : Process(uid);
    return _processes[uid]!;
  }

  Process<MediaInfo?>? get _activeProcess =>
      _processes.values.where((element) => element.isRunning).firstOrNull;

  @override
  Stream<ProcessValue<MediaInfo?>> processClip({
    required File sourceFile,
    Duration start = Duration.zero,
    Duration? duration,
    ({int width, int height})? targetSize,
  }) async* {
    _verifyAllProcessesEnded();

    final future = methodChannel.invokeMethod<Map>(
      "processClip",
      {
        "sourcePath": sourceFile.path,
        "startSeconds": start.inMilliseconds / 1000,
        "durationSeconds":
            duration == null ? null : duration.inMilliseconds / 1000,
        "targetWidth": targetSize?.width.toInt(),
        "targetHeight": targetSize?.height.toInt(),
      },
    ).then(
      (value) => value == null
          ? null
          : MediaInfo.fromJson(
              Map<String, dynamic>.from(value),
            ),
    );
    final process = _startNewProcess(fromFuture: future);
    yield* process.updates;
  }

  @override
  Stream<ProcessValue<MediaInfo?>> concatVideos({
    required List<String> sourcePaths,
    required File destination,
  }) async* {
    _verifyAllProcessesEnded();

    final future = methodChannel.invokeMethod<Map>(
      "concatVideos",
      {
        "sourcePaths": sourcePaths,
        "destinationPath": destination.path,
      },
    ).then((r) => r == null
        ? null
        : MediaInfo.fromJson(
            Map<String, dynamic>.from(r),
          ));

    final process = _startNewProcess(fromFuture: future);
    yield* process.updates;
  }

  @override
  Future<Uint8List?> getThumbnail({
    required File sourceFile,
    Duration position = Duration.zero,
    int quality = 100,
  }) async {
    return await methodChannel.invokeMethod(
      "getThumbnail",
      {
        "sourcePath": sourceFile.path,
        "positionSeconds": position.inMilliseconds / 1000,
        "quality": quality,
      },
    );
  }

  @override
  Future<void> clearCache() async {
    await methodChannel.invokeMethod("clearCache");
  }

  @override
  Future<void> cancelProcess(int uid) async {
    switch (_processes[uid]) {
      case Process(isRunning: true):
        await methodChannel.invokeMethod("cancelProcess", {"uid": uid});
      case Process(isRunning: false):
        throw StateError("Process with uid $uid is not running");
      case null:
        throw ArgumentError.value(uid, "uid", "No such process");
    }
  }

  Future<void> _methodCallHandler(MethodCall call) async {
    final args = double.tryParse(call.arguments);

    if (call.method == "updateProgress" && args != null) {
      _activeProcess?.addProgress(args);
    }
  }
}
