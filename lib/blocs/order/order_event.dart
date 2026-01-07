import 'package:equatable/equatable.dart';
import '../../models/order_model.dart';
import '../../models/cart_item_model.dart';

abstract class OrderEvent extends Equatable {
  const OrderEvent();

  @override
  List<Object> get props => [];
}

class LoadHistoryOrders extends OrderEvent {
  // Can filter by customerId if needed, or separate event
  final String? customerId;
  const LoadHistoryOrders({this.customerId});
  @override
  List<Object> get props => [customerId ?? ''];
}

class StartPollingQueue extends OrderEvent {
  final String? customerId; // If provided, filters queue for customer
  const StartPollingQueue({this.customerId});
  @override
  List<Object> get props => [customerId ?? ''];
}

class StopPollingQueue extends OrderEvent {}

class CreateOrder extends OrderEvent {
  final String customerId;
  final String customerName;
  final List<CartItem> items;
  final PaymentMethod paymentMethod;

  const CreateOrder({
    required this.customerId,
    required this.customerName,
    required this.items,
    required this.paymentMethod,
  });

  @override
  List<Object> get props => [customerId, customerName, items, paymentMethod];
}

class UpdateOrderStatus extends OrderEvent {
  final String orderId;
  final OrderStatus status;

  const UpdateOrderStatus(this.orderId, this.status);

  @override
  List<Object> get props => [orderId, status];
}

class CancelOrder extends OrderEvent {
  final String orderId;

  const CancelOrder(this.orderId);

  @override
  List<Object> get props => [orderId];
}
