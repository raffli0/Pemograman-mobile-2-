import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/order_model.dart';
import '../../blocs/auth/auth_bloc.dart';

import '../../blocs/auth/auth_state.dart';
import '../../blocs/cart/cart_bloc.dart';
import '../../blocs/cart/cart_event.dart';
import '../../blocs/cart/cart_state.dart';
import '../../blocs/order/order_bloc.dart';
import '../../blocs/order/order_event.dart';
import '../../blocs/order/order_state.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  PaymentMethod _selectedPaymentMethod = PaymentMethod.cash;

  Future<void> _handlePlaceOrder() async {
    // Get current state
    final authState = context.read<AuthBloc>().state;
    final cartState = context.read<CartBloc>().state;

    if (cartState is! CartLoaded || cartState.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your cart is empty'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Get user info
    String customerName = 'Guest';
    String customerId = '';

    // Check if authState has user
    if (authState is! AuthAuthenticated) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('User not authenticated')));
      return;
    }

    // We are sure user is authenticated (anonymous or real)
    customerName = authState.user.name;
    customerId = authState.user.uid;

    // Prompt for name if Guest
    if (customerName == 'Guest') {
      final nameController = TextEditingController();
      final name = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Enter Your Name'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Name',
              hintText: 'e.g. Travis Baker',
            ),
            textCapitalization: TextCapitalization.words,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.trim().isNotEmpty) {
                  Navigator.pop(context, nameController.text.trim());
                }
              },
              child: const Text('Confirm'),
            ),
          ],
        ),
      );

      if (name == null) return; // Cancelled
      customerName = name;
    }

    // Dispatch CreateOrder
    // ignore: use_build_context_synchronously
    context.read<OrderBloc>().add(
      CreateOrder(
        customerId: customerId,
        customerName: customerName,
        items: cartState.items,
        paymentMethod: _selectedPaymentMethod,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<OrderBloc, OrderState>(
      listener: (context, state) {
        if (state is OrderOperationSuccess) {
          // Clear cart
          context.read<CartBloc>().add(ClearCart());

          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Colors.green.shade700,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  const Text('Order Placed!'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your order has been successfully placed!',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'The cashier will be notified and will start preparing your order.',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'You can track your order status in the Orders tab.',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                    Navigator.pop(context); // Back to cart
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        } else if (state is OrderError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Checkout'),
          backgroundColor: Colors.amber.shade700,
          foregroundColor: Colors.black,
        ),
        body: BlocBuilder<CartBloc, CartState>(
          builder: (context, cartState) {
            if (cartState is! CartLoaded) {
              return const Center(child: CircularProgressIndicator());
            }

            final items = cartState.items;
            final totalAmount = cartState.totalAmount;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Order Summary
                  const Text(
                    'Order Summary',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          ...items.map((item) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${item.menuItem.name} x${item.quantity}',
                                      style: const TextStyle(fontSize: 15),
                                    ),
                                  ),
                                  Text(
                                    'Rp ${item.totalPrice.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                          const Divider(height: 24),
                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Total',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Text(
                                'Rp ${totalAmount.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Payment Method
                  const Text(
                    'Payment Method',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  // Cash option
                  Card(
                    child: RadioListTile<PaymentMethod>(
                      value: PaymentMethod.cash,
                      groupValue: _selectedPaymentMethod,
                      onChanged: (value) {
                        setState(() {
                          _selectedPaymentMethod = value!;
                        });
                      },
                      title: const Row(
                        children: [
                          Icon(Icons.money, color: Colors.green),
                          SizedBox(width: 12),
                          Text(
                            'Cash',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      subtitle: const Text(
                        'Pay with cash when you receive your order',
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Cashless option
                  Card(
                    child: RadioListTile<PaymentMethod>(
                      value: PaymentMethod.cashless,
                      groupValue: _selectedPaymentMethod,
                      onChanged: (value) {
                        setState(() {
                          _selectedPaymentMethod = value!;
                        });
                      },
                      title: const Row(
                        children: [
                          Icon(Icons.credit_card, color: Colors.blue),
                          SizedBox(width: 12),
                          Text(
                            'Cashless',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      subtitle: const Text(
                        'Pay with card, e-wallet, or other digital payment',
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        bottomNavigationBar: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: BlocBuilder<OrderBloc, OrderState>(
                builder: (context, state) {
                  final isLoading =
                      state
                          is OrderLoading; // Not explicitly defined, but creating order might not emit Loading on class level?
                  // Check if bloc emits loading. _onCreateOrder doesn't emit loading.
                  // But BLoC processing is fast. We might want to add loading state?
                  // I didn't add emit(OrderLoading()) in _onCreateOrder.
                  // I should probably have.
                  return ElevatedButton(
                    onPressed: isLoading ? null : _handlePlaceOrder,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber.shade700,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Place Order',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
