import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:narayan_farms_admin/features/orders/presentation/bloc/admin_order_timeline_bloc.dart';
import 'package:narayan_farms_admin/features/orders/presentation/pages/admin_order_timeline_screen.dart';
import 'package:narayan_farms_admin/core/infrastructure/admin_event_bus.dart';

/// TEST CATEGORY 2: Widget Tests
///
/// Verifies:
/// - Correct data is rendered
/// - No buttons that mutate state
/// - Screen renders correctly with given Bloc state
void main() {
  group('AdminOrderTimelineScreen Widget Tests', () {
    late AdminEventBus eventBus;

    setUp(() {
      eventBus = AdminEventBus();
    });

    tearDown(() {
      eventBus.dispose();
    });

    Widget createTestWidget(AdminOrderTimelineBloc bloc) {
      return MaterialApp(
        home: BlocProvider<AdminOrderTimelineBloc>.value(
          value: bloc,
          child: const AdminOrderTimelineScreen(),
        ),
      );
    }

    testWidgets('renders loading indicator when state is Loading', (
      tester,
    ) async {
      final bloc = AdminOrderTimelineBloc(eventBus: eventBus);

      // Manually emit loading state
      bloc.emit(AdminOrderTimelineLoading());

      await tester.pumpWidget(createTestWidget(bloc));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      bloc.close();
    });

    testWidgets('renders error message when state is Error', (tester) async {
      final bloc = AdminOrderTimelineBloc(eventBus: eventBus);

      bloc.emit(const AdminOrderTimelineError('Test error'));

      await tester.pumpWidget(createTestWidget(bloc));

      expect(find.text('Error: Test error'), findsOneWidget);

      bloc.close();
    });

    testWidgets('renders empty message when no orders exist', (tester) async {
      final bloc = AdminOrderTimelineBloc(eventBus: eventBus);

      bloc.emit(const AdminOrderTimelineLoaded(orders: []));

      await tester.pumpWidget(createTestWidget(bloc));

      expect(find.text('No active orders to observe.'), findsOneWidget);

      bloc.close();
    });

    testWidgets('renders order timeline data correctly', (tester) async {
      final bloc = AdminOrderTimelineBloc(eventBus: eventBus);

      final testOrder = OrderTimelineUIModel(
        orderId: 'ORDER-123',
        customerId: 'CUSTOMER-456',
        currentStatus: OrderStatusUI.created,
        history: [
          TimelineEntry(
            status: OrderStatusUI.created,
            timestamp: DateTime(2026, 1, 20, 10, 0),
            description: 'Order created',
          ),
        ],
      );

      bloc.emit(AdminOrderTimelineLoaded(orders: [testOrder]));

      await tester.pumpWidget(createTestWidget(bloc));

      expect(find.text('Order ID: ORDER-123'), findsOneWidget);
      expect(find.text('Customer: CUSTOMER-456'), findsOneWidget);
      expect(find.text('Status: created'), findsOneWidget);

      bloc.close();
    });

    testWidgets('CRITICAL: Screen has NO mutation buttons', (tester) async {
      final bloc = AdminOrderTimelineBloc(eventBus: eventBus);

      bloc.emit(const AdminOrderTimelineLoaded(orders: []));

      await tester.pumpWidget(createTestWidget(bloc));

      // Verify NO buttons that could mutate state exist
      // The screen should be read-only
      expect(find.byType(ElevatedButton), findsNothing);
      expect(find.byType(TextButton), findsNothing);
      expect(find.byType(FloatingActionButton), findsNothing);
      expect(find.byType(IconButton), findsNothing);

      // Only navigation/close buttons are allowed (like AppBar back)

      bloc.close();
    });

    testWidgets('UI is dumb - only displays state', (tester) async {
      final bloc = AdminOrderTimelineBloc(eventBus: eventBus);

      final testOrders = [
        OrderTimelineUIModel(
          orderId: 'ORDER-1',
          customerId: 'CUSTOMER-A',
          currentStatus: OrderStatusUI.created,
          history: [
            TimelineEntry(
              status: OrderStatusUI.created,
              timestamp: DateTime(2026, 1, 20, 10, 0),
              description: 'Order created',
            ),
          ],
        ),
        OrderTimelineUIModel(
          orderId: 'ORDER-2',
          customerId: 'CUSTOMER-B',
          currentStatus: OrderStatusUI.delivered,
          history: [
            TimelineEntry(
              status: OrderStatusUI.created,
              timestamp: DateTime(2026, 1, 20, 11, 0),
              description: 'Order created',
            ),
            TimelineEntry(
              status: OrderStatusUI.delivered,
              timestamp: DateTime(2026, 1, 20, 12, 0),
              description: 'Order delivered',
            ),
          ],
        ),
      ];

      bloc.emit(AdminOrderTimelineLoaded(orders: testOrders));

      await tester.pumpWidget(createTestWidget(bloc));

      // Verify ALL data is rendered
      expect(find.text('Order ID: ORDER-1'), findsOneWidget);
      expect(find.text('Order ID: ORDER-2'), findsOneWidget);
      expect(find.text('Customer: CUSTOMER-A'), findsOneWidget);
      expect(find.text('Customer: CUSTOMER-B'), findsOneWidget);

      bloc.close();
    });
  });
}
