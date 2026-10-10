import 'dart:async';

import '../models/item.dart';

/// Mock store for the shared `Items` collection (Marketplace + Lost & Found).
/// Streams are filtered by [PostType] just like the Firestore query will be.
class ItemService {
  ItemService._() {
    _controller = StreamController<List<MarketItem>>.broadcast(
      onListen: () => _controller.add(List.unmodifiable(_items)),
    );
  }
  static final ItemService instance = ItemService._();

  late final StreamController<List<MarketItem>> _controller;

  final List<MarketItem> _items = [
    const MarketItem(itemID: 'm1', title: 'Scientific Calculator', description: 'FX-991 model, barely used.', price: 650, postType: PostType.marketplace, posterID: 'uid_validated_001', category: ItemCategory.devices),
    const MarketItem(itemID: 'm2', title: 'Engineering Drawing Set', description: 'Complete set with case.', price: 400, postType: PostType.marketplace, posterID: 'uid_pending_002', category: ItemCategory.materials),
    const MarketItem(itemID: 'm3', title: 'Lab Gown (Medium)', description: 'White, clean, no stains.', price: 250, postType: PostType.marketplace, posterID: 'uid_validated_001', category: ItemCategory.clothing),
    const MarketItem(itemID: 'm4', title: 'Used Textbooks Bundle', description: 'Calculus & Physics.', price: 800, postType: PostType.marketplace, posterID: 'uid_validated_001', category: ItemCategory.books),
    const MarketItem(itemID: 'm5', title: 'Homemade Cookies (12 pcs)', description: 'Freshly baked, great for snacks.', price: 120, postType: PostType.marketplace, posterID: 'uid_pending_002', category: ItemCategory.food),
    const MarketItem(itemID: 'm6', title: 'USB-C Hub', description: '6-in-1, HDMI + USB 3.0.', price: 550, postType: PostType.marketplace, posterID: 'uid_validated_001', category: ItemCategory.technology),
    const MarketItem(itemID: 'l1', title: 'Black Umbrella', description: 'Found near the library entrance.', postType: PostType.lostFound, posterID: 'uid_pending_002'),
    const MarketItem(itemID: 'l2', title: 'Student ID — A. Reyes', description: 'Found at the cafeteria.', postType: PostType.lostFound, posterID: 'uid_validated_001'),
    const MarketItem(itemID: 'l3', title: 'Blue Tumbler', description: 'Left in Room 204.', postType: PostType.lostFound, posterID: 'uid_validated_001'),
    const MarketItem(itemID: 'l4', title: 'Set of Keys', description: 'Found at the parking lot.', postType: PostType.lostFound, posterID: 'uid_pending_002'),
  ];

  /// Filtered stream — pass the post type for each screen.
  Stream<List<MarketItem>> streamByType(PostType type) {
    return _controller.stream
        .map((all) => all.where((i) => i.postType == type).toList());
  }

  List<MarketItem> byType(PostType type) =>
      _items.where((i) => i.postType == type).toList();

  Future<void> addItem(MarketItem item) async {
    await Future.delayed(const Duration(milliseconds: 400));
    _items.insert(0, item);
    _controller.add(List.unmodifiable(_items));
  }

  Future<void> updateItem(MarketItem item) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final i = _items.indexWhere((e) => e.itemID == item.itemID);
    if (i != -1) _items[i] = item;
    _controller.add(List.unmodifiable(_items));
  }

  Future<void> deleteItem(String itemID) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _items.removeWhere((e) => e.itemID == itemID);
    _controller.add(List.unmodifiable(_items));
  }
}
