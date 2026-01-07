import 'package:equatable/equatable.dart';

import '../../models/menu_item_model.dart';

abstract class CartEvent extends Equatable {
  const CartEvent();

  @override
  List<Object> get props => [];
}

class AddToCart extends CartEvent {
  final MenuItem menuItem;
  final int quantity;

  const AddToCart(this.menuItem, {this.quantity = 1});

  @override
  List<Object> get props => [menuItem, quantity];
}

class RemoveFromCart extends CartEvent {
  final String menuItemId;

  const RemoveFromCart(this.menuItemId);

  @override
  List<Object> get props => [menuItemId];
}

class UpdateCartItemQuantity extends CartEvent {
  final String menuItemId;
  final int quantity;

  const UpdateCartItemQuantity(this.menuItemId, this.quantity);

  @override
  List<Object> get props => [menuItemId, quantity];
}

class ClearCart extends CartEvent {}
