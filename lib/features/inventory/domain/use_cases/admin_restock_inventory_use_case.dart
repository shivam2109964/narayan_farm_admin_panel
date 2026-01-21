import 'package:narayan_farms_admin/features/inventory/domain/orchestrator/admin_supply_orchestrator.dart';

class RestockInventoryInput {
  final String productId;
  final double quantity;

  RestockInventoryInput({required this.productId, required this.quantity});
}

class RestockInventoryOutput {
  final bool success;
  final String? errorMessage;

  RestockInventoryOutput({required this.success, this.errorMessage});

  factory RestockInventoryOutput.success() =>
      RestockInventoryOutput(success: true);

  factory RestockInventoryOutput.failure(String message) =>
      RestockInventoryOutput(success: false, errorMessage: message);
}

class AdminRestockInventoryUseCase {
  final AdminSupplyOrchestrator _orchestrator;

  AdminRestockInventoryUseCase(this._orchestrator);

  Future<RestockInventoryOutput> execute(RestockInventoryInput input) async {
    try {
      _orchestrator.restockInventory(
        productId: input.productId,
        quantity: input.quantity,
      );

      return RestockInventoryOutput.success();
    } catch (e) {
      // Create user-safe error message
      // Strip technical details if necessary, for now we pass the message
      // as domain errors are usually readable (e.g. "Product not found")
      return RestockInventoryOutput.failure(e.toString());
    }
  }
}
