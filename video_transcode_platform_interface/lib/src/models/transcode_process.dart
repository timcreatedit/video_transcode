import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:process_value/process_value.dart';
export 'package:process_value/process_value.dart';

/// Encapsulates a process that can be treated as a stream of values.
class TranscodeProcess<T> {
  @protected
  TranscodeProcess(
    this.uid, {
    this.onCancel,
  });

  @protected
  TranscodeProcess.guardFuture({
    required this.uid,
    required Future<T> future,
    this.onCancel,
  }) {
    future.then(complete).catchError((e, s) => error(e, stackTrace: s));
  }

  final int uid;

  final FutureOr<void> Function()? onCancel;

  final StreamController<ProcessValue<T>> _controller =
      StreamController<ProcessValue<T>>.broadcast();

  late final Stream<ProcessValue<T>> updates = _controller.stream.distinct();
  final Completer<ProcessValue<T>> _completer = Completer<ProcessValue<T>>();

  /// Whether the process has completed with an error or data.
  bool get isCompleted => _completer.isCompleted;

  /// Whether the process is still running.
  bool get isRunning => _completer.isCompleted == false;

  void complete(T data) {
    final value = ProcessData(data);
    addProgress(1);
    _controller.add(value);
    _completer.complete(value);
    _controller.close();
  }

  void error(Object error, {StackTrace? stackTrace}) {
    final value = ProcessError<T>(
      error,
      stackTrace: stackTrace ?? StackTrace.current,
    );
    addProgress(1);
    _controller.add(value);
    _completer.complete(value);
    _controller.close();
  }

  void addProgress(double progress) {
    _controller.add(ProcessLoading(progress));
  }

  Future<void> cancel() async {
    if (isCompleted) {
      throw StateError("This process is already completed.");
    }
    if (onCancel case final onCancel?) {
      await onCancel.call();
      error(ProcessCancelledException(), stackTrace: StackTrace.current);
    } else {
      throw UnsupportedError('This process does not support cancellation.');
    }
  }
}

class ProcessCancelledException implements Exception {}
