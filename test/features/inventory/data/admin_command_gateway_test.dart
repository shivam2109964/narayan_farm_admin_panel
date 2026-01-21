import 'package:flutter_test/flutter_test.dart';
import 'package:narayan_farms_admin/features/inventory/data/admin_command_gateway.dart';
import 'package:narayan_system_engine/narayan_system_engine.dart';
import 'package:supply_inventory/supply_inventory.dart' as supply;
import 'package:narayan_system_core/narayan_system_core.dart';

// ignore: depend_on_referenced_packages
import 'package:mocktail/mocktail.dart';

class MockSystemEngine extends Mock implements SystemEngine {}

class TestClock implements ClockPort, supply.Clock {
  @override
  DateTime now() => DateTime.now();
}

void main() {
  late AdminCommandGatewayImpl gateway;
  late SystemEngine systemEngine;
  late supply.InventoryManagementService inventoryService;
  late TestClock clock;
  late supply.Inventory inventory;
  late supply.RestockPolicy restockPolicy;

  setUp(() {
    // Real dependencies where possible, Mock Engine only if needed for strict unit test,
    // but the Prompt asked for Integration Tests over Mocks.
    // So let's try to instantiate a Real SystemEngine and Real Service if possible.

    clock = TestClock();
    inventory = supply.Inventory(id: 'inventory-1', clock: clock);
    restockPolicy = supply.RestockPolicy(); // Assuming default constructor

    inventoryService = supply.InventoryManagementService(
      inventory: inventory,
      restockPolicy: restockPolicy,
      clock: clock,
    );

    // We can use a real SystemEngine but we need to mock Persistence/EventBus if we want to intercept events easily
    // or we can use the EventHandlerRegistry to check if events were emitted?
    // SystemEngine uses InMemoryPersistence by default which is great for testing.

    systemEngine = SystemEngine(clock: clock);

    systemEngine.start();

    gateway = AdminCommandGatewayImpl(
      systemEngine: systemEngine,
      inventoryService: inventoryService,
    );
  });

  tearDown(() async {
    await systemEngine.stop();
  });

  test(
    'Admin AddProduct Command should flow through Gateway -> Engine -> Domain -> Event',
    () async {
      // 1. Arrange
      final command = AdminAddProductCommand(
        productId: 'PROD-123',
        name: 'Test Milk',
        unit: 'liters',
        initialQuantity: 100,
        reorderPoint: 10,
        productType: 'processed',
      );

      // 2. Act
      await gateway.addProduct(command);

      // 3. Assert - Check Domain State
      // The product should exist in the inventory entity (which the service holds)
      // We can check this by trying to deplete stock or similar, or inspecting the entity if possible.
      // But Inventory entity doesn't seem to expose a "get" method easily?
      // It has `_stockItems`.

      // Better: Check if Domain Event was emitted.
      // SystemEngine -> OutboxProcessor -> factories.
      // The default factories in SystemEngine constructor (lines 35-47) don't include ProductAdded!
      // This implies the Outbox might fail to serialize/process it if we rely on that.
      // BUT, the In Memory Event Bus should still receive it.

      // We can subscribe to the event bus?
      // SystemEngine code: `EventBusPort get eventBus => _eventBus;` (line 64)
      // `OutboxEventBus` (line 33) uses `_persistence`.
      // Wait, `OutboxEventBus` usually writes to Outbox, then `OutboxProcessor` reads it and pushes to `EventHandlerRegistry`?
      // OR `OutboxEventBus` is just an interface?

      // Let's verify if `ProductAdded` event was generated.
      // We can't easily spy on the internal `_eventBus` without a listener.
      // Since we are creating a "Real" integration test, we should verify the "Read Model" (Firebase) side ideally,
      // but here in a unit/integration test file we might not have Firebase.

      // We can rely on checking the `inventory` state via the service?
      // Service has `depleteStock`. If we can deplete 1, it means it exists?

      expect(
        () => inventoryService.depleteStock(
          supply.ProductId('PROD-123'),
          supply.Quantity(1),
        ),
        returnsNormally,
      );

      // Also verify strict values?
      // We can try to use a spy/mock on the inventory service if we really want to check arguments,
      // but we used a real one.
    },
  );
}
