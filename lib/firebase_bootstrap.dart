import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
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
  /// await SFFirebaseAuth.initialize(
  ///   options: DefaultFirebaseOptions.currentPlatform,
  /// );
  /// ```
  static Future<void> initialize({
    required FirebaseOptions options,
    bool isDev = false,
  }) async {
    await Firebase.initializeApp(options: options);

    if (isDev) {
      await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
      FirebaseFunctions.instance.useFunctionsEmulator('localhost', 5001);
      FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
      FirebaseStorage.instance.useStorageEmulator('localhost', 9199);
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
  static Future<void> initializeFromConfig({
    required FirebaseOptions options,
    bool? isDev,
  }) async {
    final useDevMode = isDev ?? (SFConfig.isDevelopment || kDebugMode);
    await initialize(options: options, isDev: useDevMode);
  }
}
