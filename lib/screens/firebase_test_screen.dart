import 'package:flutter/material.dart';
import '../verify_firebase.dart';

class FirebaseTestScreen extends StatefulWidget {
  const FirebaseTestScreen({super.key});

  @override
  State<FirebaseTestScreen> createState() => _FirebaseTestScreenState();
}

class _FirebaseTestScreenState extends State<FirebaseTestScreen> {
  Map<String, dynamic>? _verificationResults;
  bool _isLoading = false;

  Future<void> _runVerification() async {
    setState(() {
      _isLoading = true;
    });

    final results = await FirebaseVerification.verifyAllConnections();

    setState(() {
      _verificationResults = results;
      _isLoading = false;
    });

    // Print results to console
    FirebaseVerification.printVerificationResults(results);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firebase Verification'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Icon(
                      Icons.verified_user,
                      size: 48,
                      color: Colors.green,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Firebase Connection Test',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'This will test all Firebase services to ensure your app is properly connected.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _runVerification,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.play_arrow),
                      label:
                          Text(_isLoading ? 'Testing...' : 'Run Verification'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_verificationResults != null) ...[
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Verification Results',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildResultItem(
                          'Firebase Initialized',
                          _verificationResults!['firebase_initialized'],
                        ),
                        _buildResultItem(
                          'Firestore Connected',
                          _verificationResults!['firestore_connected'],
                        ),
                        _buildResultItem(
                          'Auth Connected',
                          _verificationResults!['auth_connected'],
                        ),
                        _buildResultItem(
                          'Google Services',
                          _verificationResults!['google_services_configured'],
                        ),
                        _buildResultItem(
                          'Firebase Options',
                          _verificationResults!['firebase_options_loaded'],
                        ),
                        if (_verificationResults!['errors'].isNotEmpty) ...[
                          const SizedBox(height: 16),
                          const Text(
                            'Errors:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...(_verificationResults!['errors'] as List<String>)
                              .map((error) => Padding(
                                    padding: const EdgeInsets.only(
                                        left: 16, bottom: 4),
                                    child: Text(
                                      '• $error',
                                      style: const TextStyle(color: Colors.red),
                                    ),
                                  ))
                              .toList(),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultItem(String title, bool isSuccess) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(
            isSuccess ? Icons.check_circle : Icons.error,
            color: isSuccess ? Colors.green : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}
