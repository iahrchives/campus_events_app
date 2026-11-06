import 'package:flutter/material.dart';

import '../models/item.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import '../services/item_service.dart';
import '../theme/theme.dart';
import '../widgets/item_image.dart';
import '../widgets/pill_button.dart';
import '../widgets/user_avatar.dart';
import 'chat_screen.dart';
import 'item_form_screen.dart';

/// Read view for a single listing with Edit + Delete (full CRUD).
class ItemDetailScreen extends StatefulWidget {
  final MarketItem item;

  const ItemDetailScreen({super.key, required this.item});

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  final _pageController = PageController();
  int _page = 0;

  MarketItem get item => widget.item;
  bool get _isMarket => item.postType == PostType.marketplace;

  void _messageSeller() {
    final me = AuthService.instance.currentUser?.uid ?? 'me';
    if (me == item.posterID) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('This is your own listing.')));
      return;
    }
    final convo = ChatService.instance.openConversation(
      itemId: item.itemID,
      itemTitle: item.title,
      buyerId: me,
      sellerId: item.posterID,
    );
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ChatScreen(conversation: convo)),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Widget _posterRow() {
    final me = AuthService.instance.currentUser?.uid ?? '';
    final isMine = item.posterID == me;
    final name = AuthService.instance.nameForUid(item.posterID);
    final photo =
        AuthService.instance.profileForUid(item.posterID)?.photoURL;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceTint.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(AppRadii.field),
      ),
      child: Row(
        children: [
          UserAvatar(photoURL: photo, radius: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_isMarket ? 'Posted by' : 'Reported by',
                    style: TextStyle(
                        fontSize: 11.5, color: AppColors.textMuted)),
                const SizedBox(height: 2),
                Text(isMine ? '$name (You)' : name,
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Delete listing?'),
        content: Text('"${item.title}" will be permanently removed.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete',
                style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ItemService.instance.deleteItem(item.itemID);
    if (!context.mounted) return;
    Navigator.pop(context); // back to the board
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Listing deleted.')));
  }

  @override
  Widget build(BuildContext context) {
    // Only the poster (or an admin) can edit/delete this listing.
    final canModify = AuthService.instance.canModify(item.posterID);
    // Build the combined media list: photos first, then videos.
    final media = <Widget>[
      for (final img in item.images) ItemImage(source: img),
      for (final _ in item.videos)
        Container(
          color: Colors.black87,
          alignment: Alignment.center,
          child: const Icon(Icons.play_circle_fill_rounded,
              color: Colors.white, size: 64),
        ),
    ];
    return Scaffold(
      backgroundColor: AppColors.neutralLight,
      appBar: AppBar(
        title: const Text('Listing'),
        actions: [
          if (canModify) ...[
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      ItemFormScreen(type: item.postType, existing: item),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Delete',
              onPressed: () => _confirmDelete(context),
            ),
          ],
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.card),
            child: AspectRatio(
              aspectRatio: 1.3,
              child: media.isEmpty
                  ? ItemImage(
                      source: null,
                      fallbackIcon: _isMarket
                          ? Icons.shopping_bag_outlined
                          : Icons.help_outline_rounded,
                    )
                  : Stack(
                      children: [
                        PageView(
                          controller: _pageController,
                          onPageChanged: (i) => setState(() => _page = i),
                          children: media,
                        ),
                        if (media.length > 1)
                          Positioned(
                            bottom: 10,
                            left: 0,
                            right: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                media.length,
                                (i) => AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 3),
                                  width: i == _page ? 18 : 7,
                                  height: 7,
                                  decoration: BoxDecoration(
                                    color: i == _page
                                        ? Colors.white
                                        : Colors.white60,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        Positioned(
                          top: 10,
                          right: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.collections,
                                    size: 14, color: Colors.white),
                                const SizedBox(width: 4),
                                Text('${_page + 1}/${media.length}',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            item.title,
            style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: AppColors.textDark),
          ),
          const SizedBox(height: 6),
          Text(
            _isMarket && item.price != null
                ? '₱${item.price!.toStringAsFixed(0)}'
                : 'Lost & Found',
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.primary),
          ),
          if (_isMarket) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: AppColors.surfaceTint.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(item.category.icon,
                        size: 16, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Text(item.category.label,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: AppColors.primary)),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 18),
          _posterRow(),
          const SizedBox(height: 20),
          Text('Description',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark)),
          const SizedBox(height: 8),
          Text(
            item.description.isEmpty
                ? 'No description provided.'
                : item.description,
            style: TextStyle(color: AppColors.textMuted, height: 1.6),
          ),
          const SizedBox(height: 30),
          PillButton(
            label: _isMarket ? 'Message Seller' : 'Message Finder',
            icon: Icons.chat_bubble_outline,
            onPressed: _messageSeller,
          ),
        ],
      ),
    );
  }
}
