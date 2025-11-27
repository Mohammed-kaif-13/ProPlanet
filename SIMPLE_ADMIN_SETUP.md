# 🚀 SUPER SIMPLE: Make User Admin (2 Minutes)

## ✅ Just 2 Steps!

### Step 1: Get User ID
1. Go to: https://console.firebase.google.com/project/proplanet-5987f/authentication/users
2. Click on the user
3. **Copy the UID** (the long ID)

### Step 2: Create Admin Document
1. Go to: https://console.firebase.google.com/project/proplanet-5987f/firestore/data
2. Click **"Start collection"**
3. Collection ID: `admins`
4. Document ID: **Paste the UID** you copied
5. Click **"Add field"** 5 times:
   - Field 1: `email` → Type: string → Value: user's email
   - Field 2: `name` → Type: string → Value: user's name  
   - Field 3: `role` → Type: string → Value: `admin`
   - Field 4: `isActive` → Type: boolean → Value: `true`
   - Field 5: `createdAt` → Type: timestamp → Value: Click "Set" button
6. Click **"Save"**

**DONE!** User must logout and login again. They're now admin! 🎉

---

## 📋 Quick Copy-Paste

**Collection:** `admins`  
**Document ID:** `[PASTE_USER_ID_HERE]`

**Fields:**
```
email: [user email]
name: [user name]
role: admin
isActive: true
createdAt: [click Set button]
```

---

## 🎯 That's It!

No scripts, no commands, just 2 steps in Firebase Console. Simple! ✅



