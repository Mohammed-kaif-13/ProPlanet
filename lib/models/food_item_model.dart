import 'package:cloud_firestore/cloud_firestore.dart';

/// Checkout option model - represents options like cutlery, covers, boxes
class CheckoutOption {
  final String id;
  final String name;
  final String type; // "plastic", "paper", "eco-friendly"
  final String environmentalImpact; // "high", "medium", "low"
  final int pointsReward; // Points given if NOT selected (eco-friendly choice)
  final int? pointsPenalty; // Points lost if selected (optional, for plastic items)
  final bool isDefault; // Whether this option is selected by default

  CheckoutOption({
    required this.id,
    required this.name,
    required this.type,
    required this.environmentalImpact,
    required this.pointsReward,
    this.pointsPenalty,
    this.isDefault = false,
  });

  factory CheckoutOption.fromJson(Map<String, dynamic> json) {
    return CheckoutOption(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      type: json['type'] ?? 'plastic',
      environmentalImpact: json['environmentalImpact'] ?? 'high',
      pointsReward: json['pointsReward'] ?? 0,
      pointsPenalty: json['pointsPenalty'],
      isDefault: json['isDefault'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'environmentalImpact': environmentalImpact,
      'pointsReward': pointsReward,
      'pointsPenalty': pointsPenalty,
      'isDefault': isDefault,
    };
  }

  CheckoutOption copyWith({
    String? id,
    String? name,
    String? type,
    String? environmentalImpact,
    int? pointsReward,
    int? pointsPenalty,
    bool? isDefault,
  }) {
    return CheckoutOption(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      environmentalImpact: environmentalImpact ?? this.environmentalImpact,
      pointsReward: pointsReward ?? this.pointsReward,
      pointsPenalty: pointsPenalty ?? this.pointsPenalty,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  /// Check if this option is harmful to environment
  bool get isHarmful => type == 'plastic' && environmentalImpact == 'high';

  /// Check if this option is eco-friendly
  bool get isEcoFriendly => type == 'eco-friendly' || type == 'paper';
}

/// Restaurant location model
class RestaurantLocation {
  final double latitude;
  final double longitude;
  final String address;

  RestaurantLocation({
    required this.latitude,
    required this.longitude,
    required this.address,
  });

  factory RestaurantLocation.fromJson(Map<String, dynamic> json) {
    return RestaurantLocation(
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      address: json['address'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
    };
  }
}

/// Food item model
class FoodItem {
  final String id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final String category; // "main", "appetizer", "dessert", "beverage"
  final String restaurantName;
  final RestaurantLocation restaurantLocation;
  final List<CheckoutOption> checkoutOptions;
  final bool isAvailable;
  final DateTime createdAt;
  final String createdBy; // adminId

  FoodItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.category,
    required this.restaurantName,
    required this.restaurantLocation,
    required this.checkoutOptions,
    this.isAvailable = true,
    required this.createdAt,
    required this.createdBy,
  });

  factory FoodItem.fromJson(Map<String, dynamic> json) {
    return FoodItem(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] ?? 0.0).toDouble(),
      imageUrl: json['imageUrl'] ?? '',
      category: json['category'] ?? 'main',
      restaurantName: json['restaurantName'] ?? '',
      restaurantLocation: RestaurantLocation.fromJson(
        json['restaurantLocation'] ?? {},
      ),
      checkoutOptions: (json['checkoutOptions'] as List<dynamic>?)
              ?.map((opt) => CheckoutOption.fromJson(opt))
              .toList() ??
          [],
      isAvailable: json['isAvailable'] ?? true,
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      createdBy: json['createdBy'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'imageUrl': imageUrl,
      'category': category,
      'restaurantName': restaurantName,
      'restaurantLocation': restaurantLocation.toJson(),
      'checkoutOptions': checkoutOptions.map((opt) => opt.toJson()).toList(),
      'isAvailable': isAvailable,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
    };
  }

  factory FoodItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      throw Exception('Document data is null');
    }
    return FoodItem.fromJson({'id': doc.id, ...data});
  }

  FoodItem copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    String? imageUrl,
    String? category,
    String? restaurantName,
    RestaurantLocation? restaurantLocation,
    List<CheckoutOption>? checkoutOptions,
    bool? isAvailable,
    DateTime? createdAt,
    String? createdBy,
  }) {
    return FoodItem(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      restaurantName: restaurantName ?? this.restaurantName,
      restaurantLocation: restaurantLocation ?? this.restaurantLocation,
      checkoutOptions: checkoutOptions ?? this.checkoutOptions,
      isAvailable: isAvailable ?? this.isAvailable,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }
}



