import '../../features/activity/domain/movement.dart';
import '../../features/auth/domain/user.dart';
import '../../features/inventory/domain/item.dart';
import '../../features/inventory/domain/stock_batch.dart';
import '../../features/inventory/domain/stock_unit.dart';
import '../../features/outlets/domain/outlet.dart';
import '../domain/permission_guard.dart';

class SampleData {
  SampleData._();

  static List<Outlet> get initialOutlets => [
        const Outlet(
          id: 'outlet-1',
          name: 'Main Kitchen - Downtown',
          address: '42 Brigade Road, Central District',
          phone: '+91 80 4123 4567',
          isActive: true,
        ),
        const Outlet(
          id: 'outlet-2',
          name: 'Westside Cloud Kitchen',
          address: 'Plot 18, Phase 2 Industrial Area',
          phone: '+91 80 4123 4568',
          isActive: true,
        ),
        const Outlet(
          id: 'outlet-3',
          name: 'Airport Express Hub',
          address: 'Terminal 1 Concourse East',
          phone: '+91 80 4123 4569',
          isActive: true,
        ),
      ];

  static List<User> get initialUsers => [
        const User(
          id: 'user-owner',
          name: 'Aarav Sharma',
          email: 'owner@kitchenwatch.io',
          phone: '+91 98765 43210',
          role: UserRole.owner,
          assignedOutletIds: ['outlet-1', 'outlet-2', 'outlet-3'],
          isActive: true,
        ),
        const User(
          id: 'user-manager',
          name: 'Priya Patel',
          email: 'manager@kitchenwatch.io',
          phone: '+91 98765 43211',
          role: UserRole.manager,
          assignedOutletIds: ['outlet-1', 'outlet-2'],
          isActive: true,
        ),
        const User(
          id: 'user-employee',
          name: 'Rohan Verma',
          email: 'employee@kitchenwatch.io',
          phone: '+91 98765 43212',
          role: UserRole.employee,
          assignedOutletIds: ['outlet-1'],
          isActive: true,
        ),
      ];

