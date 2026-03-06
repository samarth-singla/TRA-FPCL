import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/auth_service.dart';
import '../../services/offline_sync_service.dart';

/// Universal Profile Screen — works for RAE, SME, SUPPLIER, and ADMIN.
///
/// - Loads profile from local SQLite cache first; falls back to Supabase.
/// - Allows editing name, email, and district.
/// - Shows role badge, last sync time, and an offline sync trigger.
/// - Accent colour adapts per role.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _auth = AuthService();
  final _sync = OfflineSyncService();
  final _supabase = Supabase.instance.client;
  final _fbUser = firebase_auth.FirebaseAuth.instance.currentUser;

  // Form
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _districtCtrl = TextEditingController();

  // State
  Map<String, dynamic>? _profile;
  bool _loading = true;
  bool _saving = false;
  bool _editing = false;
  bool _isOnline = true;
  DateTime? _lastSync;
  String? _errorMsg;

  // Role → accent colour
  static Color _accentFor(String? role) {
    switch (role) {
      case 'SME':
        return const Color(0xFF7B2FDC);
      case 'SUPPLIER':
        return const Color(0xFF4F46E5);
      case 'ADMIN':
        return const Color(0xFF2563EB);
      default: // RAE
        return const Color(0xFF2E9B33);
    }
  }

  static String _roleLabel(String? role) {
    switch (role) {
      case 'SME':
        return 'District Advisor';
      case 'SUPPLIER':
        return 'Input Supplier';
      case 'ADMIN':
        return 'FPCL Admin';
      default:
        return 'Rural Agripreneur';
    }
  }

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _districtCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _loading = true;
      _errorMsg = null;
    });

    final uid = _fbUser?.uid;
    if (uid == null) {
      setState(() {
        _loading = false;
        _errorMsg = 'Not signed in.';
      });
      return;
    }

    // Check connectivity
    _isOnline = await _sync.isOnline();
    _lastSync = await _sync.lastSyncTime();

    Map<String, dynamic>? profile;

    // 1. Try local cache first (works offline)
    profile = await _sync.getLocalProfile(uid);

    // 2. If online and no local copy (or always refresh on open), fetch from Supabase
    if (_isOnline) {
      try {
        final remote = await _supabase
            .from('profiles')
            .select()
            .eq('uid', uid)
            .maybeSingle()
            .timeout(const Duration(seconds: 5));
        if (remote != null) {
          profile = remote;
          // Update local cache
          await _sync.syncProfile(uid);
          _lastSync = await _sync.lastSyncTime();
        }
      } catch (_) {
        // Use whatever local data we have
      }
    }

    if (profile == null) {
      setState(() {
        _loading = false;
        _errorMsg = 'Could not load profile. Check your connection.';
      });
      return;
    }

    _nameCtrl.text = profile['name']?.toString() ?? '';
    _emailCtrl.text = profile['email']?.toString() ?? '';
    _districtCtrl.text = profile['district']?.toString() ?? '';

    if (mounted) {
      setState(() {
        _profile = profile;
        _loading = false;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      await _auth.updateProfile(
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
      );

      // Also update district (not in AuthService.updateProfile — do it here)
      final uid = _fbUser?.uid;
      if (uid != null) {
        await _supabase.from('profiles').update({
          'district': _districtCtrl.text.trim(),
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('uid', uid);

        // Refresh local cache
        await _sync.syncProfile(uid);
      }

      if (mounted) {
        setState(() {
          _profile = {
            ..._profile!,
            'name': _nameCtrl.text.trim(),
            'email': _emailCtrl.text.trim(),
            'district': _districtCtrl.text.trim(),
          };
          _editing = false;
          _saving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _triggerSync() async {
    final uid = _fbUser?.uid;
    if (uid == null) return;
    if (!(await _sync.isOnline())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No internet connection — sync unavailable')),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Syncing data…')),
    );
    await _sync.syncAll(uid);
    final last = await _sync.lastSyncTime();
    if (mounted) {
      setState(() => _lastSync = last);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sync complete'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = _profile?['role']?.toString();
    final accent = _accentFor(role);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar ──────────────────────────────────────────────
            Container(
              color: accent,
              padding: const EdgeInsets.fromLTRB(4, 8, 16, 16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Text(
                      'My Profile',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (!_loading && _profile != null)
                    TextButton.icon(
                      onPressed: _editing
                          ? (_saving ? null : _saveProfile)
                          : () => setState(() => _editing = true),
                      icon: Icon(
                        _editing ? Icons.check : Icons.edit,
                        color: Colors.white,
                        size: 18,
                      ),
                      label: Text(
                        _editing ? (_saving ? 'Saving…' : 'Save') : 'Edit',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  if (_editing)
                    TextButton(
                      onPressed: () {
                        // Revert to saved values
                        _nameCtrl.text = _profile?['name']?.toString() ?? '';
                        _emailCtrl.text = _profile?['email']?.toString() ?? '';
                        _districtCtrl.text =
                            _profile?['district']?.toString() ?? '';
                        setState(() => _editing = false);
                      },
                      child: const Text('Cancel',
                          style: TextStyle(color: Colors.white70)),
                    ),
                ],
              ),
            ),

            // ── Body ─────────────────────────────────────────────────
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMsg != null
                      ? _buildError()
                      : _buildContent(accent),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              _errorMsg!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadProfile,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(Color accent) {
    final role = _profile?['role']?.toString();
    final phone = _fbUser?.phoneNumber ?? _profile?['phone']?.toString() ?? '—';
    final initials = _nameCtrl.text.isNotEmpty
        ? _nameCtrl.text.trim().split(' ').map((w) => w[0]).take(2).join().toUpperCase()
        : (phone.length >= 2 ? phone.substring(phone.length - 2) : '?');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            // ── Avatar + role badge ──────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 44,
                    backgroundColor: accent.withOpacity(0.15),
                    child: Text(
                      initials,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: accent,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _nameCtrl.text.isNotEmpty
                        ? _nameCtrl.text
                        : 'No name set',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: accent.withOpacity(0.3)),
                    ),
                    child: Text(
                      _roleLabel(role),
                      style: TextStyle(
                        color: accent,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Fixed info (phone — read-only) ───────────────────────
            _infoCard(
              title: 'Account',
              children: [
                _readOnlyRow(Icons.phone, 'Phone', phone),
                _readOnlyRow(Icons.badge_outlined, 'Role', role ?? '—'),
              ],
            ),

            const SizedBox(height: 12),

            // ── Editable fields ──────────────────────────────────────
            _infoCard(
              title: 'Personal Details',
              children: [
                _editableRow(
                  icon: Icons.person_outline,
                  label: 'Full Name',
                  controller: _nameCtrl,
                  enabled: _editing,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                ),
                const Divider(height: 1),
                _editableRow(
                  icon: Icons.email_outlined,
                  label: 'Email',
                  controller: _emailCtrl,
                  enabled: _editing,
                  keyboardType: TextInputType.emailAddress,
                ),
                const Divider(height: 1),
                _editableRow(
                  icon: Icons.location_on_outlined,
                  label: 'District',
                  controller: _districtCtrl,
                  enabled: _editing,
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ── Offline sync card ────────────────────────────────────
            _buildSyncCard(accent),

            const SizedBox(height: 20),

            // ── Sign out button ──────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Sign Out'),
                      content:
                          const Text('Are you sure you want to sign out?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Sign Out',
                              style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true && mounted) {
                    await AuthService().signOut();
                  }
                },
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text('Sign Out',
                    style: TextStyle(color: Colors.red, fontSize: 15)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSyncCard(Color accent) {
    final lastSyncStr = _lastSync == null
        ? 'Never synced'
        : 'Last synced: ${_formatSyncTime(_lastSync!)}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.sync, color: accent, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Offline Data Sync',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _isOnline
                      ? Colors.green.withOpacity(0.1)
                      : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _isOnline ? 'Online' : 'Offline',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _isOnline ? Colors.green[700] : Colors.orange[700],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            lastSyncStr,
            style: const TextStyle(fontSize: 12, color: Color(0xFF9E9E9E)),
          ),
          const SizedBox(height: 4),
          const Text(
            'Syncs products, orders, and your profile to local storage so the app works without internet.',
            style: TextStyle(fontSize: 12, color: Color(0xFF757575)),
          ),
          if (!OfflineSyncService().supported)
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text(
                'Offline sync is not available on web.',
                style: TextStyle(fontSize: 12, color: Colors.orange),
              ),
            )
          else ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 38,
              child: ElevatedButton.icon(
                onPressed: _isOnline ? _triggerSync : null,
                icon: const Icon(Icons.cloud_download_outlined, size: 16),
                label: const Text('Sync Now'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Reusable row widgets ──────────────────────────────────────────────────

  Widget _infoCard({required String title, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF9E9E9E),
                letterSpacing: 0.5,
              ),
            ),
          ),
          ...children,
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  Widget _readOnlyRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF9E9E9E)),
          const SizedBox(width: 12),
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF757575),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _editableRow({
    required IconData icon,
    required String label,
    required TextEditingController controller,
    required bool enabled,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: const Color(0xFF9E9E9E)),
          const SizedBox(width: 12),
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF757575),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: enabled
                ? TextFormField(
                    controller: controller,
                    keyboardType: keyboardType,
                    validator: validator,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      filled: true,
                      fillColor: const Color(0xFFF5F5F5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  )
                : ValueListenableBuilder<TextEditingValue>(
                    valueListenable: controller,
                    builder: (_, val, __) => Text(
                      val.text.isNotEmpty ? val.text : '—',
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  String _formatSyncTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
