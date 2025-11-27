# 🍽️ ProPlanet Food Ordering System - Complete Design & Implementation Guide

## 📋 Overview

This document outlines the complete design and implementation plan for integrating a food ordering system into ProPlanet that promotes eco-friendly choices through gamification and environmental impact awareness.

---

## 🎯 Core Concept

**Goal**: Create a food ordering system where:
- **Admin** can upload food items with checkout options (cutlery, covers, boxes)
- **Users** can order food and earn points for eco-friendly choices
- **System** warns users about environmental impact of plastic choices
- **System** rewards users with points for declining plastic items

---

## 🗄️ Database Structure (Firestore)

### 1. Admin Collection
```
admins/{adminId}
├── email: string
├── name: string
├── role: "admin"
├── createdAt: timestamp
└── isActive: boolean
```

### 2. Food Items Collection
```
foodItems/{foodId}
├── name: string
├── description: string
├── price: number
├── imageUrl: string
├── category: string (e.g., "main", "appetizer", "dessert")
├── restaurantName: string
├── restaurantLocation: {
│   ├── latitude: number
│   ├── longitude: number
│   └── address: string
│   }
├── checkoutOptions: [
│   {
│     id: string
│     name: string (e.g., "Cutlery", "Plastic Cover", "Paper Box")
│     type: "plastic" | "paper" | "eco-friendly"
│     environmentalImpact: "high" | "medium" | "low"
│     pointsReward: number (points given if NOT selected)
│     pointsPenalty: number (points lost if selected, optional)
│     isDefault: boolean
│   }
│   ]
├── isAvailable: boolean
├── createdAt: timestamp
└── createdBy: string (adminId)
```

### 3. User Orders Collection
```
users/{userId}/orders/{orderId}
├── orderId: string
├── items: [
│   {
│     foodId: string
│     foodName: string
│     quantity: number
│     unitPrice: number
│     totalPrice: number
│     selectedOptions: [
│       {
│         optionId: string
│         optionName: string
│         optionType: "plastic" | "paper" | "eco-friendly"
│         environmentalImpact: "high" | "medium" | "low"
│       }
│     ]
│   }
│   ]
├── deliveryAddress: {
│   ├── street: string
│   ├── city: string
│   ├── state: string
│   ├── zipCode: string
│   ├── latitude: number
│   └── longitude: number
│   }
├── subtotal: number
├── totalPrice: number
├── ecoPointsEarned: number
├── ecoPointsLost: number
├── netPointsEarned: number
├── orderStatus: "pending" | "confirmed" | "preparing" | "ready" | "delivered" | "cancelled"
├── createdAt: timestamp
├── estimatedDeliveryTime: timestamp
└── restaurantLocation: {
    ├── latitude: number
    ├── longitude: number
    └── address: string
    }
```

### 4. User Addresses Collection
```
users/{userId}/addresses/{addressId}
├── addressId: string
├── label: string (e.g., "Home", "Work", "Office")
├── street: string
├── city: string
├── state: string
├── zipCode: string
├── latitude: number
├── longitude: number
├── isDefault: boolean
├── createdAt: timestamp
└── updatedAt: timestamp
```

### 5. Order History (for analytics)
```
orderHistory/{orderId}
├── userId: string
├── orderId: string
├── items: array
├── ecoPointsEarned: number
├── ecoPointsLost: number
├── plasticItemsSelected: number
├── ecoFriendlyChoices: number
├── createdAt: timestamp
└── environmentalImpact: {
    ├── plasticWasteAvoided: number (grams)
    ├── co2Saved: number (kg)
    └── treesEquivalent: number
    }
```

---

## 🔐 Admin Panel Architecture

### Admin Authentication
- **Separate Admin Login**: Create admin authentication flow
- **Role-Based Access**: Only users with admin role can access admin panel
- **Security**: Admin credentials stored securely in Firestore

### Admin Panel Features

