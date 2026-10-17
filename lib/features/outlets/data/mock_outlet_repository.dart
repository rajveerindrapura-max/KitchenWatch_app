import 'dart:async';
import 'package:uuid/uuid.dart';
import '../../../core/data/sample_data.dart';
import '../../../core/domain/permission_guard.dart';
import '../../auth/domain/user.dart';
import '../domain/outlet.dart';
import '../domain/outlet_repository.dart';

class MockOutletRepository implements OutletRepository {
  final List<Outlet> _outlets = List.from(SampleData.initialOutlets);
  final _controller = StreamController<List<Outlet>>.broadcast();

  @override
  Future<List<Outlet>> getOutlets() async {
    return List.unmodifiable(_outlets);
  }

  @override
  Future<Outlet> createOutlet(
    User user, {
    required String name,
    required String address,
    String phone = '',
  }) async {
    PermissionGuard.verifyManageOutlets(user.role);

    final newOutlet = Outlet(
      id: 'outlet-${const Uuid().v4().substring(0, 8)}',
      name: name.trim(),
      address: address.trim(),
      phone: phone.trim(),
      isActive: true,
    );

    _outlets.add(newOutlet);
    _controller.add(List.unmodifiable(_outlets));
    return newOutlet;
  }

  @override
  Future<void> updateOutlet(User user, Outlet outlet) async {
    PermissionGuard.verifyManageOutlets(user.role);

    final index = _outlets.indexWhere((o) => o.id == outlet.id);
    if (index != -1) {
      _outlets[index] = outlet;
      _controller.add(List.unmodifiable(_outlets));
    }
  }

  @override
  Future<void> deleteOutlet(User user, String outletId) async {
    PermissionGuard.verifyManageOutlets(user.role);

    _outlets.removeWhere((o) => o.id == outletId);
    _controller.add(List.unmodifiable(_outlets));
  }

  @override
  Stream<List<Outlet>> watchOutlets() async* {
    yield List.unmodifiable(_outlets);
    yield* _controller.stream;
  }

  void resetToSample() {
    _outlets.clear();
    _outlets.addAll(SampleData.initialOutlets);
    _controller.add(List.unmodifiable(_outlets));
  }

  void clearAll() {
    _outlets.clear();
    _controller.add(List.unmodifiable(_outlets));
  }

  void dispose() {
    _controller.close();
  }
}
