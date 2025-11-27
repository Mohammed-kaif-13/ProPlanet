# 🚀 Deploy Firestore & Storage Rules from Terminal

## 📋 Prerequisites

1. **Install Firebase CLI** (if not already installed):
   ```bash
   npm install -g firebase-tools
   ```

2. **Login to Firebase**:
   ```bash
   firebase login
   ```
   - This will open a browser for authentication
   - Complete the login process

3. **Verify you're in the project directory**:
   ```bash
   cd proplanet
   ```

---

## 🔥 Step 1: Initialize Firebase (First Time Only)

If you haven't initialized Firebase in this project yet:

```bash
firebase init
```

**Select these options:**
- ✅ Firestore
- ✅ Storage
- Use an existing project: `proplanet-5987f`
- For Firestore rules file: `firestore_rules_complete.rules`
- For Storage rules file: `storage_rules_complete.rules`

---

## 📝 Step 2: Copy Rules Files to Standard Names

Firebase CLI looks for specific file names. Copy your complete rules to the standard names:

### Windows (PowerShell):
```powershell
Copy-Item firestore_rules_complete.rules firestore.rules
Copy-Item storage_rules_complete.rules storage.rules
```

### Windows (Command Prompt):
```cmd
copy firestore_rules_complete.rules firestore.rules
copy storage_rules_complete.rules storage.rules
```

### Mac/Linux:
```bash
cp firestore_rules_complete.rules firestore.rules
cp storage_rules_complete.rules storage.rules
```

---

## 🚀 Step 3: Deploy Firestore Rules

```bash
firebase deploy --only firestore:rules
```

**Expected Output:**
```
✔  firestore: released rules firestore.rules to firebase
✔  Deploy complete!
```

---

## 🗄️ Step 4: Deploy Storage Rules

```bash
firebase deploy --only storage
```

**Expected Output:**
```
✔  storage: released rules storage.rules to firebase
✔  Deploy complete!
```

---

## 🎯 Deploy Both at Once

You can deploy both rules in a single command:

```bash
firebase deploy --only firestore:rules,storage
```

---

## ✅ Verify Deployment

### Check Firestore Rules:
```bash
firebase firestore:rules:get
```

### Check Storage Rules:
```bash
firebase storage:rules:get
```

---

## 🔧 Alternative: Deploy Specific Files Directly

If you want to deploy without copying files:

### Firestore:
```bash
firebase deploy --only firestore:rules --config firestore.rules=firestore_rules_complete.rules
```

### Storage:
```bash
firebase deploy --only storage --config storage.rules=storage_rules_complete.rules
```

---

## 📋 Complete Deployment Script

Create a file `deploy_rules.sh` (Mac/Linux) or `deploy_rules.bat` (Windows):

### For Mac/Linux (`deploy_rules.sh`):
```bash
#!/bin/bash

echo "🚀 Deploying Firestore and Storage Rules..."

# Copy rules files
cp firestore_rules_complete.rules firestore.rules
cp storage_rules_complete.rules storage.rules

# Deploy both
firebase deploy --only firestore:rules,storage

echo "✅ Deployment complete!"
```

Make it executable:
```bash
chmod +x deploy_rules.sh
./deploy_rules.sh
```

### For Windows (`deploy_rules.bat`):
```batch
@echo off
echo 🚀 Deploying Firestore and Storage Rules...

REM Copy rules files
copy firestore_rules_complete.rules firestore.rules
copy storage_rules_complete.rules storage.rules

REM Deploy both
firebase deploy --only firestore:rules,storage

echo ✅ Deployment complete!
pause
```

Run it:
```cmd
deploy_rules.bat
```

---

## 🧪 Test After Deployment

### Test Firestore Rules:
```bash
# This will show current rules
firebase firestore:rules:get
```

### Test Storage Rules:
```bash
# This will show current rules
firebase storage:rules:get
```

---

## ⚠️ Troubleshooting

### Error: "Firebase CLI not found"
**Solution:**
```bash
npm install -g firebase-tools
```

### Error: "Not logged in"
**Solution:**
```bash
firebase login
```

### Error: "No Firebase project found"
**Solution:**
```bash
firebase use proplanet-5987f
```

Or initialize:
```bash
firebase init
```

### Error: "Rules file not found"
**Solution:**
Make sure you're in the `proplanet` directory and files exist:
```bash
ls firestore_rules_complete.rules
ls storage_rules_complete.rules
```

---

## 📝 Quick Reference Commands

```bash
# Login
firebase login

# Set project
firebase use proplanet-5987f

# Deploy Firestore rules
firebase deploy --only firestore:rules

# Deploy Storage rules
firebase deploy --only storage

# Deploy both
firebase deploy --only firestore:rules,storage

# View Firestore rules
firebase firestore:rules:get

# View Storage rules
firebase storage:rules:get

# List projects
firebase projects:list
```

---

## 🎉 Success!

After deployment, you should see:
```
✔  firestore: released rules firestore.rules to firebase
✔  storage: released rules storage.rules to firebase
✔  Deploy complete!
```

Your rules are now live! 🚀



