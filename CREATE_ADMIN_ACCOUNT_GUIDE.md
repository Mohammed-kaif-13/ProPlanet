# 🔐 Create Admin Account - Complete Guide

## 🚀 Quick Method: Run the Script

Run this in PowerShell:

```powershell
cd D:\proplanet\proplanet
.\create_admin.ps1
```

The script will:
1. Ask for your Firebase User ID (UID)
2. Ask for your email (defaults to classdocs2435@gmail.com)
3. Ask for your name (defaults to Admin User)
4. Show you exactly what to create in Firebase Console
5. Save the data to `admin_account_data.json` for reference

---

## 📝 Manual Method: Step by Step

### Step 1: Get Your Firebase User ID

1. Go to: https://console.firebase.google.com/project/proplanet-5987f/authentication/users
2. Find your user: `classdocs2435@gmail.com`
3. Click on your user to see details
4. **Copy the UID** (it's a long string like: `abc123xyz456...`)

### Step 2: Create Admin Document in Firestore

1. Go to: https://console.firebase.google.com/project/proplanet-5987f/firestore/data
2. Click **"Start collection"** (if `admins` collection doesn't exist)
3. **Collection ID**: `admins`
4. **Document ID**: Paste your User ID (UID from Step 1)
5. Click **"Save"**

### Step 3: Add Fields to the Document

Click on the document you just created, then add these fields:

| Field Name | Type | Value |
|------------|------|-------|
| `email` | string | `classdocs2435@gmail.com` (or your email) |
| `name` | string | `Admin User` (or your name) |
| `role` | string | `admin` |
| `isActive` | boolean | `true` |
| `createdAt` | timestamp | Click "Set" and use current time |

### Step 4: Save

Click **"Update"** to save the document.

---

## ✅ Verify Admin Account

After creating, verify it works:

1. Go to: https://console.firebase.google.com/project/proplanet-5987f/firestore/data/admins
2. You should see your document with your User ID
3. Check that all fields are correct

---

## 🎯 Quick Copy-Paste Template

When creating the document, use these exact values:

**Collection ID:** `admins`  
**Document ID:** `[YOUR_USER_ID]` (paste your UID here)

**Fields:**
```
email: classdocs2435@gmail.com
name: Admin User
role: admin
isActive: true
createdAt: [current timestamp]
```

---

## 🧪 Test Admin Access

After creating the admin account, test it:

1. Login to your app as the admin user
2. Try accessing admin features
3. You should now have admin privileges!

---

## 📋 Example Admin Document Structure

```json
{
  "email": "classdocs2435@gmail.com",
  "name": "Admin User",
  "role": "admin",
  "isActive": true,
  "createdAt": "2024-01-15T10:30:00.000Z"
}
```

---

## 🆘 Troubleshooting

### Issue: Can't find my User ID
**Solution:** 
- Go to Authentication → Users
- Your UID is shown in the list or when you click on your user

### Issue: Document already exists
**Solution:**
- That's fine! Just update the existing document with the fields above

### Issue: Can't access admin features after creating
**Solution:**
- Make sure `role` is exactly `admin` (lowercase)
- Make sure `isActive` is `true` (boolean, not string)
- Logout and login again to refresh your session

---

## 🎉 Success!

Once created, you can:
- ✅ Access admin panel
- ✅ Create/edit/delete food items
- ✅ Upload food images
- ✅ Manage all food ordering features

---

**Ready? Run the script or follow the manual steps above!** 🚀



