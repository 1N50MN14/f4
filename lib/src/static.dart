import 'dart:async';
import 'abort.dart';
import 'reflect.dart';
import 'error.dart';
import 'base.dart';

/// A class container of all static Future method helpers.
class F4 {
  /// Reflect a Future so that it always completes.
  /// ```
  /// final r = await F4.reflect(Future f);
  ///
  /// print(r.isError ? r.error : r.value);
  /// ```
  static Future<ReflectedFuture> reflect(FutureOr f,
          [Map<Object, dynamic>? m]) =>
      ReflectFuture(f, m);

  /// Iterate through a list of Futures one by one.
  /// ```
  /// await F4.forEach(
  /// [
  ///   ()=>Future.value(1),
  ///   ()=>Future.value(2)
  /// ]);
  /// ```
  static Future forEach(Iterable<Function> fns, {AbortSignal? abortSignal,
    bool? cancelOnError}) => ForEach(fns, abortSignal: abortSignal,
      cancelOnError:cancelOnError).run();

  /// Iterate a list of Futures while passing through results.
  /// ```
  /// await F4.forEach(
  /// [
  ///   ()=>Future.value(1),
  ///   (int r)=>Future.value(r*2)
  /// ]);
  /// ```
  static Future chain(Iterable<Function> fns, {AbortSignal? abortSignal,
    bool? cancelOnError}) => Chain(fns, abortSignal: abortSignal,
      cancelOnError: cancelOnError).run();

  /// Run a single Future.
  /// ```
  /// await F4.one(()=>Future.value(1));
  /// ```
  static Future one(Function fn, {AbortSignal? abortSignal}) =>
      Chain([fn], abortSignal: abortSignal).run();

  /// Conccurently iterate futures (output list is ordered).
  /// ```
  /// await F4.all(
  /// [
  ///   ()=>Future.value(1),
  ///   ()=>Future.value(2),
  ///   ()=>Future.value(3),
  /// ],
  /// concurrency:2);
  /// ```
  static Future all(Iterable<Function> fns,{AbortSignal? abortSignal,
    int? concurrency, bool? cancelOnError}) =>
      All(fns, abortSignal: abortSignal, concurrency: concurrency,
        cancelOnError:cancelOnError).run();

  /// Conccurently generate & iterate futures (output list is ordered).
  /// ```
  /// await F4.map([1,2,3], (int i)=>Future.value(i), concurrency:2);
  /// ```
  static Future map(Iterable<Object> args, Function f, {AbortSignal? abortSignal,
    int? concurrency, bool? cancelOnError}) =>
      $Map(args, f, abortSignal: abortSignal, concurrency: concurrency,
        cancelOnError:cancelOnError).run();

  /// Conccurently iterate futures from Map properties (output Map is ordered).
  /// ```
  /// await F4.props(
  /// {
  ///   'a': ()=>Future.value(1),
  ///   'b': ()=>Future.value(2),
  ///   'c': ()=>Future.value(31),
  /// }, concurrency:2);
  /// ```
  static Future props(Map<Object, dynamic> m, {AbortSignal? abortSignal,
    int? concurrency, bool? cancelOnError}) =>
      Props(m, abortSignal: abortSignal, concurrency: concurrency,
        cancelOnError:cancelOnError).run();

  /// Create a Future from scratch.
  /// ```
  /// await F4.create((resolve, reject)=>()=>resolve(1));
  /// ```
  static Future create(Function fn) {
    final completer = Completer();

    Function.apply(fn, [
      ([dynamic data]) => completer.complete(data),
      ([Object? e, StackTrace? s]) =>
          completer.completeError(e ?? RejectionError(), s)
    ]);

    return completer.future;
  }
}
