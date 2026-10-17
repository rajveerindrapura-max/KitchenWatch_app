import '../../../core/domain/permission_guard.dart';
import '../../auth/domain/user.dart';

abstract class TeamRepository {
  Future<List<User>> getTeamMembers();
  Future<User> inviteMember(
    User actor, {
    required String name,
    required String email,
    required String phone,
    required UserRole role,
    required List<String> assignedOutletIds,
  });
  Future<void> updateMember(User actor, User member);
  Future<void> deactivateMember(User actor, String userId);
  Stream<List<User>> watchTeamMembers();
}
