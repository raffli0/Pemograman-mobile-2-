import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:point_of_sale/models/menu_item_model.dart';
import 'cart_item_model.dart';

enum OrderStatus { pending, preparing, ready, completed, cancelled }

enum PaymentMethod { cash, cashless }

class Order {
  final String id;
  final String customerId;
  final String customerName;
  final List<CartItem> items;
  final double totalAmount;
  final PaymentMethod paymentMethod;
  final OrderStatus status;
  final DateTime createdAt;
  final DateTime? completedAt;

  Order({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.items,
    required this.totalAmount,
    required this.paymentMethod,
    required this.status,
    required this.createdAt,
    this.completedAt,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customerId': customerId,
      'customerName': customerName,
      'items': items.map((item) => item.toMap()).toList(),
      'totalAmount': totalAmount,
      'paymentMethod': paymentMethod.name,
      'status': status.name,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'completedAt': completedAt?.millisecondsSinceEpoch,
    };
  }

  // Create from Firestore Map
  factory Order.fromMap(Map<String, dynamic> map, String documentId) {
    DateTime parseDate(dynamic value) {
      if (value is Timestamp) {
        return value.toDate();
      } else if (value is int) {
        return DateTime.fromMillisecondsSinceEpoch(value);
      }
      return DateTime.now();
    }

    DateTime? parseNullableDate(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) {
        return value.toDate();
      } else if (value is int) {
        return DateTime.fromMillisecondsSinceEpoch(value);
      }
      return null;
    }

    return Order(
      id: documentId,
      customerId: map['customerId'] ?? '',
      customerName: map['customerName'] ?? '',
      items:
          (map['items'] as List<dynamic>?)?.map((item) {
            // Reconstruct CartItem from stored data
            return CartItem(
              menuItem: MenuItem(
                id: item['menuItemId'] ?? '',
                name: item['menuItemName'] ?? '',
                description: '',
                price: (item['menuItemPrice'] ?? 0).toDouble(),
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              ),
              quantity: item['quantity'] ?? 1,
            );
          }).toList() ??
          [],
      totalAmount: (map['totalAmount'] ?? 0).toDouble(),
      paymentMethod: PaymentMethod.values.firstWhere(
        (e) => e.name == map['paymentMethod'],
        orElse: () => PaymentMethod.cash,
      ),
      status: OrderStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => OrderStatus.pending,
      ),
      createdAt: parseDate(map['createdAt']),
      completedAt: parseNullableDate(map['completedAt']),
    );
  }

  Order copyWith({
    String? id,
    String? customerId,
    String? customerName,
    List<CartItem>? items,
    double? totalAmount,
    PaymentMethod? paymentMethod,
    OrderStatus? status,
    DateTime? createdAt,
    DateTime? completedAt,
  }) {
    return Order(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      items: items ?? this.items,
      totalAmount: totalAmount ?? this.totalAmount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}
