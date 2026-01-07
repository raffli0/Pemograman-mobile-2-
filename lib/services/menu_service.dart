import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/api_constants.dart';
import '../models/menu_item_model.dart';

class MenuService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection reference
  CollectionReference get _menuCollection =>
      _firestore.collection('menu_items');

  // Helper to get authenticated URL
  Future<Uri> _getAuthUrl(String endpoint) async {
    final token = await _auth.currentUser?.getIdToken();
    final queryParams = token != null ? {'auth': token} : null;
    return Uri.parse(
      '${ApiConstants.baseUrl}$endpoint.json',
    ).replace(queryParameters: queryParams);
  }

  // Get all menu items (Firestore SDK - Source of Truth)
  Stream<List<MenuItem>> getMenuItems() {
    return _menuCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(
                (doc) => MenuItem.fromMap(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ),
              )
              .toList();
        });
  }

  // Get availability status from Realtime DB (REST)
  Future<Map<String, bool>> getAvailabilityMap() async {
    try {
      final uri = await _getAuthUrl('/broadcast/menu_availability');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        if (response.body == 'null') return {};
        final data = json.decode(response.body);
        if (data is Map<String, dynamic>) {
          return data.map((key, value) => MapEntry(key, value as bool));
        }
      }
      return {};
    } catch (e) {
      print('Error fetching availability: $e');
      return {};
    }
  }

  // Get available menu items only
  Stream<List<MenuItem>> getAvailableMenuItems() {
    return _menuCollection
        .where('isAvailable', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(
                (doc) => MenuItem.fromMap(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ),
              )
              .toList();
        });
  }

  // Get single menu item
  Future<MenuItem?> getMenuItem(String id) async {
    try {
      final doc = await _menuCollection.doc(id).get();
      if (!doc.exists) return null;

      return MenuItem.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    } catch (e) {
      rethrow;
    }
  }

  // Add new menu item
  Future<void> addMenuItem(MenuItem item) async {
    try {
      // Generate ID first
      final docRef = _menuCollection.doc();
      // Update item with generated ID
      final newItem = item.copyWith(id: docRef.id);
      // Save to Firestore with specific ID
      await docRef.set(newItem.toMap());

      // Initialize availability in RTDB
      await toggleAvailability(docRef.id, true);
    } catch (e) {
      rethrow;
    }
  }

  // Update menu item
  Future<void> updateMenuItem(String id, MenuItem item) async {
    try {
      await _menuCollection.doc(id).update(item.toMap());
    } catch (e) {
      rethrow;
    }
  }

  // Delete menu item
  Future<void> deleteMenuItem(String id) async {
    try {
      // Get menu item to delete image if exists
      final menuItem = await getMenuItem(id);

      // Delete from Firestore
      await _menuCollection.doc(id).delete();

      // Delete from RTDB Availability
      try {
        final uri = await _getAuthUrl('/broadcast/menu_availability/$id');
        await http.delete(uri);
      } catch (_) {}

      // Delete image from Storage if exists
      if (menuItem?.imageUrl != null && menuItem!.imageUrl!.isNotEmpty) {
        try {
          final ref = _storage.refFromURL(menuItem.imageUrl!);
          await ref.delete();
        } catch (e) {
          // Image might not exist, continue anyway
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  // Toggle availability (REST PATCH to RTDB)
  Future<void> toggleAvailability(String id, bool isAvailable) async {
    try {
      // We store availability in /broadcast/menu_availability/{id}
      final uri = await _getAuthUrl('/broadcast/menu_availability');

      await http.patch(uri, body: json.encode({id: isAvailable}));
    } catch (e) {
      rethrow;
    }
  }

  // Upload menu item image
  Future<String> uploadMenuImage(File imageFile, String menuItemId) async {
    try {
      final String fileName =
          'menu_images/${menuItemId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final Reference ref = _storage.ref().child(fileName);

      final UploadTask uploadTask = ref.putFile(imageFile);
      final TaskSnapshot snapshot = await uploadTask;

      final String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      rethrow;
    }
  }
}
