import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:firebase_auth/firebase_auth.dart';
import '../core/api_constants.dart';
import '../models/order_model.dart';

class OrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection reference (History)
  CollectionReference get _historyCollection => _firestore.collection('orders');

  // Helper to get authenticated URL
  Future<Uri> _getAuthUrl(String endpoint) async {
    final token = await _auth.currentUser?.getIdToken();
    final queryParams = token != null ? {'auth': token} : null;
    return Uri.parse(
      '${ApiConstants.baseUrl}$endpoint.json',
    ).replace(queryParameters: queryParams);
  }

  // Create new order (REST POST to Queue)
  Future<String> createOrder(Order order) async {
    try {
      final uri = await _getAuthUrl('/queue/orders');

      // We rely on RTDB to generate the ID (push)
      // Or we can generate one here and PUT.
      // Let's use POST (push) and get the ID back.

      // Note: order.id is likely empty or a temporary one.
      // We will send the data without explicit ID key if possible,
      // or we accept the ID RTDB gives us.

      final response = await http.post(uri, body: json.encode(order.toMap()));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final String newId = data['name'];
        // Ideally we update the order in RTDB to include its own ID field if needed
        return newId;
      } else {
        throw Exception('Failed to create order: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Fetch pending/active orders (REST GET from Queue) - For Cashier Polling
  Future<List<Order>> fetchActiveOrders() async {
    try {
      final uri = await _getAuthUrl('/queue/orders');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        if (response.body == 'null') return [];
        final data = json.decode(response.body);

        final List<Order> orders = [];
        if (data is Map<String, dynamic>) {
          data.forEach((key, value) {
            // Include ID from key
            orders.add(Order.fromMap(value, key));
          });
        }

        // Sort oldest first
        orders.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        return orders;
      }
      return [];
    } catch (e) {
      print('Error fetching orders: $e');
      return [];
    }
  }

  // Move Order to History (Complete Order)
  Future<void> completeOrder(String orderId) async {
    try {
      // 1. Get from Queue
      final uriGet = await _getAuthUrl('/queue/orders/$orderId');
      final response = await http.get(uriGet);

      if (response.statusCode != 200 || response.body == 'null') {
        throw Exception('Order not found in queue');
      }
      final data = json.decode(response.body);
      final order = Order.fromMap(data, orderId);

      // 2. Update status to completed
      final completedOrder = order.copyWith(
        status: OrderStatus.completed,
        completedAt: DateTime.now(),
      );

      // 3. Save to Firestore History
      await _historyCollection.doc(orderId).set(completedOrder.toMap());

      // 4. Delete from Queue
      await http.delete(uriGet);
    } catch (e) {
      rethrow;
    }
  }

  // Update Order Status in Queue (REST PATCH)
  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    try {
      // If completed, use completeOrder logic instead
      if (status == OrderStatus.completed) {
        await completeOrder(orderId);
        return;
      }

      // Otherwise update in Queue
      final uri = await _getAuthUrl('/queue/orders/$orderId');
      await http.patch(uri, body: json.encode({'status': status.name}));
    } catch (e) {
      rethrow;
    }
  }

  // Cancel Order (Delete from Queue, maybe save to history as cancelled?)
  Future<void> cancelOrder(String orderId) async {
    try {
      final uri = await _getAuthUrl('/queue/orders/$orderId');
      // Option A: Just delete
      // await http.delete(uri);

      // Option B: Mark cancelled in queue (or move to history)
      await http.patch(
        uri,
        body: json.encode({'status': OrderStatus.cancelled.name}),
      );
    } catch (e) {
      rethrow;
    }
  }

  // Get historical orders (Firestore SDK)
  Stream<List<Order>> getHistoryOrders() {
    return _historyCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(
                (doc) =>
                    Order.fromMap(doc.data() as Map<String, dynamic>, doc.id),
              )
              .toList();
        });
  }

  // Get customer specific history orders (Firestore SDK)
  Stream<List<Order>> getCustomerHistoryOrders(String customerId) {
    return _historyCollection
        .where('customerId', isEqualTo: customerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(
                (doc) =>
                    Order.fromMap(doc.data() as Map<String, dynamic>, doc.id),
              )
              .toList();
        });
  }

  // Fetch active orders for specific customer (Hybrid Helper)
  Future<List<Order>> fetchCustomerActiveOrders(String customerId) async {
    final allActive = await fetchActiveOrders();
    return allActive.where((o) => o.customerId == customerId).toList();
  }
}
