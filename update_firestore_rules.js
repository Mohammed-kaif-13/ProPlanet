// Firebase CLI script to update Firestore security rules
// Run this command in your terminal:
// firebase deploy --only firestore:rules

// Or manually copy the rules from firestore_security_rules_updated.rules
// and paste them in the Firebase Console

console.log('🚨 URGENT: Update Firestore Security Rules');
console.log('');
console.log('The app is failing to save daily points due to PERMISSION_DENIED errors.');
console.log('');
console.log('To fix this:');
console.log('1. Go to Firebase Console: https://console.firebase.google.com/');
console.log('2. Select your project: proplanet');
console.log('3. Go to Firestore Database → Rules');
console.log('4. Replace current rules with content from: firestore_security_rules_updated.rules');
console.log('5. Click Publish');
console.log('');
console.log('Or use Firebase CLI:');
console.log('firebase deploy --only firestore:rules');
console.log('');
console.log('After updating rules, restart your Flutter app and daily points will work!');
