import 'dart:convert';

import 'package:saasfork_core/models/user_model.dart';

/// Les états d'authentification possibles:
/// - [AuthState.idle] : État initial ou après déconnexion
/// - [AuthState.authenticating] : Authentification en cours
/// - [AuthState.authenticated] : Utilisateur connecté
/// - [AuthState.unauthenticated] : Explicitement non-authentifié
/// - [AuthState.updating] : Mise à jour du profil en cours
/// - [AuthState.error] : Erreur survenue
enum AuthState {
  idle,
  authenticating,
  authenticated,
  unauthenticated,
  updating,
  error,
}

class AuthStateModel {
  final AuthState state;
  final UserModel? user;
  final String? errorMessage;

  AuthStateModel({this.state = AuthState.idle, this.user, this.errorMessage});

  AuthStateModel copyWith({
    AuthState? state,
    UserModel? user,
    String? errorMessage,
  }) {
    return AuthStateModel(
      state: state ?? this.state,
      user: user ?? this.user,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  bool get isAuthenticated => state == AuthState.authenticated;
  bool get hasError => errorMessage != null;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'state': state.toString(),
      'user': user?.toMap(),
      'error': errorMessage,
    };
  }

  factory AuthStateModel.fromMap(Map<String, dynamic> map) {
    return AuthStateModel(
      state:
          map['state'] != null
              ? AuthState.values[map['state'] as int]
              : AuthState.idle,
      user:
          map['user'] != null
              ? UserModel.fromMap(map['user'] as Map<String, dynamic>)
              : null,
      errorMessage: map['error'] != null ? map['error'] as String : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory AuthStateModel.fromJson(String source) =>
      AuthStateModel.fromMap(json.decode(source) as Map<String, dynamic>);

  factory AuthStateModel.empty() => AuthStateModel(
        state: AuthState.unauthenticated,
        user: null,
        errorMessage: null,
      );

  @override
  String toString() =>
      'AuthResultModel(state: $state, user: $user, error: $errorMessage)';

  @override
  bool operator ==(covariant AuthStateModel other) {
    if (identical(this, other)) return true;

    return other.state == state &&
        other.user == user &&
        other.errorMessage == errorMessage;
  }

  @override
  int get hashCode => state.hashCode ^ user.hashCode ^ errorMessage.hashCode;
}
