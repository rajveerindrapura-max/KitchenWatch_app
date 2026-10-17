import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/activity/domain/movement.dart';
import '../../features/auth/domain/user.dart';
import '../../features/inventory/domain/item_stock.dart';
import '../../features/outlets/domain/outlet.dart';
import '../../features/transfers/domain/transfer.dart';
import 'repository_providers.dart';

enum SyncState {
  synced,
  syncing,
  offline;

  String get label {
    switch (this) {
      case SyncState.synced:
        return 'Synced';
      case SyncState.syncing:
        return 'Syncing...';
      case SyncState.offline:
        return 'Offline (Queued)';
    }
  }
}

class SyncNotifier extends Notifier<SyncState> {
  @override
  SyncState build() => SyncState.synced;

  void setSyncState(SyncState state) => this.state = state;

  Future<void> simulateSync() async {
    state = SyncState.syncing;
    await Future.delayed(const Duration(milliseconds: 1200));
    state = SyncState.synced;
  }
}

final syncStatusProvider = NotifierProvider<SyncNotifier, SyncState>(SyncNotifier.new);

class IsDemoModeNotifier extends Notifier<bool> {
  @override
  bool build() => true;

  void setDemoMode(bool value) => state = value;
}

final isDemoModeProvider = NotifierProvider<IsDemoModeNotifier, bool>(IsDemoModeNotifier.new);

class SelectedOutletIdNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void selectOutlet(String? outletId) => state = outletId;
}

final selectedOutletIdProvider =
    NotifierProvider<SelectedOutletIdNotifier, String?>(SelectedOutletIdNotifier.new);

final currentUserProvider = StreamProvider<User?>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  return authRepo.watchCurrentUser();
});

final outletsProvider = StreamProvider<List<Outlet>>((ref) {
  final outletRepo = ref.watch(outletRepositoryProvider);
  return outletRepo.watchOutlets();
});

final itemStocksProvider = StreamProvider<List<ItemStock>>((ref) {
  final inventoryRepo = ref.watch(inventoryRepositoryProvider);
  final selectedOutletId = ref.watch(selectedOutletIdProvider);
  return inventoryRepo.watchItemStocks(outletId: selectedOutletId);
});

final movementsProvider = StreamProvider<List<StockMovement>>((ref) {
  final movementRepo = ref.watch(movementRepositoryProvider);
  final selectedOutletId = ref.watch(selectedOutletIdProvider);
  return movementRepo.watchMovements(outletId: selectedOutletId);
});

final transfersProvider = StreamProvider<List<TransferRecord>>((ref) {
  final transferRepo = ref.watch(transferRepositoryProvider);
  final selectedOutletId = ref.watch(selectedOutletIdProvider);
  return transferRepo.watchTransfers(outletId: selectedOutletId);
});
