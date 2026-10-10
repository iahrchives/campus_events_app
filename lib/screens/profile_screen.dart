import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/auth_service.dart';
import '../theme/theme.dart';
import '../widgets/soft_card.dart';
import '../widgets/user_avatar.dart';

/// Screen 6 — user summary with avatar, detail blocks (editable username) and
/// a "Previous Events" history list.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Future<void> _changePhoto() async {
    final hasPhoto = AuthService.instance.currentUser?.photoURL != null;
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.neutralLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined,
                  color: AppColors.primary),
              title: Text('Choose from gallery',
                  style: TextStyle(color: AppColors.textDark)),
              onTap: () => Navigator.pop(ctx, 'gallery'),
            ),
            ListTile(
              leading:
                  const Icon(Icons.photo_camera_outlined, color: AppColors.primary),
              title: Text('Take a photo',
                  style: TextStyle(color: AppColors.textDark)),
              onTap: () => Navigator.pop(ctx, 'camera'),
            ),
            if (hasPhoto)
              ListTile(
                leading: const Icon(Icons.delete_outline,
                    color: AppColors.danger),
                title: const Text('Remove photo',
                    style: TextStyle(color: AppColors.danger)),
                onTap: () => Navigator.pop(ctx, 'remove'),
              ),
          ],
        ),
      ),
    );
    if (action == null) return;
    if (action == 'remove') {
      AuthService.instance.updatePhoto(null);
      if (mounted) setState(() {});
      return;
    }
    try {
      final picked = await ImagePicker().pickImage(
          source:
              action == 'camera' ? ImageSource.camera : ImageSource.gallery);
      if (picked != null) {
        AuthService.instance.updatePhoto(picked.path);
        if (mounted) setState(() {});
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Could not open the camera/gallery on this device.')));
    }
  }

  Future<void> _editUsername() async {
    final user = AuthService.instance.currentUser;

    // Enforce the 24-hour cooldown before opening the editor.
    if (user != null && !user.canChangeUsername) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            'You can change your username again in '
            '${AuthService.formatCooldown(user.usernameCooldownRemaining)}.'),
      ));
      return;
    }

    final controller = TextEditingController(text: user?.handle ?? '');
    final formKey = GlobalKey<FormState>();

    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Edit Username'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: controller,
                autofocus: true,
                decoration: const InputDecoration(
                  prefixText: '@',
                  hintText: 'username',
                ),
                validator: (v) {
                  final t = v?.trim() ?? '';
                  if (t.isEmpty) return 'Username cannot be empty';
                  if (t.length < 3) return 'At least 3 characters';
                  if (t.contains(' ')) return 'No spaces allowed';
                  return null;
                },
              ),
              const SizedBox(height: 10),
              Text(
                'You can only change your username once every 24 hours.',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(ctx, controller.text.trim());
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty) {
      try {
        AuthService.instance.updateUsername(newName);
        if (!mounted) return;
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Username updated. Next change available in 24h.')));
      } on AuthException catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.currentUser;
    const previous = [
      'Freshmen Orientation Week',
      'Coding Bootcamp 101',
      'Cultural Night 2025',
    ];

    return Scaffold(
      backgroundColor: AppColors.neutralLight,
      appBar: AppBar(title: const Text('My Profile')),
      body: ListView(
        padding: const EdgeInsets.all(22),
        children: [
          const SizedBox(height: 8),
          Center(
            child: GestureDetector(
              onTap: _changePhoto,
              child: Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border:
                          Border.all(color: AppColors.secondary, width: 3),
                    ),
                    child: UserAvatar(photoURL: user?.photoURL, radius: 56),
                  ),
                  Positioned(
                    right: 2,
                    bottom: 2,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.camera_alt,
                          size: 18, color: AppColors.onAccent),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Center(
            child: TextButton.icon(
              onPressed: _changePhoto,
              icon: const Icon(Icons.edit_outlined, size: 16),
              label: const Text('Change photo'),
            ),
          ),
          const SizedBox(height: 24),
          _readOnlyBlock('Name', user?.fullName ?? 'Maria Santos'),
          const SizedBox(height: 14),
          _readOnlyBlock(
            'Username',
            '@${user?.handle ?? 'maria'}',
            onEdit: _editUsername,
          ),
          if (user != null && !user.canChangeUsername)
            Padding(
              padding: const EdgeInsets.only(left: 6, top: 6),
              child: Row(
                children: [
                  Icon(Icons.lock_clock_outlined,
                      size: 14, color: AppColors.textMuted),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Username locked — changeable again in '
                      '${AuthService.formatCooldown(user.usernameCooldownRemaining)}.',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.textMuted),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 28),
          Text('Previous Events',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark)),
          const SizedBox(height: 12),
          ...previous.map((title) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SoftCard(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Container(
                        height: 54,
                        width: 54,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceTint,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.event,
                            color: AppColors.primary),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(title,
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textDark)),
                      ),
                      TextButton(
                          onPressed: () {}, child: const Text('Find More')),
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }

  Widget _readOnlyBlock(String label, String value, {VoidCallback? onEdit}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 6, bottom: 6),
          child: Text(label,
              style: TextStyle(
                  fontWeight: FontWeight.w700, color: AppColors.textMuted)),
        ),
        SoftCard(
          padding: EdgeInsets.fromLTRB(20, onEdit == null ? 18 : 8, 8, onEdit == null ? 18 : 8),
          child: Row(
            children: [
              Expanded(
                child: Text(value,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark)),
              ),
              if (onEdit != null)
                IconButton(
                  icon: const Icon(Icons.edit_outlined,
                      color: AppColors.primary),
                  tooltip: 'Edit username',
                  onPressed: onEdit,
                ),
            ],
          ),
        ),
      ],
    );
  }
}
