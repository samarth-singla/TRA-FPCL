import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../catalog/product_catalog_screen.dart';

class RAEDashboard extends StatefulWidget {
  const RAEDashboard({super.key});

  @override
  State<RAEDashboard> createState() => _RAEDashboardState();
}

class _RAEDashboardState extends State<RAEDashboard> {
  final _supabase = Supabase.instance.client;

  @override
  Widget build(BuildContext context) {
    final user = _supabase.auth.currentUser;
    
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Header
              _buildWelcomeHeader(user),
              const SizedBox(height: 24),

              // Active Orders Count
              _buildActiveOrdersCard(),
              const SizedBox(height: 24),

              // Main Actions Grid
              _buildMainActionsGrid(context),
              const SizedBox(height: 24),

              // Recent Alerts Section
              _buildRecentAlertsSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader(User? user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Welcome Back!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.phone ?? 'RAE User',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveOrdersCard() {
    final currentUserId = _supabase.auth.currentUser?.id ?? '';
    
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _supabase
          .from('orders')
          .stream(primaryKey: ['id']),
      builder: (context, snapshot) {
        // Filter data after receiving it
        final allOrders = snapshot.data ?? [];
        final activeOrders = allOrders.where((order) => 
          order['rae_uid'] == currentUserId && 
          order['status'] == 'active'
        ).toList();
        
        final activeOrdersCount = activeOrders.length;
        final isLoading = snapshot.connectionState == ConnectionState.waiting;

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
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.shopping_bag,
                  color: Colors.orange,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Active Orders',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            '$activeOrdersCount',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey[400],
                size: 20,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMainActionsGrid(BuildContext context) {
    final actions = [
      {
        'title': 'Order Inputs',
        'icon': Icons.add_shopping_cart,
        'color': Colors.blue,
        'route': '/order-inputs',
      },
      {
        'title': 'Track Orders',
        'icon': Icons.location_on,
        'color': Colors.green,
        'route': '/track-orders',
      },
      {
        'title': 'Advisory',
        'icon': Icons.lightbulb,
        'color': Colors.purple,
        'route': '/advisory',
      },
      {
        'title': 'Earnings',
        'icon': Icons.account_balance_wallet,
        'color': Colors.amber,
        'route': '/earnings',
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.1,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final action = actions[index];
        return _buildActionCard(
          context,
          title: action['title'] as String,
          icon: action['icon'] as IconData,
          color: action['color'] as Color,
          onTap: () {
            // Navigate to respective screen
            if (action['title'] == 'Order Inputs') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProductCatalogScreen(),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${action['title']} - Coming Soon'),
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          },
        );
      },
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
                size: 36,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentAlertsSection() {
    final currentUserId = _supabase.auth.currentUser?.id ?? '';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Alerts',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {
                // Navigate to all notifications
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('All Notifications - Coming Soon'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        StreamBuilder<List<Map<String, dynamic>>>(
          stream: _supabase
              .from('notifications')
              .stream(primaryKey: ['id']),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (snapshot.hasError) {
              return _buildEmptyAlertsCard(
                'Unable to load notifications',
                Icons.error_outline,
              );
            }

            // Filter and sort after receiving data
            final allNotifications = snapshot.data ?? [];
            final userNotifications = allNotifications
                .where((notif) => notif['user_uid'] == currentUserId)
                .toList();
            
            // Sort by created_at descending
            userNotifications.sort((a, b) {
              final dateA = DateTime.tryParse(a['created_at'] ?? '') ?? DateTime.now();
              final dateB = DateTime.tryParse(b['created_at'] ?? '') ?? DateTime.now();
              return dateB.compareTo(dateA);
            });
            
            // Take only first 3
            final notifications = userNotifications.take(3).toList();

            if (notifications.isEmpty) {
              return _buildEmptyAlertsCard(
                'No recent alerts',
                Icons.notifications_none,
              );
            }

            return Column(
              children: notifications.map((notification) {
                return _buildAlertCard(
                  title: notification['title'] ?? 'Notification',
                  message: notification['message'] ?? '',
                  time: notification['created_at'] ?? '',
                  isRead: notification['is_read'] ?? false,
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildEmptyAlertsCard(String message, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(32),
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
      child: Center(
        child: Column(
          children: [
            Icon(
              icon,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertCard({
    required String title,
    required String message,
    required String time,
    required bool isRead,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isRead ? Colors.white : Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isRead ? Colors.grey[200]! : Colors.blue.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isRead ? Icons.notifications : Icons.notifications_active,
              color: Colors.blue,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isRead ? FontWeight.w500 : FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTime(time),
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(String timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h ago';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}d ago';
      } else {
        return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
      }
    } catch (e) {
      return '';
    }
  }
}
