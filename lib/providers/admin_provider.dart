import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../models/food_item_model.dart';
import '../models/order_model.dart';

/// Provider for admin functionality
class AdminProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Admin state
  bool _isAdmin = false;
  bool _isLoading = false;
  String? _error;
  String? _adminId;

  // Food items management
  List<FoodItem> _adminFoodItems = [];
  bool _isLoadingFoodItems = false;

  // Orders management
  List<FoodOrder> _allOrders = [];
  bool _isLoadingOrders = false;

  // Getters
  bool get isAdmin => _isAdmin;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get adminId => _adminId;
  List<FoodItem> get adminFoodItems => _adminFoodItems;
  bool get isLoadingFoodItems => _isLoadingFoodItems;
  List<FoodOrder> get allOrders => _allOrders;
  bool get isLoadingOrders => _isLoadingOrders;

  // ==================== ADMIN AUTHENTICATION ====================

  /// Check if current user is admin
  Future<bool> checkAdminStatus(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final doc = await _firestore.collection('admins').doc(userId).get();

      if (doc.exists) {
        final data = doc.data()!;
        _isAdmin = data['isActive'] == true && data['role'] == 'admin';
        _adminId = userId;
      } else {
        _isAdmin = false;
        _adminId = null;
      }

      _error = null;
      return _isAdmin;
    } catch (e) {
      _error = 'Failed to check admin status: $e';
      _isAdmin = false;
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Create admin account (for initial setup)
  Future<void> createAdminAccount({
    required String userId,
    required String email,
    required String name,
  }) async {
    try {
      await _firestore.collection('admins').doc(userId).set({
        'email': email,
        'name': name,
        'role': 'admin',
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      _isAdmin = true;
      _adminId = userId;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to create admin account: $e';
      throw Exception('Failed to create admin account: $e');
    }
  }

  // ==================== FOOD ITEMS MANAGEMENT ====================

  /// Load all food items (admin view)
  Future<void> loadAdminFoodItems() async {
    if (!_isAdmin) {
      throw Exception('User is not an admin');
    }

    _isLoadingFoodItems = true;
    notifyListeners();

    try {
      final querySnapshot = await _firestore
          .collection('foodItems')
          .orderBy('createdAt', descending: true)
          .get();

      _adminFoodItems = querySnapshot.docs
          .map((doc) => FoodItem.fromFirestore(doc))
          .toList();

      _error = null;
    } catch (e) {
      _error = 'Failed to load food items: $e';
      print('Error loading food items: $e');
    } finally {
      _isLoadingFoodItems = false;
      notifyListeners();
    }
  }

  /// Upload food item image to Firebase Storage
  Future<String> uploadFoodImage(File imageFile, String foodId) async {
    try {
      final ref = _storage
          .ref()
          .child('food_items')
          .child('$foodId.jpg');

      final uploadTask = ref.putFile(imageFile);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      print('Error uploading image: $e');
      throw Exception('Failed to upload image: $e');
    }
  }

  /// Add new food item
  Future<void> addFoodItem({
    required FoodItem foodItem,
    File? imageFile,
  }) async {
    if (!_isAdmin) {
      throw Exception('User is not an admin');
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      String imageUrl = foodItem.imageUrl;

      // Upload image if provided
      if (imageFile != null) {
        imageUrl = await uploadFoodImage(imageFile, foodItem.id);
      }

      // Create food item with image URL
      final foodItemWithImage = foodItem.copyWith(
        imageUrl: imageUrl,
        createdBy: _adminId!,
        createdAt: DateTime.now(),
      );

      // Save to Firestore
      await _firestore
          .collection('foodItems')
          .doc(foodItem.id)
          .set(foodItemWithImage.toJson());

      await loadAdminFoodItems();
      _error = null;
    } catch (e) {
      _error = 'Failed to add food item: $e';
      print('Error adding food item: $e');
      throw Exception('Failed to add food item: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update food item
  Future<void> updateFoodItem({
    required FoodItem foodItem,
    File? imageFile,
  }) async {
    if (!_isAdmin) {
      throw Exception('User is not an admin');
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      String imageUrl = foodItem.imageUrl;

      // Upload new image if provided
      if (imageFile != null) {
        imageUrl = await uploadFoodImage(imageFile, foodItem.id);
      }

      // Update food item
      final updatedFoodItem = foodItem.copyWith(imageUrl: imageUrl);

      await _firestore
          .collection('foodItems')
          .doc(foodItem.id)
          .update(updatedFoodItem.toJson());

      await loadAdminFoodItems();
      _error = null;
    } catch (e) {
      _error = 'Failed to update food item: $e';
      print('Error updating food item: $e');
      throw Exception('Failed to update food item: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Delete food item (soft delete - mark as unavailable)
  Future<void> deleteFoodItem(String foodId) async {
    if (!_isAdmin) {
      throw Exception('User is not an admin');
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _firestore.collection('foodItems').doc(foodId).update({
        'isAvailable': false,
      });

      await loadAdminFoodItems();
      _error = null;
    } catch (e) {
      _error = 'Failed to delete food item: $e';
      print('Error deleting food item: $e');
      throw Exception('Failed to delete food item: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Hard delete food item (permanent removal)
  Future<void> hardDeleteFoodItem(String foodId) async {
    if (!_isAdmin) {
      throw Exception('User is not an admin');
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _firestore.collection('foodItems').doc(foodId).delete();

      // Also delete image from storage
      try {
        await _storage.ref().child('food_items').child('$foodId.jpg').delete();
      } catch (e) {
        print('Error deleting image: $e');
        // Continue even if image deletion fails
      }

      await loadAdminFoodItems();
      _error = null;
    } catch (e) {
      _error = 'Failed to delete food item: $e';
      print('Error deleting food item: $e');
      throw Exception('Failed to delete food item: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ==================== ORDERS MANAGEMENT ====================

  /// Load all orders from all users (admin view)
  Future<void> loadAllOrders() async {
    if (!_isAdmin) {
      throw Exception('User is not an admin');
    }

    // Schedule state update after current frame to avoid setState during build
    Future.microtask(() {
      _isLoadingOrders = true;
      _error = null;
      notifyListeners();
    });

    try {
      // Get all users
      final usersSnapshot = await _firestore.collection('users').get();
      List<FoodOrder> orders = [];

      // For each user, get their orders
      for (var userDoc in usersSnapshot.docs) {
        final userId = userDoc.id;
        try {
          final ordersSnapshot = await _firestore
              .collection('users')
              .doc(userId)
              .collection('orders')
              .orderBy('createdAt', descending: true)
              .get();

          for (var orderDoc in ordersSnapshot.docs) {
            try {
              final orderData = orderDoc.data();
              final order = FoodOrder.fromJson({
                'orderId': orderDoc.id,
                'userId': userId,
                ...orderData,
              });
              orders.add(order);
            } catch (e) {
              print('Error parsing order ${orderDoc.id}: $e');
              // Continue with other orders
            }
          }
        } catch (e) {
          print('Error loading orders for user $userId: $e');
          // Continue with other users
        }
      }

      // Sort by creation date (newest first)
      orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      _allOrders = orders;
      _error = null;
    } catch (e) {
      _error = 'Failed to load orders: $e';
      print('Error loading all orders: $e');
    } finally {
      _isLoadingOrders = false;
      // Schedule state update after current frame
      Future.microtask(() {
        notifyListeners();
      });
    }
  }

  /// Update order status
  Future<void> updateOrderStatus(String userId, String orderId, OrderStatus newStatus) async {
    if (!_isAdmin) {
      throw Exception('User is not an admin');
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('orders')
          .doc(orderId)
          .update({
        'orderStatus': newStatus.toString().split('.').last,
      });

      // Reload orders
      await loadAllOrders();
      _error = null;
    } catch (e) {
      _error = 'Failed to update order status: $e';
      print('Error updating order status: $e');
      throw Exception('Failed to update order status: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Logout admin
  void logout() {
    _isAdmin = false;
    _adminId = null;
    _adminFoodItems.clear();
    _allOrders.clear();
    _error = null;
    notifyListeners();
  }
}


