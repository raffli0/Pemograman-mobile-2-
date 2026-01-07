import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';
import '../../blocs/order/order_bloc.dart';
import '../../blocs/order/order_event.dart';
import '../../blocs/order/order_state.dart';

import 'menu_management_screen.dart';
import 'order_management_screen.dart';

class CashierDashboard extends StatefulWidget {
  const CashierDashboard({super.key});

  @override
  State<CashierDashboard> createState() => _CashierDashboardState();
}

class _CashierDashboardState extends State<CashierDashboard> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const MenuManagementScreen(),
    const OrderManagementScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Start polling orders for cashier (no customerId filter means all)
    context.read<OrderBloc>().add(const StartPollingQueue());
  }

  @override
  void dispose() {
    // Stop polling when dashboard is disposed (e.g. logout)
    // context.read<OrderBloc>().add(StopPollingQueue());
    // Note: If context is invalid, this might throw, but strictly usually safe in dispose unless widget is unmounted.
    // Actually, calling read on disposed context is unsafe.
    // Better to rely on OrderBloc cleanup or handling it if we can.
    // But since OrderBloc might be global (provided in MainApp), it lives on.
    // So we MUST stop polling.
    // Safe way: usage of a variable or check mounted?
    // actually, we can just dispatch.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cashier Dashboard'),
        backgroundColor: Colors.amber.shade700,
        foregroundColor: Colors.black,
        actions: [
          // User info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Center(
              child: BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) {
                  final name = state is AuthAuthenticated
                      ? state.user.name
                      : '';
                  return Text(name, style: const TextStyle(fontSize: 14));
                },
              ),
            ),
          ),
          // Logout button
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<OrderBloc>().add(StopPollingQueue());
              context.read<AuthBloc>().add(AuthLogout());
              // Navigation handled by BlocListener in AuthWrapper or LoginScreen if reachable.
              // Since this is Home of AuthWrapper, AuthWrapper will rebuild to WelcomeScreen.
            },
          ),
        ],
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: Colors.red.shade700,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_menu),
            label: 'Menu',
          ),
          BottomNavigationBarItem(
            icon: BlocBuilder<OrderBloc, OrderState>(
              builder: (context, state) {
                int count = 0;
                if (state is OrderLoaded) {
                  count = state.activeCount;
                }
                return Badge(
                  isLabelVisible: count > 0,
                  label: Text('$count'),
                  child: const Icon(Icons.shopping_bag),
                );
              },
            ),
            label: 'Orders',
          ),
        ],
      ),
    );
  }
}