  static List<Item> get initialItems => [
        // Grains & Flours
        const Item(
          id: 'item-1',
          name: 'Basmati Rice',
          category: 'Grains & Flours',
          unit: StockUnit.kg,
          mainPacketSize: 10.0,
          minLevel: 25.0,
          purchasePricePerUnit: 85.0,
          trackExpiry: false,
          preferredVendor: 'Apex Agro Supplies',
        ),
        const Item(
          id: 'item-2',
          name: 'Sona Masoori Rice',
          category: 'Grains & Flours',
          unit: StockUnit.kg,
          mainPacketSize: 10.0,
          minLevel: 20.0,
          purchasePricePerUnit: 62.0,
          trackExpiry: false,
        ),
        const Item(
          id: 'item-3',
          name: 'Whole Wheat Atta',
          category: 'Grains & Flours',
          unit: StockUnit.kg,
          mainPacketSize: 10.0,
          minLevel: 30.0,
          purchasePricePerUnit: 45.0,
          trackExpiry: false,
        ),
        const Item(
          id: 'item-4',
          name: 'Maida Flour',
          category: 'Grains & Flours',
          unit: StockUnit.kg,
          mainPacketSize: 5.0,
          minLevel: 15.0,
          purchasePricePerUnit: 40.0,
          trackExpiry: false,
        ),
        const Item(
          id: 'item-5',
          name: 'Semolina Sooji',
          category: 'Grains & Flours',
          unit: StockUnit.kg,
          mainPacketSize: 2.0,
          minLevel: 10.0,
          purchasePricePerUnit: 55.0,
          trackExpiry: false,
        ),
        const Item(
          id: 'item-6',
          name: 'Rolled Oats',
          category: 'Grains & Flours',
          unit: StockUnit.kg,
          mainPacketSize: 1.0,
          minLevel: 5.0,
          purchasePricePerUnit: 140.0,
          trackExpiry: false,
        ),

        // Oils & Fats
        const Item(
          id: 'item-7',
          name: 'Sunflower Cooking Oil',
          category: 'Oils & Fats',
          unit: StockUnit.l,
          mainPacketSize: 15.0,
          minLevel: 30.0,
          purchasePricePerUnit: 130.0,
          trackExpiry: false,
        ),
        const Item(
          id: 'item-8',
          name: 'Mustard Oil',
          category: 'Oils & Fats',
          unit: StockUnit.l,
          mainPacketSize: 5.0,
          minLevel: 10.0,
          purchasePricePerUnit: 150.0,
          trackExpiry: false,
        ),
        const Item(
          id: 'item-9',
          name: 'Extra Virgin Olive Oil',
          category: 'Oils & Fats',
          unit: StockUnit.l,
          mainPacketSize: 5.0,
          minLevel: 5.0,
          purchasePricePerUnit: 750.0,
          trackExpiry: false,
        ),
        const Item(
          id: 'item-10',
          name: 'Pure Desi Ghee',
          category: 'Oils & Fats',
          unit: StockUnit.kg,
          mainPacketSize: 5.0,
          minLevel: 10.0,
          purchasePricePerUnit: 580.0,
          trackExpiry: false,
        ),
        const Item(
          id: 'item-11',
          name: 'Salted Butter Blocks',
          category: 'Oils & Fats',
          unit: StockUnit.kg,
          mainPacketSize: 1.0,
          minLevel: 8.0,
          purchasePricePerUnit: 460.0,
          trackExpiry: true,
        ),

        // Dairy
        const Item(
          id: 'item-12',
          name: 'Fresh Full Cream Milk',
          category: 'Dairy',
          unit: StockUnit.l,
          mainPacketSize: 1.0,
          minLevel: 25.0,
          purchasePricePerUnit: 66.0,
          trackExpiry: true,
        ),
        const Item(
          id: 'item-13',
          name: 'Cooking Cream',
          category: 'Dairy',
          unit: StockUnit.l,
          mainPacketSize: 1.0,
          minLevel: 10.0,
          purchasePricePerUnit: 210.0,
          trackExpiry: true,
        ),
        const Item(
          id: 'item-14',
          name: 'Fresh Paneer Block',
          category: 'Dairy',
          unit: StockUnit.kg,
          mainPacketSize: 1.0,
          minLevel: 12.0,
          purchasePricePerUnit: 360.0,
          trackExpiry: true,
        ),
        const Item(
          id: 'item-15',
          name: 'Mozzarella Cheese',
          category: 'Dairy',
          unit: StockUnit.kg,
          mainPacketSize: 2.0,
          minLevel: 8.0,
          purchasePricePerUnit: 480.0,
          trackExpiry: true,
        ),
        const Item(
          id: 'item-16',
          name: 'Greek Yogurt Tub',
          category: 'Dairy',
          unit: StockUnit.kg,
          mainPacketSize: 1.0,
          minLevel: 5.0,
          purchasePricePerUnit: 180.0,
          trackExpiry: true,
        ),

        // Produce & Fresh
        const Item(
          id: 'item-17',
          name: 'Red Onions',
          category: 'Produce',
          unit: StockUnit.kg,
          mainPacketSize: 50.0,
          minLevel: 40.0,
          purchasePricePerUnit: 32.0,
          trackExpiry: false,
        ),
        const Item(
          id: 'item-18',
          name: 'Fresh Potatoes',
          category: 'Produce',
          unit: StockUnit.kg,
          mainPacketSize: 50.0,
          minLevel: 35.0,
          purchasePricePerUnit: 28.0,
          trackExpiry: false,
        ),
        const Item(
          id: 'item-19',
          name: 'Roma Tomatoes',
          category: 'Produce',
          unit: StockUnit.kg,
          mainPacketSize: 10.0,
          minLevel: 20.0,
          purchasePricePerUnit: 45.0,
          trackExpiry: true,
        ),
        const Item(
          id: 'item-20',
          name: 'Fresh Ginger Root',
          category: 'Produce',
          unit: StockUnit.kg,
          mainPacketSize: 5.0,
          minLevel: 5.0,
          purchasePricePerUnit: 120.0,
          trackExpiry: false,
        ),
        const Item(
          id: 'item-21',
          name: 'Garlic Bulbs',
          category: 'Produce',
          unit: StockUnit.kg,
          mainPacketSize: 5.0,
          minLevel: 8.0,
          purchasePricePerUnit: 160.0,
          trackExpiry: false,
        ),
        const Item(
          id: 'item-22',
          name: 'Green Chillies',
          category: 'Produce',
          unit: StockUnit.kg,
          mainPacketSize: 2.0,
          minLevel: 3.0,
          purchasePricePerUnit: 90.0,
          trackExpiry: true,
        ),
        const Item(
          id: 'item-23',
          name: 'Fresh Coriander',
          category: 'Produce',
          unit: StockUnit.kg,
          mainPacketSize: 1.0,
          minLevel: 3.0,
          purchasePricePerUnit: 60.0,
          trackExpiry: true,
        ),
        const Item(
          id: 'item-24',
          name: 'Bell Peppers Tri-color',
          category: 'Produce',
          unit: StockUnit.kg,
          mainPacketSize: 5.0,
          minLevel: 6.0,
          purchasePricePerUnit: 85.0,
          trackExpiry: true,
        ),
        const Item(
          id: 'item-25',
          name: 'Fresh Lemons',
          category: 'Produce',
          unit: StockUnit.kg,
          mainPacketSize: 5.0,
          minLevel: 4.0,
          purchasePricePerUnit: 70.0,
          trackExpiry: false,
        ),

        // Meat & Poultry
        const Item(
          id: 'item-26',
          name: 'Fresh Chicken Breast',
          category: 'Meat & Poultry',
          unit: StockUnit.kg,
          mainPacketSize: 5.0,
          minLevel: 15.0,
          purchasePricePerUnit: 260.0,
          trackExpiry: true,
        ),
        const Item(
          id: 'item-27',
          name: 'Boneless Mutton',
          category: 'Meat & Poultry',
          unit: StockUnit.kg,
          mainPacketSize: 5.0,
          minLevel: 10.0,
          purchasePricePerUnit: 780.0,
          trackExpiry: true,
        ),
        const Item(
          id: 'item-28',
          name: 'Farm Fresh Eggs',
          category: 'Meat & Poultry',
          unit: StockUnit.pieces,
          mainPacketSize: 30.0,
          minLevel: 90.0,
          purchasePricePerUnit: 7.0,
          trackExpiry: true,
        ),
        const Item(
          id: 'item-29',
          name: 'Basa Fish Fillets',
          category: 'Meat & Poultry',
          unit: StockUnit.kg,
          mainPacketSize: 5.0,
          minLevel: 8.0,
          purchasePricePerUnit: 320.0,
          trackExpiry: true,
        ),

        // Spices & Seasonings
        const Item(
          id: 'item-30',
          name: 'Black Peppercorns',
          category: 'Spices',
          unit: StockUnit.kg,
          mainPacketSize: 1.0,
          minLevel: 2.0,
          purchasePricePerUnit: 650.0,
          trackExpiry: false,
        ),
        const Item(
          id: 'item-31',
          name: 'Cumin Seeds Jeera',
          category: 'Spices',
          unit: StockUnit.kg,
          mainPacketSize: 1.0,
          minLevel: 3.0,
          purchasePricePerUnit: 380.0,
          trackExpiry: false,
        ),
        const Item(
          id: 'item-32',
          name: 'Turmeric Powder',
          category: 'Spices',
          unit: StockUnit.kg,
          mainPacketSize: 1.0,
          minLevel: 4.0,
          purchasePricePerUnit: 190.0,
          trackExpiry: false,
        ),
        const Item(
          id: 'item-33',
          name: 'Garam Masala Blend',
          category: 'Spices',
          unit: StockUnit.kg,
          mainPacketSize: 1.0,
          minLevel: 2.0,
          purchasePricePerUnit: 520.0,
          trackExpiry: false,
        ),
        const Item(
          id: 'item-34',
          name: 'Kashmiri Chilli Powder',
          category: 'Spices',
          unit: StockUnit.kg,
          mainPacketSize: 1.0,
          minLevel: 3.0,
          purchasePricePerUnit: 420.0,
          trackExpiry: false,
        ),
        const Item(
          id: 'item-35',
          name: 'Iodized Table Salt',
          category: 'Spices',
          unit: StockUnit.kg,
          mainPacketSize: 1.0,
          minLevel: 20.0,
          purchasePricePerUnit: 25.0,
          trackExpiry: false,
        ),
        const Item(
          id: 'item-36',
          name: 'Granulated Sugar',
          category: 'Spices',
          unit: StockUnit.kg,
          mainPacketSize: 5.0,
          minLevel: 15.0,
          purchasePricePerUnit: 46.0,
          trackExpiry: false,
        ),

        // Packaging & Disposables
        const Item(
          id: 'item-37',
          name: '500ml Meal Bowls',
          category: 'Packaging',
          unit: StockUnit.pieces,
          mainPacketSize: 50.0,
          minLevel: 200.0,
          purchasePricePerUnit: 6.0,
          trackExpiry: false,
        ),
        const Item(
          id: 'item-38',
          name: '750ml Meal Containers',
          category: 'Packaging',
          unit: StockUnit.pieces,
          mainPacketSize: 50.0,
          minLevel: 200.0,
          purchasePricePerUnit: 8.0,
          trackExpiry: false,
        ),
        const Item(
          id: 'item-39',
          name: 'Kraft Paper Bags',
          category: 'Packaging',
          unit: StockUnit.pieces,
          mainPacketSize: 100.0,
          minLevel: 300.0,
          purchasePricePerUnit: 7.0,
          trackExpiry: false,
        ),
        const Item(
          id: 'item-40',
          name: 'Food Grade Foil Rolls',
          category: 'Packaging',
          unit: StockUnit.pieces,
          mainPacketSize: 1.0,
          minLevel: 5.0,
          purchasePricePerUnit: 280.0,
          trackExpiry: false,
        ),
      ];

