import 'dart:async' show Future, FutureOr;

/// @nodoc
Future<ReflectedFuture>
  ReflectFuture(FutureOr f,  [Map<Object, dynamic> meta]) async
{
  return f is Future

        ? f.then((v)=>ReflectedFuture(value:v, meta:meta),
                      onError:(e, s)=>
                        ReflectedFuture(error:e, stackTrace:s, meta:meta))

        : Future.value(ReflectedFuture(value:f, meta:meta));
}

/// A class representation of a reflected Future.
class ReflectedFuture
{
  final Object error;

  final StackTrace stackTrace;

  final dynamic value;

  final Map<Object, dynamic> meta;

  ReflectedFuture({
    this.value,
    this.error,
    this.stackTrace,
    this.meta
  });

  @override
  String toString() =>
  [
    'isError:$isError',
    'error:$error',
    'stacktrace:$stackTrace',
    'value:$value',
    meta == null ? '' : 'meta:$meta'
  ].join(' ');

  bool get isError => this.error != null;
}
