import 'menu_item_model.dart';

class CartItem {
  final MenuItem menuItem;
  final int quantity;

  CartItem({
    required this.menuItem,
    required this.quantity,
  });

  double get totalPrice => menuItem.price * quantity;

  CartItem copyWith({
    MenuItem? menuItem,
    int? quantity,
  }) {
    return CartItem(
      menuItem: menuItem ?? this.menuItem,
      quantity: quantity ?? this.quantity,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'menuItemId': menuItem.id,
      'menuItemName': menuItem.name,
      'menuItemPrice': menuItem.price,
      'quantity': quantity,
      'totalPrice': totalPrice,
    };
  }
}
