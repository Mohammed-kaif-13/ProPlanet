# Simple script to create admin account using Firebase REST API
# Run with: .\create_admin_simple.ps1

Write-Host "🔐 Create Admin Account in Firestore" -ForegroundColor Green
Write-Host "=====================================" -ForegroundColor Green
Write-Host ""

# Instructions to get User ID
Write-Host "📝 Step 1: Get your Firebase User ID" -ForegroundColor Yellow
Write-Host "1. Go to: https://console.firebase.google.com/project/proplanet-5987f/authentication/users" -ForegroundColor Cyan
Write-Host "2. Find your user (classdocs2435@gmail.com)" -ForegroundColor Cyan
Write-Host "3. Click on your user to see details" -ForegroundColor Cyan
Write-Host "4. Copy the UID (it's a long string like: abc123xyz...)" -ForegroundColor Cyan
Write-Host ""

$userId = Read-Host "Enter your Firebase User ID (UID)"

if ([string]::IsNullOrWhiteSpace($userId)) {
    Write-Host "❌ User ID cannot be empty!" -ForegroundColor Red
    exit 1
}

$email = Read-Host "Enter your email (or press Enter for classdocs2435@gmail.com)"
if ([string]::IsNullOrWhiteSpace($email)) {
    $email = "classdocs2435@gmail.com"
}

$name = Read-Host "Enter your name (or press Enter for 'Admin User')"
if ([string]::IsNullOrWhiteSpace($name)) {
    $name = "Admin User"
}

Write-Host ""
Write-Host "📋 Admin Account Details:" -ForegroundColor Yellow
Write-Host "  User ID: $userId" -ForegroundColor Cyan
Write-Host "  Email: $email" -ForegroundColor Cyan
Write-Host "  Name: $name" -ForegroundColor Cyan
Write-Host "  Role: admin" -ForegroundColor Cyan
Write-Host "  Active: true" -ForegroundColor Cyan
Write-Host ""

$confirm = Read-Host "Create this admin account? (Y/N)"
if ($confirm -ne "Y" -and $confirm -ne "y") {
    Write-Host "Cancelled." -ForegroundColor Yellow
    exit 0
}

Write-Host ""
Write-Host "🚀 Creating admin account..." -ForegroundColor Green

# Create the admin data
$timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
$adminData = @{
    email = $email
    name = $name
    role = "admin"
    isActive = $true
    createdAt = $timestamp
}

# Convert to JSON
$jsonData = $adminData | ConvertTo-Json -Compress

# Create the document using Firebase CLI
# Note: Firebase CLI doesn't have direct firestore:set in newer versions
# So we'll use a workaround or provide manual instructions

Write-Host ""
Write-Host "⚠️  Firebase CLI doesn't have a direct command to create Firestore documents." -ForegroundColor Yellow
Write-Host ""
Write-Host "📋 Please create the admin account manually:" -ForegroundColor Yellow
Write-Host ""
Write-Host "Method 1: Firebase Console (Easiest)" -ForegroundColor Cyan
Write-Host "1. Go to: https://console.firebase.google.com/project/proplanet-5987f/firestore/data" -ForegroundColor White
Write-Host "2. Click Start collection (if admins collection does not exist)" -ForegroundColor White
Write-Host "3. Collection ID: admins" -ForegroundColor White
Write-Host "4. Document ID: $userId" -ForegroundColor White
Write-Host "5. Add these fields:" -ForegroundColor White
Write-Host "   - email (string): $email" -ForegroundColor Gray
Write-Host "   - name (string): $name" -ForegroundColor Gray
Write-Host "   - role (string): admin" -ForegroundColor Gray
Write-Host "   - isActive (boolean): true" -ForegroundColor Gray
Write-Host "   - createdAt (timestamp): $timestamp" -ForegroundColor Gray
Write-Host "6. Click Save" -ForegroundColor White
Write-Host ""

Write-Host "Method 2: Using Node.js Script" -ForegroundColor Cyan
Write-Host "I'll create a Node.js script for you..." -ForegroundColor White

# Create Node.js script
$nodeScript = @"
const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function createAdmin() {
  const adminData = {
    email: '$email',
    name: '$name',
    role: 'admin',
    isActive: true,
    createdAt: new Date('$timestamp')
  };

  try {
    await db.collection('admins').doc('$userId').set(adminData);
    console.log('✅ Admin account created successfully!');
    console.log('User ID:', '$userId');
    console.log('Email:', '$email');
  } catch (error) {
    console.error('❌ Error:', error);
  }
  
  process.exit(0);
}

createAdmin();
"@

$nodeScript | Out-File -FilePath "create_admin_node.js" -Encoding UTF8

Write-Host "✅ Created: create_admin_node.js" -ForegroundColor Green
Write-Host ""
Write-Host "To use the Node.js script:" -ForegroundColor Yellow
Write-Host "1. Download service account key from Firebase Console" -ForegroundColor White
Write-Host "2. Save it as serviceAccountKey.json in this directory" -ForegroundColor White
Write-Host "3. Run: node create_admin_node.js" -ForegroundColor White
Write-Host ""

Write-Host "📋 Quick Copy-Paste for Firebase Console:" -ForegroundColor Yellow
Write-Host "Document ID: $userId" -ForegroundColor Cyan
Write-Host ""
Write-Host "Fields to add:" -ForegroundColor Cyan
Write-Host "email: $email" -ForegroundColor White
Write-Host "name: $name" -ForegroundColor White
Write-Host "role: admin" -ForegroundColor White
Write-Host "isActive: true" -ForegroundColor White
Write-Host "createdAt: $timestamp" -ForegroundColor White
Write-Host ""

Write-Host "✅ Script complete! Follow the instructions above to create your admin account." -ForegroundColor Green

