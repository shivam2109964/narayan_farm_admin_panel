import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:narayan_system_core/narayan_system_core.dart';
import 'package:narayan_farms_admin/core/infrastructure/admin_event_bus.dart';

part 'admin_order_timeline_event.dart';
part 'admin_order_timeline_state.dart';

class AdminOrderTimelineBloc
    extends Bloc<AdminOrderTimelineEvent, AdminOrderTimelineState> {
  final EventBusPort _eventBus;
  StreamSubscription? _subscription;

  AdminOrderTimelineBloc({required EventBusPort eventBus})
    : _eventBus = eventBus,
      super(AdminOrderTimelineInitial()) {
    on<SubscribeToOrderEvents>(_onSubscribe);
    on<OrderEventReceived>(_onEventReceived);
  }

  Future<void> _onSubscribe(
    SubscribeToOrderEvents event,
    Emitter<AdminOrderTimelineState> emit,
  ) async {
    emit(AdminOrderTimelineLoading());

    // Start with empty list
    emit(const AdminOrderTimelineLoaded(orders: []));

    if (_eventBus is AdminEventBus) {
      // ignore: unnecessary_cast
      final adminBus = _eventBus as AdminEventBus;
      _subscription = adminBus.stream.listen((e) {
        add(OrderEventReceived(e));
      });
    }
  }

  void _onEventReceived(
    OrderEventReceived event,
    Emitter<AdminOrderTimelineState> emit,
  ) {
    if (state is! AdminOrderTimelineLoaded) return;

    final currentOrders = Map<String, OrderTimelineUIModel>.fromIterable(
      (state as AdminOrderTimelineLoaded).orders,
      key: (order) => order.orderId,
      value: (order) => order,
    );

    final e = event.event;
    final eventType = e.runtimeType.toString();

    // Handle different event types from system core
    // For now, we'll handle events generically by type name
    // This is READ-ONLY - we only observe and display

    if (eventType.contains('OrderPlaced') ||
        eventType.contains('OrderCreated')) {
      // Extract order data if possible
      // Since we don't have direct access to event structure, we'll add a placeholder
      // Real implementation would properly deserialize the event
      final now = DateTime.now();
      final orderId = 'ORDER-${now.millisecondsSinceEpoch}';

      currentOrders[orderId] = OrderTimelineUIModel(
        orderId: orderId,
        customerId: 'CUSTOMER-UNKNOWN',
        currentStatus: OrderStatusUI.created,
        history: [
          TimelineEntry(
            status: OrderStatusUI.created,
            timestamp: now,
            description: 'Order created - Event: $eventType',
          ),
        ],
      );
    }

    // Emit updated state with sorted orders (newest first)
    final sortedOrders = currentOrders.values.toList()
      ..sort(
        (a, b) =>
            b.history.first.timestamp.compareTo(a.history.first.timestamp),
      );

    emit(AdminOrderTimelineLoaded(orders: sortedOrders));
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
