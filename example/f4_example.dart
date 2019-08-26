import 'dart:math';
import 'dart:async';
import 'package:f4/f4.dart';

Future sleep(int pnum, {int res, int ms = 500})
{
  pnum ??= 1;

  print('run #$pnum');

  return Future.delayed(Duration(milliseconds: Random().nextInt(ms) + ms))
        .then((_)=>pnum+(res ?? 0));
}

timeout(int s, Function fn)=>
  Timer(Duration(seconds:s), ()=> Function.apply(fn, null));


main() async
{
  List<Function> chain = [
    ()=>sleep(1),
    (int res)=>sleep(2, res:res),
    (int res)=>sleep(3, res:res),
    (int res)=>sleep(4, res:res)
  ];

  List<Function> list = [
    ()=>sleep(1),
    ()=>sleep(2),
    ()=>sleep(3),
    ()=>sleep(4),
  ];

  Map<String, Function> props = {
    'a': ()=>sleep(1),
    'b': ()=>sleep(2),
    'c': ()=>sleep(3),
    'd': ()=>sleep(4)
  };

  print('---forEach---');
  print(await F4.forEach(list));

  print('\n---chain---');
  print(await F4.chain(chain));

  print('\n---all---');
  print(await F4.all(list, concurrency:2));

  print('\n---one---');
  print(await F4.one(list[0]));

  print('\n---props---');
  print(await F4.props(props, concurrency:2));

  print('\n---map---');
  print(await F4.map([1,2,3,4], sleep, concurrency:2));

  print('\n---abort:onAbort---');
  final ctl1 = AbortController(onAbort:(e)=>print('onAbort: $e'));
  timeout(1, ()=>ctl1.abort('cancel'));
  final v = await F4.chain(chain, abortSignal:ctl1.signal);
  print('************* $v');

  print('\n---abort:catch---');
  final ctl2 = AbortController();
  timeout(1, ()=>ctl2.abort('cancel'));
  try {
    await F4.forEach(list, abortSignal:ctl2.signal);
  } catch(e) { print('catch: $e'); };

  print('\n---create---');
  print(await F4.create((resolve, reject)=>timeout(1, ()=>resolve(1))));

  try {
    await F4.create((resolve, reject)=>
      timeout(1, ()=>reject(RejectionError(message:'foo'))));
  } catch(e) { print(e.runtimeType);}


  print('\n---reflect---');
  print(await F4.reflect(Future.value(1)));
  print(await F4.reflect(Future.error('err')));
}
