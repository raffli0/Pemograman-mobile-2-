import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/order/order_bloc.dart';
import '../../blocs/order/order_event.dart';
import '../../blocs/order/order_state.dart';
import '../../models/order_model.dart';
import '../../widgets/order_card.dart';

class OrderManagementScreen extends StatefulWidget {
  const OrderManagementScreen({super.key});

  @override
  State<OrderManagementScreen> createState() => _OrderManagementScreenState();
}

class _OrderManagementScreenState extends State<OrderManagementScreen> {
  @override
  void initState() {
    super.initState();
    // Start polling for all active orders
    context.read<OrderBloc>().add(const StartPollingQueue());
  }

  // Note: automatic polling stop is handled by BLoC if we wanted,
  // but here the Bloc is global. We might want to stop polling when leaving this screen?
  // But StartPollingQueue in Bloc handles timer. calling it again replaces timer.
  // If we leave, timer continues running if Bloc is global.
  // We should ideally stop polling on dispose.
  @override
  void dispose() {
    // Only stop if we really want to stop global polling.
    // If other screens need it, we shouldn't.
    // But this is the only screen for Cashier polling active queue.
    context.read<OrderBloc>().add(StopPollingQueue());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<OrderBloc, OrderState>(
        listener: (context, state) {
          if (state is OrderError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is OrderLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          List<Order> orders = [];
          if (state is OrderLoaded) {
            orders = state.activeOrders;
          } else if (state is OrderError) {
            // If error, we might still have data if we cached it.
            // But for now, OrderBloc emits Error then Loaded.
            // If we are in Error state, it means we don't have loaded data just now?
            // Actually my logic was: emit Error then emit Loaded (with cache).
            // So listener catches Error, then builder sees Loaded.
            // So we usually won't see OrderError in builder.
          }

          if (orders.isEmpty) {
            if (state is OrderInitial)
              return const Center(child: CircularProgressIndicator());
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.inbox, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'No pending orders',
                    style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'New orders will appear here',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              return OrderCard(
                order: order,
                actions: [
                  if (order.status == OrderStatus.pending)
                    ElevatedButton.icon(
                      onPressed: () {
                        context.read<OrderBloc>().add(
                          UpdateOrderStatus(order.id, OrderStatus.preparing),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Order is now being prepared'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.restaurant),
                      label: const Text('Start Preparing'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  if (order.status == OrderStatus.preparing)
                    ElevatedButton.icon(
                      onPressed: () {
                        context.read<OrderBloc>().add(
                          UpdateOrderStatus(order.id, OrderStatus.ready),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Order is ready for pickup'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.check_circle),
                      label: const Text('Mark as Ready'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  if (order.status == OrderStatus.ready)
                    ElevatedButton.icon(
                      onPressed: () {
                        context.read<OrderBloc>().add(
                          UpdateOrderStatus(order.id, OrderStatus.completed),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Order completed!')),
                        );
                      },
                      icon: const Icon(Icons.done_all),
                      label: const Text('Complete Order'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  if (order.status != OrderStatus.completed &&
                      order.status != OrderStatus.cancelled)
                    OutlinedButton.icon(
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Cancel Order'),
                            content: const Text(
                              'Are you sure you want to cancel this order?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('No'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text(
                                  'Yes',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true) {
                          // ignore: use_build_context_synchronously
                          context.read<OrderBloc>().add(CancelOrder(order.id));
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Order cancelled')),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.cancel),
                      label: const Text('Cancel Order'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
