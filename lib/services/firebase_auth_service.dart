import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:saasfork_core/saasfork_core.dart';
import 'package:saasfork_firebase_service/cloud_functions/user_functions.dart';
import 'package:saasfork_firebase_service/exceptions/auth_exceptions.dart';
import 'package:saasfork_firebase_service/services/auth_service_interface.dart';

class FirebaseAuthService implements AuthServiceInterface {
  final firebase_auth.FirebaseAuth _auth;

  FirebaseAuthService([firebase_auth.FirebaseAuth? auth])
    : _auth = auth ?? firebase_auth.FirebaseAuth.instance;

  @override
  Stream<UserModel?> authStateChanges() {
    return _auth
        .authStateChanges()
        .map((firebase_auth.User? firebaseUser) async* {
          if (firebaseUser == null) {
            yield null;
          } else {
            try {
              final claims = await getUserClaims();
              yield UserModel(
                uid: firebaseUser.uid,
                email: firebaseUser.email,
                username: firebaseUser.displayName,
                claims: claims,
              );
            } catch (e) {
              error('Error in authStateChanges: ${e.toString()}');
              yield null;
            }
          }
        })
        .asyncExpand((stream) => stream);
  }

  @override
  Future<UserModel> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final claims = await getUserClaims();

      return UserModel(
        uid: userCredential.user!.uid,
        email: userCredential.user!.email,
        username: userCredential.user!.displayName,
        claims: claims,
      );
    } on firebase_auth.FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          throw UserNotFoundException();
        case 'wrong-password':
          throw InvalidCredentialsException();
        case 'invalid-email':
          throw InvalidEmailException();
        case 'email-already-in-use':
          throw EmailAlreadyInUseException();
        case 'requires-recent-login':
          throw RecentLoginRequiredException();
        default:
          throw UnknownAuthException(e.message ?? e.toString());
      }
    } catch (e) {
      throw UnknownAuthException(e.toString());
    }
  }

  @override
  Future<UserModel> createUserWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      try {
        await initializeUserClaims(userCredential.user!.uid, {
          'role': Roles.user.toString(),
        });
      } catch (e) {
        error('Warning: Unable to set default claims: ${e.toString()}');
      }

      final claims = await getUserClaims();

      return UserModel(
        uid: userCredential.user!.uid,
        email: userCredential.user!.email,
        username: userCredential.user!.displayName,
        claims: claims,
      );
    } on firebase_auth.FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'email-already-in-use':
          throw EmailAlreadyInUseException();
        case 'weak-password':
          throw UserNotFoundException();
        case 'invalid-email':
          throw InvalidEmailException();
        default:
          throw UnknownAuthException(e.message ?? e.toString());
      }
    } catch (e) {
      throw UnknownAuthException(e.toString());
    }
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on firebase_auth.FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          throw UserNotFoundException();
        case 'invalid-email':
          throw InvalidEmailException();
        default:
          throw UnknownAuthException(e.message ?? e.toString());
      }
    } catch (e) {
      throw UnknownAuthException(e.toString());
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw UnknownAuthException('Error during sign out: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw UserNotFoundException();
      }
      await user.delete();
    } on firebase_auth.FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'requires-recent-login':
          throw RecentLoginRequiredException();
        default:
          throw UnknownAuthException(e.message ?? e.toString());
      }
    } catch (e) {
      throw UnknownAuthException(e.toString());
    }
  }

  @override
  UserModel? get currentUser {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return null;

    return UserModel(
      uid: firebaseUser.uid,
      email: firebaseUser.email,
      username: firebaseUser.displayName,
      claims: UserClaims(role: Roles.user),
    );
  }

  Future<UserClaims> getUserClaims() async {
    try {
      firebase_auth.User? user = _auth.currentUser;
      if (user == null) {
        return UserClaims(role: Roles.visitor);
      }

      await user.getIdToken(true);
      firebase_auth.IdTokenResult idTokenResult = await user.getIdTokenResult();
      return UserClaims.fromJson(idTokenResult.claims ?? {});
    } catch (e) {
      error('Error fetching user claims: ${e.toString()}');
      return UserClaims(role: Roles.visitor);
    }
  }

  @override
  Future<UserModel> updateUserProfile({String? username, String? email}) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw UserNotFoundException();
    }

    try {
      if (email != null && email != user.email) {
        await user.verifyBeforeUpdateEmail(email);
      }

      if (username != null && username != user.displayName) {
        await user.updateDisplayName(username);
      }

      final claims = await getUserClaims();

      return UserModel(
        uid: user.uid,
        email: email ?? user.email,
        username: username ?? user.displayName,
        claims: claims,
      );
    } on firebase_auth.FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'invalid-email':
          throw InvalidEmailException();
        case 'requires-recent-login':
          throw RecentLoginRequiredException();
        default:
          throw UnknownAuthException(e.message ?? e.toString());
      }
    } catch (e) {
      if (e is AuthException) {
        rethrow;
      }
      throw UnknownAuthException(e.toString());
    }
  }

  Future<void> initializeUserClaims(
    String uid,
    Map<String, dynamic> claims,
  ) async {
    try {
      await UserFunctions.initializeUserClaims(uid, claims);
    } catch (e) {
      throw UnknownAuthException(
        'Error initializing user claims: ${e.toString()}',
      );
    }
  }
}
