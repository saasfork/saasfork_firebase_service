import 'package:saasfork_core/saasfork_core.dart';

abstract class AuthServiceInterface {
  Stream<UserModel?> authStateChanges();
  Future<UserModel> signInWithEmailAndPassword(String email, String password);
  Future<UserModel> createUserWithEmailAndPassword(
    String email,
    String password,
  );
  Future<UserModel> updateUserProfile({String? username, String? email});
  Future<void> sendPasswordResetEmail({required String email});
  Future<void> signOut();
  Future<void> deleteAccount();
  UserModel? get currentUser;
}
