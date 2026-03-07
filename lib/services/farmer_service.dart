import 'package:supabase_flutter/supabase_flutter.dart';

/// Model for a registered farmer
class Farmer {
  final String id;
  final String raeUid;
  final String name;
  final String village;
  final String phone;
  final String cropType;
  final double landArea;
  final DateTime createdAt;

  Farmer({
    required this.id,
    required this.raeUid,
    required this.name,
    required this.village,
    required this.phone,
    required this.cropType,
    required this.landArea,
    required this.createdAt,
  });

  factory Farmer.fromMap(Map<String, dynamic> map) {
    return Farmer(
      id: map['id']?.toString() ?? '',
      raeUid: map['rae_uid']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      village: map['village']?.toString() ?? '',
      phone: map['phone']?.toString() ?? '',
      cropType: map['crop_type']?.toString() ?? '',
      landArea: (map['land_area'] as num?)?.toDouble() ?? 0,
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

/// Service for farmer registration (RAE flow)
class FarmerService {
  static final FarmerService _instance = FarmerService._();
  FarmerService._();
  factory FarmerService() => _instance;

  final _supabase = Supabase.instance.client;

  /// Realtime stream of all farmers for a given RAE
  Stream<List<Farmer>> farmersStream(String raeUid) {
    return _supabase
        .from('farmers')
        .stream(primaryKey: ['id'])
        .map((rows) {
          final filtered = rows
              .where((r) => r['rae_uid'] == raeUid)
              .map((r) => Farmer.fromMap(r))
              .toList();
          filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return filtered;
        });
  }

  /// Get all farmers for this RAE (one-shot)
  Future<List<Farmer>> getFarmers(String raeUid) async {
    final data = await _supabase
        .from('farmers')
        .select()
        .eq('rae_uid', raeUid)
        .order('created_at', ascending: false);
    return (data as List).map((r) => Farmer.fromMap(r)).toList();
  }

  /// Register a new farmer
  Future<void> addFarmer({
    required String raeUid,
    required String name,
    required String village,
    required String phone,
    required String cropType,
    required double landArea,
  }) async {
    await _supabase.from('farmers').insert({
      'rae_uid': raeUid,
      'name': name,
      'village': village,
      'phone': phone,
      'crop_type': cropType,
      'land_area': landArea,
    });
  }

  /// Update an existing farmer
  Future<void> updateFarmer({
    required String id,
    required String name,
    required String village,
    required String phone,
    required String cropType,
    required double landArea,
  }) async {
    await _supabase.from('farmers').update({
      'name': name,
      'village': village,
      'phone': phone,
      'crop_type': cropType,
      'land_area': landArea,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', id);
  }

  /// Delete a farmer
  Future<void> deleteFarmer(String id) async {
    await _supabase.from('farmers').delete().eq('id', id);
  }

  /// Get stats for this RAE's farmers
  Future<Map<String, dynamic>> getFarmerStats(String raeUid) async {
    final farmers = await getFarmers(raeUid);
    final villages = farmers.map((f) => f.village).toSet();
    final totalLand = farmers.fold<double>(0, (s, f) => s + f.landArea);
    return {
      'totalFarmers': farmers.length,
      'villages': villages.length,
      'totalLand': totalLand,
    };
  }
}
