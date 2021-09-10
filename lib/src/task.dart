import 'dart:async';
import 'package:meta/meta.dart';
import 'abort.dart';
import 'reflect.dart';

class Task {
  @required
  final Function? _func;

  AbortSignal? _abortSignal;

  Completer? _cmp;

  ReflectedFuture? response;

  Map<Object, dynamic>? _meta;

  bool isolate = false;

  bool isSerial = false;

  Task(Function? func, {AbortSignal? abortSignal, Map<Object, dynamic>? meta})
      : _func = func {
    _cmp = Completer();

    abortSignal != null ? setSignal(abortSignal) : null;

    _meta = meta ?? {};
  }

  Future run([List? argp, Map<String, dynamic>? argn]) async {
    argp ??= [];


    if (!completed) {
      response = await ReflectFuture(Function.apply(_func!,
        argp, argn == null || argn.isEmpty
        ? {}
        : Map.fromEntries(argn.entries.map((e) => MapEntry(Symbol(e.key), e.value)))),
      _meta);

      !completed ? _cmp!.complete(response) : null;
    }

    return _cmp!.future;
  }

  void setSignal([AbortSignal? signal]) {
    if (signal != null) {
      _abortSignal = signal;

      _abortSignal!.addCompleter(_cmp);
    }
  }

  // ignore: unnecessary_getters_setters
  set meta(Map<Object, dynamic>? meta) => _meta = meta;

  // ignore: unnecessary_getters_setters
  Map<Object, dynamic>? get meta => _meta;

  bool get completed => _cmp!.isCompleted;

  bool get hasAbortSignal => _abortSignal != null;
}
