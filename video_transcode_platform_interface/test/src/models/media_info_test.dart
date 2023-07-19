import 'package:flutter_test/flutter_test.dart';
import 'package:video_transcode_platform_interface/src/models/media_info.dart';

void main() {
  group(MediaInfo, () {
    group('.fromJson', () {
      test('should create a MediaInfo object from valid JSON', () {
        final json = {
          "file": "/path/to/file.mp4",
          "width": 1920,
          "height": 1080,
          "duration": 120.5,
          "filesize": 1024,
          "title": "My Video",
          "author": "John Doe",
          "orientation": 0,
        };

        final mediaInfo = MediaInfo.fromJson(json);

        expect(mediaInfo.file.path, equals('/path/to/file.mp4'));
        expect(mediaInfo.size.width, equals(1920));
        expect(mediaInfo.size.height, equals(1080));
        expect(mediaInfo.duration.inMilliseconds, equals(120500));
        expect(mediaInfo.filesize, equals(1024));
        expect(mediaInfo.title, equals('My Video'));
        expect(mediaInfo.author, equals('John Doe'));
        expect(mediaInfo.orientation, equals(0));
      });

      test('can deal with missing values', () {
        final json = {
          "file": "/path/to/file.mp4",
          "width": 1920,
          "height": 1080,
          "duration": 120.5,
          "filesize": 1024,
        };

        final mediaInfo = MediaInfo.fromJson(json);

        expect(mediaInfo.file.path, equals('/path/to/file.mp4'));
        expect(mediaInfo.size.width, equals(1920));
        expect(mediaInfo.size.height, equals(1080));
        expect(mediaInfo.duration.inMilliseconds, equals(120500));
        expect(mediaInfo.filesize, equals(1024));
        expect(mediaInfo.title, isNull);
        expect(mediaInfo.author, isNull);
        expect(mediaInfo.orientation, isNull);
      });

      test('should throw an ArgumentError for invalid JSON', () {
        final json = {
          "file": "/path/to/file.mp4",
          "width": 1920,
          "height": 1080,
          "duration": 120.5,
          "filesize": 1024,
          "title": "My Video",
          "author": "John Doe",
          "orientation": "invalid",
        };

        expect(() => MediaInfo.fromJson(json), throwsArgumentError);
      });
    });
  });
}
