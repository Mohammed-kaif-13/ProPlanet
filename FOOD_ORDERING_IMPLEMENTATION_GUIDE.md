# 🍽️ Food Ordering System - Step-by-Step Implementation Guide

## 📋 Overview

This guide provides detailed step-by-step instructions for implementing the food ordering system in ProPlanet.

---

## 🚀 Phase 1: Setup & Configuration

### Step 1.1: Update Dependencies

Add these dependencies to `pubspec.yaml`:

```yaml
dependencies:
  # ... existing dependencies ...
  image_picker: ^1.0.7  # For selecting images
  google_maps_flutter: ^2.5.0  # For location picker (optional)
  geolocator: ^14.0.2  # Already added
  geocoding: ^4.0.0  # Already added
```

Run:
```bash
flutter pub get
```

### Step 1.2: Update Firestore Security Rules

Add these rules to your Firestore security rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Helper function to check if user is admin
    function isAdmin() {
      return request.auth != null && 
             exists(/databases/$(database)/documents/admins/$(request.auth.uid)) &&
             get(/databases/$(database)/documents/admins/$(request.auth.uid)).data.isActive == true;
    }
    
    // Food items - all authenticated users can read, only admins can write
    match /foodItems/{foodId} {
      allow read: if request.auth != null;
      allow create, update, delete: if isAdmin();
    }
    
    // User orders - users can only access their own orders
    match /users/{userId}/orders/{orderId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // User addresses - users can only access their own addresses
    match /users/{userId}/addresses/{addressId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Admin collection - only admins can access
    match /admins/{adminId} {
      allow read: if request.auth != null && request.auth.uid == adminId;
      allow write: if isAdmin();
    }
  }
}
```

### Step 1.3: Update Firebase Storage Rules

Add storage rules for food images:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /food_items/{foodId}.jpg {
      allow read: if request.auth != null;
      allow write: if request.auth != null && 
                      exists(/databases/(default)/documents/admins/$(request.auth.uid)) &&
                      get(/databases/(default)/documents/admins/$(request.auth.uid)).data.isActive == true;
    }
  }
}
```

---

## 🔐 Phase 2: Admin Panel Implementation

### Step 2.1: Create Admin Login Screen

Create `lib/screens/admin/admin_login_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import 'admin_dashboard_screen.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final adminProvider = Provider.of<AdminProvider>(context, listen: false);

      // Login with email/password
      final success = await authProvider.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (success && authProvider.currentUser != null) {
        // Check if user is admin
        final isAdmin = await adminProvider.checkAdminStatus(
          authProvider.currentUser!.id,
        );

        if (isAdmin && mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
          );
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Access denied. Admin privileges required.'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _login,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Login as Admin'),
            ),
          ],
        ),
      ),
    );
  }
}
```

### Step 2.2: Create Admin Dashboard

Create `lib/screens/admin/admin_dashboard_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
import 'food_item_management_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Provider.of<AdminProvider>(context, listen: false).logout();
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.restaurant_menu),
            title: const Text('Manage Food Items'),
            subtitle: const Text('Add, edit, or delete food items'),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const FoodItemManagementScreen(),
                ),
              );
            },
          ),
          // Add more admin features here
        ],
      ),
    );
  }
}
```

### Step 2.3: Create Food Item Management Screen

Create `lib/screens/admin/food_item_management_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../providers/admin_provider.dart';
import '../../models/food_item_model.dart';
import 'add_food_item_screen.dart';

class FoodItemManagementScreen extends StatefulWidget {
  const FoodItemManagementScreen({super.key});

  @override
  State<FoodItemManagementScreen> createState() => _FoodItemManagementScreenState();
}

class _FoodItemManagementScreenState extends State<FoodItemManagementScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AdminProvider>(context, listen: false).loadAdminFoodItems();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Food Items Management'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const AddFoodItemScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: Consumer<AdminProvider>(
        builder: (context, adminProvider, child) {
          if (adminProvider.isLoadingFoodItems) {
            return const Center(child: CircularProgressIndicator());
          }

          final items = adminProvider.adminFoodItems;

          if (items.isEmpty) {
            return const Center(
              child: Text('No food items. Add your first item!'),
            );
          }

          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return ListTile(
                leading: item.imageUrl.isNotEmpty
                    ? Image.network(item.imageUrl, width: 50, height: 50)
                    : const Icon(Icons.fastfood),
                title: Text(item.name),
                subtitle: Text('\$${item.price.toStringAsFixed(2)}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () {
                        // Navigate to edit screen
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () {
                        adminProvider.deleteFoodItem(item.id);
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
```

