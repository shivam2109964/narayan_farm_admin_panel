import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

/// TEST CATEGORY 3: Architectural Guard Tests
///
/// Verifies:
/// - Admin UI does NOT import repositories, Firebase, or adapters
/// - Admin Bloc does NOT import Flutter widgets or BuildContext
/// - No domain logic leaks into presentation layer
void main() {
  group('Architectural Guard Tests - Clean Architecture Enforcement', () {
    test('Admin UI MUST NOT import repositories', () {
      final libDir = Directory('lib/features');
      final uiFiles = libDir
          .listSync(recursive: true)
          .whereType<File>()
          .where(
            (f) =>
                f.path.contains('/presentation/pages/') ||
                f.path.contains('/presentation/widgets/'),
          )
          .where((f) => f.path.endsWith('.dart'));

      for (final file in uiFiles) {
        final content = file.readAsStringSync();

        expect(
          content.contains('repository'),
          isFalse,
          reason: 'UI file ${file.path} must NOT import repositories',
        );

        expect(
          content.contains('firebase'),
          isFalse,
          reason: 'UI file ${file.path} must NOT import Firebase',
        );

        expect(
          content.contains('adapter'),
          isFalse,
          reason: 'UI file ${file.path} must NOT import adapters',
        );
      }
    });

    test('Admin Bloc MUST NOT import Flutter widgets or BuildContext', () {
      final libDir = Directory('lib/features');
      final blocFiles = libDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.contains('/presentation/bloc/'))
          .where((f) => f.path.endsWith('_bloc.dart'));

      for (final file in blocFiles) {
        final content = file.readAsStringSync();

        // Bloc can import flutter_bloc and material (for @immutable, etc.)
        // but should NOT import widgets or use BuildContext

        expect(
          content.contains('BuildContext'),
          isFalse,
          reason: 'Bloc ${file.path} must NOT use BuildContext',
        );

        expect(
          content.contains('Widget'),
          isFalse,
          reason: 'Bloc ${file.path} must NOT reference Widget classes',
        );
      }
    });

    test('Admin Bloc MUST NOT contain domain logic', () {
      final libDir = Directory('lib/features');
      final blocFiles = libDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.contains('/presentation/bloc/'))
          .where((f) => f.path.endsWith('_bloc.dart'));

      for (final file in blocFiles) {
        final content = file.readAsStringSync();

        // Bloc should only translate, not implement business rules
        // Look for suspicious patterns

        expect(
          content.contains('calculate') && content.contains('price'),
          isFalse,
          reason:
              'Bloc ${file.path} appears to calculate prices (domain logic)',
        );

        expect(
          content.contains('validate') && content.contains('order'),
          isFalse,
          reason: 'Bloc ${file.path} appears to validate orders (domain logic)',
        );
      }
    });

    test('Admin PRESENTATION layer has NO write operations', () {
      final libDir = Directory('lib/features');
      final uiFiles = libDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.contains('/presentation/'))
          .where((f) => f.path.endsWith('.dart'));

      for (final file in uiFiles) {
        final content = file.readAsStringSync();

        // Check for suspicious mutation methods in UI
        final suspiciousMethods = [
          'createOrder',
          'updateOrder',
          'deleteOrder',
          'placeOrder',
          'cancelOrder',
          'updateInventory',
          'restockProduct',
          'assignAgent',
          'updateLoyalty',
        ];

        for (final method in suspiciousMethods) {
          expect(
            content.contains(method),
            isFalse,
            reason: 'UI File ${file.path} contains write method: $method',
          );
        }
      }
    });

    test(
      'AdminRestockInventoryUseCase must NOT import supply entities directly',
      () {
        final file = File(
          'lib/features/inventory/domain/use_cases/admin_restock_inventory_use_case.dart',
        );
        if (file.existsSync()) {
          final content = file.readAsStringSync();

          expect(
            content.contains('package:supply_inventory/supply_inventory.dart'),
            isFalse,
            reason:
                'UseCase must not import supply_inventory directly. Use Orchestrator.',
          );

          expect(
            content.contains('inventoryService'),
            isFalse,
            reason: 'UseCase must not access inventoryService',
          );

          expect(
            content.contains('inventory.replenishStock'),
            isFalse,
            reason: 'UseCase must not call replenishStock directly',
          );
        }
      },
    );

    test('Infrastructure layer exists and is minimal', () {
      final infraDir = Directory('lib/core/infrastructure');

      expect(
        infraDir.existsSync(),
        isTrue,
        reason: 'Infrastructure directory must exist',
      );

      final infraFiles = infraDir.listSync().whereType<File>().where(
        (f) => f.path.endsWith('.dart'),
      );

      // Admin should have minimal infrastructure
      // Only event bus and clock implementations
      expect(
        infraFiles.length,
        lessThanOrEqualTo(3),
        reason: 'Admin infrastructure should be minimal',
      );
    });

    test('UI layer must NOT import system_core directly', () {
      final presentationDir = Directory('lib/features');
      final uiFiles = presentationDir
          .listSync(recursive: true)
          .whereType<File>()
          .where(
            (f) =>
                f.path.contains('/presentation/pages/') ||
                f.path.contains('/presentation/widgets/'),
          )
          .where((f) => f.path.endsWith('.dart'));

      for (final file in uiFiles) {
        final content = file.readAsStringSync();

        expect(
          content.contains('package:narayan_system_core'),
          isFalse,
          reason:
              'UI file ${file.path} must NOT import system_core directly. Use Bloc.',
        );
      }
    });

    test('No direct Firebase imports in presentation layer', () {
      final presentationDir = Directory('lib/features');
      final presentationFiles = presentationDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.contains('/presentation/'))
          .where((f) => f.path.endsWith('.dart'));

      for (final file in presentationFiles) {
        final content = file.readAsStringSync();

        expect(
          content.contains("import 'package:cloud_firestore"),
          isFalse,
          reason: 'Presentation ${file.path} must NOT import Firestore',
        );

        expect(
          content.contains("import 'package:firebase_"),
          isFalse,
          reason: 'Presentation ${file.path} must NOT import Firebase',
        );
      }
    });
  });
}
