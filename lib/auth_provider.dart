import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saasfork_core/saasfork_core.dart';
import 'package:saasfork_firebase_service/exceptions/auth_exceptions.dart';
import 'package:saasfork_firebase_service/models/auth_state_model.dart';
import 'package:saasfork_firebase_service/services/auth_service_interface.dart';
import 'package:saasfork_firebase_service/services/firebase_auth_service.dart';

final authProvider = NotifierProvider<AuthNotifier, AuthStateModel>(() {
  final FirebaseAuthService auth = FirebaseAuthService();
  return AuthNotifier(auth: auth);
});

/// Retourne l'utilisateur authentifié (ou null)
final currentUserProvider = Provider<UserModel?>((ref) {
  final authState = ref.watch(authProvider);
  return authState.user;
});

/// Provider qui expose l'ID de l'utilisateur authentifié (ou null)
final currentUserIdProvider = Provider<String?>((ref) {
  final user = ref.watch(currentUserProvider);
  return user?.uid;
});

class AuthNotifier extends Notifier<AuthStateModel> {
  late final AuthServiceInterface _auth;
  Completer<void>? _initializeCompleter;

  AuthNotifier({required AuthServiceInterface auth}) : _auth = auth;

  @override
  AuthStateModel build() {
    _initializeAuthListener();
    return AuthStateModel(state: AuthState.idle, user: null);
  }

  bool get isAuthenticated => state.state == AuthState.authenticated;

  Future<void> initialize() {
    if (_initializeCompleter == null || _initializeCompleter!.isCompleted) {
      if (state.state != AuthState.idle) {
        return Future.value();
      }
      _initializeCompleter = Completer<void>();
    }
    return _initializeCompleter!.future;
  }

