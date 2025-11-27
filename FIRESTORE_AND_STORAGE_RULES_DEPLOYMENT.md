# 🔒 Complete Firestore & Storage Rules Deployment Guide

## 📋 Overview

This guide provides step-by-step instructions for deploying the complete security rules for ProPlanet, including:
- ✅ Existing ProPlanet functionality (users, activities, points, etc.)
- ✅ Admin panel access
- ✅ Food ordering system
- ✅ Firebase Storage rules for food images

---

## 🚀 Step 1: Deploy Firestore Security Rules

### Option A: Firebase Console (Recommended for Beginners)

1. **Go to Firebase Console**
   - Visit: https://console.firebase.google.com
   - Select your ProPlanet project: `proplanet-5987f`

2. **Navigate to Firestore Database**
   - Click on "Firestore Database" in the left sidebar
   - Click on the "Rules" tab

3. **Copy and Paste Rules**
   - Open the file: `firestore_rules_complete.rules`
   - Copy ALL the content
   - Paste it into the Firebase Console rules editor
   - Click "Publish" button

4. **Verify Deployment**
   - You should see a success message
   - Rules will be active immediately

### Option B: Firebase CLI (For Developers)

1. **Install Firebase CLI** (if not already installed)
   ```bash
   npm install -g firebase-tools
   ```

2. **Login to Firebase**
   ```bash
   firebase login
   ```

3. **Initialize Firebase** (if not already done)
   ```bash
   cd proplanet
   firebase init firestore
   ```
   - Select "Use an existing project"
   - Choose your ProPlanet project
   - When asked for rules file, use: `firestore_rules_complete.rules`

4. **Deploy Rules**
   ```bash
   firebase deploy --only firestore:rules
   ```

### Option C: Copy File to firestore.rules

1. **Copy the complete rules file**
   ```bash
   # Windows
   copy firestore_rules_complete.rules firestore.rules
   
   # Mac/Linux
   cp firestore_rules_complete.rules firestore.rules
   ```

2. **Deploy using Firebase CLI**
   ```bash
   firebase deploy --only firestore:rules
   ```

---

## 🗄️ Step 2: Deploy Firebase Storage Rules

### Option A: Firebase Console (Recommended)

1. **Go to Firebase Console**
   - Visit: https://console.firebase.google.com
   - Select your ProPlanet project

2. **Navigate to Storage**
   - Click on "Storage" in the left sidebar
   - Click on the "Rules" tab

3. **Copy and Paste Rules**
   - Open the file: `storage_rules_complete.rules`
   - Copy ALL the content
   - Paste it into the Firebase Console rules editor
   - Click "Publish" button

4. **Verify Deployment**
   - You should see a success message
   - Rules will be active immediately

### Option B: Firebase CLI

1. **Initialize Storage** (if not already done)
   ```bash
   firebase init storage
   ```
   - Select "Use an existing project"
   - Choose your ProPlanet project
   - When asked for rules file, use: `storage_rules_complete.rules`

2. **Deploy Storage Rules**
   ```bash
   firebase deploy --only storage
   ```

### Option C: Manual File Setup

1. **Create storage.rules file** (if using Firebase CLI)
   ```bash
   # Copy the storage rules
   copy storage_rules_complete.rules storage.rules
   ```

2. **Deploy**
   ```bash
   firebase deploy --only storage
   ```

---

## 🔐 What These Rules Do

### Firestore Rules Features:

#### ✅ **Admin Access**
- Admins can access `admins` collection
- Admins can create/edit/delete food items
- Admin status verified through Firestore document

#### ✅ **Food Ordering System**
- All authenticated users can **read** food items
- Only admins can **create/edit/delete** food items
- Users can only access their own orders
- Users can only access their own addresses

#### ✅ **Existing ProPlanet Features**
- Users can access their own data (activities, points, achievements)
- Daily points and activities functionality preserved
- All existing collections protected

#### ✅ **Security**
- Authentication required for all operations
- User isolation (users can't access other users' data)
- Admin verification through Firestore document
- Deny all by default (secure by default)

### Storage Rules Features:

#### ✅ **Food Images**
- All authenticated users can **read** food images
- Only admins can **upload/delete** food images
- File size limit: 5MB
- File type validation: Images only

#### ✅ **User Content**
- Users can upload their own profile images
- Users can upload their own activity photos
- File size and type validation

#### ✅ **Security**
- Authentication required
- Admin verification for food images
- File validation (size and type)
- Deny all by default

---

## 🧪 Testing the Rules

### Test Firestore Rules:

1. **Test Admin Access**
   ```dart
   // Should work if user is admin
   await FirebaseFirestore.instance
       .collection('foodItems')
       .add({...});
   ```

2. **Test User Access**
   ```dart
   // Should work - users can read food items
   await FirebaseFirestore.instance
       .collection('foodItems')
       .get();
   
   // Should work - users can create their own orders
   await FirebaseFirestore.instance
       .collection('users')
       .doc(userId)
       .collection('orders')
       .add({...});
   ```

3. **Test Unauthorized Access**
   ```dart
   // Should fail - non-admin can't create food items
   await FirebaseFirestore.instance
       .collection('foodItems')
       .add({...});
   ```

### Test Storage Rules:

1. **Test Admin Upload**
   ```dart
   // Should work if user is admin
   await FirebaseStorage.instance
       .ref('food_items/item123.jpg')
       .putFile(imageFile);
   ```

2. **Test User Read**
   ```dart
   // Should work - users can read food images
   await FirebaseStorage.instance
       .ref('food_items/item123.jpg')
       .getDownloadURL();
   ```

