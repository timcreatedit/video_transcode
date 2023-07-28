import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_transcode_platform_interface/src/method_channel_video_transcode.dart';
import 'package:video_transcode_platform_interface/video_transcode_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const kPath = "path/to/file.mp4";
  const kTargetPath = "path/to/output.mp4";
  const kStart = Duration(seconds: 1);
  const kDuration = Duration(seconds: 1, milliseconds: 500);
  const kSize = (width: 1920, height: 1080);
  final mediaInfo = MediaInfo(
    file: File(kPath),
    frameSize: kSize,
    duration: kDuration,
    fileSize: 100,
  );
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
          switch (methodCall.method) {
            case "processVideo":
              return mediaInfo.toJson();
            case "concatVideos":
              return null;
            case "getThumbnail":
              return null;
            default:
              return null;
          }
        },
      );
    });

    group("processVideo", () {
      test("calls processVideo on MethodChannel with correct defaults",
          () async {
        final result = await sut
            .processVideo(
              source: File(kPath),
              target: File(kTargetPath),
            )
            .updates
            .last;
        expect(
          log,
          [
            isMethodCall(
              'processVideo',
              arguments: {
                "sourcePath": kPath,
                "targetPath": kTargetPath,
                "startSeconds": 0,
                "durationSeconds": null,
                "targetWidth": null,
                "targetHeight": null,
              },
            ),
          ],
        );
        expect(result, ProcessData<MediaInfo?>(mediaInfo));
      });

      test("passes on all values correctly", () async {
        await sut
            .processVideo(
              source: File(kPath),
              target: File(kTargetPath),
              start: kStart,
              duration: kDuration,
              targetSize: kSize,
            )
            .updates
            .last;
        expect(
          log,
          [
            isMethodCall(
              'processVideo',
              arguments: {
                "sourcePath": kPath,
                "targetPath": kTargetPath,
                "startSeconds": kStart.inMilliseconds / 1000,
                "durationSeconds": kDuration.inMilliseconds / 1000,
                "targetWidth": kSize.width,
                "targetHeight": kSize.height,
              },
            ),
          ],
        );
      });
      test("allows one process at a time", () async {
        sut.processVideo(
          source: File(kPath),
          target: File(kTargetPath),
        );
        expect(
          () => sut.processVideo(
            source: File(kPath),
            target: File(kTargetPath),
          ),
          throwsStateError,
        );
      });
      test("Forbids target file extension that is not .mp4", () async {
        expect(
          () => sut.processVideo(
            source: File(kPath),
            target: File("path/to/output.mov"),
          ),
          throwsArgumentError,
        );
      });
    });
  });
}
