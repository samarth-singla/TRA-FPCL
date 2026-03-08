import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../../services/farmer_service.dart';

/// Screen for RAE to view registered farmers and add new ones
class FarmerListScreen extends StatefulWidget {
  const FarmerListScreen({super.key});

  @override
  State<FarmerListScreen> createState() => _FarmerListScreenState();
}

class _FarmerListScreenState extends State<FarmerListScreen> {
  static const _green = Color(0xFF2E9B33);
  final _farmerService = FarmerService();
  final _uid = firebase_auth.FirebaseAuth.instance.currentUser?.uid ?? '';
  String _search = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: StreamBuilder<List<Farmer>>(
                stream: _farmerService.farmersStream(_uid),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final allFarmers = snapshot.data ?? [];
                  final farmers = _search.isEmpty
                      ? allFarmers
                      : allFarmers.where((f) {
                          final q = _search.toLowerCase();
                          return f.name.toLowerCase().contains(q) ||
                              f.village.toLowerCase().contains(q) ||
                              f.phone.contains(q) ||
                              f.cropType.toLowerCase().contains(q);
                        }).toList();

                  if (allFarmers.isEmpty) {
                    return _buildEmptyState();
                  }

                  return Column(
                    children: [
                      _buildStatsRow(allFarmers),
                      _buildSearchBar(),
                      Expanded(
                        child: farmers.isEmpty
                            ? Center(
                                child: Text('No farmers match "$_search"',
                                    style: TextStyle(
                                        color: Colors.grey[500],
                                        fontSize: 14)))
                            : ListView.builder(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 0, 16, 80),
                                itemCount: farmers.length,
                                itemBuilder: (_, i) =>
                                    _buildFarmerCard(farmers[i]),
                              ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditDialog(null),
        backgroundColor: _green,
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: const Text('Register Farmer',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }

  // ── Header ──

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
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('My Farmers',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold)),
                SizedBox(height: 2),
                Text('Manage registered farmers',
                    style: TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Stats Row ──

  Widget _buildStatsRow(List<Farmer> farmers) {
    final villages = farmers.map((f) => f.village).toSet().length;
    final totalLand = farmers.fold<double>(0, (s, f) => s + f.landArea);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          _statChip('${farmers.length}', 'Farmers', Icons.people, _green),
          const SizedBox(width: 10),
          _statChip('$villages', 'Villages', Icons.location_on,
              const Color(0xFF1565C0)),
          const SizedBox(width: 10),
          _statChip(totalLand.toStringAsFixed(1), 'Acres',
              Icons.landscape, const Color(0xFFF57C00)),
        ],
      ),
    );
  }

  Widget _statChip(String value, String label, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 6,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(value,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(label,
                style: TextStyle(fontSize: 11, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  // ── Search ──

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: TextField(
        onChanged: (v) => setState(() => _search = v),
        decoration: InputDecoration(
          hintText: 'Search by name, village, phone, crop...',
          hintStyle: TextStyle(fontSize: 13, color: Colors.grey[400]),
          prefixIcon: const Icon(Icons.search, size: 20),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none),
        ),
      ),
    );
  }

  // ── Farmer Card ──

  Widget _buildFarmerCard(Farmer farmer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
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
          Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 22,
                backgroundColor: _green.withOpacity(0.12),
                child: Text(
                  farmer.name.isNotEmpty ? farmer.name[0].toUpperCase() : '?',
                  style: TextStyle(
                      color: _green,
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(farmer.name,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.location_on,
                            size: 13, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text(farmer.village.isNotEmpty
                                ? farmer.village
                                : 'No village',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[500])),
                      ],
                    ),
                  ],
                ),
              ),
              // Actions
              PopupMenuButton<String>(
                onSelected: (action) {
                  if (action == 'edit') _showAddEditDialog(farmer);
                  if (action == 'delete') _confirmDelete(farmer);
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete',
                          style: TextStyle(color: Colors.red))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Info chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _infoChip(Icons.phone, farmer.phone.isNotEmpty
                  ? farmer.phone
                  : 'No phone'),
              _infoChip(Icons.grass, farmer.cropType.isNotEmpty
                  ? farmer.cropType
                  : 'No crop'),
              _infoChip(Icons.landscape,
                  '${farmer.landArea.toStringAsFixed(1)} acres'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey[600]),
          const SizedBox(width: 6),
          Text(text,
              style: TextStyle(fontSize: 12, color: Colors.grey[700])),
        ],
      ),
    );
  }

  // ── Empty State ──

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text('No farmers registered yet',
              style: TextStyle(fontSize: 16, color: Colors.grey[500])),
          const SizedBox(height: 8),
          Text('Tap the button below to register your first farmer',
              style: TextStyle(fontSize: 13, color: Colors.grey[400])),
        ],
      ),
    );
  }

  // ── Add / Edit Dialog ──

  void _showAddEditDialog(Farmer? existing) {
    final isEdit = existing != null;
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final villageCtrl = TextEditingController(text: existing?.village ?? '');
    final phoneCtrl = TextEditingController(text: existing?.phone ?? '');
    final cropCtrl = TextEditingController(text: existing?.cropType ?? '');
    final landCtrl = TextEditingController(
        text: existing != null ? existing.landArea.toStringAsFixed(1) : '');
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
                      // Handle bar
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        isEdit ? 'Edit Farmer' : 'Register New Farmer',
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),
                      // Name
                      TextFormField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Full Name *',
                          prefixIcon: Icon(Icons.person),
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 14),
                      // Village
                      TextFormField(
                        controller: villageCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Village *',
                          prefixIcon: Icon(Icons.location_on),
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 14),
                      // Phone
                      TextFormField(
                        controller: phoneCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Phone Number',
                          prefixIcon: Icon(Icons.phone),
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 14),
                      // Crop Type
                      TextFormField(
                        controller: cropCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Crop Type *',
                          prefixIcon: Icon(Icons.grass),
                          hintText: 'e.g. Cotton, Wheat, Paddy',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 14),
                      // Land Area
                      TextFormField(
                        controller: landCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Land Area (acres) *',
                          prefixIcon: Icon(Icons.landscape),
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Required';
                          if (double.tryParse(v) == null) {
                            return 'Enter a valid number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      // Submit
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: saving
                              ? null
                              : () async {
                                  if (!formKey.currentState!.validate()) return;
                                  setSheetState(() => saving = true);
                                  try {
                                    if (isEdit) {
                                      await _farmerService.updateFarmer(
                                        id: existing.id,
                                        name: nameCtrl.text.trim(),
                                        village: villageCtrl.text.trim(),
                                        phone: phoneCtrl.text.trim(),
                                        cropType: cropCtrl.text.trim(),
                                        landArea:
                                            double.parse(landCtrl.text.trim()),
                                      );
                                    } else {
                                      await _farmerService.addFarmer(
                                        raeUid: _uid,
                                        name: nameCtrl.text.trim(),
                                        village: villageCtrl.text.trim(),
                                        phone: phoneCtrl.text.trim(),
                                        cropType: cropCtrl.text.trim(),
                                        landArea:
                                            double.parse(landCtrl.text.trim()),
                                      );
                                    }
                                    if (ctx.mounted) Navigator.pop(ctx);
                                    if (mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(SnackBar(
                                        content: Text(isEdit
                                            ? 'Farmer updated'
                                            : 'Farmer registered successfully'),
                                        backgroundColor: _green,
                                      ));
                                    }
                                  } catch (e) {
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
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _green,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: saving
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white))
                              : Text(
                                  isEdit ? 'Save Changes' : 'Register Farmer',
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white),
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

  // ── Delete Confirmation ──

  void _confirmDelete(Farmer farmer) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Farmer'),
        content: Text('Remove ${farmer.name} from your registered farmers?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _farmerService.deleteFarmer(farmer.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Farmer removed'),
                    backgroundColor: Colors.red,
                  ));
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')));
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
