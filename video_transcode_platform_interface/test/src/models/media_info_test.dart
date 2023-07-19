import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:video_transcode_platform_interface/src/models/media_info.dart';

void main() {
  const validJson = {
    "path": "/path/to/file.mp4",
    "width": 1920,
    "height": 1080,
    "duration": 120.5,
    "fileSize": 1024,
    "title": "My Video",
    "author": "John Doe",
    "orientation": 0,
  };

  final validMediaInfo = MediaInfo(
    file: File('/path/to/file.mp4'),
    frameSize: (width: 1920, height: 1080),
    duration: const Duration(milliseconds: 120500),
    fileSize: 1024,
    title: "My Video",
    author: "John Doe",
    orientation: 0,
  );

  group(MediaInfo, () {
    group('.fromJson', () {
      test('should create a MediaInfo object from valid JSON', () {
        final mediaInfo = MediaInfo.fromJson(validJson);

        expect(mediaInfo.file.path, validMediaInfo.file.path);
        expect(mediaInfo.frameSize.width, validMediaInfo.frameSize.width);
        expect(mediaInfo.frameSize.height, validMediaInfo.frameSize.height);
        expect(mediaInfo.duration.inMilliseconds,
            validMediaInfo.duration.inMilliseconds);
        expect(mediaInfo.fileSize, validMediaInfo.fileSize);
        expect(mediaInfo.title, validMediaInfo.title);
        expect(mediaInfo.author, validMediaInfo.author);
        expect(mediaInfo.orientation, validMediaInfo.orientation);
      });

      test('can deal with missing values', () {
        final json = {
          "path": "/path/to/file.mp4",
          "width": 1920,
          "height": 1080,
          "duration": 120.5,
          "fileSize": 1024,
        };

        final mediaInfo = MediaInfo.fromJson(json);

        expect(mediaInfo.file.path, equals('/path/to/file.mp4'));
        expect(mediaInfo.frameSize.width, equals(1920));
        expect(mediaInfo.frameSize.height, equals(1080));
        expect(mediaInfo.duration.inMilliseconds, equals(120500));
        expect(mediaInfo.fileSize, equals(1024));
        expect(mediaInfo.title, isNull);
        expect(mediaInfo.author, isNull);
        expect(mediaInfo.orientation, isNull);
      });

      test('should throw an ArgumentError for wrong optional types', () {
        final json = {
          "file": "/path/to/file.mp4",
          "width": 1920,
          "height": 1080,
          "duration": 120.5,
          "fileSize": 1024,
          "title": "My Video",
          "author": "John Doe",
          "orientation": "invalid",
        };

        expect(() => MediaInfo.fromJson(json), throwsArgumentError);
      });

      test("should throw ArgumentError for invalid JSON", () async {
        final json = {"oopsie": "dasy"};

        expect(() => MediaInfo.fromJson(json), throwsArgumentError);
      });
    });

    group("toJson", () {
      test("returns all values in JSON", () async {
        final json = validMediaInfo.toJson();

        expect(json, validJson);
      });
      test("omits optional values", () {
        final mediaInfo = MediaInfo(
          file: File('/path/to/file.mp4'),
          frameSize: (width: 1920, height: 1080),
          duration: const Duration(milliseconds: 120500),
          fileSize: 1024,
        );
        final json = mediaInfo.toJson();
        expect(json["title"], isNull);
        expect(json["author"], isNull);
        expect(json["orientation"], isNull);
      });
    });

    group("==", () {
      test("returns true for equal objects", () {
        final mediaInfo1 = MediaInfo.fromJson(validJson);
        final mediaInfo2 = MediaInfo.fromJson(validJson);

        expect(mediaInfo1 == mediaInfo2, isTrue);
      });

      test("returns false for different objects", () {
        final mediaInfo1 = MediaInfo.fromJson(validJson);
        final mediaInfo2 = MediaInfo.fromJson(const {
          "path": "/path/to/file.mp4",
          "width": 1920,
          "height": 1080,
          "duration": 120.5,
          "fileSize": 1024,
          "title": "My Video",
          "author": "John Doe",
          // Different
          "orientation": 90,
        });

        expect(mediaInfo1 == mediaInfo2, isFalse);
      });
    });

    group("hashCode", () {
      test("returns the same hash code for equal objects", () {
        final mediaInfo1 = MediaInfo.fromJson(validJson);
        final mediaInfo2 = MediaInfo.fromJson(validJson);

        expect(mediaInfo1.hashCode, mediaInfo2.hashCode);
      });

      test("returns different hash codes for different objects", () {
        final mediaInfo1 = MediaInfo.fromJson(validJson);
        final mediaInfo2 = MediaInfo.fromJson(const {
          "path": "/path/to/file.mp4",
          "width": 1920,
          "height": 1080,
          "duration": 120.5,
          "fileSize": 1024,
          "title": "My Video",
          "author": "John Doe",
          // Different
          "orientation": 90,
        });

        expect(mediaInfo1.hashCode, isNot(mediaInfo2.hashCode));
      });
    });
  });
}
