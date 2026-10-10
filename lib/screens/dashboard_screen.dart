import 'dart:async';

import 'package:flutter/material.dart';

import '../models/announcement.dart';
import '../models/event.dart';
import '../models/forum_post.dart';
import '../models/item.dart';
import '../models/user_profile.dart';
import '../models/verification.dart';
import '../services/announcement_service.dart';
import '../services/auth_service.dart';
import '../services/event_service.dart';
import '../services/forum_service.dart';
import '../services/item_service.dart';
import '../services/verification_service.dart';
import '../theme/theme.dart';
import '../widgets/item_image.dart';
import '../widgets/section_header.dart';
import '../widgets/soft_card.dart';
import 'account_verification_screen.dart';
import 'announcement_detail_screen.dart';
import 'enrollment_verification_screen.dart';
import 'event_detail_screen.dart';
import 'forum_post_detail_screen.dart';
import 'item_detail_screen.dart';

/// Screen 5 — Home view inside the shell. Vertical scroll of:
/// reminders banner · upcoming events billboard · marketplace + community rows.
class DashboardScreen extends StatefulWidget {
  /// Switches the parent shell to another tab (e.g. from a "See More" link).
  /// Tab indices: 0 Dashboard · 1 Campus Map · 2 Marketplace ·
  /// 3 Lost & Found · 4 Community Forum · 5 Announcements.
  final void Function(int index)? onNavigate;

