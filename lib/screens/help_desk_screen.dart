import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/support_ticket.dart';
import '../services/auth_service.dart';
import '../services/help_desk_service.dart';
import '../theme/theme.dart';
import '../widgets/pill_button.dart';
import '../widgets/soft_card.dart';

/// PBI-13: Help Desk & FAQ screen where students can browse searchable FAQs
/// and submit/track support tickets.
class HelpDeskScreen extends StatefulWidget {
  final int initialTabIndex;

  const HelpDeskScreen({super.key, this.initialTabIndex = 0});

  @override
  State<HelpDeskScreen> createState() => _HelpDeskScreenState();
}

class _HelpDeskScreenState extends State<HelpDeskScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _selectedFaqCategory = 'All';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 1),
    );
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    HelpDeskService.instance.addListener(_onServiceChanged);
  }

  @override
  void dispose() {
    HelpDeskService.instance.removeListener(_onServiceChanged);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onServiceChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _openSubmitTicketSheet() async {
    final formKey = GlobalKey<FormState>();
    final subjectCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String selectedCategory = HelpDeskService.ticketCategories.first;

    final submitted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.neutralLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.support_agent_rounded,
                              color: AppColors.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Submit Support Ticket',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textDark,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(sheetCtx, false),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Describe your concern and our campus support team will get back to you.',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: selectedCategory,
                        decoration: InputDecoration(
                          labelText: 'Category',
                          prefixIcon: const Icon(Icons.category_outlined),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadii.field),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        items: HelpDeskService.ticketCategories
                            .map((c) =>
                            DropdownMenuItem(value: c, child: Text(c)))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) {
                            setSheetState(() => selectedCategory = v);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: subjectCtrl,
                        decoration: InputDecoration(
                          labelText: 'Subject',
                          hintText: 'e.g. Unable to verify student ID',
                          prefixIcon: const Icon(Icons.title),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadii.field),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Please enter a subject'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: descCtrl,
                        minLines: 4,
                        maxLines: 6,
                        decoration: InputDecoration(
                          labelText: 'Description',
                          hintText:
                          'Include details like steps, dates, or error messages…',
                          alignLabelWithHint: true,
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadii.field),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        validator: (v) => (v == null || v.trim().length < 10)
                            ? 'Please provide at least 10 characters of detail'
                            : null,
                      ),
                      const SizedBox(height: 20),
                      PillButton(
                        label: 'Submit Ticket',
                        onPressed: () {
                          if (!formKey.currentState!.validate()) return;
                          final user = AuthService.instance.currentUser;
                          HelpDeskService.instance.submitTicket(
                            studentId: user?.uid ?? 'student',
                            studentName: user?.fullName ?? 'Campus Student',
                            category: selectedCategory,
                            subject: subjectCtrl.text,
                            description: descCtrl.text,
                          );
                          Navigator.pop(sheetCtx, true);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (submitted == true && mounted) {
      _tabController.animateTo(1);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Support ticket submitted! Track updates under My Tickets.'),
        ),
      );
    }
  }

  Future<void> _openAdminTicketDialog(SupportTicket ticket) async {
    final replyCtrl = TextEditingController(text: ticket.adminReply ?? '');
    TicketStatus status = ticket.status;

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.neutralLight,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text('Manage Ticket · ${ticket.studentName}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  ticket.subject,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 15),
                ),
                const SizedBox(height: 4),
                Text(
                  ticket.description,
                  style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<TicketStatus>(
                  initialValue: status,
                  decoration: InputDecoration(
                    labelText: 'Ticket Status',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: TicketStatus.values
                      .map((s) =>
                      DropdownMenuItem(value: s, child: Text(s.label)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setDialogState(() => status = v);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: replyCtrl,
                  minLines: 3,
                  maxLines: 5,
                  decoration: InputDecoration(
                    labelText: 'Official Support Response',
                    hintText: 'Write your reply to the student…',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                HelpDeskService.instance.updateTicket(
                  ticketId: ticket.id,
                  status: status,
                  adminReply: replyCtrl.text,
                );
                Navigator.pop(dialogCtx, true);
              },
              child: const Text('Save Update'),
            ),
          ],
        ),
      ),
    );

    if (saved == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Support ticket updated.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = AuthService.instance.isAdmin;
    return Scaffold(
      backgroundColor: AppColors.neutralLight,
      appBar: AppBar(
        title: const Text('Help Desk & FAQ'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            const Tab(
              icon: Icon(Icons.quiz_outlined, size: 18),
              text: 'Common FAQs',
            ),
            Tab(
              icon: const Icon(Icons.confirmation_number_outlined, size: 18),
              text: isAdmin ? 'All Tickets' : 'Support Tickets',
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_comment_outlined),
        label: const Text('New Ticket'),
        onPressed: _openSubmitTicketSheet,
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFaqTab(),
          _buildTicketsTab(isAdmin: isAdmin),
        ],
      ),
    );
  }

  Widget _buildFaqTab() {
    final allFaqs = HelpDeskService.instance.faqs;
    final categories = [
      'All',
      ...{for (final f in allFaqs) f.category},
    ];
    final query = _searchController.text.trim().toLowerCase();

    final filtered = allFaqs.where((f) {
      final matchesCat =
          _selectedFaqCategory == 'All' || f.category == _selectedFaqCategory;
      final matchesQuery = query.isEmpty ||
          f.question.toLowerCase().contains(query) ||
          f.answer.toLowerCase().contains(query) ||
          f.category.toLowerCase().contains(query);
      return matchesCat && matchesQuery;
    }).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        // Search box
        TextField(
          controller: _searchController,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: 'Search common questions…',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: query.isNotEmpty
                ? IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                setState(() {});
              },
            )
                : null,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadii.field),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Category filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: categories.map((cat) {
              final selected = _selectedFaqCategory == cat;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(cat),
                  selected: selected,
                  selectedColor: AppColors.primary.withValues(alpha: 0.16),
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    color: selected ? AppColors.primary : AppColors.textDark,
                  ),
                  onSelected: (_) =>
                      setState(() => _selectedFaqCategory = cat),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 14),

        if (filtered.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Column(
              children: [
                Icon(Icons.search_off_rounded,
                    size: 46, color: AppColors.textMuted),
                const SizedBox(height: 10),
                Text(
                  'No matching FAQs found.',
                  style: TextStyle(
                      fontWeight: FontWeight.w700, color: AppColors.textMuted),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tap "New Ticket" below to ask campus support directly.',
                  style: TextStyle(fontSize: 12.5, color: AppColors.textMuted),
                ),
              ],
            ),
          )
        else
          ...filtered.map((faq) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: SoftCard(
              padding: EdgeInsets.zero,
              child: Theme(
                data: Theme.of(context)
                    .copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 6),
                  childrenPadding:
                  const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceTint.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.help_outline_rounded,
                        color: AppColors.primary, size: 20),
                  ),
                  title: Text(
                    faq.question,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: AppColors.textDark,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      faq.category,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  children: [
                    Text(
                      faq.answer,
                      style: TextStyle(
                        fontSize: 13.5,
                        height: 1.45,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )),

        // Prompt banner to submit a ticket if FAQ didn't answer their issue
        const SizedBox(height: 8),
        SoftCard(
          color: AppColors.surfaceTint.withValues(alpha: 0.4),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.support_agent_rounded,
                  color: AppColors.primary, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Still need assistance?',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Submit a support ticket and track responses from campus staff.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: _openSubmitTicketSheet,
                child: const Text('Submit'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTicketsTab({required bool isAdmin}) {
    final uid = AuthService.instance.currentUser?.uid ?? '';
    final tickets = HelpDeskService.instance.ticketsForUser(
      uid,
      isAdmin: isAdmin,
    );

    if (tickets.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.confirmation_number_outlined,
                  size: 54, color: AppColors.textMuted),
              const SizedBox(height: 12),
              Text(
                'No support tickets yet',
                style: TextStyle(
                    fontWeight: FontWeight.w700, color: AppColors.textMuted),
              ),
              const SizedBox(height: 4),
              Text(
                'Tap "New Ticket" below if you need help with your account, events, or technical issues.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12.5, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      itemCount: tickets.length,
      itemBuilder: (context, index) {
        final t = tickets[index];
        final Color statusColor = switch (t.status) {
          TicketStatus.open => Colors.deepOrange,
          TicketStatus.inProgress => AppColors.primary,
          TicketStatus.resolved => AppColors.success,
        };
        final date = DateFormat('MMM d · h:mm a').format(t.createdAt);

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: SoftCard(
            onTap: isAdmin ? () => _openAdminTicketDialog(t) : null,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        t.status.label.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: statusColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        t.category,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    Text(
                      date,
                      style:
                      TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  t.subject,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  t.description,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: AppColors.textMuted,
                  ),
                ),
                if (isAdmin) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Submitted by: ${t.studentName} (Tap to reply/update)',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ],
                if (t.adminReply != null && t.adminReply!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceTint.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.support_agent_rounded,
                                size: 15, color: AppColors.primary),
                            SizedBox(width: 6),
                            Text(
                              'Campus Support Reply',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          t.adminReply!,
                          style: TextStyle(
                            fontSize: 12.5,
                            height: 1.35,
                            color: AppColors.textDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}