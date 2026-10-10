import 'dart:async';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/campus_floors.dart';
import '../models/event.dart';
import '../services/auth_service.dart';
import '../services/event_service.dart';
import '../theme/theme.dart';
import '../widgets/item_image.dart';
import '../widgets/pill_button.dart';
import '../widgets/rounded_text_field.dart';

/// Event creation form with LLD 15-minute booking timeout.
///
/// Admins publish the event directly. Regular (verified) users instead submit
/// an event *request* for an admin to approve — and skip the slot countdown.
///
/// • Path A — publish before 00:00 → save event and pop safely.
/// • Path B — timer hits 00:00 → dialog, wipe caches, force-pop to dashboard.
class EventCreationFormScreen extends StatefulWidget {
  /// When true the form publishes directly; otherwise it submits a request.
  final bool isAdmin;

  const EventCreationFormScreen({super.key, this.isAdmin = false});

  @override
  State<EventCreationFormScreen> createState() =>
      _EventCreationFormScreenState();
}

class _EventCreationFormScreenState extends State<EventCreationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _date = TextEditingController();
  final _time = TextEditingController();

  late String _floor = CampusFloors.names.first;
  String? _venue;
  String? _imagePath;

  static const int _totalSeconds = 15 * 60;
  int _remaining = _totalSeconds;
  Timer? _timer;
  bool _saving = false;
  bool _timedOut = false;

  /// The slot countdown only applies when an admin is reserving a real slot.
  bool get _useTimer => widget.isAdmin;

  @override
  void initState() {
    super.initState();
    if (_useTimer) _startCountdown();
  }

  Future<void> _pickImage() async {
    try {
      final x = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (x != null) setState(() => _imagePath = x.path);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Could not open the gallery on this device.')));
    }
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_remaining <= 1) {
        t.cancel();
        _onTimeout();
      } else {
        setState(() => _remaining--);
      }
    });
  }

  void _onTimeout() {
    if (!mounted || _timedOut) return;
    _timedOut = true;

    // Wipe all temporary form caches.
    for (final c in [_title, _description, _date, _time]) {
      c.clear();
    }
    _venue = null;
    _floor = CampusFloors.names.first;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.card)),
        title: const Text('Session Timed Out'),
        content: const Text(
          'Session Timed Out. Your event draft has been cleared to open the '
          'slot for others.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx); // close dialog
              Navigator.pop(context); // force-pop back to the dashboard shell
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _publish() async {
    if (_timedOut) return;
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final user = AuthService.instance.currentUser;
    if (widget.isAdmin) {
      await EventService.instance.addEvent(CampusEvent(
        id: 'local_${DateTime.now().millisecondsSinceEpoch}',
        title: _title.text.trim(),
        description: _description.text.trim(),
        venue: _venue ?? '',
        date: _date.text.trim(),
        time: _time.text.trim(),
        organizerID: user?.uid ?? 'unknown',
        imageURL: _imagePath,
      ));
    } else {
      await EventService.instance.submitRequest(EventRequest(
        id: 'er_${DateTime.now().millisecondsSinceEpoch}',
        requesterId: user?.uid ?? 'me',
        requesterName: user?.fullName ?? 'Student',
        title: _title.text.trim(),
        description: _description.text.trim(),
        venue: _venue ?? '',
        date: _date.text.trim(),
        time: _time.text.trim(),
        imageURL: _imagePath,
      ));
    }

    _timer?.cancel();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(widget.isAdmin
            ? 'Event published!'
            : 'Request sent to admins for approval.')));
    Navigator.pop(context); // pop the route back safely
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in [_title, _description, _date, _time]) {
      c.dispose();
    }
    super.dispose();
  }

  String get _formatted {
    final m = (_remaining ~/ 60).toString().padLeft(2, '0');
    final s = (_remaining % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final warning = _remaining <= 60;
    return Scaffold(
      backgroundColor: AppColors.neutralLight,
      appBar: AppBar(
          title: Text(widget.isAdmin ? 'Create Event' : 'Request Event')),
      body: Column(
        children: [
          // Bold countdown banner (admin slot reservation only).
          if (_useTimer)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              color: warning ? AppColors.danger : AppColors.primary,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.timer_outlined, color: Colors.white),
                  const SizedBox(width: 10),
                  Text(
                    'Slot reserved · $_formatted',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1),
                  ),
                ],
              ),
            ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(22),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _photoPicker(),
                    const SizedBox(height: 20),
                    _label('Event Title'),
                    RoundedTextField(
                      controller: _title,
                      hint: 'e.g. Robotics Workshop',
                      icon: Icons.title,
                      validator: _required,
                    ),
                    const SizedBox(height: 16),
                    _label('Description'),
                    RoundedTextField(
                      controller: _description,
                      hint: 'What is this event about?',
                      icon: Icons.notes,
                      maxLines: 3,
                      validator: _required,
                    ),
                    const SizedBox(height: 16),
                    _label('Date'),
                    RoundedTextField(
                      controller: _date,
                      hint: 'e.g. Jun 30, 2026',
                      icon: Icons.calendar_today_outlined,
                      validator: _required,
                    ),
                    const SizedBox(height: 16),
                    _label('Time'),
                    RoundedTextField(
                      controller: _time,
                      hint: 'e.g. 2:00 PM',
                      icon: Icons.access_time,
                      validator: _required,
                    ),
                    const SizedBox(height: 16),
                    _label('Floor'),
                    _dropdown<String>(
                      value: _floor,
                      icon: Icons.layers_outlined,
                      items: CampusFloors.names,
                      itemLabel: (f) => f,
                      onChanged: (v) => setState(() {
                        _floor = v ?? _floor;
                        _venue = null; // reset venue when floor changes
                      }),
                    ),
                    const SizedBox(height: 16),
                    _label('Venue'),
                    _dropdown<String>(
                      value: _venue,
                      hint: 'Select a venue on this floor',
                      icon: Icons.place_outlined,
                      items: CampusFloors.venuesOf(_floor),
                      itemLabel: (v) => v,
                      onChanged: (v) => setState(() => _venue = v),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Select a venue' : null,
                    ),
                    const SizedBox(height: 28),
                    PillButton(
                      label: widget.isAdmin
                          ? 'Publish Event'
                          : 'Send Event Request',
                      loading: _saving,
                      onPressed: _publish,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _photoPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Event Photo (theme / poster)'),
        GestureDetector(
          onTap: _pickImage,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.card),
            child: SizedBox(
              height: 160,
              width: double.infinity,
              child: _imagePath == null
                  ? Container(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceTint.withValues(alpha: 0.5),
                        border:
                            Border.all(color: AppColors.surfaceTint, width: 2),
                        borderRadius: BorderRadius.circular(AppRadii.card),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.add_photo_alternate_outlined,
                              size: 38, color: AppColors.primary),
                          const SizedBox(height: 6),
                          Text('Tap to add an event photo',
                              style: TextStyle(
                                  fontSize: 12.5, color: AppColors.textMuted)),
                        ],
                      ),
                    )
                  : Stack(
                      fit: StackFit.expand,
                      children: [
                        ItemImage(source: _imagePath, fallbackIcon: Icons.event),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: CircleAvatar(
                            backgroundColor: Colors.black54,
                            radius: 18,
                            child: IconButton(
                              icon: const Icon(Icons.close,
                                  color: Colors.white, size: 18),
                              onPressed: () =>
                                  setState(() => _imagePath = null),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _dropdown<T>({
    required T? value,
    String? hint,
    required IconData icon,
    required List<T> items,
    required String Function(T) itemLabel,
    required ValueChanged<T?> onChanged,
    String? Function(T?)? validator,
  }) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      isExpanded: true,
      icon: const Icon(Icons.keyboard_arrow_down_rounded,
          color: AppColors.primary),
      hint: hint == null ? null : Text(hint),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: AppColors.secondary),
      ),
      dropdownColor: AppColors.neutralLight,
      borderRadius: BorderRadius.circular(AppRadii.field),
      style: TextStyle(
          color: AppColors.textDark, fontWeight: FontWeight.w600),
      items: items
          .map((it) =>
              DropdownMenuItem<T>(value: it, child: Text(itemLabel(it))))
          .toList(),
      onChanged: onChanged,
      validator: validator,
    );
  }

  Widget _label(String t) => Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.only(left: 6, bottom: 6),
          child: Text(t,
              style: TextStyle(
                  fontWeight: FontWeight.w700, color: AppColors.textDark)),
        ),
      );

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Required' : null;
}
