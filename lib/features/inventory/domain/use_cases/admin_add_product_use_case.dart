import '../../../inventory/data/admin_command_gateway.dart';

class AdminAddProductUseCase {
  final AdminCommandGateway gateway;

  AdminAddProductUseCase(this.gateway);

  Future<void> execute({
    required String productId,
    required String name,
    required String unit,
    required int initialQuantity,
    required int reorderPoint,
    required String productType,
  }) async {
    final command = AdminAddProductCommand(
      productId: productId,
      name: name,
      unit: unit,
      initialQuantity: initialQuantity,
      reorderPoint: reorderPoint,
      productType: productType,
    );

    await gateway.addProduct(command);
  }
}
