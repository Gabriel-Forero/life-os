import 'dart:async';

import 'package:life_os/core/domain/app_event.dart';

class EventBus {
  final StreamController<AppEvent> _controller =
      StreamController<AppEvent>.broadcast();

  bool _disposed = false;

  void emit(AppEvent event) {
    if (_disposed) return;
    _controller.add(event);
  }

  Stream<T> on<T extends AppEvent>() {
    if (_disposed) return const Stream.empty();
    return _controller.stream.where((event) => event is T).cast<T>();
  }

  void dispose() {
    _disposed = true;
    _controller.close();
  }
}
