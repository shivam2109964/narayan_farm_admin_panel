import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:narayan_farms_admin/features/orders/presentation/bloc/admin_order_timeline_bloc.dart';

class AdminOrderTimelineScreen extends StatelessWidget {
  const AdminOrderTimelineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Order Timeline - READ ONLY')),
      body: BlocBuilder<AdminOrderTimelineBloc, AdminOrderTimelineState>(
        builder: (context, state) {
          if (state is AdminOrderTimelineLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is AdminOrderTimelineError) {
            return Center(child: Text('Error: ${state.message}'));
          }
          if (state is AdminOrderTimelineLoaded) {
            if (state.orders.isEmpty) {
              return const Center(child: Text('No active orders to observe.'));
            }
            return ListView.builder(
              itemCount: state.orders.length,
              itemBuilder: (context, index) {
                final order = state.orders[index];
                return Card(
                  margin: const EdgeInsets.all(8.0),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order ID: ${order.orderId}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text('Customer: ${order.customerId}'),
                        Text('Status: ${order.currentStatus.name}'),
                        const Divider(),
                        const Text(
                          'Timeline:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        ...order.history.map(
                          (e) => ListTile(
                            title: Text(e.status.name),
                            subtitle: Text(e.description),
                            trailing: Text(e.timestamp.toIso8601String()),
                            leading: const Icon(Icons.circle, size: 8),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
