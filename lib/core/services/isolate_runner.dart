import 'dart:isolate';

class IsolateRunner {
  static Future<T> run<T>(T Function() computation) =>
      Isolate.run(computation);
}
