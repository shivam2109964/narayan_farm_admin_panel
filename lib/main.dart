import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:narayan_system_core/narayan_system_core.dart';
import 'package:narayan_farms_admin/core/infrastructure/admin_event_bus.dart';
import 'package:narayan_farms_admin/features/orders/presentation/bloc/admin_order_timeline_bloc.dart';
import 'package:narayan_farms_admin/features/orders/presentation/pages/admin_order_timeline_screen.dart';

void main() {
  runApp(const AdminApp());
}

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Bootstrap system core with Admin event bus
    final adminEventBus = AdminEventBus();

    return BlocProvider(
      create: (_) =>
          AdminOrderTimelineBloc(eventBus: adminEventBus)
            ..add(SubscribeToOrderEvents()),
      child: MaterialApp(
        title: 'Narayan Farms Admin Panel',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
          useMaterial3: true,
        ),
        home: const AdminOrderTimelineScreen(),
      ),
    );
  }
}

/// Admin clock implementation
class AdminClock implements ClockPort {
  @override
  DateTime now() => DateTime.now();
}
