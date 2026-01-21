import 'package:flutter_test/flutter_test.dart';
import 'package:narayan_farms_admin/features/inventory/data/admin_command_gateway.dart';
import 'package:narayan_system_engine/narayan_system_engine.dart';
import 'package:supply_inventory/supply_inventory.dart' as supply;
import 'package:narayan_system_core/narayan_system_core.dart';
import 'package:mocktail/mocktail.dart';

// Mocks
class MockEventHandlerRegistry extends Mock implements EventHandlerRegistry {}

class TestClock implements ClockPort, supply.Clock {
  @override
  DateTime now() => DateTime(2023, 1, 1, 12, 0, 0);
}

void main() {
  late AdminCommandGatewayImpl gateway;
  late SystemEngine systemEngine;
  late supply.InventoryManagementService inventoryService;
  late TestClock clock;
  late supply.Inventory inventory;
  late supply.RestockPolicy restockPolicy;
  late EventHandlerRegistry eventRegistry;

  // Captures published events
  final List<Object> publishedEvents = [];

  setUp(() {
    publishedEvents.clear();
    clock = TestClock();

    // Domain Layer
    inventory = supply.Inventory(id: 'inventory-1', clock: clock);
    restockPolicy = const supply.RestockPolicy();
    inventoryService = supply.InventoryManagementService(
      inventory: inventory,
      restockPolicy: restockPolicy,
      clock: clock,
    );

    // System Engine Layer
    // We use a real registry but we will register a spy handler
    eventRegistry = EventHandlerRegistry();

    systemEngine = SystemEngine(
      clock: clock,
      eventHandlerRegistry: eventRegistry,
    );

    // Spy listener
    eventRegistry.register('ProductAdded', [
      _SimpleProjector((event) async {
        if (event != null) {
          publishedEvents.add(event as Object);
        }
      }),
    ]);

    systemEngine.start();

    // Data Layer
    gateway = AdminCommandGatewayImpl(
      systemEngine: systemEngine,
      inventoryService: inventoryService,
    );
  });

  tearDown(() async {
    await systemEngine.stop();
  });

  test(
    'Gateway addProduct should trigger ProductAdded domain event in SystemEngine',
    () async {
      // Arrange
      final command = AdminAddProductCommand(
        productId: 'PROD-PIPELINE-TEST',
        name: 'Test Pipeline Milk',
        unit: 'liters',
        initialQuantity: 50,
        reorderPoint: 5,
        productType: 'processed',
      );

      // Act
      await gateway.addProduct(command);

      // Wait for OutboxProcessor (runs every 100ms)
      await Future.delayed(const Duration(milliseconds: 200));

      // Assert - State Check
      // 1. Verify Inventory was updated (In-Memory Check)
      expect(
        inventory.getStock(supply.ProductId('PROD-PIPELINE-TEST')),
        equals(supply.Quantity(50)),
        reason: 'Inventory should be updated in memory',
      );

      // Assert - Event Check
      // 2. Verify Event was published to registry
      // This MUST pass for the pipeline to work
      expect(
        publishedEvents,
        isNotEmpty,
        reason: 'ProductAdded event should be published',
      );

      final event = publishedEvents.first;
      expect(event, isA<supply.ProductAdded>());
      final productAdded = event as supply.ProductAdded;

      expect(productAdded.productId.value, equals('PROD-PIPELINE-TEST'));
      expect(productAdded.initialQuantity.value, equals(50));
    },
  );
}

// Simple wrapper to match the Projector interface expected by registry
class _SimpleProjector<T> {
  final Future<void> Function(T) _handler;
  _SimpleProjector(this._handler);

  Future<void> project(T event) => _handler(event);
}
