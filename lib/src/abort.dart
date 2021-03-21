import 'dart:async';
import 'reflect.dart';
import 'error.dart';

/// Abort cancellation signal
/// ```
/// await F4.one(()=>Future.value(1), abortSignal:abortController.signal);
/// ```
///
class AbortSignal {
  AbortError _abortError;

  List<Completer> completers = [];

  Function _onAbort;

  AbortSignal([Function onAbort]) : _onAbort = onAbort;

  /// @nodoc
  void addCompleter(Completer c) => aborted
      ? _complete(c)
      : !completers.contains(c) ? completers.add(c) : null;

  /// @nodoc
  void trigger(String message) {
    _abortError = AbortError(message: message ?? '');

    completers.forEach(_complete);

    completers.clear();

    _onAbort != null ? Function.apply(_onAbort, [_abortError]) : null;
  }

  void _complete(Completer cmp) => !cmp.isCompleted
      ? _onAbort == null
          ? cmp.complete(ReflectFuture(Future.error(_abortError)))
          : cmp.complete(ReflectFuture(Future.value(null)))
      : null;

  void onAbort(Function fn) => _onAbort = fn;

  bool get aborted => _abortError != null;

  AbortError get error => _abortError;
}

/// Abort controller that optionally receives `onAbort` callback in which case
/// an `AbortError` doesn't get thrown by the Future.
/// ```
/// final ctl = AbortController(onAbort:(e)=>print('onAbort: $e'));
/// ```
class AbortController {
  AbortSignal _signal;

  Completer _abortCompleter;

  /// Trigger abort signal.
  /// ```
  /// abortController.abort('cancel message')
  /// ```
  AbortController({Function onAbort}) {
    _abortCompleter = Completer();

    _signal = AbortSignal(onAbort);
  }

  void abort([String message]) {
    !signal.aborted ? signal.trigger(message) : null;

    !_abortCompleter.isCompleted ? _abortCompleter.complete() : null;
  }

  AbortSignal get signal => _signal;
}
