# Direct script to create admin account
# This will guide you through the process and provide the exact data to create

Write-Host "🔐 Create Admin Account" -ForegroundColor Green
Write-Host "=======================" -ForegroundColor Green
Write-Host ""

# Get User ID
Write-Host "📝 Step 1: Get your Firebase User ID" -ForegroundColor Yellow
Write-Host "Go to: https://console.firebase.google.com/project/proplanet-5987f/authentication/users" -ForegroundColor Cyan
Write-Host "Find your user and copy the UID" -ForegroundColor Cyan
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

$name = Read-Host "Enter your name (or press Enter for Admin User)"
if ([string]::IsNullOrWhiteSpace($name)) {
    $name = "Admin User"
}

$timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")

Write-Host ""
Write-Host "✅ Admin Account Data:" -ForegroundColor Green
Write-Host ""
Write-Host "Collection: admins" -ForegroundColor Cyan
Write-Host "Document ID: $userId" -ForegroundColor Cyan
Write-Host ""
Write-Host "Fields to add:" -ForegroundColor Yellow
Write-Host "  email: $email" -ForegroundColor White
Write-Host "  name: $name" -ForegroundColor White
Write-Host "  role: admin" -ForegroundColor White
Write-Host "  isActive: true" -ForegroundColor White
Write-Host "  createdAt: $timestamp" -ForegroundColor White
Write-Host ""

Write-Host "📋 Instructions:" -ForegroundColor Yellow
Write-Host "1. Open: https://console.firebase.google.com/project/proplanet-5987f/firestore/data" -ForegroundColor Cyan
Write-Host "2. Click 'Start collection' (if admins collection does not exist)" -ForegroundColor White
Write-Host "3. Collection ID: admins" -ForegroundColor White
Write-Host "4. Document ID: $userId" -ForegroundColor White
Write-Host "5. Add the fields shown above" -ForegroundColor White
Write-Host "6. Click 'Save'" -ForegroundColor White
Write-Host ""

Write-Host "🎉 After creating, you can use admin features!" -ForegroundColor Green
Write-Host ""

# Also create a JSON file for reference
$adminData = @{
    email = $email
    name = $name
    role = "admin"
    isActive = $true
    createdAt = $timestamp
}

$adminData | ConvertTo-Json | Out-File -FilePath "admin_account_data.json" -Encoding UTF8
Write-Host "[OK] Saved admin data to admin_account_data.json" -ForegroundColor Green

