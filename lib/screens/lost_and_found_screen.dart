import 'package:flutter/material.dart';

import '../models/item.dart';
import '../widgets/item_board_view.dart';

/// Screen 9 — Lost & Found (postType == 'lost_found').
class LostAndFoundScreen extends StatelessWidget {
  const LostAndFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ItemBoardView(
      type: PostType.lostFound,
      title: 'Lost & Found',
    );
  }
}
