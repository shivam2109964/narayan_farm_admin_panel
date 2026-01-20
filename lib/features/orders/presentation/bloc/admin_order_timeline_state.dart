part of 'admin_order_timeline_bloc.dart';

enum OrderStatusUI { created, assigned, delivered, failed, unknown }

class TimelineEntry extends Equatable {
  final OrderStatusUI status;
  final DateTime timestamp;
  final String description;

  const TimelineEntry({
    required this.status,
    required this.timestamp,
    required this.description,
  });

  @override
  List<Object> get props => [status, timestamp, description];
}

class OrderTimelineUIModel extends Equatable {
  final String orderId;
  final String customerId;
  final OrderStatusUI currentStatus;
  final List<TimelineEntry> history;

  const OrderTimelineUIModel({
    required this.orderId,
    required this.customerId,
    required this.currentStatus,
    required this.history,
  });

  OrderTimelineUIModel copyWith({
    String? orderId,
    String? customerId,
    OrderStatusUI? currentStatus,
    List<TimelineEntry>? history,
  }) {
    return OrderTimelineUIModel(
      orderId: orderId ?? this.orderId,
      customerId: customerId ?? this.customerId,
      currentStatus: currentStatus ?? this.currentStatus,
      history: history ?? this.history,
    );
  }

  @override
  List<Object> get props => [orderId, customerId, currentStatus, history];
}

sealed class AdminOrderTimelineState extends Equatable {
  const AdminOrderTimelineState();

  @override
  List<Object> get props => [];
}

class AdminOrderTimelineInitial extends AdminOrderTimelineState {}

class AdminOrderTimelineLoading extends AdminOrderTimelineState {}

class AdminOrderTimelineLoaded extends AdminOrderTimelineState {
  final List<OrderTimelineUIModel> orders;

  const AdminOrderTimelineLoaded({this.orders = const []});

  @override
  List<Object> get props => [orders];
}

class AdminOrderTimelineError extends AdminOrderTimelineState {
  final String message;

  const AdminOrderTimelineError(this.message);

  @override
  List<Object> get props => [message];
}
