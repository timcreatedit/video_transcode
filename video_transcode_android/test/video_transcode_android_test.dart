import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_transcode_android/video_transcode_android.dart';
import 'package:video_transcode_platform_interface/video_transcode_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('VideoTranscodeAndroid', () {
    const kPlatformName = 'Android';
    late VideoTranscodeAndroid videoTranscode;
    late List<MethodCall> log;

    setUp(() async {
      videoTranscode = VideoTranscodeAndroid();

      log = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(videoTranscode.methodChannel, (methodCall) async {
        log.add(methodCall);
        switch (methodCall.method) {
          case 'getPlatformName':
            return kPlatformName;
          default:
            return null;
        }
      });
    });

    test('can be registered', () {
      VideoTranscodeAndroid.registerWith();
      expect(VideoTranscodePlatform.instance, isA<VideoTranscodeAndroid>());
    });

    test('getPlatformName returns correct name', () async {
      final name = await videoTranscode.getPlatformName();
      expect(
        log,
        <Matcher>[isMethodCall('getPlatformName', arguments: null)],
      );
      expect(name, equals(kPlatformName));
    });
  });
}
