import 'package:flutter/material.dart';

import '../models/announcement.dart';
import '../services/announcement_service.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import '../services/help_desk_service.dart';
import '../services/notification_service.dart';
import '../services/presence_service.dart';
import '../services/report_service.dart';
import '../services/settings_controller.dart';
import '../theme/theme.dart';
import '../widgets/user_avatar.dart';
import 'admin_reports_screen.dart';
import 'announcement_detail_screen.dart';
import 'announcements_screen.dart';
import 'campus_map_screen.dart';
import 'campus_marketplace_screen.dart';
import 'community_forum_screen.dart';
import 'dashboard_screen.dart';
import 'events_screen.dart';
import 'help_desk_screen.dart';
import 'lost_and_found_screen.dart';
import 'messages_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';
import 'verification_admin_screen.dart';
import 'welcome_screen.dart';

/// Persistent navigation shell. Swapping drawer items updates the body view
/// without destroying the shell context (single Scaffold, indexed body).
class MainLayoutShell extends StatefulWidget {
  const MainLayoutShell({super.key});

  @override
  State<MainLayoutShell> createState() => _MainLayoutShellState();
}

class _NavEntry {
  final String label;
  final IconData icon;
  final Widget page;
  const _NavEntry(this.label, this.icon, this.page);
}