  static List<StockBatch> generateInitialBatches() {
    final now = DateTime.now();
    final List<StockBatch> batches = [];

    // Helper to add batches across outlets
    void addBatches(
      String itemId,
      double price, {
      required double q1,
      required double q2,
      required double q3,
      int? expiryDays,
    }) {
      if (q1 > 0) {
        batches.add(StockBatch(
          batchId: 'b-$itemId-1-a',
          itemId: itemId,
          outletId: 'outlet-1',
          quantity: q1 * 0.6,
          purchasePrice: price,
          receivedDate: now.subtract(const Duration(days: 4)),
          expiryDate: expiryDays != null ? now.add(Duration(days: expiryDays)) : null,
        ));
        batches.add(StockBatch(
          batchId: 'b-$itemId-1-b',
          itemId: itemId,
          outletId: 'outlet-1',
          quantity: q1 * 0.4,
          purchasePrice: price * 1.05,
          receivedDate: now.subtract(const Duration(days: 1)),
          expiryDate: expiryDays != null ? now.add(Duration(days: expiryDays + 3)) : null,
        ));
      }

      if (q2 > 0) {
        batches.add(StockBatch(
          batchId: 'b-$itemId-2',
          itemId: itemId,
          outletId: 'outlet-2',
          quantity: q2,
          purchasePrice: price,
          receivedDate: now.subtract(const Duration(days: 3)),
          expiryDate: expiryDays != null ? now.add(Duration(days: expiryDays + 1)) : null,
        ));
      }

      if (q3 > 0) {
        batches.add(StockBatch(
          batchId: 'b-$itemId-3',
          itemId: itemId,
          outletId: 'outlet-3',
          quantity: q3,
          purchasePrice: price,
          receivedDate: now.subtract(const Duration(days: 2)),
          expiryDate: expiryDays != null ? now.add(Duration(days: expiryDays + 2)) : null,
        ));
      }
    }

    // Grains
    addBatches('item-1', 85.0, q1: 45, q2: 30, q3: 20); // Basmati Rice (healthy)
    addBatches('item-2', 62.0, q1: 15, q2: 8, q3: 10); // Sona Masoori (low in outlet-2, total 33)
    addBatches('item-3', 45.0, q1: 50, q2: 40, q3: 25);
    addBatches('item-4', 40.0, q1: 25, q2: 15, q3: 10);
    addBatches('item-5', 55.0, q1: 18, q2: 12, q3: 8);
    addBatches('item-6', 140.0, q1: 8, q2: 6, q3: 4);

    // Oils
    addBatches('item-7', 130.0, q1: 45, q2: 30, q3: 15);
    addBatches('item-8', 150.0, q1: 15, q2: 10, q3: 5);
    addBatches('item-9', 750.0, q1: 8, q2: 5, q3: 4);
    addBatches('item-10', 580.0, q1: 15, q2: 10, q3: 8);
    addBatches('item-11', 460.0, q1: 12, q2: 8, q3: 5, expiryDays: 14);

    // Dairy (some near expiry & low stock!)
    // Fresh Milk: low stock (total 18L vs min 25L) & expiring in 2 days in outlet-1!
    batches.add(StockBatch(
      batchId: 'b-milk-urgent',
      itemId: 'item-12',
      outletId: 'outlet-1',
      quantity: 8.0,
      purchasePrice: 66.0,
      receivedDate: now.subtract(const Duration(days: 2)),
      expiryDate: now.add(const Duration(days: 2)), // 2 days left!
    ));
    batches.add(StockBatch(
      batchId: 'b-milk-out2',
      itemId: 'item-12',
      outletId: 'outlet-2',
      quantity: 10.0,
      purchasePrice: 66.0,
      receivedDate: now.subtract(const Duration(days: 1)),
      expiryDate: now.add(const Duration(days: 3)),
    ));

    // Fresh Paneer: expiring in 1 day in outlet-1! Perfect candidate for transfer!
    batches.add(StockBatch(
      batchId: 'b-paneer-urgent',
      itemId: 'item-14',
      outletId: 'outlet-1',
      quantity: 6.0,
      purchasePrice: 360.0,
      receivedDate: now.subtract(const Duration(days: 3)),
      expiryDate: now.add(const Duration(days: 1)), // 1 day left!
    ));
    batches.add(StockBatch(
      batchId: 'b-paneer-out2',
      itemId: 'item-14',
      outletId: 'outlet-2',
      quantity: 8.0,
      purchasePrice: 360.0,
      receivedDate: now.subtract(const Duration(days: 1)),
      expiryDate: now.add(const Duration(days: 4)),
    ));

    addBatches('item-13', 210.0, q1: 12, q2: 10, q3: 6, expiryDays: 10);
    addBatches('item-15', 480.0, q1: 10, q2: 8, q3: 6, expiryDays: 20);
    addBatches('item-16', 180.0, q1: 7, q2: 5, q3: 3, expiryDays: 7);

    // Produce (Tomatoes low stock: total 14kg vs min 20kg!)
    batches.add(StockBatch(
      batchId: 'b-tomatoes-out1',
      itemId: 'item-19',
      outletId: 'outlet-1',
      quantity: 8.0,
      purchasePrice: 45.0,
      receivedDate: now.subtract(const Duration(days: 2)),
      expiryDate: now.add(const Duration(days: 4)),
    ));
    batches.add(StockBatch(
      batchId: 'b-tomatoes-out2',
      itemId: 'item-19',
      outletId: 'outlet-2',
      quantity: 6.0,
      purchasePrice: 45.0,
      receivedDate: now.subtract(const Duration(days: 1)),
      expiryDate: now.add(const Duration(days: 5)),
    ));

    addBatches('item-17', 32.0, q1: 70, q2: 50, q3: 30);
    addBatches('item-18', 28.0, q1: 80, q2: 60, q3: 40);
    addBatches('item-20', 120.0, q1: 10, q2: 6, q3: 4);
    addBatches('item-21', 160.0, q1: 14, q2: 10, q3: 6);
    addBatches('item-22', 90.0, q1: 5, q2: 4, q3: 2, expiryDays: 5);
    addBatches('item-23', 60.0, q1: 4, q2: 3, q3: 2, expiryDays: 3);
    addBatches('item-24', 85.0, q1: 9, q2: 7, q3: 5, expiryDays: 6);
    addBatches('item-25', 70.0, q1: 8, q2: 6, q3: 4);

    // Meat
    // Chicken Breast: expiring in 2 days in outlet-2
    batches.add(StockBatch(
      batchId: 'b-chicken-out1',
      itemId: 'item-26',
      outletId: 'outlet-1',
      quantity: 12.0,
      purchasePrice: 260.0,
      receivedDate: now.subtract(const Duration(days: 1)),
      expiryDate: now.add(const Duration(days: 3)),
    ));
    batches.add(StockBatch(
      batchId: 'b-chicken-out2',
      itemId: 'item-26',
      outletId: 'outlet-2',
      quantity: 5.0,
      purchasePrice: 260.0,
      receivedDate: now.subtract(const Duration(days: 2)),
      expiryDate: now.add(const Duration(days: 2)), // 2 days left
    ));

    addBatches('item-27', 780.0, q1: 14, q2: 10, q3: 6, expiryDays: 4);
    addBatches('item-28', 7.0, q1: 150, q2: 120, q3: 60, expiryDays: 12);
    addBatches('item-29', 320.0, q1: 12, q2: 8, q3: 5, expiryDays: 8);

    // Spices
    addBatches('item-30', 650.0, q1: 4, q2: 3, q3: 2);
    addBatches('item-31', 380.0, q1: 5, q2: 4, q3: 3);
    addBatches('item-32', 190.0, q1: 6, q2: 5, q3: 3);
    addBatches('item-33', 520.0, q1: 3, q2: 2, q3: 2);
    addBatches('item-34', 420.0, q1: 5, q2: 4, q3: 2);
    addBatches('item-35', 25.0, q1: 30, q2: 25, q3: 15);
    addBatches('item-36', 46.0, q1: 25, q2: 20, q3: 10);

    // Packaging
    addBatches('item-37', 6.0, q1: 350, q2: 250, q3: 150);
    addBatches('item-38', 8.0, q1: 300, q2: 220, q3: 140);
    addBatches('item-39', 7.0, q1: 450, q2: 350, q3: 200);
    addBatches('item-40', 280.0, q1: 8, q2: 6, q3: 4);

    return batches;
  }

