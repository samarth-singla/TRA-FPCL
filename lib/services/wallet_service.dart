import 'package:supabase_flutter/supabase_flutter.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Models
// ─────────────────────────────────────────────────────────────────────────────

class WalletInfo {
  final String id;
  final String userUid;
  final double balance;
  final DateTime createdAt;
  final DateTime updatedAt;

  const WalletInfo({
    required this.id,
    required this.userUid,
    required this.balance,
    required this.createdAt,
    required this.updatedAt,
  });

  factory WalletInfo.fromMap(Map<String, dynamic> map) {
    return WalletInfo(
      id: map['id']?.toString() ?? '',
      userUid: map['user_uid']?.toString() ?? '',
      balance: (map['balance'] as num?)?.toDouble() ?? 0.0,
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updated_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

class TransactionRecord {
  final String id;
  final String userUid;
  final String type; // 'deposit', 'payment', 'refund', 'withdrawal'
  final double amount;
  final double balanceAfter;
  final String? orderId;
  final String? referenceType;
  final String? referenceId;
  final String description;
  final String status; // 'pending', 'completed', 'failed'
  final String? notes;
  final DateTime createdAt;

  const TransactionRecord({
    required this.id,
    required this.userUid,
    required this.type,
    required this.amount,
    required this.balanceAfter,
    this.orderId,
    this.referenceType,
    this.referenceId,
    required this.description,
    required this.status,
    this.notes,
    required this.createdAt,
  });

  factory TransactionRecord.fromMap(Map<String, dynamic> map) {
    return TransactionRecord(
      id: map['id']?.toString() ?? '',
      userUid: map['user_uid']?.toString() ?? '',
      type: map['type']?.toString() ?? 'payment',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      balanceAfter: (map['balance_after'] as num?)?.toDouble() ?? 0.0,
      orderId: map['order_id']?.toString(),
      referenceType: map['reference_type']?.toString(),
      referenceId: map['reference_id']?.toString(),
      description: map['description']?.toString() ?? '',
      status: map['status']?.toString() ?? 'completed',
      notes: map['notes']?.toString(),
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  bool get isCredit => type == 'deposit' || type == 'refund';
  bool get isDebit => type == 'payment' || type == 'withdrawal';
}

// ─────────────────────────────────────────────────────────────────────────────
// Service
// ─────────────────────────────────────────────────────────────────────────────

/// Wallet Service — manages user wallet balances and transactions.
///
/// Key Operations:
/// - Get wallet balance
/// - Add funds (deposit)
/// - Deduct funds (payment)
/// - Refund funds
/// - Get transaction history
class WalletService {
  static final WalletService _instance = WalletService._internal();
  factory WalletService() => _instance;
  WalletService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;

  // ─── Get Wallet ────────────────────────────────────────────────────────────

  /// Fetch wallet info for a user. Creates one if it doesn't exist.
  Future<WalletInfo> getWallet(String userUid) async {
    try {
      final row = await _supabase
          .from('wallets')
          .select()
          .eq('user_uid', userUid)
          .maybeSingle();

      if (row != null) {
        return WalletInfo.fromMap(row);
      }

      // Create wallet if it doesn't exist
      final newWallet = await _supabase
          .from('wallets')
          .insert({
            'user_uid': userUid,
            'balance': 0.0,
          })
          .select()
          .single();

      return WalletInfo.fromMap(newWallet);
    } catch (e) {
      print('⚠️ WalletService.getWallet error: $e');
      rethrow;
    }
  }

  /// Get current balance for a user
  Future<double> getBalance(String userUid) async {
    final wallet = await getWallet(userUid);
    return wallet.balance;
  }

  // ─── Deposits ──────────────────────────────────────────────────────────────

  /// Add funds to wallet (manual deposit, recharge, etc.)
  Future<TransactionRecord> deposit({
    required String userUid,
    required double amount,
    required String description,
    String? notes,
  }) async {
    if (amount <= 0) {
      throw Exception('Deposit amount must be positive');
    }

    try {
      // Get current wallet
      final wallet = await getWallet(userUid);
      final newBalance = wallet.balance + amount;

      // Update wallet balance
      await _supabase
          .from('wallets')
          .update({'balance': newBalance})
          .eq('user_uid', userUid);

      // Create transaction record
      final txnData = {
        'user_uid': userUid,
        'type': 'deposit',
        'amount': amount,
        'balance_after': newBalance,
        'reference_type': 'manual_deposit',
        'description': description,
        'status': 'completed',
        'notes': notes,
      };

      final txnRow = await _supabase
          .from('transactions')
          .insert(txnData)
          .select()
          .single();

      return TransactionRecord.fromMap(txnRow);
    } catch (e) {
      print('⚠️ WalletService.deposit error: $e');
      rethrow;
    }
  }

  // ─── Payments ──────────────────────────────────────────────────────────────

  /// Deduct funds from wallet for an order payment
  /// Returns the transaction record if successful
  Future<TransactionRecord> makePayment({
    required String userUid,
    required double amount,
    required String orderId,
    required String description,
    String? notes,
  }) async {
    if (amount <= 0) {
      throw Exception('Payment amount must be positive');
    }

    try {
      // Get current wallet
      final wallet = await getWallet(userUid);

      // Check if sufficient balance
      if (wallet.balance < amount) {
        throw Exception(
            'Insufficient balance. Available: ₹${wallet.balance.toStringAsFixed(2)}, Required: ₹${amount.toStringAsFixed(2)}');
      }

      final newBalance = wallet.balance - amount;

      // Update wallet balance
      await _supabase
          .from('wallets')
          .update({'balance': newBalance})
          .eq('user_uid', userUid);

      // Create transaction record
      final txnData = {
        'user_uid': userUid,
        'type': 'payment',
        'amount': amount,
        'balance_after': newBalance,
        'order_id': orderId,
        'reference_type': 'order_payment',
        'description': description,
        'status': 'completed',
        'notes': notes,
      };

      final txnRow = await _supabase
          .from('transactions')
          .insert(txnData)
          .select()
          .single();

      return TransactionRecord.fromMap(txnRow);
    } catch (e) {
      print('⚠️ WalletService.makePayment error: $e');
      rethrow;
    }
  }

  // ─── Refunds ───────────────────────────────────────────────────────────────

  /// Refund funds to wallet (e.g., when order is rejected after payment)
  Future<TransactionRecord> refund({
    required String userUid,
    required double amount,
    required String orderId,
    required String description,
    String? notes,
  }) async {
    if (amount <= 0) {
      throw Exception('Refund amount must be positive');
    }

    try {
      // Get current wallet
      final wallet = await getWallet(userUid);
      final newBalance = wallet.balance + amount;

      // Update wallet balance
      await _supabase
          .from('wallets')
          .update({'balance': newBalance})
          .eq('user_uid', userUid);

      // Create transaction record
      final txnData = {
        'user_uid': userUid,
        'type': 'refund',
        'amount': amount,
        'balance_after': newBalance,
        'order_id': orderId,
        'reference_type': 'order_refund',
        'description': description,
        'status': 'completed',
        'notes': notes,
      };

      final txnRow = await _supabase
          .from('transactions')
          .insert(txnData)
          .select()
          .single();

      return TransactionRecord.fromMap(txnRow);
    } catch (e) {
      print('⚠️ WalletService.refund error: $e');
      rethrow;
    }
  }

  // ─── Transaction History ───────────────────────────────────────────────────

  /// Get transaction history for a user
  Future<List<TransactionRecord>> getTransactions({
    required String userUid,
    int limit = 50,
    String? type, // Filter by type if provided
  }) async {
    try {
      var query = _supabase
          .from('transactions')
          .select()
          .eq('user_uid', userUid)
          .order('created_at', ascending: false)
          .limit(limit);

      if (type != null) {
        query = query.eq('type', type);
      }

      final rows = await query;
      return (rows as List).map((r) => TransactionRecord.fromMap(r)).toList();
    } catch (e) {
      print('⚠️ WalletService.getTransactions error: $e');
      return [];
    }
  }

  /// Stream of wallet balance changes
  Stream<WalletInfo> walletStream(String userUid) {
    return _supabase
        .from('wallets')
        .stream(primaryKey: ['id'])
        .eq('user_uid', userUid)
        .map((rows) {
          if (rows.isEmpty) {
            // Return default wallet if none exists
            return WalletInfo(
              id: '',
              userUid: userUid,
              balance: 0.0,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );
          }
          return WalletInfo.fromMap(rows.first);
        });
  }

  /// Stream of transactions
  Stream<List<TransactionRecord>> transactionsStream(String userUid) {
    return _supabase
        .from('transactions')
        .stream(primaryKey: ['id'])
        .eq('user_uid', userUid)
        .order('created_at', ascending: false)
        .limit(50)
        .map((rows) => 
            (rows as List).map((r) => TransactionRecord.fromMap(r)).toList());
  }
}