### Step 2.4: Create Add Food Item Screen

Create `lib/screens/admin/add_food_item_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../providers/admin_provider.dart';
import '../../models/food_item_model.dart';

class AddFoodItemScreen extends StatefulWidget {
  const AddFoodItemScreen({super.key});

  @override
  State<AddFoodItemScreen> createState() => _AddFoodItemScreenState();
}

class _AddFoodItemScreenState extends State<AddFoodItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _restaurantNameController = TextEditingController();
  final _restaurantAddressController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();

  File? _selectedImage;
  String _selectedCategory = 'main';
  List<CheckoutOption> _checkoutOptions = [];

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  void _addCheckoutOption() {
    showDialog(
      context: context,
      builder: (context) => _CheckoutOptionDialog(
        onSave: (option) {
          setState(() {
            _checkoutOptions.add(option);
          });
        },
      ),
    );
  }

  Future<void> _saveFoodItem() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final foodItem = FoodItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        price: double.parse(_priceController.text),
        imageUrl: '', // Will be set after upload
        category: _selectedCategory,
        restaurantName: _restaurantNameController.text.trim(),
        restaurantLocation: RestaurantLocation(
          latitude: double.parse(_latitudeController.text),
          longitude: double.parse(_longitudeController.text),
          address: _restaurantAddressController.text.trim(),
        ),
        checkoutOptions: _checkoutOptions,
        isAvailable: true,
        createdAt: DateTime.now(),
        createdBy: '', // Will be set by provider
      );

      await Provider.of<AdminProvider>(context, listen: false).addFoodItem(
        foodItem: foodItem,
        imageFile: _selectedImage,
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Food item added successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Food Item')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Image picker
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _selectedImage != null
                    ? Image.file(_selectedImage!, fit: BoxFit.cover)
                    : const Center(child: Icon(Icons.add_photo_alternate)),
              ),
            ),
            const SizedBox(height: 16),
            
            // Name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Food Name'),
              validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
            ),
            
            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 3,
              validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
            ),
            
            // Price
            TextFormField(
              controller: _priceController,
              decoration: const InputDecoration(labelText: 'Price'),
              keyboardType: TextInputType.number,
              validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
            ),
            
            // Category
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(labelText: 'Category'),
              items: ['main', 'appetizer', 'dessert', 'beverage']
                  .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                  .toList(),
              onChanged: (value) => setState(() => _selectedCategory = value!),
            ),
            
            // Restaurant name
            TextFormField(
              controller: _restaurantNameController,
              decoration: const InputDecoration(labelText: 'Restaurant Name'),
              validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
            ),
            
            // Restaurant address
            TextFormField(
              controller: _restaurantAddressController,
              decoration: const InputDecoration(labelText: 'Restaurant Address'),
              validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
            ),
            
            // Coordinates
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _latitudeController,
                    decoration: const InputDecoration(labelText: 'Latitude'),
                    keyboardType: TextInputType.number,
                    validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _longitudeController,
                    decoration: const InputDecoration(labelText: 'Longitude'),
                    keyboardType: TextInputType.number,
                    validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Checkout options
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Checkout Options', style: TextStyle(fontSize: 16)),
                ElevatedButton.icon(
                  onPressed: _addCheckoutOption,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Option'),
                ),
              ],
            ),
            
            // List of checkout options
            ..._checkoutOptions.map((option) => ListTile(
              title: Text(option.name),
              subtitle: Text('${option.type} - ${option.environmentalImpact}'),
              trailing: IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () {
                  setState(() {
                    _checkoutOptions.remove(option);
                  });
                },
              ),
            )),
            
            const SizedBox(height: 24),
            
            // Save button
            ElevatedButton(
              onPressed: _saveFoodItem,
              child: const Text('Save Food Item'),
            ),
          ],
        ),
      ),
    );
  }
}

// Dialog for adding checkout options
class _CheckoutOptionDialog extends StatefulWidget {
  final Function(CheckoutOption) onSave;

  const _CheckoutOptionDialog({required this.onSave});

  @override
  State<_CheckoutOptionDialog> createState() => _CheckoutOptionDialogState();
}

class _CheckoutOptionDialogState extends State<_CheckoutOptionDialog> {
  final _nameController = TextEditingController();
  String _selectedType = 'plastic';
  String _selectedImpact = 'high';
  final _pointsRewardController = TextEditingController(text: '10');
  final _pointsPenaltyController = TextEditingController(text: '0');
  bool _isDefault = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Checkout Option'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Option Name (e.g., Cutlery)'),
            ),
            DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: const InputDecoration(labelText: 'Type'),
              items: ['plastic', 'paper', 'eco-friendly']
                  .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                  .toList(),
              onChanged: (value) => setState(() => _selectedType = value!),
            ),
            DropdownButtonFormField<String>(
              value: _selectedImpact,
              decoration: const InputDecoration(labelText: 'Environmental Impact'),
              items: ['high', 'medium', 'low']
                  .map((impact) => DropdownMenuItem(value: impact, child: Text(impact)))
                  .toList(),
              onChanged: (value) => setState(() => _selectedImpact = value!),
            ),
            TextField(
              controller: _pointsRewardController,
              decoration: const InputDecoration(
                labelText: 'Points Reward (if NOT selected)',
              ),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _pointsPenaltyController,
              decoration: const InputDecoration(
                labelText: 'Points Penalty (if selected, optional)',
              ),
              keyboardType: TextInputType.number,
            ),
            CheckboxListTile(
              title: const Text('Selected by default'),
              value: _isDefault,
              onChanged: (value) => setState(() => _isDefault = value ?? false),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final option = CheckoutOption(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              name: _nameController.text.trim(),
              type: _selectedType,
              environmentalImpact: _selectedImpact,
              pointsReward: int.parse(_pointsRewardController.text),
              pointsPenalty: int.tryParse(_pointsPenaltyController.text),
              isDefault: _isDefault,
            );
            widget.onSave(option);
            Navigator.of(context).pop();
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
```

