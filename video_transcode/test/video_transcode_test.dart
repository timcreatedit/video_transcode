import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:video_transcode/video_transcode.dart';
import 'package:video_transcode_platform_interface/video_transcode_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockVideoTranscodePlatform extends Mock
    with MockPlatformInterfaceMixin
    implements VideoTranscodePlatform {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('VideoTranscode', () {
    late VideoTranscodePlatform videoTranscodePlatform;

    setUp(() {
      videoTranscodePlatform = MockVideoTranscodePlatform();
      VideoTranscodePlatform.instance = videoTranscodePlatform;
    });

    group('getPlatformName', () {
      test('returns correct name when platform implementation exists',
          () async {
        const platformName = '__test_platform__';
        when(
          () => videoTranscodePlatform.getPlatformName(),
        ).thenAnswer((_) async => platformName);

        final actualPlatformName = await getPlatformName();
        expect(actualPlatformName, equals(platformName));
      });

      test('throws exception when platform implementation is missing',
          () async {
        when(
          () => videoTranscodePlatform.getPlatformName(),
        ).thenAnswer((_) async => null);

        expect(getPlatformName, throwsException);
      });
    });
  });
}
