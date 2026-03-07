import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/advisory_service.dart';

/// Screen for SME to manage advisories — view posted ones & create new
class SmeAdvisoriesScreen extends StatefulWidget {
  const SmeAdvisoriesScreen({super.key});

  @override
  State<SmeAdvisoriesScreen> createState() => _SmeAdvisoriesScreenState();
}

class _SmeAdvisoriesScreenState extends State<SmeAdvisoriesScreen> {
  static const _purple = Color(0xFF7B2FDC);
  final _advisoryService = AdvisoryService();
  final _uid = firebase_auth.FirebaseAuth.instance.currentUser?.uid ?? '';
  String _smeDistrict = '';
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
      if (mounted) {
        setState(() {
          _smeDistrict = row?['district']?.toString() ?? '';
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
            else
              Expanded(
                child: StreamBuilder<List<Advisory>>(
                  stream: _advisoryService.advisoriesBySmeStream(_uid),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final advisories = snapshot.data ?? [];

                    if (advisories.isEmpty) {
                      return _buildEmptyState();
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                      itemCount: advisories.length,
                      itemBuilder: (_, i) => _buildAdvisoryCard(advisories[i]),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateDialog,
        backgroundColor: _purple,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New Advisory',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(8, 12, 16, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF7B2FDC), Color(0xFF5B1FA8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
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
                    _smeDistrict.isNotEmpty
                        ? 'District: $_smeDistrict'
                        : 'Send alerts to RAEs in your district',
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 13)),
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
          Text('No advisories posted yet',
              style: TextStyle(fontSize: 16, color: Colors.grey[500])),
          const SizedBox(height: 8),
          Text('Tap + to send your first advisory to RAEs',
              style: TextStyle(fontSize: 13, color: Colors.grey[400])),
        ],
      ),
    );
  }

  Widget _buildAdvisoryCard(Advisory advisory) {
    final date = advisory.createdAt;
    final dateStr =
        '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: const Border(
          left: BorderSide(color: Color(0xFF7B2FDC), width: 4),
        ),
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
          Row(
            children: [
              Expanded(
                child: Text(advisory.title,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              PopupMenuButton<String>(
                onSelected: (action) {
                  if (action == 'delete') _confirmDelete(advisory);
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete',
                          style: TextStyle(color: Colors.red))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(advisory.content,
              style: TextStyle(fontSize: 14, color: Colors.grey[700])),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.location_on, size: 14, color: Colors.grey[400]),
              const SizedBox(width: 4),
              Text(advisory.district,
                  style: TextStyle(fontSize: 12, color: Colors.grey[500])),
              const Spacer(),
              Icon(Icons.access_time, size: 14, color: Colors.grey[400]),
              const SizedBox(width: 4),
              Text(dateStr,
                  style: TextStyle(fontSize: 12, color: Colors.grey[500])),
            ],
          ),
        ],
      ),
    );
  }

  void _showCreateDialog() {
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool saving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                  20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(2)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text('New Advisory',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(
                        _smeDistrict.isNotEmpty
                            ? 'This will be visible to all RAEs in $_smeDistrict'
                            : 'Set your district in Profile first',
                        style:
                            TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: titleCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Title *',
                          prefixIcon: Icon(Icons.title),
                          hintText: 'e.g. Cotton Pest Alert – Bollworm',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: contentCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Content *',
                          prefixIcon: Icon(Icons.article),
                          hintText: 'Detailed advisory message...',
                          alignLabelWithHint: true,
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 5,
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: saving
                              ? null
                              : () async {
                                  if (!formKey.currentState!.validate()) return;
                                  if (_smeDistrict.isEmpty) {
                                    Navigator.pop(ctx);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              'Set your district in Profile first'),
                                          backgroundColor: Colors.red),
                                    );
                                    return;
                                  }
                                  setSheetState(() => saving = true);
                                  try {
                                    await _advisoryService.postAdvisory(
                                      smeUid: _uid,
                                      district: _smeDistrict,
                                      title: titleCtrl.text.trim(),
                                      content: contentCtrl.text.trim(),
                                    );
                                    if (ctx.mounted) Navigator.pop(ctx);
                                    if (mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(const SnackBar(
                                        content:
                                            Text('Advisory posted successfully'),
                                        backgroundColor: Color(0xFF7B2FDC),
                                      ));
                                    }
                                  } catch (e) {
                                    if (ctx.mounted) Navigator.pop(ctx);
                                    setSheetState(() => saving = false);
                                    if (mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(SnackBar(
                                        content: Text('Error: $e'),
                                        backgroundColor: Colors.red,
                                      ));
                                    }
                                  }
                                },
                          icon: saving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.send, color: Colors.white),
                          label: Text(
                              saving ? 'Posting...' : 'Post Advisory',
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _purple,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
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
  }

  void _confirmDelete(Advisory advisory) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Advisory'),
        content: Text('Delete "${advisory.title}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _advisoryService.deleteAdvisory(advisory.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Advisory deleted'),
                    backgroundColor: Colors.red,
                  ));
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
