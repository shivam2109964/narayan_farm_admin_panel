import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:narayan_farms_admin/features/inventory/presentation/bloc/admin_inventory_bloc.dart';
import 'package:narayan_farms_admin/features/inventory/presentation/pages/admin_inventory_screen.dart';

class MockAdminInventoryBloc
    extends MockBloc<AdminInventoryEvent, AdminInventoryState>
    implements AdminInventoryBloc {}

void main() {
  group('AdminInventoryScreen Widget Tests', () {
    late MockAdminInventoryBloc mockBloc;

    setUp(() {
      mockBloc = MockAdminInventoryBloc();
      when(() => mockBloc.state).thenReturn(const AdminInventoryState());
    });

    Widget createTestWidget() {
      return BlocProvider<AdminInventoryBloc>.value(
        value: mockBloc,
        child: const MaterialApp(home: AdminInventoryScreen()),
      );
    }

    testWidgets('renders Restock Inventory button', (tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.text('Restock Inventory'), findsOneWidget);
    });

    testWidgets('shows dialog when Restock Inventory is clicked', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget());

      await tester.tap(find.text('Restock Inventory'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Product ID'), findsOneWidget);
      expect(find.text('Quantity'), findsOneWidget);
    });

    testWidgets(
      'adds RestockInventoryPressed event when dialog Restock is clicked',
      (tester) async {
        await tester.pumpWidget(createTestWidget());

        // Open dialog
        await tester.tap(find.text('Restock Inventory'));
        await tester.pumpAndSettle();

        // Enter text
        await tester.enterText(
          find.widgetWithText(TextField, 'Product ID'),
          'PROD-123',
        );
        await tester.enterText(
          find.widgetWithText(TextField, 'Quantity'),
          '50',
        );

        // Click Restock
        await tester.tap(find.text('Restock'));

        // Verify Bloc event added
        verify(
          () => mockBloc.add(
            const RestockInventoryPressed(
              productId: 'PROD-123',
              quantityStr: '50',
            ),
          ),
        ).called(1);
      },
    );

    testWidgets('shows success snackbar when restockState is success', (
      tester,
    ) async {
      whenListen(
        mockBloc,
        Stream.fromIterable([
          const AdminInventoryState(restockStatus: RestockStatus.success),
        ]),
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pump(); // Pump stream
      await tester.pump(); // Pump animation

      expect(find.text('Inventory Restocked Successfully'), findsOneWidget);
    });

    testWidgets('shows failure snackbar when restockState is failure', (
      tester,
    ) async {
      whenListen(
        mockBloc,
        Stream.fromIterable([
          const AdminInventoryState(
            restockStatus: RestockStatus.failure,
            errorMessage: 'Test Error',
          ),
        ]),
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      await tester.pump();

      expect(find.text('Restock Failed: Test Error'), findsOneWidget);
    });
  });
}
