import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:video_transcode_platform_interface/src/method_channel_video_transcode.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const kPath = "path/to/file.mp4";
  const kStart = Duration(seconds: 1);
  const kDuration = Duration(seconds: 1, milliseconds: 500);
  const kSize = (width: 1920, height: 1080);

  group(MethodChannelVideoTranscode, () {
    late MethodChannelVideoTranscode sut;
    late List<MethodCall> log;

    setUp(() async {
      sut = MethodChannelVideoTranscode();
      log = [];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        sut.methodChannel,
        (methodCall) async {
          log.add(methodCall);
        },
      );
    });

    group("processClip", () {
      test("calls processClip on MethodChannel with correct defaults",
          () async {
        await sut.processClip(sourceFile: File("path/to/file.mp4")).last;
        expect(
          log,
          [
            isMethodCall(
              'processClip',
              arguments: {
                "sourcePath": "path/to/file.mp4",
                "startSeconds": 0,
                "durationSeconds": null,
                "targetWidth": null,
                "targetHeight": null,
              },
            ),
          ],
        );
      });

      test("passes on all values correctly", () async {
        await sut
            .processClip(
              sourceFile: File(kPath),
              start: kStart,
              duration: kDuration,
              targetSize: kSize,
            )
            .last;
        expect(
          log,
          [
            isMethodCall(
              'processClip',
              arguments: {
                "sourcePath": "path/to/file.mp4",
                "startSeconds": kStart.inMilliseconds / 1000,
                "durationSeconds": kDuration.inMilliseconds / 1000,
                "targetWidth": kSize.width,
                "targetHeight": kSize.height,
              },
            ),
          ],
        );
      });
    });
  });
}
