import 'package:supabase_flutter/supabase_flutter.dart';

/// Model for an advisory/alert sent by an SME
class Advisory {
  final String id;
  final String smeUid;
  final String district;
  final String title;
  final String content;
  final DateTime createdAt;
  // Joined from profiles for display
  final String smeName;

  Advisory({
    required this.id,
    required this.smeUid,
    required this.district,
    required this.title,
    required this.content,
    required this.createdAt,
    this.smeName = '',
  });

  factory Advisory.fromMap(Map<String, dynamic> map) {
    return Advisory(
      id: map['id']?.toString() ?? '',
      smeUid: map['sme_uid']?.toString() ?? '',
      district: map['district']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      content: map['content']?.toString() ?? '',
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ??
          DateTime.now(),
      smeName: map['sme_name']?.toString() ?? '',
    );
  }
}

/// Service for advisories/alerts
class AdvisoryService {
  static final AdvisoryService _instance = AdvisoryService._();
  AdvisoryService._();
  factory AdvisoryService() => _instance;

  final _supabase = Supabase.instance.client;

  /// Realtime stream of advisories for a district (RAE-side: see advisories for their district)
  Stream<List<Advisory>> advisoriesForDistrictStream(String district) {
    return _supabase
        .from('advisories')
        .stream(primaryKey: ['id'])
        .map((rows) {
      final filtered = rows
          .where((r) =>
              r['district']?.toString().toLowerCase() ==
              district.toLowerCase())
          .map((r) => Advisory.fromMap(r))
          .toList();
      filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return filtered;
    });
  }

  /// Realtime stream of advisories posted by this SME
  Stream<List<Advisory>> advisoriesBySmeStream(String smeUid) {
    return _supabase
        .from('advisories')
        .stream(primaryKey: ['id'])
        .map((rows) {
      final filtered = rows
          .where((r) => r['sme_uid'] == smeUid)
          .map((r) => Advisory.fromMap(r))
          .toList();
      filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return filtered;
    });
  }

  /// Get advisories for a district (one-shot, with SME name joined)
  Future<List<Advisory>> getAdvisoriesForDistrict(String district) async {
    final data = await _supabase
        .from('advisories')
        .select()
        .ilike('district', district)
        .order('created_at', ascending: false);
    final advisories =
        (data as List).map((r) => Advisory.fromMap(r)).toList();

    // Enrich with SME names
    final smeUids = advisories.map((a) => a.smeUid).toSet().toList();
    if (smeUids.isNotEmpty) {
      final profiles = await _supabase
          .from('profiles')
          .select('uid, name')
          .inFilter('uid', smeUids);
      final nameMap = <String, String>{};
      for (final p in profiles) {
        nameMap[p['uid']?.toString() ?? ''] = p['name']?.toString() ?? '';
      }
      return advisories
          .map((a) => Advisory(
                id: a.id,
                smeUid: a.smeUid,
                district: a.district,
                title: a.title,
                content: a.content,
                createdAt: a.createdAt,
                smeName: nameMap[a.smeUid] ?? '',
              ))
          .toList();
    }
    return advisories;
  }

  /// Post a new advisory (SME flow)
  Future<void> postAdvisory({
    required String smeUid,
    required String district,
    required String title,
    required String content,
  }) async {
    await _supabase.from('advisories').insert({
      'sme_uid': smeUid,
      'district': district,
      'title': title,
      'content': content,
    });
  }

  /// Delete an advisory
  Future<void> deleteAdvisory(String id) async {
    await _supabase.from('advisories').delete().eq('id', id);
  }
}
