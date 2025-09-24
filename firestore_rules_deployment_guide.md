# Firestore Security Rules Deployment Guide

## 🚨 CRITICAL: Update Firestore Security Rules

The app is currently failing to save daily points due to **PERMISSION_DENIED** errors. You need to update your Firestore security rules immediately.

## Current Issue
```
W/Firestore: Write failed at users/{userId}/dailyPoints/{date}: Status{code=PERMISSION_DENIED, description=Missing or insufficient permissions., cause=null}
```

## Solution

### Step 1: Access Firebase Console
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: `proplanet`
3. Navigate to **Firestore Database** → **Rules**

### Step 2: Replace Current Rules
Replace your current rules with the updated rules from `firestore_security_rules_updated.rules`:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow authenticated users to read/write their own user document
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      
      // Allow access to user's daily points collection
      match /dailyPoints/{date} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
      
      // Allow access to user's daily activities collection
      match /dailyActivities/{date} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
      
      // Allow access to user's activities collection
      match /activities/{activityId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
      
      // Allow access to user's userActivities collection
      match /userActivities/{userActivityId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
    
    // Allow authenticated users to read available activities
    match /activities/{activityId} {
      allow read: if request.auth != null;
    }
    
    // Allow authenticated users to read notifications
    match /notifications/{notificationId} {
      allow read, write: if request.auth != null && request.auth.uid == resource.data.userId;
    }
  }
}
```

### Step 3: Publish Rules
1. Click **Publish** button
2. Confirm the changes
3. Wait for deployment to complete

### Step 4: Test the App
1. Restart your Flutter app
2. Complete an activity
3. Check if daily points are now being saved

## What These Rules Do

- **User Documents**: Users can read/write their own user document
- **Daily Points**: Users can read/write their own daily points collection
- **Daily Activities**: Users can read/write their own daily activities collection
- **User Activities**: Users can read/write their own user activities collection
- **Public Activities**: All authenticated users can read available activities
- **Notifications**: Users can read/write their own notifications

## Security Features

✅ **Authentication Required**: All operations require user authentication
✅ **User Isolation**: Users can only access their own data
✅ **Data Protection**: No cross-user data access allowed
✅ **Collection Access**: Proper access to all required collections

## After Deployment

Once you update the rules, the daily points should start working immediately. You'll see:
- Daily points being saved to Firebase
- Real-time updates in the dashboard
- Proper persistence across app restarts

## Troubleshooting

If issues persist after updating rules:
1. Check Firebase Console for any rule syntax errors
2. Verify the rules were published successfully
3. Restart the Flutter app completely
4. Check the console logs for any remaining permission errors
