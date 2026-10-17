import '../../auth/domain/user.dart';
import 'transfer.dart';

abstract class TransferRepository {
  Future<TransferRecord> createTransfer(
    User user, {
    required String fromOutletId,
    required String toOutletId,
    required List<TransferItem> items,
    String? notes,
  });

  Future<List<TransferRecord>> getTransfers({String? outletId});
  Stream<List<TransferRecord>> watchTransfers({String? outletId});
}
