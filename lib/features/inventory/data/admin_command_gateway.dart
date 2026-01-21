import 'package:narayan_system_engine/narayan_system_engine.dart';
import 'package:narayan_system_core/narayan_system_core.dart';
import 'package:supply_inventory/supply_inventory.dart';

/// Pure intent object for adding a product.
class AdminAddProductCommand {
  final String productId;
  final String name;
  final String unit;
  final int initialQuantity;
  final int reorderPoint;
  final String productType;

  AdminAddProductCommand({
    required this.productId,
    required this.name,
    required this.unit,
    required this.initialQuantity,
    required this.reorderPoint,
    required this.productType,
  });
}

abstract class AdminCommandGateway {
  Future<void> addProduct(AdminAddProductCommand command);
}

class AdminCommandGatewayImpl implements AdminCommandGateway {
  final SystemEngine systemEngine;
  final InventoryManagementService inventoryService;

  AdminCommandGatewayImpl({
    required this.systemEngine,
    required this.inventoryService,
  });

  @override
  Future<void> addProduct(AdminAddProductCommand command) async {
    final input = AddProductInput(
      productId: command.productId,
      name: command.name,
      unit: command.unit,
      initialQuantity: command.initialQuantity,
      reorderPoint: command.reorderPoint,
      productType: command.productType,
    );

    final result = await systemEngine.addProduct(
      input,
      inventoryService: inventoryService,
    );

    if (!result.success) {
      throw Exception('Failed to add product: ${result.errorMessage}');
    }
  }
}
