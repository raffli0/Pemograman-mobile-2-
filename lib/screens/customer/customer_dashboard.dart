import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';

import '../../blocs/cart/cart_bloc.dart';
import '../../blocs/cart/cart_state.dart';
import '../../blocs/order/order_bloc.dart';
import '../../blocs/order/order_event.dart';

import 'menu_browse_screen.dart';
import 'cart_screen.dart';
import 'order_history_screen.dart';

class CustomerDashboard extends StatefulWidget {
  const CustomerDashboard({super.key});

  @override
  State<CustomerDashboard> createState() => _CustomerDashboardState();
}

class _CustomerDashboardState extends State<CustomerDashboard> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // Load menu items if not already loaded (handled by main, but safe to trigger)
    // context.read<MenuBloc>().add(LoadMenu());

    // Load customer orders
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      final uid = authState.user.uid;
      // Start polling/loading orders for this customer
      context.read<OrderBloc>().add(LoadHistoryOrders(customerId: uid));
      context.read<OrderBloc>().add(StartPollingQueue(customerId: uid));
    }
  }

  @override
  void dispose() {
    // Optionally stop polling for this customer, or let it continue if we want persistence while in app.
    // If we logout, OrderBloc might need cleanup.
    // context.read<OrderBloc>().add(StopPollingQueue());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Pages might need arguments? No, they use Blocs.
    final List<Widget> pages = [
      const MenuBrowseScreen(),
      const CartScreen(),
      const OrderHistoryScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu'),
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
          // Logout button - only show if not anonymous or if we want guest logout too
          BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              if (state is AuthAuthenticated && state.user.name != 'Guest') {
                return IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: () {
                    context.read<OrderBloc>().add(StopPollingQueue());
                    context.read<AuthBloc>().add(AuthLogout());
                    // Navigate handled by wrappers
                  },
                );
              } else if (state is AuthAuthenticated &&
                  state.user.name == 'Guest') {
                // Option for guest to "Exit" or Logout?
                return IconButton(
                  icon: const Icon(Icons.exit_to_app),
                  onPressed: () {
                    context.read<OrderBloc>().add(StopPollingQueue());
                    context.read<AuthBloc>().add(AuthLogout());
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: pages[_currentIndex],
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
            icon: BlocBuilder<CartBloc, CartState>(
              builder: (context, state) {
                int count = 0;
                if (state is CartLoaded) {
                  count = state.itemCount;
                }
                return Badge(
                  isLabelVisible: count > 0,
                  label: Text('$count'),
                  child: const Icon(Icons.shopping_cart),
                );
              },
            ),
            label: 'Cart',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Orders',
          ),
        ],
      ),
    );
  }
}
