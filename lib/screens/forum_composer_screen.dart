import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/auth_service.dart';
import '../services/forum_service.dart';
import '../theme/theme.dart';
import '../widgets/forum_widgets.dart';
import '../widgets/pill_button.dart';

/// Facebook-style "Create Post" composer with optional photo / video.
class ForumComposerScreen extends StatefulWidget {
  const ForumComposerScreen({super.key});

  @override
  State<ForumComposerScreen> createState() => _ForumComposerScreenState();
}

class _ForumComposerScreenState extends State<ForumComposerScreen> {
  final _body = TextEditingController();
  String? _imagePath;
  String? _videoPath;
  bool _posting = false;

  @override
  void dispose() {
    _body.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final picked =
          await ImagePicker().pickImage(source: ImageSource.gallery);
      if (picked != null) {
        setState(() {
          _imagePath = picked.path;
          _videoPath = null; // one attachment at a time
        });
      }
    } catch (_) {
      _attachError();
    }
  }

  Future<void> _pickVideo() async {
    try {
      final picked =
          await ImagePicker().pickVideo(source: ImageSource.gallery);
      if (picked != null) {
        setState(() {
          _videoPath = picked.path;
          _imagePath = null;
        });
      }
    } catch (_) {
      _attachError();
    }
  }

  void _attachError() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Could not open the gallery on this device.')));
  }

  /// Inserts a '#' at the cursor (with a leading space if needed) and focuses
  /// the field so the student can type the tag straight away.
  void _insertHashtag() {
    final text = _body.text;
    final sel = _body.selection;
    final pos = sel.isValid ? sel.start : text.length;
    final needsSpace = pos > 0 && text[pos - 1] != ' ' && text[pos - 1] != '\n';
    final insert = needsSpace ? ' #' : '#';
    final newText = text.replaceRange(pos, sel.isValid ? sel.end : pos, insert);
    _body.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: pos + insert.length),
    );
    setState(() {});
  }

  Future<void> _post() async {
    final text = _body.text.trim();
    if (text.isEmpty && _imagePath == null && _videoPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Write something or attach a photo/video.')));
      return;
    }
    setState(() => _posting = true);
    final user = AuthService.instance.currentUser;
    await ForumService.instance.addPost(
      author: user?.fullName ?? 'You',
      authorId: user?.uid ?? '',
      body: text,
      imageURL: _imagePath,
      videoURL: _videoPath,
    );
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Post shared!')));
  }

  @override
  Widget build(BuildContext context) {
    final hasMedia = _imagePath != null || _videoPath != null;
    return Scaffold(
      backgroundColor: AppColors.neutralLight,
      appBar: AppBar(title: const Text('Create Post')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _body,
              autofocus: true,
              minLines: 4,
              maxLines: 10,
              decoration: const InputDecoration(
                hintText: 'What\u2019s on your mind? Use #hashtags to tag topics.',
              ),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: ActionChip(
                avatar: const Icon(Icons.tag, size: 18, color: AppColors.primary),
                label: const Text('Add hashtag'),
                labelStyle: TextStyle(
                    color: AppColors.primary, fontWeight: FontWeight.w700),
                backgroundColor: AppColors.surfaceTint.withValues(alpha: 0.5),
                shape: StadiumBorder(
                    side: BorderSide(color: AppColors.surfaceTint, width: 1.5)),
                onPressed: _insertHashtag,
              ),
            ),
            const SizedBox(height: 16),
            if (hasMedia) ...[
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
              const SizedBox(height: 16),
            ],
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.photo_outlined),
                    label: const Text('Photo'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: BorderSide(
                          color: AppColors.surfaceTint, width: 2),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppRadii.field)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickVideo,
                    icon: const Icon(Icons.videocam_outlined),
                    label: const Text('Video'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: BorderSide(
                          color: AppColors.surfaceTint, width: 2),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppRadii.field)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 26),
            PillButton(label: 'Post', loading: _posting, onPressed: _post),
          ],
        ),
      ),
    );
  }
}
