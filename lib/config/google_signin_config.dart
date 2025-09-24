import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

class GoogleSignInConfig {
  static const String webClientId =
      '265975639920-omv2vfv6heoem9esskcntssei5n7ovsc.apps.googleusercontent.com';
  static const String androidClientId =
      '265975639920-igfucrsimh9h7p7oub2vjsn1kg8ksj3f.apps.googleusercontent.com';

  static GoogleSignIn get googleSignIn {
    if (kIsWeb) {
      // For web platform
      return GoogleSignIn(
        clientId: webClientId,
        scopes: scopes,
      );
    } else {
      // For mobile platforms (Android/iOS)
      // Use standard constructor - it will automatically pick up configuration from google-services.json
      return GoogleSignIn();
    }
  }

  static const List<String> scopes = [
    'email',
    'profile',
  ];
}
