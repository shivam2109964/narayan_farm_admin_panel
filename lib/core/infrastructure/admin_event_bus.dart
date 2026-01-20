import 'dart:async';
import 'package:narayan_system_core/narayan_system_core.dart';

/// **AdminEventBus**
///
/// An implementation of [EventBusPort] that exposes a [Stream]
/// of all events for the Admin Panel to observe.
class AdminEventBus implements EventBusPort {
  final _controller = StreamController<dynamic>.broadcast();

  /// Stream of all system events
  Stream<dynamic> get stream => _controller.stream;

  @override
  void emit(event) {
    _controller.add(event);
  }

  void dispose() {
    _controller.close();
  }
}
