import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_transcode_ios/video_transcode_ios.dart';
import 'package:video_transcode_platform_interface/video_transcode_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('VideoTranscodeIOS', () {
    const kPlatformName = 'iOS';
    late VideoTranscodeIOS videoTranscode;
    late List<MethodCall> log;

    setUp(() async {
      videoTranscode = VideoTranscodeIOS();

      log = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(videoTranscode.methodChannel,
              (methodCall) async {
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
      VideoTranscodeIOS.registerWith();
      expect(VideoTranscodePlatform.instance, isA<VideoTranscodeIOS>());
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
