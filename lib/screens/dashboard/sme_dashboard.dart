import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../../../services/sme_service.dart';
import '../profile/profile_screen.dart';

/// SME District Advisor Dashboard
///
/// Matches the Figma wireframe exactly:
///   - Full-bleed purple gradient header (no standard AppBar)
///   - 2×2 stat cards grid
///   - Active Conversations (realtime stream)
///   - Recent Issues & Complaints (realtime stream)
///   - District Performance Overview
///   - My Activity Log
///   - Dark-green FAB (sign-out / navigation)
class SMEDashboard extends StatefulWidget {
  const SMEDashboard({super.key});

  @override
  State<SMEDashboard> createState() => _SMEDashboardState();
}

class _SMEDashboardState extends State<SMEDashboard> {
  final _smeService = SmeService();
  final _firebaseUser = firebase_auth.FirebaseAuth.instance.currentUser;

  // -----------------------------------------------------------------
  // Colour palette (matches wireframe)
  // -----------------------------------------------------------------
  static const _purpleDeep = Color(0xFF7B2FDC);
  static const _purpleMid = Color(0xFF5B1FA8);
  static const _greenFab = Color(0xFF1B8C4E);

  String get _smeUid => _firebaseUser?.uid ?? '';

  // -----------------------------------------------------------------
  // Build
  // -----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Purple header ──────────────────────────────────────
              _buildHeader(),

              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Stat cards grid ────────────────────────────
                    _buildStatCardsGrid(),

                    const SizedBox(height: 20),

                    // ── Active Conversations ───────────────────────
                    _buildConversationsSection(),

                    const SizedBox(height: 20),

                    // ── Recent Issues & Complaints ─────────────────
                    _buildIssuesSection(),

                    const SizedBox(height: 20),

                    // ── District Performance Overview ──────────────
                    _buildDistrictPerformanceSection(),

                    const SizedBox(height: 20),

                    // ── My Activity Log ────────────────────────────
                    _buildActivityLogSection(),

