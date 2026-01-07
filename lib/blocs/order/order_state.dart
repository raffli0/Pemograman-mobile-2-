import 'package:equatable/equatable.dart';
import '../../models/order_model.dart';

abstract class OrderState extends Equatable {
  const OrderState();

  @override
  List<Object> get props => [];
}

class OrderInitial extends OrderState {}

class OrderLoading extends OrderState {}

class OrderLoaded extends OrderState {
  final List<Order> activeOrders;
  final List<Order> historyOrders;

  // Computed property for combined view
  List<Order> get allOrders {
    final combined = [...activeOrders, ...historyOrders];
    combined.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return combined;
  }

  int get activeCount => activeOrders.length;

  const OrderLoaded({
    this.activeOrders = const [],
    this.historyOrders = const [],
  });

  OrderLoaded copyWith({
    List<Order>? activeOrders,
    List<Order>? historyOrders,
  }) {
    return OrderLoaded(
      activeOrders: activeOrders ?? this.activeOrders,
      historyOrders: historyOrders ?? this.historyOrders,
    );
  }

  @override
  List<Object> get props => [activeOrders, historyOrders];
}

class OrderError extends OrderState {
  final String message;

  const OrderError(this.message);

  @override
  List<Object> get props => [message];
}

class OrderOperationSuccess extends OrderState {
  final String message;
  const OrderOperationSuccess(this.message);
  @override
  List<Object> get props => [message];
}
