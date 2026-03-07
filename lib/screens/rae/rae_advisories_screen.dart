import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/advisory_service.dart';

/// Screen for RAE to view advisories/alerts for their district
class RaeAdvisoriesScreen extends StatefulWidget {
  const RaeAdvisoriesScreen({super.key});

  @override
  State<RaeAdvisoriesScreen> createState() => _RaeAdvisoriesScreenState();
}

class _RaeAdvisoriesScreenState extends State<RaeAdvisoriesScreen> {
  static const _green = Color(0xFF2E9B33);
  final _advisoryService = AdvisoryService();
  final _uid = firebase_auth.FirebaseAuth.instance.currentUser?.uid ?? '';
  String _raeDistrict = '';
  bool _loadingDistrict = true;

  @override
  void initState() {
    super.initState();
    _loadDistrict();
  }

  Future<void> _loadDistrict() async {
    try {
      final row = await Supabase.instance.client
          .from('profiles')
          .select('district')
          .eq('uid', _uid)
          .maybeSingle();
      if (row != null && mounted) {
        setState(() {
          _raeDistrict = row['district']?.toString() ?? '';
          _loadingDistrict = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingDistrict = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            if (_loadingDistrict)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (_raeDistrict.isEmpty)
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.location_off,
                            size: 64, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text('District not set',
                            style: TextStyle(
                                fontSize: 16, color: Colors.grey[500])),
                        const SizedBox(height: 8),
                        Text(
                            'Set your district in Profile to see advisories from your district SME.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 13, color: Colors.grey[400])),
                      ],
                    ),
                  ),
                ),
              )
            else
              Expanded(
                child: StreamBuilder<List<Advisory>>(
                  stream: _advisoryService
                      .advisoriesForDistrictStream(_raeDistrict),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final advisories = snapshot.data ?? [];

                    if (advisories.isEmpty) {
                      return _buildEmptyState();
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                      itemCount: advisories.length,
                      itemBuilder: (_, i) => _buildAdvisoryCard(advisories[i]),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(8, 12, 16, 20),
      color: _green,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Advisories & Alerts',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(
                  _raeDistrict.isNotEmpty
                      ? 'From your district SME · $_raeDistrict'
                      : 'Alerts from your district SME',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.campaign_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text('No advisories yet',
              style: TextStyle(fontSize: 16, color: Colors.grey[500])),
          const SizedBox(height: 8),
          Text('Your district SME will post advisories here',
              style: TextStyle(fontSize: 13, color: Colors.grey[400])),
        ],
      ),
    );
  }

  Widget _buildAdvisoryCard(Advisory advisory) {
    final date = advisory.createdAt;
    final now = DateTime.now();
    final diff = now.difference(date);
    String timeStr;
    if (diff.inMinutes < 60) {
      timeStr = '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      timeStr = '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      timeStr = '${diff.inDays}d ago';
    } else {
      timeStr = '${date.day}/${date.month}/${date.year}';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _green.withOpacity(0.08),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                Icon(Icons.campaign, color: _green, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(advisory.title,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Text(advisory.content,
                style: TextStyle(fontSize: 14, color: Colors.grey[700])),
          ),
          // Footer
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Row(
              children: [
                Icon(Icons.access_time, size: 14, color: Colors.grey[400]),
                const SizedBox(width: 4),
                Text(timeStr,
                    style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                const Spacer(),
                Icon(Icons.location_on, size: 14, color: Colors.grey[400]),
                const SizedBox(width: 4),
                Text(advisory.district,
                    style: TextStyle(fontSize: 12, color: Colors.grey[500])),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
