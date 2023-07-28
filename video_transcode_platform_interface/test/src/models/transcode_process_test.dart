import 'package:flutter_test/flutter_test.dart';
import 'package:video_transcode_platform_interface/src/models/transcode_process.dart';

void main() {
  group("Process", () {
    group(".guardFuture", () {
      test('completes with data', () async {
        final process = TranscodeProcess<int>.guardFuture(
          uid: 3,
          future:
              Future.delayed(const Duration(seconds: 1)).then((value) => 42),
        );

        await expectLater(
          process.updates,
          emitsInOrder(
            [
              emitsThrough(ProcessData(42)),
              emitsDone,
            ],
          ),
        );

        expect(process.isCompleted, isTrue);
        expect(process.isRunning, isFalse);
      });

      test("completes with error", () async {
        final process = TranscodeProcess<int>.guardFuture(
          uid: 4,
          future: Future.error(Exception('oops')),
        );

        await expectLater(process.updates, emitsThrough(isA<ProcessError>()));

        expect(process.isCompleted, isTrue);
        expect(process.isRunning, isFalse);
      });
    });
    group("complete", () {
      test('completes with data', () async {
        final process = TranscodeProcess<int>(1);

        expect(process.isCompleted, isFalse);
        expect(process.isRunning, isTrue);

        process.complete(42);

        expect(process.isCompleted, isTrue);
        expect(process.isRunning, isFalse);
      });
    });

    group("error", () {
      test('completes with error', () async {
        final process = TranscodeProcess<int>(2);
        final error = Exception('oops');

        expect(process.isCompleted, isFalse);
        expect(process.isRunning, isTrue);

        expectLater(
          process.updates,
          emitsInOrder([
            emitsThrough(
              isA<ProcessError>(),
            ),
            emitsDone,
          ]),
        );

        process.error(error);
        expect(process.isCompleted, isTrue);
        expect(process.isRunning, isFalse);
      });
    });

    group("addProgress", () {
      test("emits progress correctly on success", () async {
        final process = TranscodeProcess<int>(5);
        expectLater(
          process.updates,
          emitsInOrder(
            [
              ProcessLoading<int>(0.0),
              ProcessLoading<int>(0.5),
              ProcessLoading<int>(1),
              ProcessData(42),
              emitsDone,
            ],
          ),
        );
        process.addProgress(0);
        process.addProgress(0.5);
        process.complete(42);
      });
      test("emits progress correctly on error", () async {
        final process = TranscodeProcess<int>(6);
        expectLater(
          process.updates,
          emitsInOrder(
            [
              ProcessLoading<int>(0.0),
              ProcessLoading<int>(0.5),
              ProcessLoading<int>(1),
              isA<ProcessError>(),
              emitsDone,
            ],
          ),
        );
        process.addProgress(0);
        process.addProgress(0.5);
        process.error(42);
      });

      test("ignores duplicate values", () async {
        final process = TranscodeProcess<int>(6);

        expectLater(
          process.updates,
          emitsInOrder(
            [
              ProcessLoading<int>(0.0),
              ProcessLoading<int>(0.5),
              ProcessLoading<int>(1),
              ProcessData(42),
              emitsDone,
            ],
          ),
        );

        process.addProgress(0);
        process.addProgress(0.5);
        process.addProgress(0.5);
        process.complete(42);
      });
    });

    group("cancel", () {
      test("calls onCancel callback", () async {
        var onCancelCalled = false;
        final process = TranscodeProcess<int>(
          7,
          onCancel: () => onCancelCalled = true,
        );

        process.cancel();

        expect(onCancelCalled, isTrue);
      });

      test("throws if already completed", () async {
        final process = TranscodeProcess<int>(8);

        process.complete(42);

        expect(() => process.cancel(), throwsStateError);
      });

      test("throws if no cancellation possible", () async {
        final process = TranscodeProcess<int>(8);

        expect(() => process.cancel(), throwsUnsupportedError);
      });

      test("emits a ProcessCancelledException when cancelled successfully", () {
        final process = TranscodeProcess<int>(42, onCancel: () {});
        expectLater(
            process.updates,
            emitsInOrder([
              const ProcessLoading<int>(1),
              (e) => e is ProcessError && e.error is ProcessCancelledException,
              emitsDone,
            ]));
        process.cancel();
      });
    });
  });
}
