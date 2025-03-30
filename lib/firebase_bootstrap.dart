import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:saasfork_core/utils/config.dart';

/// Firebase Authentication service for SaasFork.
///
/// This class provides a method to initialize Firebase Authentication
/// with the necessary configurations.
///
/// Example usage:
///
/// ```dart
/// await SFFirebaseAuth.initialize(
///   apiKey: 'your-api-key',
///   authDomain: 'your-project.firebaseapp.com',
///   projectId: 'your-project-id',
///   storageBucket: 'your-project.appspot.com',
///   messagingSenderId: '1234567890',
///   appId: '1:1234567890:web:abcdef1234567890',
///   isDev: true, // Use emulator in development
/// );
///
/// // After initialization, you can use FirebaseAuth
/// // To sign in with a user:
/// await FirebaseAuth.instance.signInWithEmailAndPassword(
///   email: 'user@example.com',
///   password: 'password123'
/// );
/// ```
class SFFirebaseBootstrap {
  /// Initializes Firebase with the specified configurations.
  ///
  /// This method must be called before any other Firebase operation.
  ///
  /// Parameters:
  /// - [apiKey]: Firebase API key for your project
  /// - [authDomain]: Firebase authentication domain
  /// - [projectId]: Firebase project ID
  /// - [storageBucket]: Firebase storage bucket
  /// - [messagingSenderId]: Firebase Cloud Messaging sender ID
  /// - [appId]: Firebase application ID
  /// - [isDev]: If `true`, Firebase Auth will use the local emulator
  ///   on localhost:9099. Defaults to `false`.
  ///
  /// Examples:
  ///
  /// ```dart
  /// // Production environment initialization
  /// await SFFirebaseAuth.initialize(
  ///   apiKey: 'AIzaSyD_example_key',
  ///   authDomain: 'my-app.firebaseapp.com',
  ///   projectId: 'my-app',
  ///   storageBucket: 'my-app.appspot.com',
  ///   messagingSenderId: '1234567890',
  ///   appId: '1:1234567890:web:abcdef1234567890',
  /// );
  ///
  /// // Development environment with emulator
  /// await SFFirebaseAuth.initialize(
  ///   apiKey: 'demo-key',
  ///   authDomain: 'localhost',
  ///   projectId: 'demo-project',
  ///   storageBucket: '',
  ///   messagingSenderId: '',
  ///   appId: '',
  ///   isDev: true,
  /// );
  /// ```
  static Future<void> initialize({
    required String apiKey,
    required String authDomain,
    required String projectId,
    required String storageBucket,
    required String messagingSenderId,
    required String appId,
    bool isDev = false,
  }) async {
    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: apiKey,
        authDomain: authDomain,
        projectId: projectId,
        storageBucket: storageBucket,
        messagingSenderId: messagingSenderId,
        appId: appId,
      ),
    );

    if (isDev) {
      await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
      FirebaseFunctions.instance.useFunctionsEmulator('localhost', 5001);
      FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
    }
  }

  /// Initializes Firebase using configuration from SFConfig.
  ///
  /// This method retrieves Firebase configuration variables from SFConfig
  /// and initializes Firebase accordingly.
  ///
  /// Parameters:
  /// - [isDev]: If `true`, Firebase Auth will use the local emulator
  ///   on localhost:9099. Defaults to `false`. If `null`, the mode will
  ///   be determined automatically based on SFConfig and kDebugMode.
  ///
  /// Throws:
  /// - Exception if any required Firebase configuration variable is missing.
  static Future<void> initializeFromConfig({bool? isDev}) async {
    final apiKey = SFConfig.get<String>('FIREBASE_API_KEY');
    final authDomain = SFConfig.get<String>('FIREBASE_AUTH_DOMAIN');
    final projectId = SFConfig.get<String>('FIREBASE_PROJECT_ID');
    final storageBucket = SFConfig.get<String>('FIREBASE_STORAGE_BUCKET');
    final messagingSenderId = SFConfig.get<String>(
      'FIREBASE_MESSAGING_SENDER_ID',
    );
    final appId = SFConfig.get<String>('FIREBASE_APP_ID');

    // Verify that all required variables are present
    final requiredFields = {
      'FIREBASE_API_KEY': apiKey,
      'FIREBASE_AUTH_DOMAIN': authDomain,
      'FIREBASE_PROJECT_ID': projectId,
      'FIREBASE_STORAGE_BUCKET': storageBucket,
      'FIREBASE_MESSAGING_SENDER_ID': messagingSenderId,
      'FIREBASE_APP_ID': appId,
    };

    final missingFields =
        requiredFields.entries
            .where((entry) => entry.value == null)
            .map((entry) => entry.key)
            .toList();

    if (missingFields.isNotEmpty) {
      throw Exception(
        'Missing Firebase configuration variables: ${missingFields.join(', ')}',
      );
    }

    // Automatically determine if we are in development mode
    final useDevMode = isDev ?? (SFConfig.isDevelopment || kDebugMode);

    // Use the existing initialization method
    await initialize(
      apiKey: apiKey!,
      authDomain: authDomain!,
      projectId: projectId!,
      storageBucket: storageBucket!,
      messagingSenderId: messagingSenderId!,
      appId: appId!,
      isDev: useDevMode,
    );
  }
}
