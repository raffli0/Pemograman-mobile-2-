import 'package:equatable/equatable.dart';
import '../../models/cart_item_model.dart';

abstract class CartState extends Equatable {
  const CartState();

  @override
  List<Object> get props => [];
}

class CartLoaded extends CartState {
  final List<CartItem> items;

  const CartLoaded({this.items = const []});

  double get totalAmount => items.fold(0, (sum, item) => sum + item.totalPrice);
  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  CartLoaded copyWith({List<CartItem>? items}) {
    return CartLoaded(items: items ?? this.items);
  }

  @override
  List<Object> get props => [items];
}
