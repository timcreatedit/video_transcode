import 'package:flutter_test/flutter_test.dart';
import 'package:video_transcode_platform_interface/src/method_channel_video_transcode.dart';
import 'package:video_transcode_platform_interface/video_transcode_platform_interface.dart';

class MockVideoTranscodePlatform extends VideoTranscodePlatform {
  @override
  noSuchMethod(Invocation invocation) {}
}

void main() {
  late VideoTranscodePlatform videoTranscode;

  setUp(() {
    videoTranscode = MockVideoTranscodePlatform();
  });

  group('instance', () {
    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        MethodChannelVideoTranscode().methodChannel,
        (methodCall) => Future.value(null),
      );
    });
    test("defaults to VideoTranscodePlatform", () async {
      expect(VideoTranscodePlatform.instance, isA<VideoTranscodePlatform>());
    });

    test("can be set to a mock", () async {
      VideoTranscodePlatform.instance = videoTranscode;
      expect(VideoTranscodePlatform.instance, equals(videoTranscode));
    });
  });
}
