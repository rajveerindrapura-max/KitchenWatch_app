import 'user.dart';

abstract class AuthRepository {
  Future<User?> getCurrentUser();
  Future<User> signInWithEmailPassword(String email, String password);
  Future<User> signInWithPhone(String phone, String code);
  Future<void> signOut();
  Stream<User?> watchCurrentUser();
}
