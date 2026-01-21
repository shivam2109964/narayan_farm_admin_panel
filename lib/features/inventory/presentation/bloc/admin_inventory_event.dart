part of 'admin_inventory_bloc.dart';

sealed class AdminInventoryEvent extends Equatable {
  const AdminInventoryEvent();

  @override
  List<Object> get props => [];
}

class RestockInventoryPressed extends AdminInventoryEvent {
  final String productId;
  final String quantityStr; // Text input from UI

  const RestockInventoryPressed({
    required this.productId,
    required this.quantityStr,
  });

  @override
  List<Object> get props => [productId, quantityStr];
}
