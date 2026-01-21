import 'package:narayan_system_core/narayan_system_core.dart';
import 'package:supply_inventory/supply_inventory.dart';

/// Orchestrator for Admin-specific Supply Inventory operations.
///
/// This wrapper encapsulates logic that requires coordination between
/// the System Core's components and Admin-specific requirements,
/// cleaning up UseCases from domain logic details.
class AdminSupplyOrchestrator {
  final SupplyFlowOrchestrator _coreOrchestrator;
  final EventBusPort _eventBus;

  AdminSupplyOrchestrator(this._coreOrchestrator, this._eventBus);

  /// Restocks inventory for a specific product.
  ///
  /// Delegates to the core InventoryService to replenish stock,
  /// then collects and emits any resulting domain events.
  void restockInventory({required String productId, required double quantity}) {
    if (quantity <= 0) {
      throw ArgumentError('Quantity must be positive');
    }

    final inventory = _coreOrchestrator.inventoryService.inventory;

    // Delegate to Core
    inventory.replenishStock(ProductId(productId), Quantity(quantity.toInt()));

    // Collect and Emit Domain Events
    final events = inventory.collectDomainEvents();
    for (final event in events) {
      _eventBus.emit(event);
    }
  }
}
