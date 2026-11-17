import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/announcement.dart';
import '../services/announcement_service.dart';
import '../services/auth_service.dart';
import '../theme/theme.dart';
import '../widgets/forum_widgets.dart';
import '../widgets/pill_button.dart';
import '../widgets/rounded_text_field.dart';

/// Rich composer for announcements. Admins publish directly (including urgent
/// broadcasts & emergency overlays); regular users submit a request for an
/// admin to approve.
class AnnouncementComposerScreen extends StatefulWidget {
  final bool isAdmin;

  const AnnouncementComposerScreen({super.key, required this.isAdmin});

  @override
  State<AnnouncementComposerScreen> createState() =>
      _AnnouncementComposerScreenState();
}

class _AnnouncementComposerScreenState
    extends State<AnnouncementComposerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _body = TextEditingController();
  String? _imagePath;
  String? _videoPath;
  bool _busy = false;

  AnnouncementPriority _priority = AnnouncementPriority.normal;
  String _category = 'General';

  static const List<String> _adminCategories = [
    'General',
    'Class Suspension',
    'Room Change',
    'Emergency Alert',
    'Facility Advisory',
  ];

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final x = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (x != null) {
        setState(() {
          _imagePath = x.path;
          _videoPath = null;
        });
      }
    } catch (_) {
      _err();
    }
  }

  Future<void> _pickVideo() async {
    try {
      final x = await ImagePicker().pickVideo(source: ImageSource.gallery);
      if (x != null) {
        setState(() {
          _videoPath = x.path;
          _imagePath = null;
        });
      }
    } catch (_) {
      _err();
    }
  }

  void _err() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Could not open the gallery on this device.')));
  }

  void _applyUrgentTemplate({
    required String category,
    required String title,
    required String body,
    required AnnouncementPriority priority,
  }) {
    setState(() {
      _category = category;
      _title.text = title;
      _body.text = body;
      _priority = priority;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    final user = AuthService.instance.currentUser;
    if (widget.isAdmin) {
      await AnnouncementService.instance.postAnnouncement(
        title: _title.text.trim(),
        body: _body.text.trim(),
        authorId: user?.uid ?? 'uid_admin',
        authorName: user?.fullName ?? 'Campus Admin',
        priority: _priority,
        category: _category,
        imageURL: _imagePath,
        videoURL: _videoPath,
      );
    } else {
      await AnnouncementService.instance.submitRequest(
        requesterId: user?.uid ?? 'me',
        requesterName: user?.fullName ?? 'Student',
        title: _title.text.trim(),
        body: _body.text.trim(),
        imageURL: _imagePath,
        videoURL: _videoPath,
      );
    }
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(widget.isAdmin
            ? (_priority == AnnouncementPriority.emergency
            ? 'Emergency alert published across all active screens!'
            : 'Campus-wide announcement posted.')
            : 'Request sent to admins for approval.')));
  }

  @override
  Widget build(BuildContext context) {
    final hasMedia = _imagePath != null || _videoPath != null;
    return Scaffold(
      backgroundColor: AppColors.neutralLight,
      appBar: AppBar(
        title: Text(widget.isAdmin
            ? 'Post Campus Broadcast'
            : 'Request Announcement'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.isAdmin) ...[
                Text(
                  'QUICK URGENT BROADCAST TEMPLATES',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ActionChip(
                      avatar: const Icon(Icons.warning_amber_rounded,
                          size: 16, color: AppColors.danger),
                      label: const Text('Class Suspension'),
                      onPressed: () => _applyUrgentTemplate(
                        category: 'Class Suspension',
                        title: 'URGENT: Campus Classes Suspended Today',
                        body:
                        'All on-site classes are suspended effective immediately due to inclement weather. Please stay safe and monitor official advisories.',
                        priority: AnnouncementPriority.emergency,
                      ),
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.meeting_room_outlined,
                          size: 16, color: Colors.deepOrange),
                      label: const Text('Room Change'),
                      onPressed: () => _applyUrgentTemplate(
                        category: 'Room Change',
                        title: 'Room Reassignment Notice',
                        body:
                        'Please be advised that scheduled classes in Room 304 have been moved to Room 201 today.',
                        priority: AnnouncementPriority.urgent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'BROADCAST PRIORITY & DISPLAY',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 8),
                _priorityCard(
                  value: AnnouncementPriority.normal,
                  title: 'Normal Announcement',
                  subtitle: 'Appears on the Announcements board & dashboard.',
                  icon: Icons.campaign_outlined,
                  accent: AppColors.primary,
                ),
                const SizedBox(height: 8),
                _priorityCard(
                  value: AnnouncementPriority.urgent,
                  title: 'Urgent Broadcast',
                  subtitle:
                  'Highlighted as Urgent + notifies all students immediately.',
                  icon: Icons.notification_important_rounded,
                  accent: Colors.deepOrange,
                ),
                const SizedBox(height: 8),
                _priorityCard(
                  value: AnnouncementPriority.emergency,
                  title: 'High-Priority Emergency Banner',
                  subtitle:
                  'Pins a persistent red banner across the top of all active screens until dismissed.',
                  icon: Icons.emergency_share_rounded,
                  accent: AppColors.danger,
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: _category,
                  decoration: InputDecoration(
                    labelText: 'Broadcast Category',
                    prefixIcon: const Icon(Icons.label_outline),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadii.field),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: _adminCategories
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _category = v);
                  },
                ),
                const SizedBox(height: 16),
              ],
              RoundedTextField(
                controller: _title,
                hint: 'Title',
                icon: Icons.title,
                validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Enter a title' : null,
              ),
              const SizedBox(height: 14),
              RoundedTextField(
                controller: _body,
                hint: 'Write your message… emoji 🎉 and links are supported',
                icon: Icons.notes,
                maxLines: 7,
                validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Enter a message' : null,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.link, size: 16, color: AppColors.textMuted),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Links you paste (https://…) become tappable automatically.',
                      style:
                      TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                  ),
                ],
              ),
              if (hasMedia) ...[
                const SizedBox(height: 16),
                Stack(
                  alignment: Alignment.topRight,
                  children: [
                    ForumMedia(imageURL: _imagePath, videoURL: _videoPath),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: CircleAvatar(
                        backgroundColor: Colors.black54,
                        child: IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => setState(() {
                            _imagePath = null;
                            _videoPath = null;
                          }),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                      child:
                      _attachBtn('Photo', Icons.photo_outlined, _pickImage)),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _attachBtn(
                          'Video', Icons.videocam_outlined, _pickVideo)),
                ],
              ),
              const SizedBox(height: 26),
              PillButton(
                label: widget.isAdmin
                    ? (_priority == AnnouncementPriority.emergency
                    ? 'Broadcast Emergency Alert'
                    : 'Publish Broadcast')
                    : 'Send Request',
                loading: _busy,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _priorityCard({
    required AnnouncementPriority value,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accent,
  }) {
    final selected = _priority == value;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => setState(() => _priority = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? accent.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? accent
                : AppColors.surfaceTint.withValues(alpha: 0.4),
            width: selected ? 1.8 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: accent, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: selected ? accent : AppColors.textMuted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _attachBtn(String label, IconData icon, VoidCallback onTap) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: BorderSide(color: AppColors.surfaceTint, width: 2),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.field)),
      ),
    );
  }
}