---

## 👤 Phase 3: User Panel Implementation

### Step 3.1: Add Food Ordering Icon to HomeScreen

Update `lib/screens/home_screen.dart`:

```dart
// In HomeTab widget, add to AppBar actions or create a floating button
FloatingActionButton(
  onPressed: () {
    Navigator.of(context).pushNamed('/food-menu');
  },
  child: const Icon(Icons.restaurant),
  tooltip: 'Order Food',
),
```

### Step 3.2: Create Food Menu Screen

Create `lib/screens/food/food_menu_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/food_ordering_provider.dart';
import '../../models/food_item_model.dart';
import 'food_detail_screen.dart';

class FoodMenuScreen extends StatefulWidget {
  const FoodMenuScreen({super.key});

  @override
  State<FoodMenuScreen> createState() => _FoodMenuScreenState();
}

class _FoodMenuScreenState extends State<FoodMenuScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<FoodOrderingProvider>(context, listen: false).loadFoodItems();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Food'),
        actions: [
          Consumer<FoodOrderingProvider>(
            builder: (context, provider, child) {
              if (provider.cartItemCount > 0) {
                return Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.shopping_cart),
                      onPressed: () {
                        Navigator.of(context).pushNamed('/cart');
                      },
                    ),
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${provider.cartItemCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Consumer<FoodOrderingProvider>(
        builder: (context, provider, child) {
          if (provider.isLoadingFoodItems) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.foodItems.isEmpty) {
            return const Center(child: Text('No food items available'));
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.75,
            ),
            itemCount: provider.foodItems.length,
            itemBuilder: (context, index) {
              final item = provider.foodItems[index];
              return _FoodItemCard(foodItem: item);
            },
          );
        },
      ),
    );
  }
}

class _FoodItemCard extends StatelessWidget {
  final FoodItem foodItem;

  const _FoodItemCard({required this.foodItem});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => FoodDetailScreen(foodItem: foodItem),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: foodItem.imageUrl.isNotEmpty
                  ? Image.network(
                      foodItem.imageUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                    )
                  : Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.fastfood, size: 50),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    foodItem.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '\$${foodItem.price.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

### Step 3.3: Create Food Detail Screen

Create `lib/screens/food/food_detail_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/food_ordering_provider.dart';
import '../../models/food_item_model.dart';
import '../cart_screen.dart';

