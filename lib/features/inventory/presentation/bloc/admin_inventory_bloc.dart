import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:narayan_farms_admin/features/inventory/domain/use_cases/admin_restock_inventory_use_case.dart';

part 'admin_inventory_event.dart';
part 'admin_inventory_state.dart';

class AdminInventoryBloc
    extends Bloc<AdminInventoryEvent, AdminInventoryState> {
  final AdminRestockInventoryUseCase _restockUseCase;

  AdminInventoryBloc({required AdminRestockInventoryUseCase restockUseCase})
    : _restockUseCase = restockUseCase,
      super(const AdminInventoryState()) {
    on<RestockInventoryPressed>(_onRestockPressed);
  }

  Future<void> _onRestockPressed(
    RestockInventoryPressed event,
    Emitter<AdminInventoryState> emit,
  ) async {
    emit(state.copyWith(restockStatus: RestockStatus.submitting));

    final quantity = double.tryParse(event.quantityStr);

    if (quantity == null) {
      emit(
        state.copyWith(
          restockStatus: RestockStatus.failure,
          errorMessage: 'Invalid quantity',
        ),
      );
      return;
    }

    final result = await _restockUseCase.execute(
      RestockInventoryInput(productId: event.productId, quantity: quantity),
    );

    if (result.success) {
      emit(
        state.copyWith(
          restockStatus: RestockStatus.success,
          errorMessage: null,
        ),
      );
    } else {
      emit(
        state.copyWith(
          restockStatus: RestockStatus.failure,
          errorMessage: result.errorMessage ?? 'Restock failed',
        ),
      );
    }
  }
}
