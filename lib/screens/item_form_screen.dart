import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/item.dart';
import '../services/auth_service.dart';
import '../services/item_service.dart';
import '../theme/theme.dart';
import '../widgets/item_image.dart';
import '../widgets/pill_button.dart';
import '../widgets/rounded_text_field.dart';

/// Create or edit a Marketplace / Lost & Found listing (with a photo).
///
/// Pass [existing] to edit; leave null to create a new item of [type].
class ItemFormScreen extends StatefulWidget {
  final PostType type;
  final MarketItem? existing;

  const ItemFormScreen({super.key, required this.type, this.existing});

  @override
  State<ItemFormScreen> createState() => _ItemFormScreenState();
}

class _ItemFormScreenState extends State<ItemFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _description;
  late final TextEditingController _price;

  final List<String> _images = [];
  final List<String> _videos = [];
  late ItemCategory _category;
  bool _saving = false;

  bool get _isEdit => widget.existing != null;
  bool get _isMarket => widget.type == PostType.marketplace;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _title = TextEditingController(text: e?.title ?? '');
    _description = TextEditingController(text: e?.description ?? '');
    _price = TextEditingController(
        text: e?.price != null ? e!.price!.toStringAsFixed(0) : '');
    if (e != null) {
      _images.addAll(e.images);
      _videos.addAll(e.videos);
    }
    _category = e?.category ??
        (widget.type == PostType.marketplace
            ? ItemCategory.food
            : ItemCategory.other);
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _price.dispose();
    super.dispose();
  }

  Future<void> _addPhotos() async {
    final remaining = MarketItem.maxPhotos - _images.length;
    if (remaining <= 0) {
      _limitMsg('You can attach up to ${MarketItem.maxPhotos} photos.');
      return;
    }
    try {
      final picked = await ImagePicker().pickMultiImage();
      if (picked.isEmpty) return;
      final paths = picked.map((x) => x.path).toList();
      setState(() {
        _images.addAll(paths.take(remaining));
      });
      if (paths.length > remaining) {
        _limitMsg(
            'Only ${MarketItem.maxPhotos} photos allowed — extras were skipped.');
      }
    } catch (_) {
      _pickError();
    }
  }

  Future<void> _addVideo() async {
    if (_videos.length >= MarketItem.maxVideos) {
      _limitMsg('You can attach up to ${MarketItem.maxVideos} videos.');
      return;
    }
    try {
      final picked =
          await ImagePicker().pickVideo(source: ImageSource.gallery);
      if (picked != null) setState(() => _videos.add(picked.path));
    } catch (_) {
      _pickError();
    }
  }

  void _limitMsg(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  void _pickError() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Could not open the gallery on this device.')));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final price = _isMarket ? double.tryParse(_price.text.trim()) : null;
    final uid = AuthService.instance.currentUser?.uid ?? 'me';

    if (_isEdit) {
      await ItemService.instance.updateItem(
        widget.existing!.copyWith(
          title: _title.text.trim(),
          description: _description.text.trim(),
          price: price,
          clearPrice: !_isMarket,
          images: List.of(_images),
          videos: List.of(_videos),
          category: _category,
        ),
      );
    } else {
      await ItemService.instance.addItem(
        MarketItem(
          itemID: 'item_${DateTime.now().millisecondsSinceEpoch}',
          title: _title.text.trim(),
          description: _description.text.trim(),
          price: price,
          postType: widget.type,
          posterID: uid,
          images: List.of(_images),
          videos: List.of(_videos),
          category: _category,
        ),
      );
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_isEdit ? 'Listing updated.' : 'Listing posted.')));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final title = _isEdit
        ? 'Edit Listing'
        : (_isMarket ? 'Sell an Item' : 'Report Lost & Found');
    return Scaffold(
      backgroundColor: AppColors.neutralLight,
      appBar: AppBar(title: Text(title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _mediaSection(),
              const SizedBox(height: 20),
              RoundedTextField(
                controller: _title,
                hint: 'Title',
                icon: Icons.title,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Enter a title' : null,
              ),
              const SizedBox(height: 16),
              RoundedTextField(
                controller: _description,
                hint: 'Description',
                icon: Icons.notes,
                maxLines: 4,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Enter a description'
                    : null,
              ),
              if (_isMarket) ...[
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Category',
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDark)),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ItemCategory.values.map((c) {
                    final selected = c == _category;
                    return ChoiceChip(
                      selected: selected,
                      onSelected: (_) => setState(() => _category = c),
                      avatar: Icon(c.icon,
                          size: 18,
                          color: selected
                              ? AppColors.onAccent
                              : AppColors.primary),
                      label: Text(c.label),
                      labelStyle: TextStyle(
                        color: selected
                            ? AppColors.onAccent
                            : AppColors.textDark,
                        fontWeight: FontWeight.w600,
                      ),
                      selectedColor: AppColors.primary,
                      backgroundColor: AppColors.surfaceTint.withValues(alpha: 0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadii.pill),
                        side: BorderSide(
                            color: AppColors.surfaceTint, width: 1.5),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                RoundedTextField(
                  controller: _price,
                  hint: 'Price (₱)',
                  icon: Icons.sell_outlined,
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Enter a price';
                    if (double.tryParse(v.trim()) == null) {
                      return 'Enter a valid number';
                    }
                    return null;
                  },
                ),
              ],
              const SizedBox(height: 30),
              PillButton(
                label: _isEdit ? 'Save Changes' : 'Post Listing',
                loading: _saving,
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _mediaSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Photos',
                style: TextStyle(
                    fontWeight: FontWeight.w800, color: AppColors.textDark)),
            const SizedBox(width: 6),
            Text('(${_images.length}/${MarketItem.maxPhotos})',
                style: TextStyle(
                    fontSize: 12.5, color: AppColors.textMuted)),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _images.length + 1,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              if (i == _images.length) return _addTile(_addPhotos);
              return _thumb(
                child: ItemImage(source: _images[i]),
                onRemove: () => setState(() => _images.removeAt(i)),
              );
            },
          ),
        ),
        if (_isMarket) ...[
          const SizedBox(height: 18),
          Row(
            children: [
              Text('Videos',
                  style: TextStyle(
                      fontWeight: FontWeight.w800, color: AppColors.textDark)),
              const SizedBox(width: 6),
              Text('(${_videos.length}/${MarketItem.maxVideos})',
                  style: TextStyle(
                      fontSize: 12.5, color: AppColors.textMuted)),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _videos.length + 1,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, i) {
                if (i == _videos.length) {
                  return _addTile(_addVideo, icon: Icons.video_call_outlined);
                }
                return _thumb(
                  child: Container(
                    color: Colors.black87,
                    alignment: Alignment.center,
                    child: const Icon(Icons.play_circle_fill_rounded,
                        color: Colors.white, size: 34),
                  ),
                  onRemove: () => setState(() => _videos.removeAt(i)),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _addTile(VoidCallback onTap, {IconData icon = Icons.add_a_photo_outlined}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.surfaceTint, width: 2),
        ),
        child: Icon(icon, color: AppColors.secondary, size: 30),
      ),
    );
  }

  Widget _thumb({required Widget child, required VoidCallback onRemove}) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(width: 100, height: 100, child: child),
        ),
        Positioned(
          top: 2,
          right: 2,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                  color: Colors.black54, shape: BoxShape.circle),
              child: const Icon(Icons.close, color: Colors.white, size: 16),
            ),
          ),
        ),
      ],
    );
  }
}
