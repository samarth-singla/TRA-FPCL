import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Offline Sync Service
///
/// Caches key Supabase tables into a local SQLite database so the app can
/// display stale data when the device is offline. Uses sqflite (mobile only —
/// falls back to no-op on web).
///
/// Tables cached: profiles, products, orders, order_items, notifications.
///
/// Usage:
///   await OfflineSyncService().init();
///   await OfflineSyncService().syncAll(uid);       // call after login
///   final products = await OfflineSyncService().getLocalProducts();
class OfflineSyncService {
  static final OfflineSyncService _instance = OfflineSyncService._internal();
  factory OfflineSyncService() => _instance;
  OfflineSyncService._internal();

  static const _dbName = 'tra_fpcl_offline.db';
  static const _dbVersion = 1;
  static const _lastSyncKey = 'offline_last_sync';

  Database? _db;

  // ── Public getters ────────────────────────────────────────────────────────

  /// true if this platform supports SQLite (mobile). Web returns false.
  bool get supported => !kIsWeb;

  // ── Init ─────────────────────────────────────────────────────────────────

  /// Must be called once at app startup (after Supabase.initialize).
  Future<void> init() async {
    if (!supported) return;
    if (_db != null) return; // Already open

    final dbPath = p.join(await getDatabasesPath(), _dbName);
    _db = await openDatabase(
      dbPath,
      version: _dbVersion,
      onCreate: _createTables,
    );
  }

