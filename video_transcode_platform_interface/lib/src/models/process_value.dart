import 'dart:async';

/// A union type for [ProcessData], [ProcessLoading], and [ProcessError].
///
/// Meant to treat a process declaratively, as a stream of values. This concept
/// is similar to `AsyncValue` from [Riverpod](https://riverpod.dev/).
sealed class ProcessValue<T> {}

class ProcessData<T> extends ProcessValue<T> {
  ProcessData(this.data);

  final T data;

  @override
  String toString() => 'ProcessData<$T>($data)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProcessData<T> &&
          runtimeType == other.runtimeType &&
          data == other.data;

  @override
  int get hashCode => data.hashCode;
}

class ProcessLoading<T> extends ProcessValue<T> {
  ProcessLoading(this.progress) : assert(progress >= 0 && progress <= 1);

  final double progress;

  @override
  String toString() => 'ProcessLoading<$T>($progress)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProcessLoading<T> &&
          runtimeType == other.runtimeType &&
          progress == other.progress;

  @override
  int get hashCode => progress.hashCode;
}

class ProcessError<T> extends ProcessValue<T> {
  ProcessError(this.error, {this.stackTrace});

  final Object error;
  final StackTrace? stackTrace;

  @override
  String toString() => 'ProcessError<$T>($error, $stackTrace)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProcessError<T> &&
          runtimeType == other.runtimeType &&
          error == other.error &&
          stackTrace == other.stackTrace;

  @override
  int get hashCode => error.hashCode ^ stackTrace.hashCode;
}

/// Encapsulates a process that can be treated as a stream of values.
class Process<T> {
  Process(this.uid);

  Process.guardFuture({
    required this.uid,
    required Future<T> future,
  }) {
    future.then(complete).catchError((e, s) => error(e, stackTrace: s));
  }

  final int uid;

  final StreamController<ProcessValue<T>> _controller =
      StreamController<ProcessValue<T>>.broadcast();

  late final Stream<ProcessValue<T>> updates = _controller.stream;

  late final Completer<ProcessValue<T>> completer = Completer<ProcessValue<T>>()
    ..complete(updates.last);

  /// Whether the process has completed with an error or data.
  bool get isCompleted => completer.isCompleted;

  /// Whether the process is still running.
  bool get isRunning => completer.isCompleted == false;

  void complete(T data) {
    _controller.add(ProcessData(data));
    _controller.close();
  }

  void error(Object error, {StackTrace? stackTrace}) {
    _controller
        .add(ProcessError(error, stackTrace: stackTrace ?? StackTrace.current));
    _controller.close();
  }

  void addProgress(double progress) {
    _controller.add(ProcessLoading(progress));
  }
}