class _MainLayoutShellState extends State<MainLayoutShell>
    with WidgetsBindingObserver {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SettingsController.instance.addListener(_onChanged);
    AuthService.instance.addListener(_onChanged);
    NotificationService.instance.addListener(_onChanged);
    ChatService.instance.addListener(_onChanged);
    ReportService.instance.addListener(_onChanged);
    AnnouncementService.instance.addListener(_onChanged);
    HelpDeskService.instance.addListener(_onChanged);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    SettingsController.instance.removeListener(_onChanged);
    AuthService.instance.removeListener(_onChanged);
    NotificationService.instance.removeListener(_onChanged);
    ChatService.instance.removeListener(_onChanged);
    ReportService.instance.removeListener(_onChanged);
    AnnouncementService.instance.removeListener(_onChanged);
    HelpDeskService.instance.removeListener(_onChanged);
    super.dispose();
  }

  /// PBI-7: keep presence in sync with the actual app lifecycle.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final uid = AuthService.instance.currentUser?.uid ?? '';
    if (uid.isEmpty) return;
    if (state == AppLifecycleState.resumed) {
      PresenceService.instance.markOnline(uid);
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      PresenceService.instance.markOffline(uid);
    }
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  void _goToTab(int index) {
    final max = _entries().length - 1;
    setState(() => _index = index.clamp(0, max));
  }

  /// Nav entries gated by verification + admin role.
  List<_NavEntry> _entries() {
    final verified = AuthService.instance.isVerified;
    final isAdmin = AuthService.instance.isAdmin;
    return [
      _NavEntry('Dashboard', Icons.dashboard_rounded,
          DashboardScreen(onNavigate: _goToTab)),
      if (verified) ...[
        _NavEntry('Events', Icons.event_rounded, const EventsScreen()),
        _NavEntry('Campus Map', Icons.map_rounded, const CampusMapScreen()),
        _NavEntry('Campus Marketplace', Icons.storefront_rounded,
            const CampusMarketplaceScreen()),
        _NavEntry(
            'Lost & Found', Icons.search_rounded, const LostAndFoundScreen()),
        _NavEntry('Community Forum', Icons.forum_rounded,
            const CommunityForumScreen()),
      ],
      _NavEntry(
          'Announcements', Icons.campaign_rounded, const AnnouncementsScreen()),
      _NavEntry('Messages', Icons.chat_bubble_outline_rounded,
          const MessagesScreen()),
      if (isAdmin) ...[
        _NavEntry('Verification', Icons.verified_user_rounded,
            const VerificationAdminScreen()),
        _NavEntry('Reports', Icons.flag_rounded, const AdminReportsScreen()),
      ],
      // PBI-13: Help Desk & FAQ tab accessible to all students and admins
      _NavEntry('Help Desk & FAQ', Icons.support_agent_rounded,
          const HelpDeskScreen()),
      _NavEntry('Settings', Icons.settings_rounded, const SettingsScreen()),
    ];
  }

  /// Index of the named tab in the *current* entry list, or null if hidden.
  int? _indexOfLabel(String label) {
    final entries = _entries();
    for (var i = 0; i < entries.length; i++) {
      if (entries[i].label == label) return i;
    }
    return null;
  }

  /// PBI-10: High-priority emergency banner pinned across the top of any
  /// active screen until the student taps or dismisses it.
  Widget _buildEmergencyBannerOverlay(BuildContext context) {
    final uid = AuthService.instance.currentUser?.uid ?? '';
    final Announcement? emergency =
    AnnouncementService.instance.activeEmergencyFor(uid);
    if (emergency == null) return const SizedBox.shrink();

    return Material(
      color: AppColors.danger,
      elevation: 6,
      child: InkWell(
        onTap: () {
          AnnouncementService.instance.dismissEmergency(uid, emergency.id);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  AnnouncementDetailScreen(announcementId: emergency.id),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              const Icon(Icons.emergency_share_rounded,
                  color: Colors.white, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'EMERGENCY ALERT · ${emergency.category.toUpperCase()}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      emergency.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Tap to view details',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Dismiss emergency alert',
                icon: const Icon(Icons.close_rounded, color: Colors.white),
                onPressed: () {
                  AnnouncementService.instance
                      .dismissEmergency(uid, emergency.id);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final entries = _entries();
    if (_index >= entries.length) _index = 0;
    return Scaffold(
      backgroundColor: AppColors.neutralLight,
      appBar: AppBar(
        title: InkWell(
          onTap: () {
            final target = _indexOfLabel('Events') ?? 0;
            setState(() => _index = target);
          },
          borderRadius: BorderRadius.circular(8),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Text('CAMPUS EVENTS'),
          ),
        ),
        actions: [
          _NotificationsButton(onOpen: _openNotifications),
          Padding(
            padding: const EdgeInsets.only(right: 12, left: 4),
            child: GestureDetector(
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
                if (mounted) setState(() {});
              },
              child: UserAvatar(
                photoURL: AuthService.instance.currentUser?.photoURL,
                radius: 18,
                backgroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
      drawer: _buildDrawer(context, entries),
      body: Column(
        children: [
          // PBI-10: Stays visible across the top of any active screen
          _buildEmergencyBannerOverlay(context),
          Expanded(
            child: IndexedStack(
              index: _index,
              children: entries
                  .map((e) => KeyedSubtree(
                key: ValueKey('${e.label}_${AppColors.dark}'),
                child: e.page,
              ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openNotifications() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
    );
    if (mounted) setState(() {});
  }

  Widget _buildDrawer(BuildContext context, List<_NavEntry> entries) {
    final uid = AuthService.instance.currentUser?.uid ?? '';
    final isAdmin = AuthService.instance.isAdmin;
    final unreadMessages = ChatService.instance.unreadFor(uid);
    final openReports = ReportService.instance.openCount;
    final openTickets = isAdmin ? HelpDeskService.instance.openTicketCount : 0;
    final user = AuthService.instance.currentUser;
    return Drawer(
      backgroundColor: AppColors.neutralLight,
      child: SafeArea(
        child: Column(
          children: [
            InkWell(
              onTap: () async {
                Navigator.pop(context);
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
                if (mounted) setState(() {});
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: const BoxDecoration(color: AppColors.secondary),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        UserAvatar(
                          photoURL: user?.photoURL,
                          radius: 30,
                          backgroundColor: Colors.white,
                        ),
                        const Spacer(),
                        const Icon(Icons.chevron_right,
                            color: Colors.white70),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      user?.fullName ?? 'Campus Student',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800),
                    ),
                    Text(
                      user?.schoolEmail ?? '',
                      style:
                      const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'View profile',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: entries.length,
                itemBuilder: (context, i) {
                  final selected = i == _index;
                  return Padding(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                    child: Container(
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.surfaceTint.withValues(alpha: 0.5)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: ListTile(
                        leading: Icon(entries[i].icon,
                            color: selected
                                ? AppColors.primary
                                : AppColors.secondary),
                        title: Text(
                          entries[i].label,
                          style: TextStyle(
                            fontWeight:
                            selected ? FontWeight.w800 : FontWeight.w600,
                            color: AppColors.textDark,
                          ),
                        ),
                        trailing: _navBadge(
                          entries[i].label,
                          unreadMessages,
                          openReports,
                          openTickets,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        onTap: () {
                          setState(() => _index = i);
                          Navigator.pop(context);
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout_rounded,
                  color: AppColors.danger),
              title: const Text('Log out',
                  style: TextStyle(
                      color: AppColors.danger, fontWeight: FontWeight.w700)),
              onTap: () {
                AuthService.instance.signOut();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                      (route) => false,
                );
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget? _navBadge(
      String label,
      int unreadMessages,
      int openReports,
      int openTickets,
      ) {
    final count = switch (label) {
      'Messages' => unreadMessages,
      'Reports' => openReports,
      'Help Desk & FAQ' => openTickets,
      _ => 0,
    };
    if (count <= 0) return null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: const BoxDecoration(
        color: AppColors.danger,
        borderRadius: BorderRadius.all(Radius.circular(10)),
      ),
      child: Text(
        count > 9 ? '9+' : '$count',
        style: const TextStyle(
            color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800),
      ),
    );
  }
}

/// A small badge wrapper used by the nav-bar action icons.
class _BadgeIcon extends StatelessWidget {
  final IconData icon;
  final int count;
  final String tooltip;
  final VoidCallback onTap;

  const _BadgeIcon({
    required this.icon,
    required this.count,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(icon: Icon(icon), tooltip: tooltip, onPressed: onTap),
        if (count > 0)
          Positioned(
            right: 6,
            top: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              decoration: const BoxDecoration(
                color: AppColors.danger,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(count > 9 ? '9+' : '$count',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w800)),
            ),
          ),
      ],
    );
  }
}

class _NotificationsButton extends StatelessWidget {
  final VoidCallback onOpen;
  const _NotificationsButton({required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final uid = AuthService.instance.currentUser?.uid ?? '';
    return _BadgeIcon(
      icon: Icons.notifications_outlined,
      count: NotificationService.instance.unreadFor(uid),
      tooltip: 'Notifications',
      onTap: onOpen,
    );
  }
}