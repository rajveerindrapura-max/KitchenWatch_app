import 'dart:async';
import '../../../core/data/sample_data.dart';
import '../domain/auth_repository.dart';
import '../domain/user.dart';

class MockAuthRepository implements AuthRepository {
  final _controller = StreamController<User?>.broadcast();
  User? _currentUser;

  MockAuthRepository({User? initialUser}) {
    // Default logged in user is the Owner for initial app preview
    _currentUser = initialUser ?? SampleData.initialUsers.first;
  }

  @override
  Future<User?> getCurrentUser() async {
    return _currentUser;
  }

  @override
  Future<User> signInWithEmailPassword(String email, String password) async {
    // Look up in sample users or create a mock session
    final found = SampleData.initialUsers.firstWhere(
      (u) => u.email.toLowerCase() == email.trim().toLowerCase(),
      orElse: () => SampleData.initialUsers.first,
    );
    _currentUser = found;
    _controller.add(_currentUser);
    return _currentUser!;
  }

  @override
  Future<User> signInWithPhone(String phone, String code) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    final found = SampleData.initialUsers.firstWhere(
      (u) => u.phone.replaceAll(RegExp(r'[\s\-\(\)]'), '').contains(cleanPhone),
      orElse: () => SampleData.initialUsers.first,
    );
    _currentUser = found;
    _controller.add(_currentUser);
    return _currentUser!;
  }

  Future<void> switchUser(User user) async {
    _currentUser = user;
    _controller.add(_currentUser);
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
    _controller.add(null);
  }

  @override
  Stream<User?> watchCurrentUser() async* {
    yield _currentUser;
    yield* _controller.stream;
  }

  void dispose() {
    _controller.close();
  }
}
