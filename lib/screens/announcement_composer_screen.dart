import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/announcement_service.dart';
import '../services/auth_service.dart';
import '../theme/theme.dart';
import '../widgets/forum_widgets.dart';
import '../widgets/pill_button.dart';
import '../widgets/rounded_text_field.dart';

/// Rich composer for announcements. Admins publish directly; regular users
/// submit a request for an admin to approve. Supports a photo or video
/// attachment and auto-detects links / emoji typed into the message.
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
            ? 'Announcement posted.'
            : 'Request sent to admins for approval.')));
  }

  @override
  Widget build(BuildContext context) {
    final hasMedia = _imagePath != null || _videoPath != null;
    return Scaffold(
      backgroundColor: AppColors.neutralLight,
      appBar: AppBar(
        title: Text(widget.isAdmin
            ? 'Post Announcement'
            : 'Request Announcement'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
                  Expanded(child: _attachBtn('Photo', Icons.photo_outlined, _pickImage)),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _attachBtn(
                          'Video', Icons.videocam_outlined, _pickVideo)),
                ],
              ),
              const SizedBox(height: 26),
              PillButton(
                label: widget.isAdmin ? 'Publish' : 'Send Request',
                loading: _busy,
                onPressed: _submit,
              ),
            ],
          ),
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
