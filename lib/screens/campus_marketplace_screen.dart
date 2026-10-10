import 'package:flutter/material.dart';

import '../models/item.dart';
import '../widgets/item_board_view.dart';

/// Screen 8 — Campus Marketplace (postType == 'marketplace').
class CampusMarketplaceScreen extends StatelessWidget {
  const CampusMarketplaceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ItemBoardView(
      type: PostType.marketplace,
      title: 'Campus Marketplace',
    );
  }
}