#### 1. Admin Login Screen
- Email/Password authentication
- Admin role verification
- Secure session management

#### 2. Food Item Management
- **Add Food Item**:
  - Upload food image (Firebase Storage)
  - Enter food name, description, price
  - Select category
  - Add restaurant name and location (coordinates)
  - Configure checkout options with environmental impact settings
  
- **Edit Food Item**:
  - Update all fields
  - Change availability status
  
- **Delete Food Item**:
  - Soft delete (mark as unavailable)
  - Or hard delete with confirmation

#### 3. Checkout Options Configuration
For each food item, admin can add options like:
- **Cutlery**: 
  - Type: "plastic"
  - Environmental Impact: "high"
  - Points Reward: 10 (if NOT selected)
  - Points Penalty: -5 (if selected, optional)
  
- **Plastic Cover**:
  - Type: "plastic"
  - Environmental Impact: "high"
  - Points Reward: 15 (if NOT selected)
  
- **Paper Box**:
  - Type: "paper"
  - Environmental Impact: "low"
  - Points Reward: 5 (if NOT selected)

#### 4. Restaurant Management
- Add restaurant location (coordinates)
- View all restaurants on map
- Edit restaurant details

---

## 👤 User Panel Architecture

### User Features

#### 1. Food Ordering Icon/Button
- Add to HomeScreen navigation
- Icon: 🍽️ or shopping cart icon
- Badge showing cart item count

#### 2. Food Menu Screen
- Display all available food items
- Grid/List view toggle
- Filter by category
- Search functionality
- Show:
  - Food image
  - Name, description
  - Price
  - Restaurant name
  - Distance (if location enabled)

#### 3. Food Detail Screen
- Large food image
- Full description
- Price
- Quantity selector (+/-)
- Dynamic price calculation
- Restaurant location on map
- "Add to Cart" button

#### 4. Shopping Cart Screen
- List of selected items
- Quantity adjustment
- Remove items
- Subtotal calculation
- "Proceed to Checkout" button

#### 5. Checkout Screen
- **Delivery Address Selection**:
  - Select from saved addresses
  - Add new address
  - Set default address
  
- **Checkout Options Selection**:
  - For each item, show available options
  - Toggle switches for each option
  - **Real-time Environmental Impact Display**:
    - Show warning if plastic selected
    - Show points reward if eco-friendly choice
    - Visual indicators (red for plastic, green for eco-friendly)
  
- **Order Summary**:
  - Items list
  - Subtotal
  - Delivery fee (if applicable)
  - **Eco Points Preview**:
    - Points earned for eco-friendly choices
    - Points lost for plastic choices (if penalty enabled)
    - Net points earned
  
- **Place Order** button

#### 6. Order Confirmation & Points System
When order is placed:
1. **Calculate Points**:
   - For each item's selected options
   - If option NOT selected (eco-friendly): Add points
   - If option selected (plastic): Show warning, optionally deduct points
   
2. **Trigger Notifications**:
   - **If Plastic Selected**: 
     ```
     "⚠️ Environmental Impact Alert!
     You selected plastic items. Plastic takes 450+ years to decompose and harms marine life. 
     Consider eco-friendly alternatives next time!"
     ```
   
   - **If Eco-Friendly Choice**:
     ```
     "🌱 Great Choice!
     You declined plastic items and earned +25 points! 
     Your eco-friendly choice helps protect our planet!"
     ```
   
3. **Update Points**:
   - Add points to user's total
   - Update category points (add "food" category)
   - Update daily points
   - Trigger level up check

4. **Save Order**:
   - Save to user's orders collection
   - Save to order history for analytics

#### 7. Order History Screen
- List of past orders
- Order status
- Points earned per order
- Re-order functionality

#### 8. Address Management (Settings)
- View all saved addresses
- Add new address
- Edit address
- Delete address
- Set default address
- Use current location

---

## 🎮 Points System Integration

