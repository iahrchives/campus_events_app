import 'package:flutter/material.dart';

import '../models/item.dart';
import '../screens/item_detail_screen.dart';
import '../screens/item_form_screen.dart';
import '../services/auth_service.dart';
import '../services/item_service.dart';
import '../theme/theme.dart';
import 'item_image.dart';
import 'soft_card.dart';

/// Shared layout for the Marketplace and Lost & Found boards:
/// search bar + filter button on top, then a strict 2-column grid.
class ItemBoardView extends StatefulWidget {
  final PostType type;
  final String title;

  const ItemBoardView({super.key, required this.type, required this.title});

  @override
  State<ItemBoardView> createState() => _ItemBoardViewState();
}

class _ItemBoardViewState extends State<ItemBoardView> {
  String _query = '';

  /// When true, only show listings posted by the current user.
  bool _mineOnly = false;

  /// Active category filters (marketplace only). All selected = no filtering.
  final Set<ItemCategory> _activeCategories =
      ItemCategory.values.toSet();

  bool get _filtersActive =>
      _activeCategories.length != ItemCategory.values.length;

  Future<void> _openFilter() async {
    final temp = _activeCategories.toSet();
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.neutralLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheet) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('Filter by category',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textDark)),
                      const Spacer(),
                      TextButton(
                        onPressed: () => setSheet(() =>
                            temp..clear()..addAll(ItemCategory.values)),
                        child: const Text('Select all'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ItemCategory.values.map((c) {
                      final on = temp.contains(c);
                      return FilterChip(
                        selected: on,
                        onSelected: (sel) => setSheet(() {
                          if (sel) {
                            temp.add(c);
                          } else if (temp.length > 1) {
                            // Keep at least one category selected.
                            temp.remove(c);
                          }
                        }),
                        avatar: Icon(c.icon,
                            size: 18,
                            color: on
                                ? AppColors.onAccent
                                : AppColors.primary),
                        label: Text(c.label),
                        labelStyle: TextStyle(
                          color: on
                              ? AppColors.onAccent
                              : AppColors.textDark,
                          fontWeight: FontWeight.w600,
                        ),
                        selectedColor: AppColors.primary,
                        backgroundColor:
                            AppColors.surfaceTint.withValues(alpha: 0.5),
                        showCheckmark: false,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadii.pill),
                          side: BorderSide(
                              color: AppColors.surfaceTint, width: 1.5),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _activeCategories
                            ..clear()
                            ..addAll(temp);
                        });
                        Navigator.pop(ctx);
                      },
                      child: const Text('Apply'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMarket = widget.type == PostType.marketplace;
    final myId = AuthService.instance.currentUser?.uid ?? '';
    final mineLabel = isMarket ? 'My Items' : 'My Reports';
    return Scaffold(
      backgroundColor: AppColors.neutralLight,
      appBar: AppBar(title: Text(widget.title)),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add),
        label: Text(isMarket ? 'Sell Item' : 'Report Item'),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => ItemFormScreen(type: widget.type)),
        ),
      ),
      body: Column(
        children: [
          // Search bar + filter button.
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (v) => setState(() => _query = v.toLowerCase()),
                    decoration: const InputDecoration(
                      hintText: 'Search...',
                      prefixIcon:
                          Icon(Icons.search, color: AppColors.secondary),
                    ),
                  ),
                ),
                if (isMarket) ...[
                  const SizedBox(width: 12),
                  Stack(
                    alignment: Alignment.topRight,
                    children: [
                      Container(
                        height: 56,
                        width: 56,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceTint,
                          borderRadius: BorderRadius.circular(AppRadii.field),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.tune_rounded,
                              color: AppColors.primary),
                          tooltip: 'Filter by category',
                          onPressed: _openFilter,
                        ),
                      ),
                      if (_filtersActive)
                        Container(
                          margin: const EdgeInsets.all(6),
                          height: 12,
                          width: 12,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          // "My Items" panel toggle — flips the board to the user's own posts.
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: Wrap(
                spacing: 8,
                children: [
                  _scopeChip(label: 'All', selected: !_mineOnly,
                      onTap: () => setState(() => _mineOnly = false)),
                  _scopeChip(
                      label: mineLabel,
                      icon: Icons.person_outline,
                      selected: _mineOnly,
                      onTap: () => setState(() => _mineOnly = true)),
                ],
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<MarketItem>>(
              stream: ItemService.instance.streamByType(widget.type),
              initialData: ItemService.instance.byType(widget.type),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final all = snapshot.data ?? const [];
                final items = all.where((i) {
                  final matchesQuery = _query.isEmpty ||
                      i.title.toLowerCase().contains(_query) ||
                      i.description.toLowerCase().contains(_query);
                  // Category filtering applies to the marketplace only.
                  final matchesCategory =
                      !isMarket || _activeCategories.contains(i.category);
                  final matchesScope = !_mineOnly || i.posterID == myId;
                  return matchesQuery && matchesCategory && matchesScope;
                }).toList();

                if (items.isEmpty) {
                  return Center(
                    child: Text(
                        _mineOnly
                            ? "You haven't posted anything here yet."
                            : _filtersActive
                                ? 'No items match the selected categories.'
                                : 'No items found.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textMuted)),
                  );
                }

                return GridView.count(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.82,
                  children:
                      items.map((i) => _itemCard(i, isMarket)).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _scopeChip({
    required String label,
    IconData? icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadii.pill),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary
              : AppColors.surfaceTint.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(AppRadii.pill),
          border: Border.all(color: AppColors.surfaceTint, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon,
                  size: 15,
                  color: selected ? AppColors.onAccent : AppColors.primary),
              const SizedBox(width: 5),
            ],
            Text(label,
                style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color:
                        selected ? AppColors.onAccent : AppColors.textDark)),
          ],
        ),
      ),
    );
  }

  Widget _itemCard(MarketItem item, bool isMarket) {
    final posterName = AuthService.instance.nameForUid(item.posterID);
    final isMine =
        item.posterID == (AuthService.instance.currentUser?.uid ?? '');
    return SoftCard(
      padding: const EdgeInsets.all(12),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ItemDetailScreen(item: item)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ItemImage(
                    source: item.imageURL,
                    fallbackIcon: isMarket
                        ? Icons.shopping_bag_outlined
                        : Icons.help_outline_rounded,
                  ),
                  if (isMarket)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(item.category.icon,
                                size: 12, color: Colors.white),
                            const SizedBox(width: 4),
                            Text(item.category.label,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ),
                  if (item.images.length > 1 || item.hasVideo)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                                item.hasVideo
                                    ? Icons.videocam
                                    : Icons.collections,
                                size: 12,
                                color: Colors.white),
                            const SizedBox(width: 3),
                            Text(
                                '${item.images.length + item.videos.length}',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            item.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontWeight: FontWeight.w800, color: AppColors.textDark),
          ),
          const SizedBox(height: 2),
          Text(
            isMarket && item.price != null
                ? '₱${item.price!.toStringAsFixed(0)}'
                : 'Lost & Found',
            style: const TextStyle(
                color: AppColors.primary, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          // Who posted this listing.
          Row(
            children: [
              Icon(isMine ? Icons.person : Icons.person_outline,
                  size: 13, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Expanded(
                child: Text(isMine ? 'You' : posterName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
