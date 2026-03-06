import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Screen for RAE to request advisory help from district SMEs
class RequestAdvisoryScreen extends StatefulWidget {
  const RequestAdvisoryScreen({super.key});

  @override
  State<RequestAdvisoryScreen> createState() => _RequestAdvisoryScreenState();
}

class _RequestAdvisoryScreenState extends State<RequestAdvisoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _topicController = TextEditingController();
  bool _isLoading = false;
  bool _hasActiveSending = false;

  @override
  void initState() {
    super.initState();
    _checkExistingRequest();
  }

  @override
  void dispose() {
    _topicController.dispose();
    super.dispose();
  }

  /// Check if RAE already has a pending request
  Future<void> _checkExistingRequest() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      final response = await Supabase.instance.client
          .from('conversations')
          .select('id, status')
          .eq('rae_uid', uid)
          .inFilter('status', ['pending', 'active'])
          .maybeSingle();

      if (mounted && response != null) {
        setState(() {
          _hasActiveSending = true;
        });
      }
    } catch (e) {
      debugPrint('Error checking existing request: $e');
    }
  }

  /// Send advisory request to district SMEs
  Future<void> _sendRequest() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Get RAE profile to fetch name, code, district
      final profileResponse = await Supabase.instance.client
          .from('profiles')
          .select('name, district')
          .eq('uid', user.uid)
          .single();

      final raeName = profileResponse['name'] as String? ?? 'RAE';
      final raeDistrict = profileResponse['district'] as String? ?? '';

      if (raeDistrict.isEmpty) {
        throw Exception('Your district information is missing. Please contact admin.');
      }

      // Create pending conversation
      await Supabase.instance.client.from('conversations').insert({
        'rae_uid': user.uid,
        'sme_uid': null, // Will be assigned when SME accepts
        'rae_name': raeName,
        'rae_code': user.phoneNumber ?? '',
        'rae_district': raeDistrict,
        'status': 'pending',
        'last_message': _topicController.text.trim(),
        'last_message_at': DateTime.now().toIso8601String(),
        'unread_count': 0,
        'is_resolved': false,
      });

      if (!mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Advisory request sent to district SMEs!'),
          backgroundColor: Colors.green,
        ),
      );

      // Go back to dashboard
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Advisory'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: _hasActiveSending
          ? _buildActiveRequestView()
          : _buildRequestForm(),
    );
  }

  /// Show message if RAE already has active/pending request
  Widget _buildActiveRequestView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.pending_actions,
              size: 80,
              color: Colors.orange.shade600,
            ),
            const SizedBox(height: 24),
            const Text(
              'You already have an active or pending advisory request',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Please wait for an SME to accept your request, or resolve your current conversation before creating a new one.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
              ),
              child: const Text('Back to Dashboard'),
            ),
          ],
        ),
      ),
    );
  }

  /// Form for creating new advisory request
  Widget _buildRequestForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Info card
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.blue.shade700,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Your request will be sent to all SMEs in your district. The first available SME will accept and start chatting with you.',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Topic / Issue field
            TextFormField(
              controller: _topicController,
              decoration: InputDecoration(
                labelText: 'Topic / Issue',
                hintText: 'Briefly describe what you need help with',
                prefixIcon: const Icon(Icons.topic),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              maxLines: 4,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please describe your issue';
                }
                if (value.trim().length < 10) {
                  return 'Please provide more details (min 10 characters)';
                }
                return null;
              },
            ),
            const SizedBox(height: 32),

            // Send Request button
            ElevatedButton(
              onPressed: _isLoading ? null : _sendRequest,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Send Request',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
