import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:narayan_farms_admin/features/inventory/data/admin_command_gateway.dart';
import 'package:narayan_system_engine/narayan_system_engine.dart';
import 'package:supply_inventory/supply_inventory.dart' as supply;
import 'package:narayan_system_core/narayan_system_core.dart';
import 'package:inventory_firebase_adapter/listeners/inventory_event_listener.dart';
import 'package:inventory_firebase_adapter/repositories/inventory_firebase_repository.dart';

// --------------------------------------------------------------------------
// SETUP: REAL IMPLEMENTATIONS WITH FAKE INFRASTRUCTURE
// --------------------------------------------------------------------------

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

  late FakeFirebaseFirestore fakeFirestore;
  late InventoryFirebaseRepository realRepo;
  late InventoryEventListener inventoryListener;
  late EventHandlerRegistry eventRegistry;

  setUp(() {
    clock = TestClock();
    fakeFirestore = FakeFirebaseFirestore();

    // ----------------------------------------------------------------------
    // 1. DATA LAYER (REAL REPOSITORY, FAKE DB)
    // ----------------------------------------------------------------------
    realRepo = InventoryFirebaseRepository(firestore: fakeFirestore);

    // ----------------------------------------------------------------------
    // 2. PROJECTION LAYER (REAL LISTENER)
    // ----------------------------------------------------------------------
    inventoryListener = InventoryEventListener(realRepo);

    // ----------------------------------------------------------------------
    // 3. EVENT HANDLER REGISTRY (WIRING)
    // ----------------------------------------------------------------------
    eventRegistry = EventHandlerRegistry();
    eventRegistry.register('ProductAdded', [
      _SimpleProjector<supply.ProductAdded>((event) async {
        await inventoryListener.handle(event);
      }),
    ]);

    // ----------------------------------------------------------------------
    // 4. DOMAIN LAYER (REAL)
    // ----------------------------------------------------------------------
    inventory = supply.Inventory(id: 'inventory-live-test', clock: clock);
    restockPolicy = const supply.RestockPolicy();
    inventoryService = supply.InventoryManagementService(
      inventory: inventory,
      restockPolicy: restockPolicy,
      clock: clock,
    );

    // ----------------------------------------------------------------------
    // 5. SYSTEM ENGINE LAYER (REAL)
    // ----------------------------------------------------------------------
    systemEngine = SystemEngine(
      clock: clock,
      eventHandlerRegistry: eventRegistry,
    );
    systemEngine.start();

    // ----------------------------------------------------------------------
    // 6. ADAPTER LAYER (REAL GATEWAY)
    // ----------------------------------------------------------------------
    gateway = AdminCommandGatewayImpl(
      systemEngine: systemEngine,
      inventoryService: inventoryService,
    );
  });

  tearDown(() async {
    await systemEngine.stop();
  });

  test(
    'HARD ASSERTION: Gateway addProduct MUST persist to Firestore',
    () async {
      // 1. Arrange
      final productId = 'PROD-REAL-DB-TEST';
      final command = AdminAddProductCommand(
        productId: productId,
        name: 'Real Database Verification Product',
        unit: 'kg',
        initialQuantity: 100,
        reorderPoint: 10,
        productType: 'consumable',
      );

      // 2. Act
      await gateway.addProduct(command);

      // Wait for OutboxProcessor (async)
      await Future.delayed(const Duration(milliseconds: 200));

      // 3. Assert (HARD CHECK ON DATABASE)
      // We are NOT mocking the repository. We are checking the DB itself.

      final docSnapshot = await fakeFirestore
          .collection('inventory')
          .doc(productId)
          .get();

      // EXISTENCE CHECK
      expect(
        docSnapshot.exists,
        isTrue,
        reason: 'Document must exist in Firestore',
      );

      // DATA INTEGRITY CHECK
      final data = docSnapshot.data()!;
      expect(data['productId'], equals(productId));
      expect(data['name'], equals('Real Database Verification Product'));
      expect(data['quantity'], equals(100)); // Initial stock
      expect(data['productType'], equals('consumable'));
      expect(data.containsKey('lastUpdatedAt'), isTrue);
    },
  );
}
