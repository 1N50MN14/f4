## A Future with some added sugar.

A set of Future helper functions (mostly) compatible with Node.js counterpart
Promise libraries such as Bluebird. Supports concurrency & cancellation.

The library exposes static methods under a single class `F4` (pronounced
*Future*) to avoid accendential pollution of the global namespace, maybe a bit
of an anti-pattern in Dart land, then again maybe some of helpers should have
been natively supported by Dart itself.

Currently supports the following helper methods: `all`, `map`, `chain`, `props`,
`one`, `forEach`, `create`, and `reflect`.

The `AbortController` class exposes means for cancellation of Futures and is
compatible with its Fetch API counterpart.

PS: Not tested in production, written over a weekend for me to learn Dart, PRs
are welcome.

## Usage
A simple usage example:

```dart
import 'package:f4/f4.dart';

main() async
{
  final r = await F4.map([1, 2, 3, 4], (int i)=>Future.value(i), concurrency:2);
  print(r); //[1, 2, 3, 4]
}
```

Complete usage example under [/example][example].

[example]: https://github.com/1N50MN14/f4/tree/master/example

## Features and bugs

Please file feature requests and bugs at the [issue tracker][tracker].

[tracker]: https://github.com/1N50MN14/f4/issues
