part of 'admin_inventory_bloc.dart';

enum RestockStatus { initial, submitting, success, failure }

class AdminInventoryState extends Equatable {
  final List<dynamic> products; // Placeholder for product list
  final RestockStatus restockStatus;
  final String? errorMessage;

  const AdminInventoryState({
    this.products = const [],
    this.restockStatus = RestockStatus.initial,
    this.errorMessage,
  });

  AdminInventoryState copyWith({
    List<dynamic>? products,
    RestockStatus? restockStatus,
    String? errorMessage,
  }) {
    return AdminInventoryState(
      products: products ?? this.products,
      restockStatus: restockStatus ?? this.restockStatus,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [products, restockStatus, errorMessage];
}
