import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:narayan_system_core/narayan_system_core.dart';
import 'package:narayan_system_engine/narayan_system_engine.dart';
import 'package:narayan_farms_admin/core/infrastructure/admin_event_bus.dart';
import 'package:narayan_farms_admin/features/orders/presentation/bloc/admin_order_timeline_bloc.dart';
import 'package:narayan_farms_admin/features/orders/presentation/pages/admin_order_timeline_screen.dart';

import 'package:supply_inventory/supply_inventory.dart' as supply;
import 'package:inventory_firebase_adapter/listeners/inventory_event_listener.dart';
import 'package:inventory_firebase_adapter/repositories/inventory_firebase_repository.dart';
import 'package:narayan_farms_admin/features/inventory/data/admin_command_gateway.dart';
import 'package:narayan_farms_admin/features/inventory/domain/use_cases/admin_restock_inventory_use_case.dart';
import 'package:narayan_farms_admin/features/inventory/domain/use_cases/admin_add_product_use_case.dart';
import 'package:narayan_farms_admin/features/inventory/presentation/bloc/admin_inventory_bloc.dart';
import 'package:narayan_farms_admin/features/inventory/presentation/bloc/add_product_bloc.dart';
import 'package:narayan_farms_admin/features/inventory/presentation/pages/admin_inventory_screen.dart';
import 'package:narayan_farms_admin/features/inventory/presentation/pages/add_product_screen.dart';
import 'package:narayan_farms_admin/features/inventory/domain/orchestrator/admin_supply_orchestrator.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const AdminApp());
}

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. INFRASTRUCTURE
    final adminEventBus = AdminEventBus();
    final clock = AdminClock();

    // 2. DOMAIN - SUPPLY INVENTORY
    final inventory = supply.Inventory(id: 'admin-inv', clock: clock);
    final inventoryService = supply.InventoryManagementService(
      inventory: inventory,
      restockPolicy: const supply.RestockPolicy(),
      clock: clock,
    );

    // 3. FIREBASE ADAPTERS - Event listeners for projections (create before engine)
    final inventoryRepo = InventoryFirebaseRepository();
    final inventoryListener = InventoryEventListener(inventoryRepo);

    // 4. EVENT HANDLER REGISTRY - Register projectors for inventory events
    final eventRegistry = EventHandlerRegistry();

    // Create simple projector wrappers that delegate to the listener
    final productAddedProjector = _SimpleProjector<supply.ProductAdded>(
      (event) async => await inventoryListener.handle(event),
    );
    final stockReplenishedProjector = _SimpleProjector<supply.StockReplenished>(
      (event) async => await inventoryListener.handle(event),
    );
    final stockDepletedProjector = _SimpleProjector<supply.StockDepleted>(
      (event) async => await inventoryListener.handle(event),
    );

    // Register projectors with the registry
    eventRegistry.register('ProductAdded', [productAddedProjector]);
    eventRegistry.register('StockReplenished', [stockReplenishedProjector]);
    eventRegistry.register('StockDepleted', [stockDepletedProjector]);

    // 5. SYSTEM ENGINE - Backend orchestration with event processing
    final systemEngine = SystemEngine(
      clock: clock,
      eventHandlerRegistry: eventRegistry,
    );

    // Start the engine to begin processing outbox events
    systemEngine.start();

    // 6. ADMIN COMMAND GATEWAY - For product creation
    // ignore: unused_local_variable
    final adminCommandGateway = AdminCommandGatewayImpl(
      systemEngine: systemEngine,
      inventoryService: inventoryService,
    );

    // 7. ORCHESTRATORS - For restock operations (keep existing pattern)
    final supplyOrchestrator = SupplyFlowOrchestrator(
      inventoryService: inventoryService,
      clock: clock,
      eventBus: systemEngine.eventBus,
    );

    final adminOrchestrator = AdminSupplyOrchestrator(
      supplyOrchestrator,
      systemEngine.eventBus,
    );

    // 8. ADMIN USE CASES
    final restockUseCase = AdminRestockInventoryUseCase(adminOrchestrator);
    final addProductUseCase = AdminAddProductUseCase(adminCommandGateway);

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) =>
              AdminOrderTimelineBloc(eventBus: adminEventBus)
                ..add(SubscribeToOrderEvents()),
        ),
        BlocProvider(
          create: (_) => AdminInventoryBloc(restockUseCase: restockUseCase),
        ),
        BlocProvider(
          create: (_) => AddProductBloc(addProductUseCase: addProductUseCase),
        ),
      ],
      child: MaterialApp(
        title: 'Narayan Farms Admin Panel',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
          useMaterial3: true,
        ),
        home: const AdminHomeShell(),
      ),
    );
  }
}

/// Navigation Shell to switch between Timeline (Eyes) and Inventory (Command)
class AdminHomeShell extends StatefulWidget {
  const AdminHomeShell({super.key});

  @override
  State<AdminHomeShell> createState() => _AdminHomeShellState();
}

class _AdminHomeShellState extends State<AdminHomeShell> {
  int _selectedIndex = 0;

  final _screens = const [
    AdminOrderTimelineScreen(),
    AdminInventoryScreen(),
    AddProductScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (int index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.timeline),
                label: Text('Timeline'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.inventory),
                label: Text('Inventory'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.add_box),
                label: Text('Add Product'),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: _screens[_selectedIndex]),
        ],
      ),
    );
  }
}

/// Admin clock implementation
class AdminClock implements ClockPort, supply.Clock {
  @override
  DateTime now() => DateTime.now();
}

/// Simple projector wrapper for function-based event handling
class _SimpleProjector<T> {
  final Future<void> Function(T) _handler;

  _SimpleProjector(this._handler);

  Future<void> project(T event) => _handler(event);
}
