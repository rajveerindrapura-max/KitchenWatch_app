import 'movement.dart';

abstract class MovementRepository {
  Future<List<StockMovement>> getMovements({
    String? outletId,
    MovementType? type,
    String? userId,
    DateTime? since,
  });

  Future<void> logMovement(StockMovement movement);
  Stream<List<StockMovement>> watchMovements({String? outletId});
}