  void _initializeAuthListener() {
    try {
      _auth.authStateChanges().listen((UserModel? user) async {
        if (user == null) {
          state = AuthStateModel(state: AuthState.unauthenticated, user: null);
        } else {
          try {
            state = AuthStateModel(state: AuthState.authenticated, user: user);
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
    var currentState = AuthStateModel.empty();

    try {
      final userModel = await _auth.signInWithEmailAndPassword(email, password);

      currentState = currentState.copyWith(
        state: AuthState.authenticated,
        user: userModel,
        errorMessage: null,
      );

      state = currentState;
    } on UserNotFoundException catch (e) {
      error('Auth error: User not found', error: e);
      currentState = currentState.copyWith(
        state: AuthState.error,
        errorMessage: e.code,
      );
      state = currentState;
    } on InvalidCredentialsException catch (e) {
      error('Auth error: Invalid credentials', error: e);
      currentState = currentState.copyWith(
        state: AuthState.error,
        errorMessage: e.code,
      );
      state = currentState;
    } on EmailAlreadyInUseException catch (e) {
      error('Auth error: Email already in use', error: e);
      currentState = currentState.copyWith(
        state: AuthState.error,
        errorMessage: e.code,
      );
      state = currentState;
    } on RecentLoginRequiredException catch (e) {
      error('Auth error: Recent login required', error: e);
      currentState = currentState.copyWith(
        state: AuthState.error,
        errorMessage: e.code,
      );
      state = currentState;
    } on AuthException catch (e) {
      error('Auth error: ${e.message}', error: e);
      currentState = currentState.copyWith(
        state: AuthState.error,
        errorMessage: e.code,
      );
      state = currentState;
    } catch (e) {
      error('Unexpected auth error: ${e.toString()}', error: e);
      currentState = currentState.copyWith(
        state: AuthState.error,
        errorMessage: AuthException.unknownCode,
      );
      state = currentState;
    }

    return state;
  }

  Future<AuthStateModel> register(String email, String password) async {
    var currentState = AuthStateModel.empty();

    try {
      final userModel = await _auth.createUserWithEmailAndPassword(
        email,
        password,
      );

      currentState = currentState.copyWith(
        state: AuthState.authenticated,
        user: userModel,
      );
      state = currentState;
    } on EmailAlreadyInUseException catch (e) {
      error('Auth error: Email already in use', error: e);
      currentState = currentState.copyWith(
        state: AuthState.error,
        errorMessage: e.code,
      );
      state = currentState;
    } on AuthException catch (e) {
      error('Auth error: ${e.message}', error: e);
      currentState = currentState.copyWith(
        state: AuthState.error,
        errorMessage: e.code,
      );
      state = currentState;
    } catch (e) {
      error('Unexpected auth error: ${e.toString()}', error: e);
      currentState = currentState.copyWith(
        state: AuthState.error,
        errorMessage: AuthException.unknownCode,
      );
      state = currentState;
    }

    return state;
  }

  Future<AuthStateModel> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return AuthStateModel(state: AuthState.idle, errorMessage: null);
    } on UserNotFoundException catch (e) {
      error('Error sending reset email: ${e.message}', error: e);
      return AuthStateModel(state: AuthState.error, errorMessage: e.code);
    } on AuthException catch (e) {
      error('Error sending reset email: ${e.message}', error: e);
      return AuthStateModel(state: AuthState.error, errorMessage: e.code);
    } catch (e) {
      error('Error sending reset email: ${e.toString()}', error: e);
      return AuthStateModel(
        state: AuthState.error,
        errorMessage: AuthException.unknownCode,
      );
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      state = AuthStateModel(
        state: AuthState.unauthenticated,
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
        errorMessage: AuthException.unknownCode,
      );
    }

    var currentState = AuthStateModel(
      state: state.state,
      user: state.user,
      errorMessage: state.errorMessage,
    );

    try {
      final updatedUser = await _auth.updateUserProfile(
        username: username,
        email: email,
      );

      currentState = currentState.copyWith(user: updatedUser);

      state = currentState;
      return state;
    } on UserNotFoundException catch (e) {
      error('Profile update error: ${e.message}', error: e);
      currentState = currentState.copyWith(
        state: AuthState.error,
        errorMessage: e.code,
      );
      state = currentState;
    } on RecentLoginRequiredException catch (e) {
      error('Profile update error: ${e.message}', error: e);
      currentState = currentState.copyWith(
        state: AuthState.error,
        errorMessage: e.code,
      );
      state = currentState;
    } on AuthException catch (e) {
      error('Profile update error: ${e.message}', error: e);
      currentState = currentState.copyWith(
        state: AuthState.error,
        errorMessage: e.code,
      );
      state = currentState;
    } catch (e) {
      error('Profile update error: ${e.toString()}', error: e);
      currentState = currentState.copyWith(
        state: AuthState.error,
        errorMessage: AuthException.unknownCode,
      );
      state = currentState;
    }

    return state;
  }

  Future<AuthStateModel> deleteUserAccount() async {
    if (state.user == null) {
      return AuthStateModel(
        state: AuthState.error,
        errorMessage: AuthException.unknownCode,
      );
    }

    var currentState = AuthStateModel(
      state: state.state,
      user: state.user,
      errorMessage: state.errorMessage,
    );

    currentState = currentState.copyWith(state: AuthState.updating);
    state = currentState;

    try {
      await _auth.deleteAccount();

      return AuthStateModel(
        state: AuthState.unauthenticated,
        errorMessage: null,
      );
    } on RecentLoginRequiredException catch (e) {
      error('Account deletion error: ${e.message}', error: e);
      currentState = currentState.copyWith(
        state: AuthState.error,
        errorMessage: e.code,
      );
      state = currentState;
    } on UserNotFoundException catch (e) {
      error('Account deletion error: ${e.message}', error: e);
      currentState = currentState.copyWith(
        state: AuthState.error,
        errorMessage: e.code,
      );
      state = currentState;
    } on AuthException catch (e) {
      error('Account deletion error: ${e.message}', error: e);
      currentState = currentState.copyWith(
        state: AuthState.error,
        errorMessage: e.code,
      );
      state = currentState;
    } catch (e) {
      error('Account deletion error: ${e.toString()}', error: e);
      currentState = currentState.copyWith(
        state: AuthState.error,
        errorMessage: AuthException.unknownCode,
      );
      state = currentState;
    }

    return state;
  }
}
