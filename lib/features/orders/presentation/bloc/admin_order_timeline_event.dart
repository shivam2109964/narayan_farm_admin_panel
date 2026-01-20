part of 'admin_order_timeline_bloc.dart';

sealed class AdminOrderTimelineEvent extends Equatable {
  const AdminOrderTimelineEvent();

  @override
  List<Object> get props => [];
}

class SubscribeToOrderEvents extends AdminOrderTimelineEvent {}

class OrderEventReceived extends AdminOrderTimelineEvent {
  final dynamic event;

  const OrderEventReceived(this.event);

  @override
  List<Object> get props => [event];
}