class FoodDetailScreen extends StatefulWidget {
  final FoodItem foodItem;

  const FoodDetailScreen({super.key, required this.foodItem});

  @override
  State<FoodDetailScreen> createState() => _FoodDetailScreenState();
}

class _FoodDetailScreenState extends State<FoodDetailScreen> {
  int _quantity = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.foodItem.name)),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            widget.foodItem.imageUrl.isNotEmpty
                ? Image.network(
                    widget.foodItem.imageUrl,
                    height: 250,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  )
                : Container(
                    height: 250,
                    color: Colors.grey[300],
                    child: const Icon(Icons.fastfood, size: 100),
                  ),
            
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name and price
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          widget.foodItem.name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        '\$${widget.foodItem.price.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Restaurant
                  Text(
                    widget.foodItem.restaurantName,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Description
                  Text(
                    widget.foodItem.description,
                    style: const TextStyle(fontSize: 16),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Quantity selector
                  Row(
                    children: [
                      const Text('Quantity:', style: TextStyle(fontSize: 18)),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: () {
                          if (_quantity > 1) {
                            setState(() => _quantity--);
                          }
                        },
                      ),
                      Text(
                        '$_quantity',
                        style: const TextStyle(fontSize: 18),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: () {
                          setState(() => _quantity++);
                        },
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Total price
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total:',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '\$${(widget.foodItem.price * _quantity).toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Add to cart button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Provider.of<FoodOrderingProvider>(context, listen: false)
                            .addToCart(widget.foodItem, quantity: _quantity);
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Added to cart!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                        
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Add to Cart'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

### Step 3.4: Create Cart Screen

Create `lib/screens/food/cart_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/food_ordering_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/points_provider.dart';
import '../../providers/notification_provider.dart';
import '../../services/firebase_service.dart';
import '../../utils/food_order_points_calculator.dart';
import 'checkout_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Shopping Cart')),
      body: Consumer<FoodOrderingProvider>(
        builder: (context, provider, child) {
          if (provider.isCartEmpty) {
            return const Center(
              child: Text('Your cart is empty'),
            );
          }

          final pointsPreview = provider.getCartPointsPreview();

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: provider.cartItems.length,
                  itemBuilder: (context, index) {
                    final cartItem = provider.cartItems[index];
                    return _CartItemCard(cartItem: cartItem);
                  },
                ),
              ),
              
              // Points preview
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.green[50],
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Eco Points Preview:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green[900],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Points Earned: +${pointsPreview['pointsEarned']}',
                      style: TextStyle(color: Colors.green[700]),
                    ),
                    if (pointsPreview['pointsLost'] > 0)
                      Text(
                        'Points Lost: -${pointsPreview['pointsLost']}',
                        style: const TextStyle(color: Colors.red),
                      ),
                    Text(
                      'Net Points: ${pointsPreview['netPoints']}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green[900],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Subtotal and checkout
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      spreadRadius: 1,
                      blurRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Subtotal:',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '\$${provider.cartSubtotal.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const CheckoutScreen(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Proceed to Checkout'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CartItemCard extends StatelessWidget {
  final CartItem cartItem;

  const _CartItemCard({required this.cartItem});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FoodOrderingProvider>(context, listen: false);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: cartItem.foodItem.imageUrl.isNotEmpty
            ? Image.network(cartItem.foodItem.imageUrl, width: 50, height: 50)
            : const Icon(Icons.fastfood),
        title: Text(cartItem.foodItem.name),
        subtitle: Text('\$${cartItem.foodItem.price.toStringAsFixed(2)} each'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.remove),
              onPressed: () {
                provider.updateCartItemQuantity(
                  cartItem.foodItem.id,
                  cartItem.quantity - 1,
                );
              },
            ),
            Text('${cartItem.quantity}'),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                provider.updateCartItemQuantity(
                  cartItem.foodItem.id,
                  cartItem.quantity + 1,
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () {
                provider.removeFromCart(cartItem.foodItem.id);
              },
            ),
          ],
        ),
      ),
    );
  }
}
```

### Step 3.5: Create Checkout Screen

Create `lib/screens/food/checkout_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/food_ordering_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/points_provider.dart';
import '../../providers/notification_provider.dart';
import '../../services/firebase_service.dart';
import '../../utils/food_order_points_calculator.dart';
import '../../models/order_model.dart';
import '../../models/food_item_model.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  DeliveryAddress? _selectedAddress;
  bool _isPlacingOrder = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.currentUser != null) {
        Provider.of<FoodOrderingProvider>(context, listen: false)
            .loadUserAddresses(authProvider.currentUser!.id);
      }
    });
  }

  Future<void> _placeOrder() async {
    if (_selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a delivery address')),
      );
      return;
    }

    setState(() => _isPlacingOrder = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final foodProvider = Provider.of<FoodOrderingProvider>(context, listen: false);
      final pointsProvider = Provider.of<PointsProvider>(context, listen: false);
      final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
      final firebaseService = FirebaseService();

      if (authProvider.currentUser == null) {
        throw Exception('User not logged in');
      }

      // Place order
      final order = await foodProvider.placeOrder(
        userId: authProvider.currentUser!.id,
        deliveryAddress: _selectedAddress!,
      );

      // Add points to user
      if (order.netPointsEarned > 0) {
        await pointsProvider.addPoints(
          order.netPointsEarned,
          category: 'food',
        );
      }

      // Update environmental impact
      final impact = FoodOrderPointsCalculator.calculateEnvironmentalImpact(
        order.items,
      );
      await firebaseService.updateUserData(
        authProvider.currentUser!.id,
        {
          'environmentalImpact.food': FieldValue.increment(impact['co2Saved'] ?? 0),
        },
      );

      // Send notifications
      if (order.hasPlasticItems) {
        final warningMessage = FoodOrderPointsCalculator
            .getEnvironmentalWarningMessage(order);
        await notificationProvider.addNotification(
          AppNotification(
            id: 'env_warning_${DateTime.now().millisecondsSinceEpoch}',
            title: '🌍 Environmental Impact Alert',
            body: warningMessage,
            type: NotificationType.tips,
            scheduledTime: DateTime.now(),
          ),
        );
      } else if (order.ecoPointsEarned > 0) {
        final rewardMessage = FoodOrderPointsCalculator
            .getEcoFriendlyRewardMessage(order.ecoPointsEarned);
        await notificationProvider.sendAchievementNotification(
          '🌱 Eco-Friendly Choice!',
          rewardMessage,
        );
      }

      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/home',
          (route) => false,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Order placed! ${order.netPointsEarned > 0 ? "You earned +${order.netPointsEarned} points!" : ""}',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error placing order: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPlacingOrder = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: Consumer<FoodOrderingProvider>(
        builder: (context, provider, child) {
          final pointsPreview = provider.getCartPointsPreview();

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Address selection
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Delivery Address',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      if (provider.userAddresses.isEmpty)
                        const Text('No addresses saved. Please add an address.'),
                      ...provider.userAddresses.map((address) {
                        return RadioListTile<DeliveryAddress>(
                          title: Text(address.label),
                          subtitle: Text(address.fullAddress),
                          value: address,
                          groupValue: _selectedAddress,
                          onChanged: (value) {
                            setState(() => _selectedAddress = value);
                          },
                        );
                      }),
                      TextButton.icon(
                        onPressed: () {
                          // Navigate to add address screen
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Add New Address'),
                      ),
                    ],
                  ),
                ),

                // Checkout options for each item
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Checkout Options',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ...provider.cartItems.map((cartItem) {
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ExpansionTile(
                            title: Text(cartItem.foodItem.name),
                            subtitle: Text('Quantity: ${cartItem.quantity}'),
                            children: cartItem.selectedOptions.map((option) {
                              return CheckboxListTile(
                                title: Text(option.optionName),
                                subtitle: Text(
                                  option.isHarmful
                                      ? '⚠️ Plastic - Harmful to environment'
                                      : '🌱 Eco-friendly',
                                  style: TextStyle(
                                    color: option.isHarmful ? Colors.red : Colors.green,
                                  ),
                                ),
                                value: option.isSelected,
                                onChanged: (value) {
                                  provider.updateCheckoutOption(
                                    cartItem.foodItem.id,
                                    option.optionId,
                                    value ?? false,
                                  );
                                },
                              );
                            }).toList(),
                          ),
                        );
                      }),
                    ],
                  ),
                ),

                // Points preview
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.green[50],
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Eco Points Preview:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text('Points Earned: +${pointsPreview['pointsEarned']}'),
                      if (pointsPreview['pointsLost'] > 0)
                        Text(
                          'Points Lost: -${pointsPreview['pointsLost']}',
                          style: const TextStyle(color: Colors.red),
                        ),
                      Text(
                        'Net Points: ${pointsPreview['netPoints']}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),

                // Order summary
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Order Summary',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Subtotal:'),
                          Text('\$${provider.cartSubtotal.toStringAsFixed(2)}'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total:',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '\$${provider.cartSubtotal.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Place order button
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isPlacingOrder ? null : _placeOrder,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isPlacingOrder
                          ? const CircularProgressIndicator()
                          : const Text('Place Order'),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
```

---

## 🔗 Phase 4: Integration with Existing System

### Step 4.1: Update main.dart

Add providers to `lib/main.dart`:

```dart
MultiProvider(
  providers: [
    // ... existing providers ...
    ChangeNotifierProvider(create: (_) => AdminProvider()),
    ChangeNotifierProvider(create: (_) => FoodOrderingProvider()),
  ],
  // ...
)
```

### Step 4.2: Add Routes

Update routes in `lib/main.dart`:

```dart
routes: {
  // ... existing routes ...
  '/admin-login': (context) => const AdminLoginScreen(),
  '/admin-dashboard': (context) => const AdminDashboardScreen(),
  '/food-menu': (context) => const FoodMenuScreen(),
  '/cart': (context) => const CartScreen(),
  '/checkout': (context) => const CheckoutScreen(),
},
```

---

## ✅ Testing Checklist

- [ ] Admin can login
- [ ] Admin can add food items with images
- [ ] Admin can configure checkout options
- [ ] Users can view food menu
- [ ] Users can add items to cart
- [ ] Users can select/deselect checkout options
- [ ] Points are calculated correctly
- [ ] Environmental warnings appear for plastic selections
- [ ] Points are awarded for eco-friendly choices
- [ ] Orders are saved to Firestore
- [ ] Addresses are saved and retrieved
- [ ] Notifications are sent correctly

---

## 🎉 You're Done!

Your food ordering system is now integrated with ProPlanet's environmental impact system. Users will be motivated to make eco-friendly choices through points and notifications!



