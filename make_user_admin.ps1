# Script to make any existing user an admin
# Run with: .\make_user_admin.ps1

Write-Host "Make User Admin" -ForegroundColor Green
Write-Host "===============" -ForegroundColor Green
Write-Host ""
Write-Host "This script will add any existing user to the admins collection." -ForegroundColor Yellow
Write-Host "The user will immediately have admin privileges!" -ForegroundColor Yellow
Write-Host ""

Write-Host "Step 1: Get the User ID (UID) of the user you want to make admin" -ForegroundColor Cyan
Write-Host ""
Write-Host "Option A: From Firebase Console" -ForegroundColor Yellow
Write-Host "1. Go to: https://console.firebase.google.com/project/proplanet-5987f/authentication/users" -ForegroundColor White
Write-Host "2. Find the user you want to make admin" -ForegroundColor White
Write-Host "3. Click on the user to see details" -ForegroundColor White
Write-Host "4. Copy the UID (User ID)" -ForegroundColor White
Write-Host ""
Write-Host "Option B: From your app" -ForegroundColor Yellow
Write-Host "If you know the user's email, you can find their UID in Authentication section" -ForegroundColor White
Write-Host ""

$userId = Read-Host "Enter the User ID (UID) of the user to make admin"

if ([string]::IsNullOrWhiteSpace($userId)) {
    Write-Host "User ID cannot be empty!" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Step 2: Get user details" -ForegroundColor Cyan
Write-Host ""

$email = Read-Host "Enter the user's email"
if ([string]::IsNullOrWhiteSpace($email)) {
    Write-Host "Email cannot be empty!" -ForegroundColor Red
    exit 1
}

$name = Read-Host "Enter the user's name (or press Enter to skip)"
if ([string]::IsNullOrWhiteSpace($name)) {
    $name = "Admin User"
}

$timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")

Write-Host ""
Write-Host "Admin Account Data:" -ForegroundColor Green
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

Write-Host "Instructions:" -ForegroundColor Yellow
Write-Host "1. Open: https://console.firebase.google.com/project/proplanet-5987f/firestore/data" -ForegroundColor Cyan
Write-Host "2. Navigate to or create collection: admins" -ForegroundColor White
Write-Host "3. Create document with ID: $userId" -ForegroundColor White
Write-Host "4. Add the fields shown above" -ForegroundColor White
Write-Host "5. Click Save" -ForegroundColor White
Write-Host ""

Write-Host "IMPORTANT:" -ForegroundColor Yellow
Write-Host "- The user must LOGOUT and LOGIN again for changes to take effect" -ForegroundColor White
Write-Host "- After login, they will have admin privileges" -ForegroundColor White
Write-Host "- They can now access admin panel and create food items" -ForegroundColor White
Write-Host ""

# Create JSON file for reference
$adminData = @{
    email = $email
    name = $name
    role = "admin"
    isActive = $true
    createdAt = $timestamp
}

$adminData | ConvertTo-Json | Out-File -FilePath "admin_user_$userId.json" -Encoding UTF8
Write-Host "Saved admin data to admin_user_$userId.json" -ForegroundColor Green
Write-Host ""

Write-Host "After creating the admin document:" -ForegroundColor Yellow
Write-Host "1. The user should logout from the app" -ForegroundColor White
Write-Host "2. Login again" -ForegroundColor White
Write-Host "3. They will now have admin access!" -ForegroundColor White
Write-Host ""



