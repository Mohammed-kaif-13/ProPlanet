import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/food_item_model.dart';
import '../models/order_model.dart';
import '../utils/food_order_points_calculator.dart';

/// Provider for managing food ordering functionality
class FoodOrderingProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Food items
  List<FoodItem> _foodItems = [];
  bool _isLoadingFoodItems = false;
  String? _foodItemsError;

  // Cart
  List<CartItem> _cartItems = [];
  double _cartSubtotal = 0.0;

  // Orders
  List<FoodOrder> _userOrders = [];
  bool _isLoadingOrders = false;
  String? _ordersError;

  // Addresses
  List<DeliveryAddress> _userAddresses = [];
  bool _isLoadingAddresses = false;
  String? _addressesError;

  // Getters
  List<FoodItem> get foodItems => _foodItems;
  bool get isLoadingFoodItems => _isLoadingFoodItems;
  String? get foodItemsError => _foodItemsError;

  List<CartItem> get cartItems => _cartItems;
  double get cartSubtotal => _cartSubtotal;
  int get cartItemCount => _cartItems.fold(0, (sum, item) => sum + item.quantity);
  bool get isCartEmpty => _cartItems.isEmpty;

  List<FoodOrder> get userOrders => _userOrders;
  bool get isLoadingOrders => _isLoadingOrders;
  String? get ordersError => _ordersError;

  List<DeliveryAddress> get userAddresses => _userAddresses;
  DeliveryAddress? get defaultAddress =>
      _userAddresses.firstWhere((addr) => addr.isDefault, orElse: () => _userAddresses.isNotEmpty ? _userAddresses.first : DeliveryAddress(addressId: '', label: '', street: '', city: '', state: '', zipCode: '', latitude: 0, longitude: 0, createdAt: DateTime.now()));
  bool get isLoadingAddresses => _isLoadingAddresses;
  String? get addressesError => _addressesError;

  // ==================== FOOD ITEMS ====================

  /// Load all available food items
  Future<void> loadFoodItems() async {
    _isLoadingFoodItems = true;
    _foodItemsError = null;
    notifyListeners();

    try {
      // Try with index first (preferred method)
      try {
        final querySnapshot = await _firestore
            .collection('foodItems')
            .where('isAvailable', isEqualTo: true)
            .orderBy('createdAt', descending: true)
            .get();

        _foodItems = querySnapshot.docs
            .map((doc) => FoodItem.fromFirestore(doc))
            .toList();
      } catch (e) {
        // If index not ready, fallback to in-memory sorting
        if (e.toString().contains('index') || e.toString().contains('FAILED_PRECONDITION')) {
          print('Index not ready, using fallback query...');
          final querySnapshot = await _firestore
              .collection('foodItems')
              .where('isAvailable', isEqualTo: true)
              .get();

          // Sort in memory
          final sortedDocs = querySnapshot.docs.toList()
            ..sort((a, b) {
              final aData = a.data();
              final bData = b.data();
              final aTime = (aData['createdAt'] as Timestamp?)?.toDate() ?? DateTime(1970);
              final bTime = (bData['createdAt'] as Timestamp?)?.toDate() ?? DateTime(1970);
              return bTime.compareTo(aTime); // Descending order
            });

          _foodItems = sortedDocs
              .map((doc) => FoodItem.fromFirestore(doc))
              .toList();
        } else {
          rethrow;
        }
      }

      _foodItemsError = null;
    } catch (e) {
      _foodItemsError = 'Failed to load food items: $e';
      print('Error loading food items: $e');
    } finally {
      _isLoadingFoodItems = false;
      notifyListeners();
    }
  }

  /// Get food items by category
  List<FoodItem> getFoodItemsByCategory(String category) {
    return _foodItems.where((item) => item.category == category).toList();
  }

  /// Search food items
  List<FoodItem> searchFoodItems(String query) {
    if (query.isEmpty) return _foodItems;
    final lowerQuery = query.toLowerCase();
    return _foodItems.where((item) {
      return item.name.toLowerCase().contains(lowerQuery) ||
          item.description.toLowerCase().contains(lowerQuery) ||
          item.restaurantName.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  // ==================== CART MANAGEMENT ====================

  /// Add item to cart
  void addToCart(FoodItem foodItem, {int quantity = 1}) {
    final existingIndex = _cartItems.indexWhere(
      (item) => item.foodItem.id == foodItem.id,
    );

    if (existingIndex != -1) {
      // Update quantity
      _cartItems[existingIndex] = _cartItems[existingIndex].copyWith(
        quantity: _cartItems[existingIndex].quantity + quantity,
      );
    } else {
      // Add new item
      _cartItems.add(CartItem(
        foodItem: foodItem,
        quantity: quantity,
        selectedOptions: foodItem.checkoutOptions
            .map((opt) => SelectedCheckoutOption(
                  optionId: opt.id,
                  optionName: opt.name,
                  optionType: opt.type,
                  environmentalImpact: opt.environmentalImpact,
                  isSelected: opt.isDefault,
                ))
            .toList(),
      ));
    }

    _updateCartSubtotal();
    notifyListeners();
  }

  /// Update cart item quantity
  void updateCartItemQuantity(String foodId, int quantity) {
    if (quantity <= 0) {
      removeFromCart(foodId);
      return;
    }

    final index = _cartItems.indexWhere((item) => item.foodItem.id == foodId);
    if (index != -1) {
      _cartItems[index] = _cartItems[index].copyWith(quantity: quantity);
      _updateCartSubtotal();
      notifyListeners();
    }
  }

  /// Remove item from cart
  void removeFromCart(String foodId) {
    _cartItems.removeWhere((item) => item.foodItem.id == foodId);
    _updateCartSubtotal();
    notifyListeners();
  }

  /// Clear cart
  void clearCart() {
    _cartItems.clear();
    _cartSubtotal = 0.0;
    notifyListeners();
  }

  /// Update checkout option selection for cart item
  void updateCheckoutOption(String foodId, String optionId, bool isSelected) {
    final cartItemIndex = _cartItems.indexWhere(
      (item) => item.foodItem.id == foodId,
    );

    if (cartItemIndex != -1) {
      final updatedOptions = _cartItems[cartItemIndex].selectedOptions.map((opt) {
        if (opt.optionId == optionId) {
          return opt.copyWith(isSelected: isSelected);
        }
        return opt;
      }).toList();

      _cartItems[cartItemIndex] = _cartItems[cartItemIndex].copyWith(
        selectedOptions: updatedOptions,
      );

      notifyListeners();
    }
  }

  /// Calculate cart points preview
  Map<String, dynamic> getCartPointsPreview() {
    int pointsEarned = 0;
    int pointsLost = 0;
    List<String> ecoFriendlyChoices = [];
    List<String> plasticChoices = [];

    for (var cartItem in _cartItems) {
      // Match selected options with original checkout options from FoodItem
      for (var selectedOption in cartItem.selectedOptions) {
        // Find the original checkout option to get points values
        final originalOption = cartItem.foodItem.checkoutOptions.firstWhere(
          (opt) => opt.id == selectedOption.optionId,
          orElse: () => CheckoutOption(
            id: selectedOption.optionId,
            name: selectedOption.optionName,
            type: selectedOption.optionType,
            environmentalImpact: selectedOption.environmentalImpact,
            pointsReward: 0,
            pointsPenalty: 0,
          ),
        );

        // PLASTIC OPTIONS (Harmful to environment)
        if (originalOption.isHarmful) {
          // If NOT selected (user declined plastic) → EARN points (reward for eco-friendly choice)
          if (!selectedOption.isSelected) {
            final reward = originalOption.pointsReward;
            pointsEarned += reward;
            ecoFriendlyChoices.add(
              'Declined ${selectedOption.optionName} (+$reward pts)',
            );
          }
          // If SELECTED (user chose plastic) → LOSE points (penalty for harmful choice)
          else if (selectedOption.isSelected) {
            final penalty = originalOption.pointsPenalty ?? 0;
            if (penalty > 0) {
              pointsLost += penalty;
              plasticChoices.add(
                'Selected ${selectedOption.optionName} (-$penalty pts)',
              );
            } else {
              plasticChoices.add('Selected ${selectedOption.optionName}');
            }
          }
        }
        // PAPER/ECO-FRIENDLY OPTIONS (Good for environment)
        else if (originalOption.isEcoFriendly) {
          // If SELECTED (user chose eco-friendly) → EARN points (reward for good choice)
          if (selectedOption.isSelected) {
            // Use pointsReward for eco-friendly options when selected
            final reward = originalOption.pointsReward;
            if (reward > 0) {
              pointsEarned += reward;
              ecoFriendlyChoices.add(
                'Selected ${selectedOption.optionName} (+$reward pts)',
              );
            }
          }
          // If NOT selected (user declined eco-friendly) → No points change (neutral)
          // We don't penalize for not selecting eco-friendly options
        }
      }
    }

    return {
      'pointsEarned': pointsEarned,
      'pointsLost': pointsLost,
      'netPoints': pointsEarned - pointsLost,
      'ecoFriendlyChoices': ecoFriendlyChoices,
      'plasticChoices': plasticChoices,
    };
  }

  /// Update cart subtotal
  void _updateCartSubtotal() {
    _cartSubtotal = _cartItems.fold(
      0.0,
      (sum, item) => sum + (item.foodItem.price * item.quantity),
    );
  }

  // ==================== ORDERS ====================

  /// Place order
  Future<FoodOrder> placeOrder({
    required String userId,
    required DeliveryAddress deliveryAddress,
    double deliveryFee = 0.0,
  }) async {
    if (_cartItems.isEmpty) {
      throw Exception('Cart is empty');
    }

    try {
      // Create order items
      final orderItems = _cartItems.map((cartItem) {
        return OrderItem(
          foodId: cartItem.foodItem.id,
          foodName: cartItem.foodItem.name,
          foodImageUrl: cartItem.foodItem.imageUrl,
          quantity: cartItem.quantity,
          unitPrice: cartItem.foodItem.price,
          totalPrice: cartItem.foodItem.price * cartItem.quantity,
          selectedOptions: cartItem.selectedOptions,
        );
      }).toList();

      // Calculate points
      final pointsBreakdown = FoodOrderPointsCalculator.calculatePointsBreakdown(
        orderItems,
      );
      final ecoPointsEarned = pointsBreakdown['pointsEarned'] as int;
      final ecoPointsLost = pointsBreakdown['pointsLost'] as int;
      final netPointsEarned = pointsBreakdown['netPoints'] as int;

      // Calculate totals
      final subtotal = _cartSubtotal;
      final totalPrice = subtotal + deliveryFee;

      // Create order
      final orderId = DateTime.now().millisecondsSinceEpoch.toString();
      final order = FoodOrder(
        orderId: orderId,
        userId: userId,
        items: orderItems,
        deliveryAddress: deliveryAddress,
        subtotal: subtotal,
        deliveryFee: deliveryFee,
        totalPrice: totalPrice,
        ecoPointsEarned: ecoPointsEarned,
        ecoPointsLost: ecoPointsLost,
        netPointsEarned: netPointsEarned,
        orderStatus: OrderStatus.pending,
        createdAt: DateTime.now(),
        estimatedDeliveryTime: DateTime.now().add(const Duration(minutes: 30)),
        restaurantLocation: _cartItems.first.foodItem.restaurantLocation,
      );

      // Save order to Firestore
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('orders')
          .doc(orderId)
          .set(order.toJson());

      // Clear cart
      clearCart();

      return order;
    } catch (e) {
      print('Error placing order: $e');
      throw Exception('Failed to place order: $e');
    }
  }

  /// Load user orders
  Future<void> loadUserOrders(String userId) async {
    _isLoadingOrders = true;
    _ordersError = null;
    notifyListeners();

    try {
      final querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('orders')
          .orderBy('createdAt', descending: true)
          .get();

      _userOrders = querySnapshot.docs
          .map((doc) => FoodOrder.fromFirestore(doc))
          .toList();

      _ordersError = null;
    } catch (e) {
      _ordersError = 'Failed to load orders: $e';
      print('Error loading orders: $e');
    } finally {
      _isLoadingOrders = false;
      notifyListeners();
    }
  }

  // ==================== ADDRESSES ====================

  /// Load user addresses
  Future<void> loadUserAddresses(String userId) async {
    _isLoadingAddresses = true;
    _addressesError = null;
    notifyListeners();

    try {
      final querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('addresses')
          .orderBy('createdAt', descending: true)
          .get();

      _userAddresses = querySnapshot.docs
          .map((doc) {
            final data = doc.data();
            return DeliveryAddress.fromJson({
              'addressId': doc.id,
              ...data,
            });
          })
          .toList();

      _addressesError = null;
    } catch (e) {
      _addressesError = 'Failed to load addresses: $e';
      print('Error loading addresses: $e');
    } finally {
      _isLoadingAddresses = false;
      notifyListeners();
    }
  }

  /// Add new address
  Future<void> addAddress(String userId, DeliveryAddress address) async {
    try {
      final docRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('addresses')
          .doc();

      // If this is set as default, unset other defaults
      if (address.isDefault) {
        await _unsetDefaultAddresses(userId);
      }

      await docRef.set({
        'addressId': docRef.id,
        ...address.copyWith(addressId: docRef.id).toJson(),
      });

      await loadUserAddresses(userId);
    } catch (e) {
      print('Error adding address: $e');
      throw Exception('Failed to add address: $e');
    }
  }

  /// Update address
  Future<void> updateAddress(String userId, DeliveryAddress address) async {
    try {
      // If this is set as default, unset other defaults
      if (address.isDefault) {
        await _unsetDefaultAddresses(userId, excludeId: address.addressId);
      }

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('addresses')
          .doc(address.addressId)
          .update(address.toJson());

      await loadUserAddresses(userId);
    } catch (e) {
      print('Error updating address: $e');
      throw Exception('Failed to update address: $e');
    }
  }

  /// Delete address
  Future<void> deleteAddress(String userId, String addressId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('addresses')
          .doc(addressId)
          .delete();

      await loadUserAddresses(userId);
    } catch (e) {
      print('Error deleting address: $e');
      throw Exception('Failed to delete address: $e');
    }
  }

  /// Unset default addresses
  Future<void> _unsetDefaultAddresses(String userId, {String? excludeId}) async {
    final querySnapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('addresses')
        .where('isDefault', isEqualTo: true)
        .get();

    final batch = _firestore.batch();
    for (var doc in querySnapshot.docs) {
      if (excludeId == null || doc.id != excludeId) {
        batch.update(doc.reference, {'isDefault': false});
      }
    }
    await batch.commit();
  }
}

/// Cart item model
class CartItem {
  final FoodItem foodItem;
  final int quantity;
  final List<SelectedCheckoutOption> selectedOptions;

  CartItem({
    required this.foodItem,
    required this.quantity,
    required this.selectedOptions,
  });

  CartItem copyWith({
    FoodItem? foodItem,
    int? quantity,
    List<SelectedCheckoutOption>? selectedOptions,
  }) {
    return CartItem(
      foodItem: foodItem ?? this.foodItem,
      quantity: quantity ?? this.quantity,
      selectedOptions: selectedOptions ?? this.selectedOptions,
    );
  }

  double get totalPrice => foodItem.price * quantity;
}

/// Extension for SelectedCheckoutOption
extension SelectedCheckoutOptionExtension on SelectedCheckoutOption {
  SelectedCheckoutOption copyWith({
    String? optionId,
    String? optionName,
    String? optionType,
    String? environmentalImpact,
    bool? isSelected,
  }) {
    return SelectedCheckoutOption(
      optionId: optionId ?? this.optionId,
      optionName: optionName ?? this.optionName,
      optionType: optionType ?? this.optionType,
      environmentalImpact: environmentalImpact ?? this.environmentalImpact,
      isSelected: isSelected ?? this.isSelected,
    );
  }
}

