import 'package:equatable/equatable.dart';
import '../../models/menu_item_model.dart';

abstract class MenuState extends Equatable {
  const MenuState();

  @override
  List<Object> get props => [];
}

class MenuInitial extends MenuState {}

class MenuLoading extends MenuState {}

class MenuLoaded extends MenuState {
  final List<MenuItem> items;
  final List<MenuItem> availableItems;

  const MenuLoaded(this.items) : availableItems = items;

  @override
  List<Object> get props => [items];

  // Helper to filter available items
  List<MenuItem> get available =>
      items.where((item) => item.isAvailable).toList();
}

class MenuError extends MenuState {
  final String message;

  const MenuError(this.message);

  @override
  List<Object> get props => [message];
}