                    // Bottom padding so FAB doesn't cover last card
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildFab(context),
    );
  }

  // -----------------------------------------------------------------
  // Header
  // -----------------------------------------------------------------

  Widget _buildHeader() {
    return FutureBuilder<Map<String, String>>(
      future: _smeService.getSmeProfile(_smeUid),
      builder: (context, snapshot) {
        final name = snapshot.data?['name'] ?? 'District Advisor';
        final district = snapshot.data?['district'] ?? 'Hyderabad';

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [_purpleDeep, _purpleMid],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title + subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'District Advisor Portal',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$name - $district',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              // Notification bell with red dot badge
              Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.notifications_outlined,
                      color: Colors.white,
                      size: 28,
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Notifications – Coming Soon')),
                      );
                    },
                  ),
                  // Red dot
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        border: Border.all(color: _purpleDeep, width: 1.5),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // -----------------------------------------------------------------
  // Stat Cards Grid
  // -----------------------------------------------------------------

  Widget _buildStatCardsGrid() {
    return FutureBuilder<SmeDashboardStats>(
      future: _smeService.getDashboardStats(_smeUid),
      builder: (context, snapshot) {
        final stats = snapshot.data ?? const SmeDashboardStats();
        final loading = snapshot.connectionState == ConnectionState.waiting;

        final cards = [
          _StatCardData(
            count: stats.activeRaes,
            label: 'Active RAEs',
            icon: Icons.people_outline,
            color: const Color(0xFF2F8AE0),
          ),
          _StatCardData(
            count: stats.openChats,
            label: 'Open Chats',
            icon: Icons.chat_bubble_outline,
            color: const Color(0xFF27AE60),
          ),
          _StatCardData(
            count: stats.resolvedIssues,
            label: 'Resolved Issues',
            icon: Icons.description_outlined,
            color: _purpleDeep,
          ),
          _StatCardData(
            count: stats.districtOrders,
            label: 'District Orders',
            icon: Icons.trending_up,
            color: const Color(0xFFE67E22),
          ),
        ];

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.25,
          ),
          itemCount: cards.length,
          itemBuilder: (context, index) =>
              _buildStatCard(cards[index], loading),
        );
      },
    );
  }

  Widget _buildStatCard(_StatCardData data, bool loading) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Icon box
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: data.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(data.icon, color: data.color, size: 22),
          ),
          // Count
          loading
              ? SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: data.color,
                  ),
                )
              : Text(
                  '${data.count}',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
          // Label
          Text(
            data.label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  // -----------------------------------------------------------------
  // Active Conversations
  // -----------------------------------------------------------------

  Widget _buildConversationsSection() {
    return StreamBuilder<List<ConversationItem>>(
      stream: _smeService.conversationsStream(_smeUid),
      builder: (context, snapshot) {
        final conversations = snapshot.data ?? [];
        final newCount = _smeService.countUnread(conversations);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section header
            Row(
              children: [
                const Icon(Icons.chat_bubble_outline, size: 18),
                const SizedBox(width: 8),
                const Text(
                  'Active Conversations',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (newCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$newCount New',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            if (snapshot.connectionState == ConnectionState.waiting)
              const Center(child: Padding(
                padding: EdgeInsets.all(24.0),
                child: CircularProgressIndicator(),
              ))
            else if (conversations.isEmpty)
              _buildEmptyCard('No active conversations', Icons.chat_bubble_outline)
            else
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Column(
                    children: conversations
                        .map((c) => _buildConversationTile(c))
                        .toList(),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildConversationTile(ConversationItem convo) {
    final hasUnread = convo.unreadCount > 0;
    final timeStr = _formatTime(convo.lastMessageAt);

    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chat interface – Coming Soon')),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: hasUnread
              ? const Color(0xFFF0FFF4)  // light green tint for unread
              : Colors.white,
          border: Border(
            left: BorderSide(
              color: hasUnread ? const Color(0xFF27AE60) : Colors.transparent,
              width: 4,
            ),
            bottom: BorderSide(color: Colors.grey[100]!, width: 1),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Text block
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    convo.raeName,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight:
                          hasUnread ? FontWeight.bold : FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    convo.raeCode,
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    convo.lastMessage,
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Time + unread badge column
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  timeStr,
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
                const SizedBox(height: 6),
                if (hasUnread)
                  Container(
                    width: 22,
                    height: 22,
                    decoration: const BoxDecoration(
                      color: Color(0xFF27AE60),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${convo.unreadCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // -----------------------------------------------------------------
  // Recent Issues & Complaints
  // -----------------------------------------------------------------

  Widget _buildIssuesSection() {
    return StreamBuilder<List<IssueItem>>(
      stream: _smeService.issuesStream(_smeUid),
      builder: (context, snapshot) {
        final issues = snapshot.data ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.description_outlined, size: 18),
                SizedBox(width: 8),
                Text(
                  'Recent Issues & Complaints',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (snapshot.connectionState == ConnectionState.waiting)
              const Center(child: CircularProgressIndicator())
            else if (issues.isEmpty)
              _buildEmptyCard('No issues reported', Icons.check_circle_outline)
            else
              Column(
                children: issues.map(_buildIssueCard).toList(),
              ),
          ],
        );
      },
    );
  }

  Widget _buildIssueCard(IssueItem issue) {
    final isOpen = issue.status == 'open';
    final statusColor = isOpen ? const Color(0xFFE74C3C) : const Color(0xFF27AE60);

    Color priorityColor;
    switch (issue.priority) {
      case 'high':
        priorityColor = const Color(0xFFE74C3C);
        break;
      case 'low':
        priorityColor = const Color(0xFF27AE60);
        break;
      default:
        priorityColor = Colors.grey[700]!;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: name + status badge + priority pill
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      issue.raeName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      issue.title,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Status badge (Open / Resolved)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isOpen ? 'Open' : 'Resolved',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Priority pill (outlined)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _capitalize(issue.priority),
                      style: TextStyle(
                        fontSize: 11,
                        color: priorityColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // View Details button (full-width outlined)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                // Show a dialog with description
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text(issue.title),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('RAE: ${issue.raeName}'),
                        const SizedBox(height: 8),
                        Text(issue.description.isNotEmpty
                            ? issue.description
                            : 'No description provided.'),
                      ],
                    ),
                    actions: [
                      if (isOpen)
                        TextButton(
                          onPressed: () async {
                            Navigator.pop(ctx);
                            try {
                              await _smeService.resolveIssue(issue.id);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Issue marked as resolved'),
                                    backgroundColor: Color(0xFF27AE60),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error: $e')),
                                );
                              }
                            }
                          },
                          child: const Text('Mark Resolved'),
                        ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.grey[300]!),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              child: const Text(
                'View Details',
                style: TextStyle(fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -----------------------------------------------------------------
  // District Performance Overview
  // -----------------------------------------------------------------

  Widget _buildDistrictPerformanceSection() {
    return FutureBuilder<SmeDistrictPerformance>(
      future: _smeService.getDistrictPerformance(_smeUid),
      builder: (context, snapshot) {
        final perf = snapshot.data ?? const SmeDistrictPerformance();
        final loading = snapshot.connectionState == ConnectionState.waiting;

        final rows = [
          _PerfRow(label: 'Total Orders (This Month)', value: loading ? '…' : '${perf.totalOrdersThisMonth}'),
          _PerfRow(label: 'Active RAEs', value: loading ? '…' : '${perf.activeRaes} / ${perf.totalRaes}'),
          _PerfRow(label: 'Villages Covered', value: loading ? '…' : '${perf.villagesCovered}'),
          _PerfRow(label: 'Farmers Served', value: loading ? '…' : '${perf.farmersServed}'),
        ];

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.trending_up, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'District Performance Overview',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...rows.map(_buildPerfRow),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPerfRow(_PerfRow row) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              row.label,
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
          ),
          Text(
            row.value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // -----------------------------------------------------------------
  // Activity Log
  // -----------------------------------------------------------------

  Widget _buildActivityLogSection() {
    return FutureBuilder<SmeActivityLog>(
      future: _smeService.getActivityLog(_smeUid),
      builder: (context, snapshot) {
        final log = snapshot.data ?? const SmeActivityLog();
        final loading = snapshot.connectionState == ConnectionState.waiting;

        final rows = [
          _PerfRow(label: 'Chats Resolved', value: loading ? '…' : '${log.chatsResolved}'),
          _PerfRow(label: 'Issues Handled', value: loading ? '…' : '${log.issuesHandled}'),
          _PerfRow(label: 'RAEs Mentored', value: loading ? '…' : '${log.raesMentored}'),
        ];

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'My Activity Log',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.bar_chart, size: 14, color: Colors.blue),
                  const SizedBox(width: 6),
                  Text(
                    'Activity logs help calculate your honorarium',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...rows.map(_buildPerfRow),
            ],
          ),
        );
      },
    );
  }

  // -----------------------------------------------------------------
  // Empty State Card
  // -----------------------------------------------------------------

  Widget _buildEmptyCard(String message, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(32),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: Colors.grey[300]),
          const SizedBox(height: 10),
          Text(
            message,
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  // -----------------------------------------------------------------
  // FAB (sign-out drawer)
  // -----------------------------------------------------------------

  Widget _buildFab(BuildContext context) {
    return FloatingActionButton(
      backgroundColor: _greenFab,
      onPressed: () {
        _showBottomMenu(context);
      },
      child: const Icon(Icons.menu, color: Colors.white),
    );
  }

  void _showBottomMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.dashboard),
                title: const Text('Dashboard'),
                onTap: () => Navigator.pop(ctx),
              ),
              ListTile(
                leading: const Icon(Icons.chat_bubble_outline),
                title: const Text('All Conversations'),
                onTap: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('All Conversations – Coming Soon')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.description_outlined),
                title: const Text('All Issues'),
                onTap: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('All Issues – Coming Soon')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('My Profile'),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ProfileScreen()),
                  );
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text('Sign Out', style: TextStyle(color: Colors.red)),
                onTap: () async {
                  Navigator.pop(ctx);
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (dCtx) => AlertDialog(
                      title: const Text('Sign Out'),
                      content: const Text('Are you sure you want to sign out?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dCtx, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(dCtx, true),
                          child: const Text('Sign Out'),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true && context.mounted) {
                    await firebase_auth.FirebaseAuth.instance.signOut();
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // -----------------------------------------------------------------
  // Helpers
  // -----------------------------------------------------------------

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) {
      // Show HH:MM for today
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return '$h:$m';
    }
    return 'Yesterday';
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

// -----------------------------------------------------------------
// Small data holders (private to this file)
// -----------------------------------------------------------------

class _StatCardData {
  final int count;
  final String label;
  final IconData icon;
  final Color color;
  const _StatCardData({
    required this.count,
    required this.label,
    required this.icon,
    required this.color,
  });
}

class _PerfRow {
  final String label;
  final String value;
  const _PerfRow({required this.label, required this.value});
}