3. **Test Unauthorized Upload**
   ```dart
   // Should fail - non-admin can't upload food images
   await FirebaseStorage.instance
       .ref('food_items/item123.jpg')
       .putFile(imageFile);
   ```

---

## 👤 Step 3: Create First Admin Account

### Method 1: Firebase Console (Easiest)

1. **Go to Firestore Database**
   - Open Firebase Console
   - Navigate to Firestore Database

2. **Create Admin Document**
   - Click "Start collection" or use existing collection
   - Collection ID: `admins`
   - Document ID: `[USER_ID]` (the Firebase Auth UID of the admin user)
   - Add fields:
     ```
     email: "admin@proplanet.com" (string)
     name: "Admin User" (string)
     role: "admin" (string)
     isActive: true (boolean)
     createdAt: [current timestamp]
     ```

3. **Get User ID**
   - Go to Authentication section
   - Find the user you want to make admin
   - Copy their UID
   - Use this UID as the document ID in `admins` collection

### Method 2: Using Flutter App

Create a temporary admin setup screen or use Firebase Console directly.

### Method 3: Firebase CLI

```bash
# Create admin document using Firebase CLI
firebase firestore:set admins/[USER_ID] \
  '{"email":"admin@proplanet.com","name":"Admin","role":"admin","isActive":true,"createdAt":"2024-01-01T00:00:00Z"}'
```

---

## 📊 Rules Structure Summary

### Firestore Collections:

```
✅ admins/{adminId}
   - Read: Own admin document
   - Write: Only admins

✅ foodItems/{foodId}
   - Read: All authenticated users
   - Write: Only admins

✅ users/{userId}
   - Read/Write: Own user data only

✅ users/{userId}/orders/{orderId}
   - Read/Write: Own orders only

✅ users/{userId}/addresses/{addressId}
   - Read/Write: Own addresses only

✅ users/{userId}/dailyPoints/{date}
   - Read/Write: Own daily points only

✅ users/{userId}/activities/{activityId}
   - Read/Write: Own activities only

✅ ... (all other existing collections)
```

### Storage Paths:

```
✅ food_items/{foodId}.jpg
   - Read: All authenticated users
   - Write: Only admins

✅ user_profiles/{userId}/**
   - Read/Write: Own profile images only

✅ activity_photos/{userId}/**
   - Read/Write: Own activity photos only
```

---

## ⚠️ Important Notes

### Before Deployment:

1. **Backup Current Rules**
   - Copy your current rules to a backup file
   - In case you need to revert

2. **Test in Development First**
   - Deploy to a test project first if possible
   - Verify all functionality works

3. **Check Admin Status**
   - Make sure you have at least one admin account created
   - Verify admin document structure is correct

### After Deployment:

1. **Test Immediately**
   - Test admin login
   - Test food item creation
   - Test user food ordering
   - Test image uploads

2. **Monitor Logs**
   - Check Firebase Console for any permission errors
   - Watch for any access denied errors

3. **Verify Functionality**
   - All existing ProPlanet features should still work
   - New food ordering features should work
   - Admin panel should be accessible

---

## 🆘 Troubleshooting

### Issue: "Permission Denied" Errors

**Solution:**
1. Check if user is authenticated
2. Verify admin document exists and `isActive: true`
3. Check if user ID matches admin document ID
4. Verify rules were deployed correctly

### Issue: Can't Upload Food Images

**Solution:**
1. Verify user is admin (check `admins` collection)
2. Check file size (must be < 5MB)
3. Check file type (must be image)
4. Verify Storage rules were deployed

### Issue: Can't Read Food Items

**Solution:**
1. Verify user is authenticated
2. Check Firestore rules were deployed
3. Verify `foodItems` collection exists
4. Check network connection

### Issue: Can't Create Orders

**Solution:**
1. Verify user is authenticated
2. Check user ID matches order userId
3. Verify Firestore rules allow user to write to their own orders
4. Check order data structure

---

## ✅ Deployment Checklist

- [ ] Firestore rules deployed successfully
- [ ] Storage rules deployed successfully
- [ ] Admin account created in Firestore
- [ ] Tested admin login
- [ ] Tested food item creation (admin)
- [ ] Tested food item reading (user)
- [ ] Tested order creation (user)
- [ ] Tested image upload (admin)
- [ ] Tested image reading (user)
- [ ] Verified existing ProPlanet features still work
- [ ] No permission errors in console

---

## 🎉 Success!

Once deployed, your ProPlanet app will have:
- ✅ Secure admin access for food management
- ✅ Public food item browsing for users
- ✅ Secure user order management
- ✅ Protected image storage
- ✅ All existing ProPlanet features preserved

Your food ordering system is now ready to use with proper security! 🚀

---

## 📝 Quick Reference

### Firestore Rules File:
- **Location**: `firestore_rules_complete.rules`
- **Deploy**: Firebase Console → Firestore → Rules → Paste → Publish

### Storage Rules File:
- **Location**: `storage_rules_complete.rules`
- **Deploy**: Firebase Console → Storage → Rules → Paste → Publish

### Admin Collection:
- **Path**: `admins/{userId}`
- **Required Fields**: `email`, `name`, `role: "admin"`, `isActive: true`

### Food Items Collection:
- **Path**: `foodItems/{foodId}`
- **Read**: All authenticated users
- **Write**: Only admins

### User Orders:
- **Path**: `users/{userId}/orders/{orderId}`
- **Access**: Own orders only

---

**Remember**: Always test thoroughly after deploying rules to ensure everything works correctly!



