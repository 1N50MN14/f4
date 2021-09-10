import 'dart:math';
import 'dart:async';
import 'package:f4/f4.dart';
import 'package:test/test.dart';

Future sleep(int pnum, {int? res, int ms = 500})
{
  print('run #$pnum');

  return Future.delayed(Duration(milliseconds: Random().nextInt(ms) + ms))
        .then((_)=>pnum+(res ?? 0));
}

void timeout(int s, Function fn)=>
  Timer(Duration(seconds:s), ()=> Function.apply(fn, null));

void main() {
  group('', () {
    ReflectedFuture r;

    final chain =
    <Function>[
      ()=>sleep(1),
      (int res)=>sleep(2, res:res),
      (int res)=>sleep(3, res:res),
      (int res)=>sleep(4, res:res)
    ];

    var list =
    [
      ()=>sleep(1),
      ()=>sleep(2),
      ()=>sleep(3),
      ()=>sleep(4),
    ];

    var props =
    {
      'a': ()=>sleep(1),
      'b': ()=>sleep(2),
      'c': ()=>sleep(3),
      'd': ()=>sleep(4)
    };

    setUp(() {});


    test('reflect: Reflect a future that completes',
    () async {
      r = await F4.reflect(Future.value(1));
      expect(r.isError, isFalse);
    });

    test('reflect: Reflect a future that errors',
    () async {
      r = await F4.reflect(Future.error('err'));
      expect(r.isError, isTrue);
    });

    test('create->resolve: Create and manually resolve a new future',
    () async {
      r = await F4.reflect(F4.create((resolve, reject)=>
        timeout(1, ()=>resolve())));

      expect(r.value, null);
    });

    test('create->reject: Create and manually reject a new future',
    () async {
      r = await F4.reflect(F4.create((resolve, reject)=>
        timeout(1, ()=>reject())));

      expect(r.isError, true);
    });

    test('forEach: Serially run a list of futures',
    () async {
      final v = await F4.forEach(list, cancelOnError: true);
      print('output: $v');
      expect(v, null);
    });

    test('chain: Serially run a future chain passing through responses',
    () async {
      final v = await F4.chain(chain);
      print('output: $v');
      expect(v, 10);
    });

    test('one: Run a single future and return its result',
    () async {
      final v = await F4.one(list[0]);
      print('output: $v');
      expect(v, 1);
    });

    test('all: Run all futures with concurrently & return result in order',
    () async {
      final v = await F4.all(list, concurrency: 2);
      print('output: $v');
      expect(v, [1,2,3,4]);
    });

    test('map: Generate from iterable, run concurrently & return result in order',
    () async {
      final v = await F4.map([1,2,3,4], sleep, concurrency: 2);
      print('output: $v');
      expect(v, [1,2,3,4]);
    });

    test('props: Concurrently run futures from Map props & return ordered Map ',
    () async {
      final v = await F4.props(props, concurrency:2);
      print('output: $v');
      expect(v, {'a':1,'b':2,'c':3,'d':4});
    });

    test('AbortController(onAbort)->abort: Abort without throwing an AbortError',
    () async {
      final ctl1 = AbortController(onAbort:(e)=>print('onAbort: $e'));
      timeout(1, ()=>ctl1.abort('cancel'));
      final v = await F4.reflect(F4.chain(chain, abortSignal:ctl1.signal));
      expect(v.isError, isFalse);
    });

    test('AbortController()->abort: Abort & throw an AbortError',
    () async {
      final ctl1 = AbortController();
      timeout(1, ()=>ctl1.abort('cancel'));
      final v = await F4.reflect(F4.chain(chain, abortSignal:ctl1.signal));
      print(v.error);
      expect(v.isError, isTrue);
    });

  });
}
