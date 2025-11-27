import 'package:cloud_firestore/cloud_firestore.dart';
import 'food_item_model.dart';

/// Delivery address model
class DeliveryAddress {
  final String addressId;
  final String label; // "Home", "Work", "Office"
  final String street;
  final String city;
  final String state;
  final String zipCode;
  final double latitude;
  final double longitude;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime? updatedAt;

  DeliveryAddress({
    required this.addressId,
    required this.label,
    required this.street,
    required this.city,
    required this.state,
    required this.zipCode,
    required this.latitude,
    required this.longitude,
    this.isDefault = false,
    required this.createdAt,
    this.updatedAt,
  });

  factory DeliveryAddress.fromJson(Map<String, dynamic> json) {
    return DeliveryAddress(
      addressId: json['addressId'] ?? '',
      label: json['label'] ?? '',
      street: json['street'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      zipCode: json['zipCode'] ?? '',
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      isDefault: json['isDefault'] ?? false,
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? (json['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'addressId': addressId,
      'label': label,
      'street': street,
      'city': city,
      'state': state,
      'zipCode': zipCode,
      'latitude': latitude,
      'longitude': longitude,
      'isDefault': isDefault,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  String get fullAddress => '$street, $city, $state $zipCode';

  DeliveryAddress copyWith({
    String? addressId,
    String? label,
    String? street,
    String? city,
    String? state,
    String? zipCode,
    double? latitude,
    double? longitude,
    bool? isDefault,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DeliveryAddress(
      addressId: addressId ?? this.addressId,
      label: label ?? this.label,
      street: street ?? this.street,
      city: city ?? this.city,
      state: state ?? this.state,
      zipCode: zipCode ?? this.zipCode,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Selected checkout option in an order
class SelectedCheckoutOption {
  final String optionId;
  final String optionName;
  final String optionType; // "plastic", "paper", "eco-friendly"
  final String environmentalImpact; // "high", "medium", "low"
  final bool isSelected;

  SelectedCheckoutOption({
    required this.optionId,
    required this.optionName,
    required this.optionType,
    required this.environmentalImpact,
    required this.isSelected,
  });

  factory SelectedCheckoutOption.fromJson(Map<String, dynamic> json) {
    return SelectedCheckoutOption(
      optionId: json['optionId'] ?? '',
      optionName: json['optionName'] ?? '',
      optionType: json['optionType'] ?? 'plastic',
      environmentalImpact: json['environmentalImpact'] ?? 'high',
      isSelected: json['isSelected'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'optionId': optionId,
      'optionName': optionName,
      'optionType': optionType,
      'environmentalImpact': environmentalImpact,
      'isSelected': isSelected,
    };
  }

  bool get isHarmful => optionType == 'plastic' && environmentalImpact == 'high';
}

/// Order item model
class OrderItem {
  final String foodId;
  final String foodName;
  final String foodImageUrl;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final List<SelectedCheckoutOption> selectedOptions;

  OrderItem({
    required this.foodId,
    required this.foodName,
    required this.foodImageUrl,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    required this.selectedOptions,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      foodId: json['foodId'] ?? '',
      foodName: json['foodName'] ?? '',
      foodImageUrl: json['foodImageUrl'] ?? '',
      quantity: json['quantity'] ?? 1,
      unitPrice: (json['unitPrice'] ?? 0.0).toDouble(),
      totalPrice: (json['totalPrice'] ?? 0.0).toDouble(),
      selectedOptions: (json['selectedOptions'] as List<dynamic>?)
              ?.map((opt) => SelectedCheckoutOption.fromJson(opt))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'foodId': foodId,
      'foodName': foodName,
      'foodImageUrl': foodImageUrl,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'totalPrice': totalPrice,
      'selectedOptions': selectedOptions.map((opt) => opt.toJson()).toList(),
    };
  }

  bool get hasPlasticItems =>
      selectedOptions.any((opt) => opt.isSelected && opt.isHarmful);
}

/// Order status enum
enum OrderStatus {
  pending,
  confirmed,
  preparing,
  ready,
  delivered,
  cancelled,
}

/// Food Order model
class FoodOrder {
  final String orderId;
  final String userId;
  final List<OrderItem> items;
  final DeliveryAddress deliveryAddress;
  final double subtotal;
  final double deliveryFee;
  final double totalPrice;
  final int ecoPointsEarned;
  final int ecoPointsLost;
  final int netPointsEarned;
  final OrderStatus orderStatus;
  final DateTime createdAt;
  final DateTime? estimatedDeliveryTime;
  final RestaurantLocation restaurantLocation;

  FoodOrder({
    required this.orderId,
    required this.userId,
    required this.items,
    required this.deliveryAddress,
    required this.subtotal,
    this.deliveryFee = 0.0,
    required this.totalPrice,
    required this.ecoPointsEarned,
    required this.ecoPointsLost,
    required this.netPointsEarned,
    required this.orderStatus,
    required this.createdAt,
    this.estimatedDeliveryTime,
    required this.restaurantLocation,
  });

  factory FoodOrder.fromJson(Map<String, dynamic> json) {
    return FoodOrder(
      orderId: json['orderId'] ?? '',
      userId: json['userId'] ?? '',
      items: (json['items'] as List<dynamic>?)
              ?.map((item) => OrderItem.fromJson(item))
              .toList() ??
          [],
      deliveryAddress: DeliveryAddress.fromJson(
        json['deliveryAddress'] ?? {},
      ),
      subtotal: (json['subtotal'] ?? 0.0).toDouble(),
      deliveryFee: (json['deliveryFee'] ?? 0.0).toDouble(),
      totalPrice: (json['totalPrice'] ?? 0.0).toDouble(),
      ecoPointsEarned: json['ecoPointsEarned'] ?? 0,
      ecoPointsLost: json['ecoPointsLost'] ?? 0,
      netPointsEarned: json['netPointsEarned'] ?? 0,
      orderStatus: OrderStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['orderStatus'],
        orElse: () => OrderStatus.pending,
      ),
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      estimatedDeliveryTime: json['estimatedDeliveryTime'] != null
          ? (json['estimatedDeliveryTime'] as Timestamp).toDate()
          : null,
      restaurantLocation: RestaurantLocation.fromJson(
        json['restaurantLocation'] ?? {},
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'orderId': orderId,
      'userId': userId,
      'items': items.map((item) => item.toJson()).toList(),
      'deliveryAddress': deliveryAddress.toJson(),
      'subtotal': subtotal,
      'deliveryFee': deliveryFee,
      'totalPrice': totalPrice,
      'ecoPointsEarned': ecoPointsEarned,
      'ecoPointsLost': ecoPointsLost,
      'netPointsEarned': netPointsEarned,
      'orderStatus': orderStatus.toString().split('.').last,
      'createdAt': Timestamp.fromDate(createdAt),
      'estimatedDeliveryTime': estimatedDeliveryTime != null
          ? Timestamp.fromDate(estimatedDeliveryTime!)
          : null,
      'restaurantLocation': restaurantLocation.toJson(),
    };
  }

  factory FoodOrder.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      throw Exception('Document data is null');
    }
    return FoodOrder.fromJson({'orderId': doc.id, ...data});
  }

  bool get hasPlasticItems =>
      items.any((item) => item.hasPlasticItems);

  int get plasticItemsCount {
    int count = 0;
    for (var item in items) {
      for (var option in item.selectedOptions) {
        if (option.isSelected && option.isHarmful) {
          count++;
        }
      }
    }
    return count;
  }
}


