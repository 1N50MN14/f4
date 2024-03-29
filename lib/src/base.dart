import 'dart:async';
import 'package:meta/meta.dart';
import 'reflect.dart';
import 'task.dart';
import 'abort.dart';

abstract class Base {
  late StreamController controller;

  StreamSubscription? _sub;

  late Stream _stream;

  AbortSignal? _abortSignal;

  int? _concurrency;

  final Completer _completer = Completer();

  bool? _cancelOnError;

  @required
  late Iterable<Iterable<Task>> _chunks;

  Base(List<dynamic> tasks, {
    AbortSignal? abortSignal,
    int? concurrency,
    bool? cancelOnError
  })
  {
    _cancelOnError = cancelOnError ?? true;

    _abortSignal = abortSignal;

    _concurrency =
        concurrency == null || concurrency < 0 ? tasks.length : concurrency;

    _chunks = _chunkTasks(
        tasks.map((Object? t) =>
            _prepareTask(t is Task ? t : Task(t as Function?), tasks.indexOf(t))),
        _concurrency);

    _stream = Stream.fromIterable(_chunks);

    controller = _stream.isBroadcast
        ? StreamController.broadcast(
            onListen: _listen, onCancel: _cancel, sync: true)
        : StreamController(
            onListen: _listen,
            onCancel: _cancel,
            sync: true,
            onPause: _pause,
            onResume: _resume);
  }

  Task _prepareTask(Task t, Object id) => t
    ..meta!['index'] = t.meta!['index'] ?? id
    ..setSignal(_abortSignal);

  Iterable<Iterable<Task>> _chunkTasks(Iterable<Task> t, int? s)
  {
    if(t.isEmpty || s == 0) {
      return Iterable<Iterable<Task>>.empty();
    }

    return Iterable.generate((t.length / s!).ceil(),
      (i) => t.skip(i * s).take(s == 1 ? 1 : i * s + s));
  }

  Future _runTask(Task t) async => await t.run();

  Future run() {
    stream.listen(_onData,
        onDone: _onDone, onError: _completeError, cancelOnError: _cancelOnError);

    return _completer.future;
  }

  void _onData(data) => null;

  void _onDone() => _complete();

  void _next(Iterable<Task> chunk) async {
    _pause();

    Stream.fromFutures(chunk.map((t) => _runTask(t))).listen(
        (r) => r.isError ? _error(r.error, r.stackTrace) : _add(r),
        onError: _error,
        onDone: _resume,
        cancelOnError: true);
  }

  void _listen() => _sub =
      _stream.listen((chunk) => _next(chunk), onError: _error, onDone: _close);

  void _add(ReflectedFuture r) => _ctrlAdd(r);

  void _error(Object? e, [StackTrace? s]) => _ctrlAddError(e, s);

  void _ctrlAdd(ReflectedFuture r) =>
      !_closed && !_completed ? controller.add(r) : null;

  void _ctrlAddError(Object? e, [StackTrace? s]) =>
      !_closed && !_completed ? controller.addError(e!, s) : null;

  void _complete([dynamic data]) =>
      !_completed ? _completer.complete(data) : null;

  void _completeError(Object e, [StackTrace? s]) =>
      !_completed ? _completer.completeError(e, s) : null;

  void _close() => controller.close();

  void _pause() => _sub?.pause();

  void _resume() => _sub?.resume();

  void _cancel() => _sub?.cancel();

  bool get _closed => controller.isClosed;

  bool get _completed => _completer.isCompleted;

  bool get abortable => _abortSignal != null;

  Stream get stream => controller.stream;
}

class ForEach extends Base {
  ForEach(Iterable<Function> fns, {AbortSignal? abortSignal, bool? cancelOnError})
    : super(fns.toList(), abortSignal: abortSignal, concurrency: 1,
      cancelOnError:cancelOnError);
}

class Chain extends Base {
  ReflectedFuture? _ref;

  Object? _resp;

  Chain(Iterable<Function> fns, {AbortSignal? abortSignal, bool? cancelOnError})
    : super(fns.toList(), abortSignal: abortSignal, cancelOnError: cancelOnError,
        concurrency: 1);

  @override
  void _onData(data) => _resp = data.value;

  @override
  void _onDone() => _complete(_resp);

  @override
  void _add(ReflectedFuture r) {
    _ref = r;
    _ctrlAdd(r);
  }

  @override
  void _error(Object? e, [StackTrace? s]) {
    _ref = null;
    _ctrlAddError(e, s);
  }

  @override
  Future _runTask(Task t) async =>
      await t.run(t.meta!['index'] == 0 ? null : [_ref?.value], {});
}

class All extends Base {
  final List _resp;

  All(Iterable<Function> fns, {AbortSignal? abortSignal, int? concurrency,
    bool? cancelOnError})
      : _resp = List.filled(fns.length, []),
      super(fns.toList(), abortSignal: abortSignal, concurrency: concurrency,
        cancelOnError:cancelOnError);

  @override
  void _onData(data) => _resp[data.meta['index']] = data.value;

  @override
  void _onDone() => _complete(_resp);
}

class $Map extends Base {
  final List _resp;

  $Map(Iterable<Object> args, Function f, {AbortSignal? abortSignal,
    int? concurrency, bool? cancelOnError})
  : _resp = List.filled(args.length, []),
     super(
      ((List _args, Function _f) sync* {
        for (var i = 0; i < _args.length; i++) {
          yield () async {
            return await _f(_args[i]);
          };
        }
      })(args as List<dynamic>, f)
          .toList(),
      abortSignal: abortSignal,
      concurrency: concurrency,
      cancelOnError:cancelOnError
    );

  @override
  void _onData(data) => _resp[data.meta['index']] = data.value;

  @override
  void _onDone() => _complete(_resp);
}

class Props extends Base {
  final Map<dynamic, dynamic> _resp;

  Props(Map<Object, dynamic> m, {AbortSignal? abortSignal, int? concurrency,
    bool? cancelOnError})
  : _resp = Map.fromEntries(m.keys.map((k) => MapEntry(k, null))),
    super(
    m.keys.fold(
        [],
        (c, k) => c
          ..add((m[k] is Task ? m[k] : Task(m[k])
            ..meta['index'] = k))),
    abortSignal: abortSignal,
    concurrency: concurrency,
    cancelOnError:cancelOnError
  );

  @override
  void _onData(data) => _resp[data.meta['index']] = data.value;

  @override
  void _onDone() => _complete(_resp);
}