  static List<StockMovement> generateInitialMovements() {
    final now = DateTime.now();

    return [
      // 1. Used by employee Rohan today
      StockMovement(
        id: 'mov-1',
        type: MovementType.used,
        itemId: 'item-1',
        itemName: 'Basmati Rice',
        fromOutletId: 'outlet-1',
        fromOutletName: 'Main Kitchen - Downtown',
        quantity: 5.0,
        unit: StockUnit.kg,
        userId: 'user-employee',
        userName: 'Rohan Verma',
        userRole: UserRole.employee,
        timestamp: now.subtract(const Duration(minutes: 45)),
        costImpact: 425.0,
      ),
      // 2. Wasted by employee Rohan today (spoilage)
      StockMovement(
        id: 'mov-2',
        type: MovementType.wasted,
        itemId: 'item-19',
        itemName: 'Roma Tomatoes',
        fromOutletId: 'outlet-1',
        fromOutletName: 'Main Kitchen - Downtown',
        quantity: 2.0,
        unit: StockUnit.kg,
        userId: 'user-employee',
        userName: 'Rohan Verma',
        userRole: UserRole.employee,
        timestamp: now.subtract(const Duration(hours: 3)),
        wasteReason: WasteReason.spoilage,
        costImpact: 90.0,
      ),
      // 3. Transferred by Manager Priya yesterday
      StockMovement(
        id: 'mov-3',
        type: MovementType.transferred,
        itemId: 'item-14',
        itemName: 'Fresh Paneer Block',
        fromOutletId: 'outlet-1',
        fromOutletName: 'Main Kitchen - Downtown',
        toOutletId: 'outlet-2',
        toOutletName: 'Westside Cloud Kitchen',
        quantity: 4.0,
        unit: StockUnit.kg,
        userId: 'user-manager',
        userName: 'Priya Patel',
        userRole: UserRole.manager,
        timestamp: now.subtract(const Duration(hours: 18)),
        costImpact: 1440.0,
      ),
      // 4. Received incoming by Manager Priya 2 days ago
      StockMovement(
        id: 'mov-4',
        type: MovementType.received,
        itemId: 'item-7',
        itemName: 'Sunflower Cooking Oil',
        fromOutletId: 'outlet-1',
        fromOutletName: 'Main Kitchen - Downtown',
        quantity: 30.0,
        unit: StockUnit.l,
        userId: 'user-manager',
        userName: 'Priya Patel',
        userRole: UserRole.manager,
        timestamp: now.subtract(const Duration(days: 2)),
        costImpact: 3900.0,
      ),
      // 5. Wasted in Westside Cloud Kitchen (expiry)
      StockMovement(
        id: 'mov-5',
        type: MovementType.wasted,
        itemId: 'item-12',
        itemName: 'Fresh Full Cream Milk',
        fromOutletId: 'outlet-2',
        fromOutletName: 'Westside Cloud Kitchen',
        quantity: 3.0,
        unit: StockUnit.l,
        userId: 'user-manager',
        userName: 'Priya Patel',
        userRole: UserRole.manager,
        timestamp: now.subtract(const Duration(days: 3)),
        wasteReason: WasteReason.expiry,
        costImpact: 198.0,
      ),
      // 6. Adjustment by Owner Aarav 4 days ago
      StockMovement(
        id: 'mov-6',
        type: MovementType.adjustment,
        itemId: 'item-17',
        itemName: 'Red Onions',
        fromOutletId: 'outlet-1',
        fromOutletName: 'Main Kitchen - Downtown',
        quantity: 3.0,
        unit: StockUnit.kg,
        userId: 'user-owner',
        userName: 'Aarav Sharma',
        userRole: UserRole.owner,
        timestamp: now.subtract(const Duration(days: 4)),
        note: 'Audit correction after monthly physical scale count',
        costImpact: 96.0,
      ),
      // 7. Wasted in Airport Express (spill or damage)
      StockMovement(
        id: 'mov-7',
        type: MovementType.wasted,
        itemId: 'item-8',
        itemName: 'Mustard Oil',
        fromOutletId: 'outlet-3',
        fromOutletName: 'Airport Express Hub',
        quantity: 1.0,
        unit: StockUnit.l,
        userId: 'user-owner',
        userName: 'Aarav Sharma',
        userRole: UserRole.owner,
        timestamp: now.subtract(const Duration(days: 5)),
        wasteReason: WasteReason.spillOrDamage,
        costImpact: 150.0,
      ),
    ];
  }
}