  const DashboardScreen({super.key, this.onNavigate});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _showReminder = true;
  int _reminderIndex = 0;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AuthService.instance,
      builder: (context, _) {
        final verified = AuthService.instance.isVerified;
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _reverifyBanner(),
              if (!verified) _verifyAccountBanner(),
              if (_showReminder) _reminders(),
              if (verified) ...[
                const SizedBox(height: 20),
                _upcomingBillboard(),
                const SizedBox(height: 24),
                _section(
                  title: 'Campus Marketplace Highlights',
                  tab: 3,
                  previews: _marketPreviews(),
                ),
                const SizedBox(height: 24),
                _section(
                  title: 'Community Board Highlights',
                  tab: 5,
                  previews: _communityPreviews(),
                ),
                const SizedBox(height: 24),
                _section(
                  title: 'Lost & Found Highlights',
                  tab: 4,
                  previews: _lostFoundPreviews(),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  /// Shown to unverified students: prompts them to submit enrollment proof.
  Widget _verifyAccountBanner() {
    final status =
        AuthService.instance.currentUser?.verifyStatus ?? VerifyStatus.none;
    final pending = status == VerifyStatus.pending;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: SoftCard(
        color: AppColors.secondary.withValues(alpha: 0.12),
        border: Border.all(color: AppColors.secondary, width: 2),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => const AccountVerificationScreen()),
        ),
        child: Row(
          children: [
            Icon(pending ? Icons.hourglass_top : Icons.verified_user_outlined,
                color: AppColors.primary, size: 30),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      pending
                          ? 'Verification pending review'
                          : 'Verify your account to unlock everything',
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDark)),
                  const SizedBox(height: 4),
                  Text(
                    pending
                        ? 'An admin will review your enrollment proof soon.'
                        : 'Until then you can only see the Dashboard and '
                            'Announcements. Tap to submit your proof.',
                    style: TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textMuted,
                        height: 1.4),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.primary),
          ],
        ),
      ),
    );
  }

  Widget _section({
    required String title,
    required int tab,
    required Widget previews,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: title,
          onSeeMore: () => widget.onNavigate?.call(tab),
        ),
        const SizedBox(height: 8),
        previews,
      ],
    );
  }

  /// Prominent banner shown while an enrollment re-verification drive is open
  /// and the current student hasn't re-submitted proof yet.
  Widget _reverifyBanner() {
    return AnimatedBuilder(
      animation: VerificationService.instance,
      builder: (context, _) {
        final user = AuthService.instance.currentUser;
        if (!VerificationService.instance.needsResubmission(user)) {
          return const SizedBox.shrink();
        }
        final drive = VerificationService.instance.activeDrive!;
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: SoftCard(
            color: AppColors.danger.withValues(alpha: 0.10),
            border: Border.all(color: AppColors.danger, width: 2),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const EnrollmentVerificationScreen(reverify: true),
                ),
              );
              if (mounted) setState(() {});
            },
            child: Row(
              children: [
                const Icon(Icons.gpp_maybe_outlined,
                    color: AppColors.danger, size: 30),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Action needed: re-verify enrollment',
                          style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: AppColors.textDark)),
                      const SizedBox(height: 4),
                      Text(
                        'Re-submit your proof for ${drive.semester.label} '
                        '(${drive.schoolYear}). Tap to upload.',
                        style: TextStyle(
                            fontSize: 12.5,
                            color: AppColors.textMuted,
                            height: 1.4),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.danger),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _reminders() {
    // A small carousel over recent announcements with left/right arrows so the
    // student can flip through more than just the latest one.
    return StreamBuilder<List<Announcement>>(
      stream: AnnouncementService.instance.stream,
      initialData: AnnouncementService.instance.current,
      builder: (context, snapshot) {
        final list = snapshot.data ?? const [];
        final hasItems = list.isNotEmpty;
        final index = hasItems ? _reminderIndex.clamp(0, list.length - 1) : 0;
        final current = hasItems ? list[index] : null;
        final body = current?.brief ??
            'Don’t forget — the Tech & Innovation Fair registration closes this '
                'Friday. Reserve your slot from the Campus Map events list.';

        void step(int delta) {
          if (!hasItems) return;
          setState(() => _reminderIndex =
              (index + delta + list.length) % list.length);
        }

        return SoftCard(
          color: AppColors.surfaceTint.withValues(alpha: 0.45),
          border: Border.all(color: AppColors.secondary, width: 2),
          onTap: current == null
              ? null
              : () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          AnnouncementDetailScreen(announcementId: current.id),
                    ),
                  ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  InkWell(
                    onTap: () => setState(() => _showReminder = false),
                    borderRadius: BorderRadius.circular(20),
                    child: const Padding(
                      padding: EdgeInsets.all(2),
                      child: Icon(Icons.close_rounded,
                          size: 20, color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('New Reminders:',
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: AppColors.textDark)),
                  const Spacer(),
                  if (list.length > 1) ...[
                    Text('${index + 1}/${list.length}',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textMuted)),
                    _arrow(Icons.chevron_left_rounded, () => step(-1)),
                    _arrow(Icons.chevron_right_rounded, () => step(1)),
                  ] else if (current != null)
                    const Icon(Icons.chevron_right,
                        size: 20, color: AppColors.primary),
                ],
              ),
              if (current != null) ...[
                const SizedBox(height: 8),
                Text(current.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary)),
              ],
              const SizedBox(height: 10),
              Text(
                body,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: AppColors.textMuted, height: 1.5),
              ),
              if (current != null) ...[
                const SizedBox(height: 8),
                const Text('Tap to view announcement →',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary)),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _arrow(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: Icon(icon, size: 26, color: AppColors.primary),
      ),
    );
  }

  Widget _upcomingBillboard() {
    return StreamBuilder<List<CampusEvent>>(
      stream: EventService.instance.stream,
      initialData: EventService.instance.current,
      builder: (context, snapshot) {
        final events = snapshot.data ?? const [];
        return _UpcomingCarousel(events: events);
      },
    );
  }

  // ----- Marketplace highlights → product description -----
  Widget _marketPreviews() {
    return SizedBox(
      height: 150,
      child: StreamBuilder<List<MarketItem>>(
        stream: ItemService.instance.streamByType(PostType.marketplace),
        initialData: ItemService.instance.byType(PostType.marketplace),
        builder: (context, snapshot) {
          final items = (snapshot.data ?? const []).take(8).toList();
          if (items.isEmpty) return _emptyRow('No products yet');
          return ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (context, i) {
              final item = items[i];
              return _previewTile(
                imageSource: item.imageURL,
                fallbackIcon: Icons.shopping_bag_outlined,
                title: item.title,
                subtitle: item.price != null
                    ? '₱${item.price!.toStringAsFixed(0)}'
                    : 'For sale',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => ItemDetailScreen(item: item)),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // ----- Lost & Found highlights → item info -----
  Widget _lostFoundPreviews() {
    return SizedBox(
      height: 150,
      child: StreamBuilder<List<MarketItem>>(
        stream: ItemService.instance.streamByType(PostType.lostFound),
        initialData: ItemService.instance.byType(PostType.lostFound),
        builder: (context, snapshot) {
          final items = (snapshot.data ?? const []).take(8).toList();
          if (items.isEmpty) return _emptyRow('Nothing reported yet');
          return ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (context, i) {
              final item = items[i];
              return _previewTile(
                imageSource: item.imageURL,
                fallbackIcon: Icons.help_outline_rounded,
                title: item.title,
                subtitle: item.description.isEmpty
                    ? 'Lost & Found'
                    : item.description,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => ItemDetailScreen(item: item)),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // ----- Community board highlights → post thread / info -----
  Widget _communityPreviews() {
    return SizedBox(
      height: 150,
      child: StreamBuilder<List<ForumPost>>(
        stream: ForumService.instance.stream,
        initialData: ForumService.instance.current,
        builder: (context, snapshot) {
          final posts = (snapshot.data ?? const []).take(8).toList();
          if (posts.isEmpty) return _emptyRow('No posts yet');
          return ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: posts.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (context, i) {
              final post = posts[i];
              return _previewTile(
                fallbackIcon: Icons.forum_outlined,
                title: post.author,
                subtitle: post.body,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => ForumPostDetailScreen(postId: post.id)),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _previewTile({
    String? imageSource,
    required IconData fallbackIcon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: 140,
      child: SoftCard(
        color: AppColors.surfaceTint,
        border: Border.all(color: AppColors.secondary, width: 1.5),
        padding: const EdgeInsets.all(10),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: ItemImage(
                    source: imageSource, fallbackIcon: fallbackIcon),
              ),
            ),
            const SizedBox(height: 8),
            Text(title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: AppColors.textDark)),
            Text(subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 11.5, color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }

  Widget _emptyRow(String text) => Center(
        child: Text(text, style: TextStyle(color: AppColors.textMuted)),
      );
}

/// Auto-rotating "Upcoming Events" billboard. Cycles through the events every
/// few seconds, supports manual swiping, taps through to the event detail, and
/// shows page dots.
class _UpcomingCarousel extends StatefulWidget {
  final List<CampusEvent> events;
  const _UpcomingCarousel({required this.events});

  @override
  State<_UpcomingCarousel> createState() => _UpcomingCarouselState();
}

class _UpcomingCarouselState extends State<_UpcomingCarousel> {
  final _controller = PageController();
  Timer? _timer;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _timer?.cancel();
    if (widget.events.length < 2) return;
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!_controller.hasClients) return;
      final next = (_page + 1) % widget.events.length;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void didUpdateWidget(covariant _UpcomingCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Restart the timer if the number of events changed.
    if (oldWidget.events.length != widget.events.length) {
      if (_page >= widget.events.length) _page = 0;
      _startAutoScroll();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final events = widget.events;
    if (events.isEmpty) return _emptyCard();

    return Column(
      children: [
        SizedBox(
          height: 190,
          child: PageView.builder(
            controller: _controller,
            itemCount: events.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (context, i) => _eventCard(events[i]),
          ),
        ),
        if (events.length > 1) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(events.length, (i) {
              final active = i == _page;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: active ? 20 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: active ? AppColors.primary : AppColors.surfaceTint,
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }

  Widget _eventCard(CampusEvent event) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => EventDetailScreen(event: event)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadii.card),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.secondary, AppColors.primary],
            ),
          ),
          child: Stack(
            children: [
              const Positioned.fill(
                child: Icon(Icons.celebration_outlined,
                    size: 150, color: Colors.white12),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text('UPCOMING EVENTS',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                              letterSpacing: 1)),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(event.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w900)),
                        const SizedBox(height: 4),
                        Text('${event.date} · ${event.venue}',
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 14)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyCard() => Container(
        height: 190,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.secondary, AppColors.primary],
          ),
          borderRadius: BorderRadius.circular(AppRadii.card),
        ),
        alignment: Alignment.center,
        child: const Text('No events yet · Check back soon',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      );
}
