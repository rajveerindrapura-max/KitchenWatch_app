import '../../auth/domain/user.dart';
import 'outlet.dart';

abstract class OutletRepository {
  Future<List<Outlet>> getOutlets();
  Future<Outlet> createOutlet(User user, {required String name, required String address, String phone});
  Future<void> updateOutlet(User user, Outlet outlet);
  Future<void> deleteOutlet(User user, String outletId);
  Stream<List<Outlet>> watchOutlets();
}
