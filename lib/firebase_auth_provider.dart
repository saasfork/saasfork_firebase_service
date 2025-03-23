import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saasfork_core/saasfork_core.dart';
import 'package:saasfork_firebase_service/cloud_functions/user_functions.dart';
import 'package:saasfork_firebase_service/models/auth_state_model.dart';

final authProvider = NotifierProvider<AuthNotifier, AuthStateModel>(
  () => AuthNotifier(),
);

class AuthNotifier extends Notifier<AuthStateModel> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Completer<void>? _initializeCompleter;

  @override
  AuthStateModel build() {
    _initializeAuthListener();
    return AuthStateModel(state: AuthState.idle, user: null);
  }

  bool get isAuthenticated => state.state == AuthState.authenticated;

  Future<void> initialize() async {
    if (_initializeCompleter != null) {
      if (_initializeCompleter!.isCompleted) {
        if (state.state != AuthState.idle) {
          return Future.value();
        }
      } else {
        return _initializeCompleter!.future;
      }
    }

    _initializeCompleter = Completer<void>();

    if (state.state != AuthState.idle) {
      _initializeCompleter!.complete();
    }

    return _initializeCompleter!.future;
  }

  void _initializeAuthListener() {
    try {
      _auth.authStateChanges().listen((User? user) async {
        if (user == null) {
          state = AuthStateModel(state: AuthState.unauthenticated, user: null);
        } else {
          try {
            final claims = await getUserClaims();
            final userModel = UserModel(
              uid: user.uid,
              email: user.email,
              username: user.displayName,
              claims: claims,
            );

            state = AuthStateModel(
              state: AuthState.authenticated,
              user: userModel,
            );
          } catch (e) {
            warn("Error processing user authentication: ${e.toString()}");
            state = AuthStateModel(
              state: AuthState.error,
              user: null,
              errorMessage: e.toString(),
            );
          }
        }

        if (_initializeCompleter != null &&
            !_initializeCompleter!.isCompleted) {
          _initializeCompleter!.complete();
        }
      });
    } catch (e) {
      error('Error retrieving current user: ${e.toString()}');
      state = AuthStateModel(
        state: AuthState.error,
        user: null,
        errorMessage: 'Error retrieving current user: ${e.toString()}',
      );

      if (_initializeCompleter != null && !_initializeCompleter!.isCompleted) {
        _initializeCompleter!.completeError(e);
      }
    }
  }

  Future<AuthStateModel> login(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final claims = await getUserClaims();

      state = state.copyWith(
        state: AuthState.authenticated,
        user: UserModel(
          uid: userCredential.user!.uid,
          email: userCredential.user!.email,
          username: userCredential.user!.displayName,
          claims: claims,
        ),
        errorMessage: null,
      );
    } on FirebaseAuthException catch (e) {
      state = _handleFirebaseAuthError(e, state);
    } catch (e) {
      state = _handleFirebaseAuthError(e, state);
    }

    return state;
  }

  Future<AuthStateModel> register(String email, String password) async {
    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      Roles role = Roles.user;

      try {
        await UserFunctions.initializeUserClaims(userCredential.user!.uid, {
          'role': role.toString(),
        });
      } catch (e) {
        error('Warning: Unable to set default claims: ${e.toString()}');
      }

      final UserClaims claims = await getUserClaims();

      state = state.copyWith(
        state: AuthState.authenticated,
        user: UserModel(
          uid: userCredential.user!.uid,
          email: userCredential.user!.email,
          claims: claims,
        ),
      );
    } on FirebaseAuthException catch (e) {
      state = _handleFirebaseAuthError(e, state);
    } catch (e) {
      state = _handleFirebaseAuthError(e, state);
    }

    return state;
  }

  Future<UserClaims> getUserClaims() async {
    try {
      User? user = _auth.currentUser;

      await user!.getIdToken(true);
      IdTokenResult idTokenResult = await user.getIdTokenResult();
      return UserClaims.fromJson(idTokenResult.claims!);
    } catch (e) {
      error('Error fetching user claims: ${e.toString()}', error: e);
    }

    return UserClaims(role: Roles.visitor);
  }

  Future<AuthStateModel> resetPassword(String email) async {
    String? errorString;

    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      errorString = e.toString();
      error('Error sending reset email: $errorString');
    }

    return AuthStateModel(state: AuthState.idle, errorMessage: errorString);
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      state = AuthStateModel(
        state: AuthState.idle,
        user: null,
        errorMessage: null,
      );
    } catch (e) {
      error('Error during sign out: ${e.toString()}');
    }
  }

  Future<AuthStateModel> updateUserProfile({
    String? username,
    String? email,
  }) async {
    if (state.user == null) {
      return AuthStateModel(
        state: AuthState.error,
        errorMessage: 'User not authenticated',
      );
    }

    try {
      User? currentFirebaseUser = _auth.currentUser;
      if (currentFirebaseUser == null) {
        throw Exception('User not authenticated');
      }

      if (email != null && email != currentFirebaseUser.email) {
        await currentFirebaseUser.verifyBeforeUpdateEmail(email);
      }

      if (username != null) {
        await currentFirebaseUser.updateProfile(
          displayName: username,
          photoURL: currentFirebaseUser.photoURL ?? "",
        );
      }

      state = state.copyWith(
        user: state.user?.copyWith(
          username: username ?? currentFirebaseUser.displayName,
          email: email ?? currentFirebaseUser.email,
        ),
      );

      return state;
    } on FirebaseAuthException catch (e) {
      state = _handleFirebaseAuthError(e, state);
    } catch (e) {
      state = _handleFirebaseAuthError(e, state);
    }

    return state;
  }

  Future<AuthStateModel> deleteUserAccount() async {
    if (state.user == null) {
      return AuthStateModel(
        state: AuthState.error,
        errorMessage: 'User not authenticated',
      );
    }

    state = state.copyWith(state: AuthState.updating);

    try {
      User? currentFirebaseUser = _auth.currentUser;
      if (currentFirebaseUser == null) {
        throw Exception('User not authenticated');
      }

      await currentFirebaseUser.delete();

      return AuthStateModel(state: AuthState.idle, errorMessage: null);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        state = state.copyWith(
          state: AuthState.error,
          errorMessage:
              'Cette opération nécessite une connexion récente. Veuillez vous reconnecter.',
        );
        return state;
      }

      state = _handleFirebaseAuthError(e, state);
      return state;
    } catch (e) {
      state = _handleFirebaseAuthError(e, state);
      return state;
    }
  }

  AuthStateModel _handleFirebaseAuthError(
    dynamic e,
    AuthStateModel currentState,
  ) {
    String? errorMessage;

    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'Aucun utilisateur trouvé avec cet email';
          break;
        case 'wrong-password':
          errorMessage = 'Mot de passe incorrect';
          break;
        case 'email-already-in-use':
          errorMessage = 'Cette adresse email est déjà utilisée';
          break;
        default:
          errorMessage = e.message ?? e.toString();
      }
    } else {
      errorMessage = e.toString();
    }

    error('Auth error: $errorMessage', error: e);

    return currentState.copyWith(
      state: AuthState.error,
      errorMessage: errorMessage,
    );
  }
}