### Points Calculation Logic

```dart
class FoodOrderPointsCalculator {
  // Calculate points for an order
  static int calculateOrderPoints(List<CartItem> items) {
    int totalPoints = 0;
    
    for (var item in items) {
      for (var option in item.selectedOptions) {
        // If option is NOT selected (eco-friendly choice)
        if (!option.isSelected && option.type == 'plastic') {
          totalPoints += option.pointsReward;
        }
        // If option IS selected (plastic choice) - optional penalty
        else if (option.isSelected && option.type == 'plastic' && option.pointsPenalty > 0) {
          totalPoints -= option.pointsPenalty;
        }
      }
    }
    
    return totalPoints;
  }
  
  // Calculate environmental impact
  static Map<String, double> calculateEnvironmentalImpact(List<CartItem> items) {
    double plasticWasteAvoided = 0.0;
    double co2Saved = 0.0;
    
    for (var item in items) {
      for (var option in item.selectedOptions) {
        if (!option.isSelected && option.type == 'plastic') {
          // Calculate based on option type
          switch (option.name.toLowerCase()) {
            case 'cutlery':
              plasticWasteAvoided += 15.0; // grams
              co2Saved += 0.05; // kg CO2
              break;
            case 'plastic cover':
              plasticWasteAvoided += 10.0;
              co2Saved += 0.03;
              break;
            case 'plastic box':
              plasticWasteAvoided += 25.0;
              co2Saved += 0.08;
              break;
          }
        }
      }
    }
    
    return {
      'plasticWasteAvoided': plasticWasteAvoided,
      'co2Saved': co2Saved,
      'treesEquivalent': co2Saved / 0.02, // 1 tree = 0.02 kg CO2
    };
  }
}
```

### Points Integration with Existing System

```dart
// In checkout process
Future<void> processOrder(Order order) async {
  // Calculate points
  final pointsEarned = FoodOrderPointsCalculator.calculateOrderPoints(order.items);
  
  // Calculate environmental impact
  final impact = FoodOrderPointsCalculator.calculateEnvironmentalImpact(order.items);
  
  // Add points to user (using existing PointsProvider)
  await pointsProvider.addPoints(
    pointsEarned,
    category: 'food',
  );
  
  // Update environmental impact in user profile
  await firebaseService.updateUserData(userId, {
    'environmentalImpact.food': FieldValue.increment(impact['co2Saved'] ?? 0),
  });
  
  // Trigger notifications
  if (order.hasPlasticItems) {
    await notificationProvider.sendEnvironmentalWarning(order);
  } else {
    await notificationProvider.sendEcoFriendlyReward(pointsEarned);
  }
}
```

---

## 🔔 Notification System Integration

### Environmental Warning Notification

```dart
Future<void> sendEnvironmentalWarning(Order order) async {
  final plasticItems = order.items
      .expand((item) => item.selectedOptions)
      .where((opt) => opt.isSelected && opt.type == 'plastic')
      .toList();
  
  final message = '''
⚠️ Environmental Impact Alert!

You selected ${plasticItems.length} plastic item(s) in your order:
${plasticItems.map((item) => '• ${item.optionName}').join('\n')}

🌍 Did you know?
• Plastic takes 450+ years to decompose
• Millions of marine animals die from plastic pollution annually
• Plastic production contributes to climate change

💚 Next time, consider eco-friendly alternatives to earn points and protect our planet!
  ''';
  
  await notificationProvider.addNotification(
    AppNotification(
      id: 'env_warning_${DateTime.now().millisecondsSinceEpoch}',
      title: '🌍 Environmental Impact Alert',
      body: message,
      type: NotificationType.tips,
      scheduledTime: DateTime.now(),
    ),
  );
}
```

### Eco-Friendly Reward Notification