  Future<void> _createTables(Database db, int version) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS profiles (
        uid TEXT PRIMARY KEY,
        phone TEXT,
        role TEXT,
        name TEXT,
        email TEXT,
        district TEXT,
        synced_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS products (
        id TEXT PRIMARY KEY,
        name TEXT,
        category TEXT,
        price REAL,
        unit TEXT,
        description TEXT,
        stock_quantity INTEGER,
        is_active INTEGER,
        image_url TEXT,
        data_json TEXT,
        synced_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS orders (
        id TEXT PRIMARY KEY,
        rae_uid TEXT,
        status TEXT,
        total_amount REAL,
        notes TEXT,
        created_at TEXT,
        updated_at TEXT,
        data_json TEXT,
        synced_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS order_items (
        id TEXT PRIMARY KEY,
        order_id TEXT,
        product_id TEXT,
        product_name TEXT,
        quantity INTEGER,
        unit_price REAL,
        total_price REAL,
        data_json TEXT,
        synced_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS notifications (
        id TEXT PRIMARY KEY,
        uid TEXT,
        title TEXT,
        body TEXT,
        is_read INTEGER,
        created_at TEXT,
        data_json TEXT,
        synced_at TEXT
      )
    ''');
  }

  // ── Connectivity check ────────────────────────────────────────────────────

  Future<bool> isOnline() async {
    final result = await Connectivity().checkConnectivity();
    return result.any((c) =>
        c == ConnectivityResult.wifi ||
        c == ConnectivityResult.mobile ||
        c == ConnectivityResult.ethernet);
  }

  // ── Sync (online → local) ─────────────────────────────────────────────────

  /// Sync all relevant tables for [uid]. Safe to call even if offline (no-op).
  Future<void> syncAll(String uid) async {
    if (!supported || _db == null) return;
    if (!(await isOnline())) return;

    await Future.wait([
      syncProfile(uid),
      syncProducts(),
      syncOrders(uid),
      syncNotifications(uid),
    ]);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());
  }

  Future<void> syncProfile(String uid) async {
    if (!supported || _db == null) return;
    try {
      final row = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('uid', uid)
          .maybeSingle();
      if (row == null) return;
      await _db!.insert(
        'profiles',
        {
          'uid': row['uid']?.toString() ?? uid,
          'phone': row['phone']?.toString() ?? '',
          'role': row['role']?.toString() ?? '',
          'name': row['name']?.toString() ?? '',
          'email': row['email']?.toString() ?? '',
          'district': row['district']?.toString() ?? '',
          'synced_at': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (_) {}
  }

  Future<void> syncProducts() async {
    if (!supported || _db == null) return;
    try {
      final rows = await Supabase.instance.client
          .from('products')
          .select()
          .eq('is_active', true)
          .order('name');
      final now = DateTime.now().toIso8601String();
      final batch = _db!.batch();
      for (final row in rows) {
        batch.insert(
          'products',
          {
            'id': row['id']?.toString() ?? '',
            'name': row['name']?.toString() ?? '',
            'category': row['category']?.toString() ?? '',
            'price': (row['price'] as num?)?.toDouble() ?? 0.0,
            'unit': row['unit']?.toString() ?? '',
            'description': row['description']?.toString() ?? '',
            'stock_quantity': (row['stock_quantity'] as num?)?.toInt() ?? 0,
            'is_active': (row['is_active'] == true) ? 1 : 0,
            'image_url': row['image_url']?.toString() ?? '',
            'data_json': jsonEncode(row),
            'synced_at': now,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    } catch (_) {}
  }

  Future<void> syncOrders(String uid) async {
    if (!supported || _db == null) return;
    try {
      final rows = await Supabase.instance.client
          .from('orders')
          .select()
          .eq('rae_uid', uid)
          .order('created_at', ascending: false)
          .limit(100);
      final now = DateTime.now().toIso8601String();
      final batch = _db!.batch();
      for (final row in rows) {
        batch.insert(
          'orders',
          {
            'id': row['id']?.toString() ?? '',
            'rae_uid': row['rae_uid']?.toString() ?? uid,
            'status': row['status']?.toString() ?? '',
            'total_amount':
                (row['total_amount'] ?? row['total'] as num? ?? 0).toDouble(),
            'notes': row['notes']?.toString() ?? '',
            'created_at': row['created_at']?.toString() ?? '',
            'updated_at': row['updated_at']?.toString() ?? '',
            'data_json': jsonEncode(row),
            'synced_at': now,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    } catch (_) {}
  }

  Future<void> syncNotifications(String uid) async {
    if (!supported || _db == null) return;
    try {
      final rows = await Supabase.instance.client
          .from('notifications')
          .select()
          .eq('uid', uid)
          .order('created_at', ascending: false)
          .limit(50);
      final now = DateTime.now().toIso8601String();
      final batch = _db!.batch();
      for (final row in rows) {
        batch.insert(
          'notifications',
          {
            'id': row['id']?.toString() ?? '',
            'uid': row['uid']?.toString() ?? uid,
            'title': row['title']?.toString() ?? '',
            'body': row['body']?.toString() ?? '',
            'is_read': (row['is_read'] == true) ? 1 : 0,
            'created_at': row['created_at']?.toString() ?? '',
            'data_json': jsonEncode(row),
            'synced_at': now,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    } catch (_) {}
  }

  // ── Local reads (work offline) ────────────────────────────────────────────

  Future<Map<String, dynamic>?> getLocalProfile(String uid) async {
    if (!supported || _db == null) return null;
    final rows = await _db!.query(
      'profiles',
      where: 'uid = ?',
      whereArgs: [uid],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first;
  }

  Future<List<Map<String, dynamic>>> getLocalProducts({String? category}) async {
    if (!supported || _db == null) return [];
    if (category != null && category.isNotEmpty) {
      return _db!.query(
        'products',
        where: 'is_active = 1 AND category = ?',
        whereArgs: [category],
        orderBy: 'name ASC',
      );
    }
    return _db!.query(
      'products',
      where: 'is_active = 1',
      orderBy: 'name ASC',
    );
  }

  Future<List<Map<String, dynamic>>> getLocalOrders(String uid) async {
    if (!supported || _db == null) return [];
    return _db!.query(
      'orders',
      where: 'rae_uid = ?',
      whereArgs: [uid],
      orderBy: 'created_at DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getLocalNotifications(String uid) async {
    if (!supported || _db == null) return [];
    return _db!.query(
      'notifications',
      where: 'uid = ?',
      whereArgs: [uid],
      orderBy: 'created_at DESC',
      limit: 30,
    );
  }

  // ── Pending write queue (offline writes) ──────────────────────────────────

  /// Returns DateTime of last successful sync, or null if never synced.
  Future<DateTime?> lastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    final s = prefs.getString(_lastSyncKey);
    return s == null ? null : DateTime.tryParse(s);
  }

  // ── Cleanup ───────────────────────────────────────────────────────────────

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
