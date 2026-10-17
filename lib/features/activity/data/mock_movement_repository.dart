import 'dart:async';
import '../../../core/data/sample_data.dart';
import '../domain/movement.dart';
import '../domain/movement_repository.dart';

class MockMovementRepository implements MovementRepository {
  final List<StockMovement> _movements = List.from(SampleData.generateInitialMovements());
  final _controller = StreamController<List<StockMovement>>.broadcast();

  @override
  Future<List<StockMovement>> getMovements({
    String? outletId,
    MovementType? type,
    String? userId,
    DateTime? since,
  }) async {
    return _filterMovements(outletId: outletId, type: type, userId: userId, since: since);
  }

  List<StockMovement> _filterMovements({
    String? outletId,
    MovementType? type,
    String? userId,
    DateTime? since,
  }) {
    var filtered = List<StockMovement>.from(_movements);

    if (outletId != null) {
      filtered = filtered
          .where((m) => m.fromOutletId == outletId || m.toOutletId == outletId)
          .toList();
    }

    if (type != null) {
      filtered = filtered.where((m) => m.type == type).toList();
    }

    if (userId != null) {
      filtered = filtered.where((m) => m.userId == userId).toList();
    }

    if (since != null) {
      filtered = filtered.where((m) => m.timestamp.isAfter(since)).toList();
    }

    // Sort newest first
    filtered.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return List.unmodifiable(filtered);
  }

  @override
  Future<void> logMovement(StockMovement movement) async {
    _movements.insert(0, movement);
    _controller.add(List.unmodifiable(_movements));
  }

  @override
  Stream<List<StockMovement>> watchMovements({String? outletId}) async* {
    yield _filterMovements(outletId: outletId);
    yield* _controller.stream.map((list) => _filterMovements(outletId: outletId));
  }

  void resetToSample() {
    _movements.clear();
    _movements.addAll(SampleData.generateInitialMovements());
    _controller.add(List.unmodifiable(_movements));
  }

  void clearAll() {
    _movements.clear();
    _controller.add(List.unmodifiable(_movements));
  }

  void dispose() {
    _controller.close();
  }
}
