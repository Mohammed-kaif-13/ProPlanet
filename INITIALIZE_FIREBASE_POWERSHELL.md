# 🚀 Initialize Firebase in PowerShell - Step by Step

## ✅ You're Already Logged In!

Good news: You're logged in as `classdocs2435@gmail.com` ✅

Now you just need to initialize Firebase in your project directory.

---

## 📝 Step-by-Step Instructions

### Step 1: Make sure you're in the right directory

```powershell
cd D:\proplanet\proplanet
```

### Step 2: Initialize Firebase

Run this command:

```powershell
firebase init
```

### Step 3: Answer the Questions

When `firebase init` runs, you'll see interactive prompts. Answer like this:

**Question 1: Which Firebase features do you want to set up?**
```
Use arrow keys to navigate, Space to select
✅ Firestore
✅ Storage
Press Enter to confirm
```

**Question 2: Please select an option:**
```
Use an existing project
```

**Question 3: Select a default Firebase project:**
```
Use arrow keys to navigate
Select: proplanet-5987f
Press Enter
```

**Question 4: What file should be used for Firestore Rules?**
```
firestore.rules
Press Enter
```

**Question 5: File firestore.rules already exists. Overwrite?**
```
N (No) - We'll use our custom file
```

**Question 6: What file should be used for Storage Rules?**
```
storage.rules
Press Enter
```

**Question 7: File storage.rules already exists. Overwrite?**
```
N (No) - We'll use our custom file
```

---

## 🎯 Alternative: Quick Non-Interactive Setup

If you want to skip the interactive prompts, create a `.firebaserc` file manually:

### Create `.firebaserc` file:

```json
{
  "projects": {
    "default": "proplanet-5987f"
  }
}
```

### Create `firebase.json` file:

```json
{
  "firestore": {
    "rules": "firestore.rules"
  },
  "storage": {
    "rules": "storage.rules"
  }
}
```

---

## ✅ After Initialization

Once initialized, verify:

```powershell
firebase use
```

**Expected Output:**
```
Now using project proplanet-5987f
```

---

## 🚀 Then Deploy Rules

After initialization, deploy the rules:

```powershell
# Copy the final rules files
Copy-Item firestore_rules_final.rules firestore.rules
Copy-Item storage_rules_final.rules storage.rules

# Deploy both
firebase deploy --only firestore:rules,storage
```

---

## 🧪 Quick Test

Test if everything works:

```powershell
# Check project
firebase use

# Check Firestore rules
firebase firestore:rules:get

# Check Storage rules
firebase storage:rules:get
```

---

## 📋 Complete PowerShell Script

Save this as `setup_firebase.ps1`:

```powershell
# Setup Firebase for ProPlanet

Write-Host "🚀 Setting up Firebase..." -ForegroundColor Green

# Check if already initialized
if (Test-Path ".firebaserc") {
    Write-Host "✅ Firebase already initialized" -ForegroundColor Green
} else {
    Write-Host "📝 Creating Firebase configuration..." -ForegroundColor Yellow
    
    # Create .firebaserc
    @"
{
  "projects": {
    "default": "proplanet-5987f"
  }
}
"@ | Out-File -FilePath ".firebaserc" -Encoding UTF8
    
    # Create firebase.json
    @"
{
  "firestore": {
    "rules": "firestore.rules"
  },
  "storage": {
    "rules": "storage.rules"
  }
}
"@ | Out-File -FilePath "firebase.json" -Encoding UTF8
    
    Write-Host "✅ Firebase configuration created" -ForegroundColor Green
}

# Verify project
Write-Host "`n🔍 Verifying project..." -ForegroundColor Yellow
firebase use

# Copy rules files
Write-Host "`n📋 Copying rules files..." -ForegroundColor Yellow
Copy-Item firestore_rules_final.rules firestore.rules -Force
Copy-Item storage_rules_final.rules storage.rules -Force
Write-Host "✅ Rules files copied" -ForegroundColor Green

# Deploy
Write-Host "`n🚀 Deploying rules..." -ForegroundColor Yellow
firebase deploy --only firestore:rules,storage

Write-Host "`n✅ Setup complete!" -ForegroundColor Green
```

**Run it:**
```powershell
.\setup_firebase.ps1
```

---

## 🎉 You're Ready!

After initialization, you can deploy rules anytime with:

```powershell
firebase deploy --only firestore:rules,storage
```

