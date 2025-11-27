// Script to create admin account in Firestore
// Run with: node create_admin_account.js

const admin = require('firebase-admin');
const readline = require('readline');

const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout
});

// Initialize Firebase Admin (you'll need to download service account key)
// For now, we'll use a simpler approach with Firebase CLI

console.log('🔐 Creating Admin Account in Firestore...\n');

rl.question('Enter your Firebase User ID (UID): ', (userId) => {
  rl.question('Enter your email: ', (email) => {
    rl.question('Enter your name: ', (name) => {
      rl.close();
      
      const adminData = {
        email: email,
        name: name,
        role: 'admin',
        isActive: true,
        createdAt: new Date().toISOString()
      };
      
      console.log('\n📋 Admin Data to Create:');
      console.log(JSON.stringify(adminData, null, 2));
      console.log('\n📝 Run this command in PowerShell:');
      console.log(`firebase firestore:set admins/${userId} '${JSON.stringify(adminData)}'`);
    });
  });
});



