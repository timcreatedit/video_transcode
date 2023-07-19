import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:video_transcode_platform_interface/video_transcode_platform_interface.dart';

/// The iOS implementation of [VideoTranscodePlatform].
class VideoTranscodeIOS extends VideoTranscodePlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('video_transcode_ios');

  /// Registers this class as the default instance of [VideoTranscodePlatform]
  static void registerWith() {
    VideoTranscodePlatform.instance = VideoTranscodeIOS();
  }

  @override
  Future<String?> getPlatformName() {
    return methodChannel.invokeMethod<String>('getPlatformName');
  }
}
