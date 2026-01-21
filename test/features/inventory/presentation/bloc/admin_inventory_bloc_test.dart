import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:narayan_farms_admin/features/inventory/presentation/bloc/admin_inventory_bloc.dart';
import 'package:narayan_farms_admin/features/inventory/domain/use_cases/admin_restock_inventory_use_case.dart';

class MockRestockUseCase extends Mock implements AdminRestockInventoryUseCase {}

void main() {
  group('AdminInventoryBloc', () {
    late MockRestockUseCase mockUseCase;

    setUpAll(() {
      registerFallbackValue(
        RestockInventoryInput(productId: 'dummy', quantity: 1),
      );
    });

    setUp(() {
      mockUseCase = MockRestockUseCase();
    });

    test('initial state is correct', () {
      final bloc = AdminInventoryBloc(restockUseCase: mockUseCase);
      expect(bloc.state.restockStatus, RestockStatus.initial);
      bloc.close();
    });

    blocTest<AdminInventoryBloc, AdminInventoryState>(
      'emits [failure] when quantity input is invalid',
      build: () => AdminInventoryBloc(restockUseCase: mockUseCase),
      act: (bloc) => bloc.add(
        const RestockInventoryPressed(
          productId: 'PROD-1',
          quantityStr: 'invalid',
        ),
      ),
      expect: () => [
        isA<AdminInventoryState>().having(
          (s) => s.restockStatus,
          'status',
          RestockStatus.submitting,
        ),
        isA<AdminInventoryState>()
            .having((s) => s.restockStatus, 'status', RestockStatus.failure)
            .having((s) => s.errorMessage, 'error', 'Invalid quantity'),
      ],
    );

    blocTest<AdminInventoryBloc, AdminInventoryState>(
      'emits [submitting, success] when use case returns success',
      build: () {
        when(
          () => mockUseCase.execute(any()),
        ).thenAnswer((_) async => RestockInventoryOutput.success());
        return AdminInventoryBloc(restockUseCase: mockUseCase);
      },
      act: (bloc) => bloc.add(
        const RestockInventoryPressed(productId: 'PROD-1', quantityStr: '50'),
      ),
      verify: (_) {
        verify(() => mockUseCase.execute(any())).called(1);
      },
      expect: () => [
        isA<AdminInventoryState>().having(
          (s) => s.restockStatus,
          'status',
          RestockStatus.submitting,
        ),
        isA<AdminInventoryState>()
            .having((s) => s.restockStatus, 'status', RestockStatus.success)
            .having((s) => s.errorMessage, 'error', isNull),
      ],
    );

    blocTest<AdminInventoryBloc, AdminInventoryState>(
      'emits [submitting, failure] when use case returns failure',
      build: () {
        when(() => mockUseCase.execute(any())).thenAnswer(
          (_) async => RestockInventoryOutput.failure('Domain Error'),
        );
        return AdminInventoryBloc(restockUseCase: mockUseCase);
      },
      act: (bloc) => bloc.add(
        const RestockInventoryPressed(productId: 'PROD-1', quantityStr: '50'),
      ),
      expect: () => [
        isA<AdminInventoryState>().having(
          (s) => s.restockStatus,
          'status',
          RestockStatus.submitting,
        ),
        isA<AdminInventoryState>()
            .having((s) => s.restockStatus, 'status', RestockStatus.failure)
            .having((s) => s.errorMessage, 'error', 'Domain Error'),
      ],
    );
  });
}
