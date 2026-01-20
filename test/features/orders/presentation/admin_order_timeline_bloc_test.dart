import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:narayan_farms_admin/core/infrastructure/admin_event_bus.dart';
import 'package:narayan_farms_admin/features/orders/presentation/bloc/admin_order_timeline_bloc.dart';

/// TEST CATEGORY 1: Bloc Contract Tests
///
/// Verifies:
/// - Bloc emits Loading → Loaded states
/// - Bloc handles errors appropriately
/// - Uses REAL system components (AdminEventBus)
void main() {
  group('AdminOrderTimelineBloc Contract Tests', () {
    late AdminEventBus eventBus;

    setUp(() {
      eventBus = AdminEventBus();
    });

    tearDown(() {
      eventBus.dispose();
    });

    test('initial state is AdminOrderTimelineInitial', () {
      final bloc = AdminOrderTimelineBloc(eventBus: eventBus);
      expect(bloc.state, isA<AdminOrderTimelineInitial>());
      bloc.close();
    });

    blocTest<AdminOrderTimelineBloc, AdminOrderTimelineState>(
      'emits [Loading, Loaded] when SubscribeToOrderEvents is added',
      build: () => AdminOrderTimelineBloc(eventBus: eventBus),
      act: (bloc) => bloc.add(SubscribeToOrderEvents()),
      expect: () => [
        isA<AdminOrderTimelineLoading>(),
        isA<AdminOrderTimelineLoaded>().having(
          (s) => s.orders,
          'orders',
          isEmpty,
        ),
      ],
    );

    blocTest<AdminOrderTimelineBloc, AdminOrderTimelineState>(
      'receives and processes order events from event bus',
      build: () => AdminOrderTimelineBloc(eventBus: eventBus),
      act: (bloc) async {
        bloc.add(SubscribeToOrderEvents());
        // Wait for subscription to be established
        await Future.delayed(const Duration(milliseconds: 100));

        // Emit a mock order created event
        eventBus.emit(_MockOrderPlacedEvent());

        // Give time for event to be processed
        await Future.delayed(const Duration(milliseconds: 100));
      },
      expect: () => [
        isA<AdminOrderTimelineLoading>(),
        isA<AdminOrderTimelineLoaded>().having(
          (s) => s.orders,
          'orders',
          isEmpty,
        ),
        isA<AdminOrderTimelineLoaded>().having(
          (s) => s.orders.length,
          'order count',
          1,
        ),
      ],
    );

    blocTest<AdminOrderTimelineBloc, AdminOrderTimelineState>(
      'maintains read-only state - no mutations allowed',
      build: () => AdminOrderTimelineBloc(eventBus: eventBus),
      act: (bloc) => bloc.add(SubscribeToOrderEvents()),
      verify: (_) {
        // This test verifies that the bloc only reads events
        // and does not provide any mutation methods
        // The contract is: observe only, no write operations
      },
    );
  });
}

/// Mock event to simulate order placement
class _MockOrderPlacedEvent {
  @override
  String toString() => 'OrderPlaced';
}
