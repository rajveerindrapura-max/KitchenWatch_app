import 'dart:async';
import 'package:uuid/uuid.dart';
import '../../../core/data/sample_data.dart';
import '../../../core/domain/permission_guard.dart';
import '../../auth/domain/user.dart';
import '../domain/team_repository.dart';

class MockTeamRepository implements TeamRepository {
  final List<User> _members = List.from(SampleData.initialUsers);
  final _controller = StreamController<List<User>>.broadcast();

  @override
  Future<List<User>> getTeamMembers() async {
    return List.unmodifiable(_members);
  }

  @override
  Future<User> inviteMember(
    User actor, {
    required String name,
    required String email,
    required String phone,
    required UserRole role,
    required List<String> assignedOutletIds,
  }) async {
    PermissionGuard.verifyManageTeam(actor.role);

    final newMember = User(
      id: 'user-${const Uuid().v4().substring(0, 8)}',
      name: name.trim(),
      email: email.trim(),
      phone: phone.trim(),
      role: role,
      assignedOutletIds: assignedOutletIds,
      isActive: true,
    );

    _members.add(newMember);
    _controller.add(List.unmodifiable(_members));
    return newMember;
  }

  @override
  Future<void> updateMember(User actor, User member) async {
    PermissionGuard.verifyManageTeam(actor.role);

    final index = _members.indexWhere((m) => m.id == member.id);
    if (index != -1) {
      _members[index] = member;
      _controller.add(List.unmodifiable(_members));
    }
  }

  @override
  Future<void> deactivateMember(User actor, String userId) async {
    PermissionGuard.verifyManageTeam(actor.role);

    final index = _members.indexWhere((m) => m.id == userId);
    if (index != -1) {
      _members[index] = _members[index].copyWith(isActive: false);
      _controller.add(List.unmodifiable(_members));
    }
  }

  @override
  Stream<List<User>> watchTeamMembers() async* {
    yield List.unmodifiable(_members);
    yield* _controller.stream;
  }

  void resetToSample() {
    _members.clear();
    _members.addAll(SampleData.initialUsers);
    _controller.add(List.unmodifiable(_members));
  }

  void dispose() {
    _controller.close();
  }
}
