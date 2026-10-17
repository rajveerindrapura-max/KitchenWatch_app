import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/activity/data/mock_movement_repository.dart';
import '../../features/auth/data/mock_auth_repository.dart';
import '../../features/inventory/data/mock_inventory_repository.dart';
import '../../features/outlets/data/mock_outlet_repository.dart';
import '../../features/team/data/mock_team_repository.dart';
import '../../features/transfers/data/mock_transfer_repository.dart';

final authRepositoryProvider = Provider<MockAuthRepository>((ref) {
  final repo = MockAuthRepository();
  ref.onDispose(repo.dispose);
  return repo;
});

final outletRepositoryProvider = Provider<MockOutletRepository>((ref) {
  final repo = MockOutletRepository();
  ref.onDispose(repo.dispose);
  return repo;
});

final movementRepositoryProvider = Provider<MockMovementRepository>((ref) {
  final repo = MockMovementRepository();
  ref.onDispose(repo.dispose);
  return repo;
});

final inventoryRepositoryProvider = Provider<MockInventoryRepository>((ref) {
  final movementRepo = ref.watch(movementRepositoryProvider);
  final outletRepo = ref.watch(outletRepositoryProvider);
  final repo = MockInventoryRepository(
    movementRepository: movementRepo,
    outletRepository: outletRepo,
  );
  ref.onDispose(repo.dispose);
  return repo;
});

final transferRepositoryProvider = Provider<MockTransferRepository>((ref) {
  final inventoryRepo = ref.watch(inventoryRepositoryProvider);
  final movementRepo = ref.watch(movementRepositoryProvider);
  final outletRepo = ref.watch(outletRepositoryProvider);
  final repo = MockTransferRepository(
    inventoryRepository: inventoryRepo,
    movementRepository: movementRepo,
    outletRepository: outletRepo,
  );
  ref.onDispose(repo.dispose);
  return repo;
});

final teamRepositoryProvider = Provider<MockTeamRepository>((ref) {
  final repo = MockTeamRepository();
  ref.onDispose(repo.dispose);
  return repo;
});
