import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:narayan_farms_admin/features/inventory/presentation/bloc/admin_inventory_bloc.dart';

class AdminInventoryScreen extends StatelessWidget {
  const AdminInventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AdminInventoryBloc, AdminInventoryState>(
      listener: (context, state) {
        if (state.restockStatus == RestockStatus.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Inventory Restocked Successfully')),
          );
        } else if (state.restockStatus == RestockStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Restock Failed: ${state.errorMessage}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Admin Inventory - COMMAND')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Inventory Management'),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => _showRestockDialog(context),
                icon: const Icon(Icons.add_shopping_cart),
                label: const Text('Restock Inventory'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRestockDialog(BuildContext context) {
    final productIdController = TextEditingController();
    final quantityController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Restock Inventory'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: productIdController,
                decoration: const InputDecoration(labelText: 'Product ID'),
              ),
              TextField(
                controller: quantityController,
                decoration: const InputDecoration(labelText: 'Quantity'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            BlocBuilder<AdminInventoryBloc, AdminInventoryState>(
              builder: (context, state) {
                if (state.restockStatus == RestockStatus.submitting) {
                  return const CircularProgressIndicator();
                }
                return ElevatedButton(
                  onPressed: () {
                    context.read<AdminInventoryBloc>().add(
                      RestockInventoryPressed(
                        productId: productIdController.text,
                        quantityStr: quantityController.text,
                      ),
                    );
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Restock'),
                );
              },
            ),
          ],
        );
      },
    );
  }
}
