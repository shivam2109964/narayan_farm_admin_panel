import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/add_product_bloc.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _productIdController = TextEditingController();
  final _nameController = TextEditingController();
  final _unitController = TextEditingController();
  final _quantityController = TextEditingController();
  final _reorderPointController = TextEditingController();

  String _selectedProductType = 'raw';
  final List<Map<String, String>> _productTypes = [
    {'value': 'raw', 'label': 'Raw Materials'},
    {'value': 'processed', 'label': 'Processed Goods'},
    {'value': 'packaging', 'label': 'Packaging Materials'},
    {'value': 'consumable', 'label': 'Consumable Supplies'},
  ];

  @override
  void dispose() {
    _productIdController.dispose();
    _nameController.dispose();
    _unitController.dispose();
    _quantityController.dispose();
    _reorderPointController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      context.read<AddProductBloc>().add(
        SubmitProduct(
          productId: _productIdController.text.trim(),
          name: _nameController.text.trim(),
          unit: _unitController.text.trim(),
          initialQuantity: int.parse(_quantityController.text),
          reorderPoint: int.parse(_reorderPointController.text),
          productType: _selectedProductType,
        ),
      );
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _productIdController.clear();
    _nameController.clear();
    _unitController.clear();
    _quantityController.clear();
    _reorderPointController.clear();
    setState(() {
      _selectedProductType = 'raw';
    });
    context.read<AddProductBloc>().add(ResetProductForm());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Product'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: BlocConsumer<AddProductBloc, AddProductState>(
        listener: (context, state) {
          if (state is AddProductSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '✓ Product "${state.productName}" added successfully!',
                ),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 3),
              ),
            );
            _resetForm();
          } else if (state is AddProductError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('✗ Error: ${state.message}'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 4),
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is AddProductLoading;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Product Information',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 24),

                          // Product ID
                          TextFormField(
                            controller: _productIdController,
                            enabled: !isLoading,
                            decoration: const InputDecoration(
                              labelText: 'Product ID *',
                              hintText: 'e.g., PROD-001',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.tag),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Product ID is required';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Product Name
                          TextFormField(
                            controller: _nameController,
                            enabled: !isLoading,
                            decoration: const InputDecoration(
                              labelText: 'Product Name *',
                              hintText: 'e.g., Tomato',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.inventory_2),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Product name is required';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Product Type Dropdown
                          DropdownButtonFormField<String>(
                            value: _selectedProductType,
                            decoration: const InputDecoration(
                              labelText: 'Product Type *',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.category),
                            ),
                            items: _productTypes.map((type) {
                              return DropdownMenuItem(
                                value: type['value'],
                                child: Text(type['label']!),
                              );
                            }).toList(),
                            onChanged: isLoading
                                ? null
                                : (value) {
                                    setState(() {
                                      _selectedProductType = value!;
                                    });
                                  },
                          ),
                          const SizedBox(height: 16),

                          // Unit
                          TextFormField(
                            controller: _unitController,
                            enabled: !isLoading,
                            decoration: const InputDecoration(
                              labelText: 'Unit *',
                              hintText: 'e.g., kg, liter, piece',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.straighten),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Unit is required';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Initial Quantity
                          TextFormField(
                            controller: _quantityController,
                            enabled: !isLoading,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Initial Quantity *',
                              hintText: 'e.g., 100',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.numbers),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Initial quantity is required';
                              }
                              final quantity = int.tryParse(value);
                              if (quantity == null || quantity < 0) {
                                return 'Enter a valid non-negative number';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Reorder Point
                          TextFormField(
                            controller: _reorderPointController,
                            enabled: !isLoading,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Reorder Point *',
                              hintText: 'e.g., 20',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.warning_amber),
                              helperText:
                                  'Alert when stock falls below this level',
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Reorder point is required';
                              }
                              final reorderPoint = int.tryParse(value);
                              if (reorderPoint == null || reorderPoint < 0) {
                                return 'Enter a valid non-negative number';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 32),

                          // Submit Button
                          ElevatedButton(
                            onPressed: isLoading ? null : _submitForm,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.primary,
                              foregroundColor: Colors.white,
                            ),
                            child: isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Add Product',
                                    style: TextStyle(fontSize: 16),
                                  ),
                          ),
                          const SizedBox(height: 12),

                          // Reset Button
                          OutlinedButton(
                            onPressed: isLoading ? null : _resetForm,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text('Reset Form'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
