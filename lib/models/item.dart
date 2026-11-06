import 'package:flutter/material.dart';

/// Shared template for Marketplace listings and Lost & Found posts
/// (mirrors the Firestore `Items` collection).
enum PostType { marketplace, lostFound }

extension PostTypeX on PostType {
  /// Stored string used for Firestore filtering.
  String get value =>
      this == PostType.marketplace ? 'marketplace' : 'lost_found';

  static PostType fromValue(String v) =>
      v == 'lost_found' ? PostType.lostFound : PostType.marketplace;
}

/// Category tag for listings (food, materials, devices, technology, …).
enum ItemCategory {
  food,
  materials,
  devices,
  technology,
  books,
  clothing,
  supplies,
  other,
}

extension ItemCategoryX on ItemCategory {
  /// Stored string used for Firestore filtering.
  String get value => name;

  String get label {
    switch (this) {
      case ItemCategory.food:
        return 'Food';
      case ItemCategory.materials:
        return 'Materials';
      case ItemCategory.devices:
        return 'Devices';
      case ItemCategory.technology:
        return 'Technology';
      case ItemCategory.books:
        return 'Books';
      case ItemCategory.clothing:
        return 'Clothing';
      case ItemCategory.supplies:
        return 'Supplies';
      case ItemCategory.other:
        return 'Other';
    }
  }

  IconData get icon {
    switch (this) {
      case ItemCategory.food:
        return Icons.fastfood_outlined;
      case ItemCategory.materials:
        return Icons.construction_outlined;
      case ItemCategory.devices:
        return Icons.devices_other_outlined;
      case ItemCategory.technology:
        return Icons.memory_outlined;
      case ItemCategory.books:
        return Icons.menu_book_outlined;
      case ItemCategory.clothing:
        return Icons.checkroom_outlined;
      case ItemCategory.supplies:
        return Icons.inventory_2_outlined;
      case ItemCategory.other:
        return Icons.category_outlined;
    }
  }

  static ItemCategory fromValue(String? v) => ItemCategory.values.firstWhere(
        (c) => c.name == v,
        orElse: () => ItemCategory.other,
      );
}

class MarketItem {
  /// Upload limits requested for marketplace listings.
  static const int maxPhotos = 6;
  static const int maxVideos = 2;

  final String itemID;
  final String title;
  final String description;

  /// null for Lost & Found items.
  final double? price;
  final PostType postType;
  final String posterID;

  /// Photo attachments (local paths or URLs). Up to [maxPhotos].
  final List<String> images;

  /// Video attachments (local paths or URLs). Up to [maxVideos].
  final List<String> videos;

  /// What kind of item this is (for filtering on the boards).
  final ItemCategory category;

  const MarketItem({
    required this.itemID,
    required this.title,
    required this.description,
    required this.postType,
    required this.posterID,
    this.price,
    List<String>? images,
    List<String>? videos,
    this.category = ItemCategory.other,
  })  : images = images ?? const [],
        videos = videos ?? const [];

  /// Cover image used by cards / previews (first photo if any).
  String? get imageURL => images.isNotEmpty ? images.first : null;

  bool get hasVideo => videos.isNotEmpty;

  MarketItem copyWith({
    String? title,
    String? description,
    double? price,
    bool clearPrice = false,
    List<String>? images,
    List<String>? videos,
    ItemCategory? category,
  }) =>
      MarketItem(
        itemID: itemID,
        title: title ?? this.title,
        description: description ?? this.description,
        price: clearPrice ? null : (price ?? this.price),
        postType: postType,
        posterID: posterID,
        images: images ?? this.images,
        videos: videos ?? this.videos,
        category: category ?? this.category,
      );

  Map<String, dynamic> toMap() => {
        'itemID': itemID,
        'title': title,
        'description': description,
        'price': price,
        'postType': postType.value,
        'posterID': posterID,
        'images': images,
        'videos': videos,
        'category': category.value,
      };

  factory MarketItem.fromMap(String id, Map<String, dynamic> map) => MarketItem(
        itemID: id,
        title: map['title'] as String? ?? '',
        description: map['description'] as String? ?? '',
        price: (map['price'] as num?)?.toDouble(),
        postType: PostTypeX.fromValue(map['postType'] as String? ?? 'marketplace'),
        posterID: map['posterID'] as String? ?? '',
        images: (map['images'] as List?)?.cast<String>() ??
            (map['imageURL'] != null ? [map['imageURL'] as String] : const []),
        videos: (map['videos'] as List?)?.cast<String>() ?? const [],
        category: ItemCategoryX.fromValue(map['category'] as String?),
      );
}
