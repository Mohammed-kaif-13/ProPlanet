import 'package:flutter/material.dart';
import '../config/google_signin_config.dart';
import '../services/firebase_service.dart';

class DebugScreen extends StatefulWidget {
  const DebugScreen({super.key});

  @override
  State<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen> {
  String _status = 'Ready to test';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Screen'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Google Sign-In Debug',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Status: $_status'),
                    const SizedBox(height: 10),
                    Text('Web Client ID: ${GoogleSignInConfig.webClientId}'),
                    const SizedBox(height: 5),
                    Text(
                        'Android Client ID: ${GoogleSignInConfig.androidClientId}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _testGoogleSignIn,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Test Google Sign-In'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _isLoading ? null : _testGoogleSignOut,
              child: const Text('Test Google Sign-Out'),
            ),
            const SizedBox(height: 20),
            const Text(
              'Instructions:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              '1. Tap "Test Google Sign-In" to test the configuration\n'
              '2. If you see an error, check the Firebase console\n'
              '3. Make sure the SHA1 fingerprint is correct\n'
              '4. Verify Google Sign-In is enabled in Firebase',
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _testGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _status = 'Testing Google Sign-In...';
    });

    try {
      final FirebaseService firebaseService = FirebaseService();
      final result = await firebaseService.signInWithGoogle();

      if (result?.user != null) {
        setState(() {
          _status = 'Success! Signed in as: ${result!.user!.email}';
        });
      } else {
        setState(() {
          _status = 'Sign-in failed or was cancelled';
        });
      }
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testGoogleSignOut() async {
    setState(() {
      _isLoading = true;
      _status = 'Signing out...';
    });

    try {
      final FirebaseService firebaseService = FirebaseService();
      await firebaseService.signOut();

      setState(() {
        _status = 'Successfully signed out!';
      });
    } catch (e) {
      setState(() {
        _status = 'Sign-out error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
