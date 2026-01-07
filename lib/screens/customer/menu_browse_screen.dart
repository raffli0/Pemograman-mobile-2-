import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/menu/menu_bloc.dart';
import '../../blocs/menu/menu_state.dart';
import '../../blocs/cart/cart_bloc.dart';
import '../../blocs/cart/cart_event.dart';
import '../../widgets/menu_item_card.dart';

class MenuBrowseScreen extends StatefulWidget {
  const MenuBrowseScreen({super.key});

  @override
  State<MenuBrowseScreen> createState() => _MenuBrowseScreenState();
}

class _MenuBrowseScreenState extends State<MenuBrowseScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search menu...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey.shade100,
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
        ),

        // Menu items grid
        Expanded(
          child: BlocBuilder<MenuBloc, MenuState>(
            builder: (context, state) {
              if (state is MenuLoading) {
                return const Center(child: CircularProgressIndicator());
              } else if (state is MenuError) {
                return Center(child: Text('Error: ${state.message}'));
              } else if (state is MenuLoaded) {
                final filteredItems = state.items.where((item) {
                  final matchesSearch =
                      item.name.toLowerCase().contains(
                        _searchQuery.toLowerCase(),
                      ) ||
                      item.description.toLowerCase().contains(
                        _searchQuery.toLowerCase(),
                      );
                  // Only show available items for customers to browse/order
                  // Assuming this screen is for customers. Cashiers might use menu management.
                  // Actually customer dashboard uses this.
                  return matchesSearch && item.isAvailable;
                }).toList();

                if (filteredItems.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.restaurant_menu,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty
                              ? 'No menu items available'
                              : 'No items found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: filteredItems.length,
                  itemBuilder: (context, index) {
                    final item = filteredItems[index];
                    return MenuItemCard(
                      item: item,
                      onAddToCart: () {
                        context.read<CartBloc>().add(AddToCart(item));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${item.name} added to cart'),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      },
                    );
                  },
                );
              }
              return const Center(child: SizedBox());
            },
          ),
        ),
      ],
    );
  }
}
