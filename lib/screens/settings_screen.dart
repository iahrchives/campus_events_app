import 'package:flutter/material.dart';

import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../services/settings_controller.dart';
import '../theme/theme.dart';
import '../widgets/soft_card.dart';
import 'account_verification_screen.dart';

/// App Settings — typical preferences incl. a working dark-mode toggle.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _s = SettingsController.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutralLight,
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          _section('Appearance'),
          _switchTile(
            icon: Icons.dark_mode_outlined,
            title: 'Dark Mode',
            subtitle: 'Switch between light and dark themes',
            value: _s.darkMode,
            onChanged: (v) => setState(() => _s.setDarkMode(v)),
          ),
          _switchTile(
            icon: Icons.view_agenda_outlined,
            title: 'Compact Feed',
            subtitle: 'Show more posts with tighter spacing',
            value: _s.compactFeed,
            onChanged: (v) => setState(() => _s.setCompactFeed(v)),
          ),
          const SizedBox(height: 18),
          _section('Notifications'),
          _switchTile(
            icon: Icons.notifications_outlined,
            title: 'Push Notifications',
            subtitle: 'Announcements, replies and reactions',
            value: _s.notifications,
            onChanged: (v) => setState(() => _s.setNotifications(v)),
          ),
          _switchTile(
            icon: Icons.event_available_outlined,
            title: 'Event Reminders',
            subtitle: 'Get reminded before events you joined',
            value: _s.eventReminders,
            onChanged: (v) => setState(() => _s.setEventReminders(v)),
          ),
          const SizedBox(height: 18),
          _section('General'),
          _navTile(
            icon: Icons.language_outlined,
            title: 'Language',
            trailing: _s.language,
            onTap: _pickLanguage,
          ),
          _navTile(
            icon: Icons.lock_outline,
            title: 'Privacy',
            onTap: () => _info('Privacy controls coming soon.'),
          ),
          _navTile(
            icon: Icons.info_outline,
            title: 'About',
            onTap: _showAbout,
          ),
          if (!AuthService.instance.isAdmin) ...[
            const SizedBox(height: 18),
            _section('Account'),
            _navTile(
              icon: Icons.verified_user_outlined,
              title: 'Verify Account',
              trailing: _verifyTrailing(),
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const AccountVerificationScreen()),
                );
                if (mounted) setState(() {});
              },
            ),
          ],
        ],
      ),
    );
  }

  String _verifyTrailing() {
    final status =
        AuthService.instance.currentUser?.verifyStatus ?? VerifyStatus.none;
    return status.label;
  }

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.only(left: 6, bottom: 8, top: 4),
        child: Text(title.toUpperCase(),
            style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 12.5,
                letterSpacing: 0.6,
                color: AppColors.primary)),
      );

  Widget _switchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SoftCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark)),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 12, color: AppColors.textMuted)),
                ],
              ),
            ),
            Switch(
              value: value,
              activeThumbColor: AppColors.primary,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }

  Widget _navTile({
    required IconData icon,
    required String title,
    String? trailing,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SoftCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        onTap: onTap,
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(width: 14),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Text(title,
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark)),
              ),
            ),
            if (trailing != null)
              Text(trailing,
                  style: TextStyle(
                      color: AppColors.textMuted, fontWeight: FontWeight.w600)),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  Future<void> _pickLanguage() async {
    const options = ['English', 'Filipino', 'Spanish'];
    final chosen = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.neutralLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: options
            .map((o) => ListTile(
                  title: Text(o, style: TextStyle(color: AppColors.textDark)),
                  trailing: _s.language == o
                      ? const Icon(Icons.check, color: AppColors.primary)
                      : null,
                  onTap: () => Navigator.pop(ctx, o),
                ))
            .toList(),
      ),
    );
    if (chosen != null) setState(() => _s.setLanguage(chosen));
  }

  void _info(String msg) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(msg)));

  void _showAbout() {
    showAboutDialog(
      context: context,
      applicationName: 'Campus Events',
      applicationVersion: '1.0.0',
      applicationLegalese: '© 2026 Campus Events App',
      children: const [
        SizedBox(height: 12),
        Text('A campus events, marketplace and community hub.'),
      ],
    );
  }
}
