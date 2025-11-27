# Complete script to get user ID and create admin account
# Run with: .\get_user_id_and_create_admin.ps1

Write-Host "🔐 Admin Account Creation Script" -ForegroundColor Green
Write-Host "=================================" -ForegroundColor Green
Write-Host ""

# Method 1: Get User ID from Firebase Auth (if available)
Write-Host "📝 Option 1: Get User ID from Firebase Console" -ForegroundColor Yellow
Write-Host "1. Go to: https://console.firebase.google.com/project/proplanet-5987f/authentication/users" -ForegroundColor Cyan
Write-Host "2. Find your user (classdocs2435@gmail.com)" -ForegroundColor Cyan
Write-Host "3. Copy the UID (User ID)" -ForegroundColor Cyan
Write-Host ""

# Get user input
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
Write-Host "📋 Creating admin account with:" -ForegroundColor Yellow
Write-Host "  User ID: $userId" -ForegroundColor Cyan
Write-Host "  Email: $email" -ForegroundColor Cyan
Write-Host "  Name: $name" -ForegroundColor Cyan
Write-Host ""

$confirm = Read-Host "Continue? (Y/N)"
if ($confirm -ne "Y" -and $confirm -ne "y") {
    Write-Host "Cancelled." -ForegroundColor Yellow
    exit 0
}

# Create admin data
$timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
$adminData = @{
    email = $email
    name = $name
    role = "admin"
    isActive = $true
    createdAt = $timestamp
}

# Convert to JSON (Firebase CLI format)
$jsonData = $adminData | ConvertTo-Json -Compress

Write-Host ""
Write-Host "🚀 Creating admin document in Firestore..." -ForegroundColor Green

# Use firebase firestore:set command
# Note: Firebase CLI might need the data in a specific format
$firestorePath = "admins/$userId"

# Try using firebase firestore:set
$command = "firebase firestore:set `"$firestorePath`" '$jsonData'"
Write-Host "Command: $command" -ForegroundColor Gray

try {
    # Execute the command
    $result = Invoke-Expression $command 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "✅ Admin account created successfully!" -ForegroundColor Green
        Write-Host ""
        Write-Host "Admin Details:" -ForegroundColor Yellow
        Write-Host "  Document ID: $userId" -ForegroundColor Cyan
        Write-Host "  Email: $email" -ForegroundColor Cyan
        Write-Host "  Name: $name" -ForegroundColor Cyan
        Write-Host "  Role: admin" -ForegroundColor Cyan
        Write-Host "  Active: true" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "🎉 You can now use admin features!" -ForegroundColor Green
        Write-Host ""
        Write-Host "Verify in Firebase Console:" -ForegroundColor Yellow
        Write-Host "https://console.firebase.google.com/project/proplanet-5987f/firestore/data/admins/$userId" -ForegroundColor Cyan
    } else {
        Write-Host ""
        Write-Host "❌ Error: $result" -ForegroundColor Red
        Write-Host ""
        Write-Host "Alternative: Create manually in Firebase Console:" -ForegroundColor Yellow
        Write-Host "1. Go to Firestore Database" -ForegroundColor Cyan
        Write-Host "2. Create collection: admins" -ForegroundColor Cyan
        Write-Host "3. Create document with ID: $userId" -ForegroundColor Cyan
        Write-Host "4. Add fields:" -ForegroundColor Cyan
        Write-Host "   - email: $email" -ForegroundColor Gray
        Write-Host "   - name: $name" -ForegroundColor Gray
        Write-Host "   - role: admin" -ForegroundColor Gray
        Write-Host "   - isActive: true" -ForegroundColor Gray
        Write-Host "   - createdAt: $timestamp" -ForegroundColor Gray
    }
} catch {
    Write-Host ""
    Write-Host "❌ Error: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please create the admin account manually in Firebase Console" -ForegroundColor Yellow
}