```dart
Future<void> sendEcoFriendlyReward(int points) async {
  await notificationProvider.sendAchievementNotification(
    '🌱 Eco-Friendly Choice!',
    'You earned +$points points for choosing eco-friendly options! Your sustainable choices help protect our planet! 🎉',
    data: {
      'points': points,
      'type': 'food_order',
    },
  );
}
```

---

## 📱 Implementation Plan

### Phase 1: Database & Models (Week 1)
1. Create Firestore collections structure
2. Create data models:
   - `FoodItem` model
   - `CheckoutOption` model
   - `Order` model
   - `OrderItem` model
   - `DeliveryAddress` model
3. Update Firestore security rules

### Phase 2: Admin Panel (Week 2-3)
1. Create admin authentication
2. Build admin login screen
3. Create food item management screens
4. Implement image upload (Firebase Storage)
5. Build checkout options configuration UI
6. Add restaurant location picker

### Phase 3: User Panel - Basic Features (Week 4-5)
1. Add food ordering icon to HomeScreen
2. Create food menu screen
3. Build food detail screen
4. Implement shopping cart
5. Create checkout screen
6. Implement address management

### Phase 4: Points & Notifications (Week 6)
1. Integrate points calculation
2. Implement environmental impact warnings
3. Add eco-friendly reward notifications
4. Update PointsProvider for food category
5. Add points animation on checkout

### Phase 5: Order Management (Week 7)
1. Create order history screen
2. Implement order status tracking
3. Add re-order functionality
4. Build order analytics

### Phase 6: Testing & Polish (Week 8)
1. Comprehensive testing
2. UI/UX improvements
3. Performance optimization
4. Bug fixes

---

## 🔒 Security Considerations

### Firestore Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Admin access
    function isAdmin() {
      return request.auth != null && 
             get(/databases/$(database)/documents/admins/$(request.auth.uid)).data.role == 'admin';
    }
    
    // Food items - all authenticated users can read, only admins can write
    match /foodItems/{foodId} {
      allow read: if request.auth != null;
      allow write: if isAdmin();
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
      allow read, write: if isAdmin();
    }
  }
}
```

---

## 🎨 UI/UX Design Guidelines

### Color Coding for Environmental Impact
- **Red**: Plastic items (harmful)
- **Green**: Eco-friendly choices (reward)
- **Yellow**: Paper items (moderate impact)
- **Blue**: Neutral items

### Visual Indicators
- ⚠️ Warning icon for plastic selections
- 🌱 Eco-friendly badge for sustainable choices
- 💚 Points reward indicator
- 📍 Location/map integration

### Animations
- Points animation when order is placed
- Success animation for eco-friendly choices
- Warning animation for plastic selections

---

## 📊 Analytics & Reporting

### Admin Analytics
- Total orders
- Most popular items
- Eco-friendly choice percentage
- Plastic usage statistics
- Revenue by item

### User Analytics
- Total eco points from food orders
- Environmental impact (CO2 saved, plastic avoided)
- Order history
- Eco-friendly choice streak

---

## 🚀 Next Steps

1. **Review this design** with stakeholders
2. **Set up Firestore collections** with sample data
3. **Create data models** in Flutter
4. **Build admin panel** first (easier to test)
5. **Implement user panel** with points integration
6. **Test thoroughly** with real scenarios
7. **Deploy and monitor** user behavior

---

## 💡 Additional Features (Future Enhancements)

1. **Restaurant Ratings**: Users can rate restaurants
2. **Favorites**: Save favorite food items
3. **Dietary Preferences**: Filter by vegetarian, vegan, etc.
4. **Loyalty Program**: Extra points for frequent orders
5. **Group Orders**: Share orders with friends
6. **Scheduled Orders**: Order in advance
7. **Carbon Footprint Calculator**: Show total environmental impact
8. **Eco-Friendly Restaurant Badge**: Highlight sustainable restaurants

---

This design provides a complete, integrated solution that aligns with ProPlanet's mission of promoting environmental consciousness through gamification and user engagement.

