import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:narayan_farms_admin/features/inventory/domain/use_cases/admin_restock_inventory_use_case.dart';
import 'package:narayan_farms_admin/features/inventory/domain/orchestrator/admin_supply_orchestrator.dart';

class MockAdminSupplyOrchestrator extends Mock
    implements AdminSupplyOrchestrator {}

void main() {
  group('AdminRestockInventoryUseCase Contract Tests', () {
    late AdminRestockInventoryUseCase useCase;
    late MockAdminSupplyOrchestrator mockOrchestrator;

    setUp(() {
      mockOrchestrator = MockAdminSupplyOrchestrator();
      useCase = AdminRestockInventoryUseCase(mockOrchestrator);
    });

    test('successfully calls orchestrator to restock inventory', () async {
      final productId = 'PROD-1';
      final quantity = 50.0;

      when(
        () => mockOrchestrator.restockInventory(
          productId: productId,
          quantity: quantity,
        ),
      ).thenReturn(null);

      final result = await useCase.execute(
        RestockInventoryInput(productId: productId, quantity: quantity),
      );

      expect(result.success, isTrue);

      // Verify orchestrator interaction
      verify(
        () => mockOrchestrator.restockInventory(
          productId: productId,
          quantity: quantity,
        ),
      ).called(1);
    });

    test('fails when orchestrator throws error', () async {
      final productId = 'PROD-1';
      final quantity = 50.0;

      when(
        () => mockOrchestrator.restockInventory(
          productId: productId,
          quantity: quantity,
        ),
      ).thenThrow(Exception('Simulated Failure'));

      final result = await useCase.execute(
        RestockInventoryInput(productId: productId, quantity: quantity),
      );

      expect(result.success, isFalse);
      expect(result.errorMessage, contains('Simulated Failure'));
    });
  });
}
