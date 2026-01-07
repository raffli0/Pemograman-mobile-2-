import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/cart_item_model.dart';
import 'cart_event.dart';
import 'cart_state.dart';

class CartBloc extends Bloc<CartEvent, CartState> {
  CartBloc() : super(const CartLoaded()) {
    on<AddToCart>(_onAddToCart);
    on<RemoveFromCart>(_onRemoveFromCart);
    on<UpdateCartItemQuantity>(_onUpdateCartItemQuantity);
    on<ClearCart>(_onClearCart);
  }

  void _onAddToCart(AddToCart event, Emitter<CartState> emit) {
    if (state is CartLoaded) {
      final currentItems = List<CartItem>.from((state as CartLoaded).items);
      final index = currentItems.indexWhere(
        (item) => item.menuItem.id == event.menuItem.id,
      );

      if (index != -1) {
        // Update existing item
        final existingItem = currentItems[index];
        currentItems[index] = existingItem.copyWith(
          quantity: existingItem.quantity + event.quantity,
        );
      } else {
        // Add new item
        currentItems.add(
          CartItem(menuItem: event.menuItem, quantity: event.quantity),
        );
      }
      emit(CartLoaded(items: currentItems));
    }
  }

  void _onRemoveFromCart(RemoveFromCart event, Emitter<CartState> emit) {
    if (state is CartLoaded) {
      final currentItems = List<CartItem>.from((state as CartLoaded).items);
      currentItems.removeWhere((item) => item.menuItem.id == event.menuItemId);
      emit(CartLoaded(items: currentItems));
    }
  }

  void _onUpdateCartItemQuantity(
    UpdateCartItemQuantity event,
    Emitter<CartState> emit,
  ) {
    if (state is CartLoaded) {
      final currentItems = List<CartItem>.from((state as CartLoaded).items);
      final index = currentItems.indexWhere(
        (item) => item.menuItem.id == event.menuItemId,
      );

      if (index != -1) {
        if (event.quantity <= 0) {
          currentItems.removeAt(index);
        } else {
          currentItems[index] = currentItems[index].copyWith(
            quantity: event.quantity,
          );
        }
        emit(CartLoaded(items: currentItems));
      }
    }
  }

  void _onClearCart(ClearCart event, Emitter<CartState> emit) {
    emit(const CartLoaded(items: []));
  }
}
