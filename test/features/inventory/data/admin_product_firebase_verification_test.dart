import 'package:flutter_test/flutter_test.dart';
import 'package:narayan_farms_admin/features/inventory/data/admin_command_gateway.dart';
import 'package:narayan_system_engine/narayan_system_engine.dart';
import 'package:supply_inventory/supply_inventory.dart' as supply;
import 'package:narayan_system_core/narayan_system_core.dart';
import 'package:inventory_firebase_adapter/listeners/inventory_event_listener.dart';
import 'package:inventory_firebase_adapter/repositories/inventory_firebase_repository.dart';
import 'package:mocktail/mocktail.dart';

// Mocks
class MockInventoryFirebaseRepository extends Mock
    implements InventoryFirebaseRepository {}

class MockEventHandlerRegistry extends Mock implements EventHandlerRegistry {}

class TestClock implements ClockPort, supply.Clock {
  @override
  DateTime now() => DateTime(2023, 1, 1, 12, 0, 0);
}

// Simple projector wrapper (same as in main.dart)
class _SimpleProjector<T> {
  final Future<void> Function(T) _handler;
  _SimpleProjector(this._handler);

  Future<void> project(T event) => _handler(event);
}

void main() {
  late AdminCommandGatewayImpl gateway;
  late SystemEngine systemEngine;
  late supply.InventoryManagementService inventoryService;
  late TestClock clock;
  late supply.Inventory inventory;
  late supply.RestockPolicy restockPolicy;

  late MockInventoryFirebaseRepository mockRepo;
  late InventoryEventListener inventoryListener;
  late EventHandlerRegistry eventRegistry;

  setUpAll(() {
    registerFallbackValue(
      supply.StockItem(
        productId: supply.ProductId('FALLBACK-1'),
        initialQuantity: supply.Quantity(0),
        unit: supply.Unit('units'),
        reorderPoint: supply.Quantity(0),
        productType: supply.ProductType.raw,
      ),
    );
  });

  setUp(() {
    clock = TestClock();

    // Domain Layer
    inventory = supply.Inventory(id: 'inventory-1', clock: clock);
    restockPolicy = const supply.RestockPolicy();
    inventoryService = supply.InventoryManagementService(
      inventory: inventory,
      restockPolicy: restockPolicy,
      clock: clock,
    );

    // Infrastructure Layer (Mocks)
    mockRepo = MockInventoryFirebaseRepository();
    when(
      () => mockRepo.saveItem(
        any(),
        at: any(named: 'at'),
        name: any(named: 'name'),
      ),
    ).thenAnswer((_) async {});

    // Projection Layer (Real Listener)
    inventoryListener = InventoryEventListener(mockRepo);

    // System Engine Layer
    eventRegistry = EventHandlerRegistry();
    systemEngine = SystemEngine(
      clock: clock,
      eventHandlerRegistry: eventRegistry,
    );

    // Register PROJECTOR (This connects Engine -> Listener)
    eventRegistry.register('ProductAdded', [
      _SimpleProjector<supply.ProductAdded>((event) async {
        await inventoryListener.handle(event);
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
    'Gateway addProduct should invoke Firebase Repository saveItem with correct data',
    () async {
      // Arrange
      final command = AdminAddProductCommand(
        productId: 'PROD-FIREBASE-VERIFY',
        name: 'Firebase Verification Milk',
        unit: 'liters',
        initialQuantity: 75,
        reorderPoint: 15,
        productType: 'processed',
      );

      // Act
      await gateway.addProduct(command);

      // Wait for OutboxProcessor (runs every 100ms)
      await Future.delayed(const Duration(milliseconds: 200));

      // Assert - Verify Mock Interaction
      // verification of: await _repo.saveItem(...)
      verify(
        () => mockRepo.saveItem(
          any(
            that: isA<supply.StockItem>()
                .having(
                  (s) => s.productId.value,
                  'productId',
                  'PROD-FIREBASE-VERIFY',
                )
                .having((s) => s.quantity.value, 'quantity', 75)
                .having(
                  (s) => s.productType,
                  'productType',
                  supply.ProductType.processed,
                ),
          ),
          at: any(named: 'at'),
          name: 'Firebase Verification Milk',
        ),
      ).called(1);
    },
  );
}
