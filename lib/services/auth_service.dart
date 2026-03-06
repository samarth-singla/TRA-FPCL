import 'dart:async';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();
  final firebase_auth.FirebaseAuth _firebaseAuth = firebase_auth.FirebaseAuth.instance;
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Current Firebase user
  firebase_auth.User? get currentUser => _firebaseAuth.currentUser;

  /// Current Supabase user
  User? get currentSupabaseUser => _supabase.auth.currentUser;

  /// Verification ID for phone auth
  String? _verificationId;

  /// Selected role — set BEFORE sendOTP so verificationCompleted can use it
  String? _selectedRole;

  /// SharedPreferences key for persisting role across app restarts
  static const _roleKey = 'user_role';

  // -----------------------------------------------------------------------
  // Role helpers
  // -----------------------------------------------------------------------

  /// Call this in PhoneLoginScreen BEFORE sendOTP so the auto-verification
  /// callback (verificationCompleted) already has the correct role.
  void setRole(String role) {
    _selectedRole = role;
    print('🏷️ Role pre-set to: $role');
  }

  /// Persist role to device storage.
  Future<void> cacheRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_roleKey, role);
    print('💾 Role cached locally: $role');
  }

  /// Read the locally cached role. Returns null if never set.
  Future<String?> getCachedRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_roleKey);
  }

  /// Clear cached role on sign-out.
  Future<void> clearCachedRole() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_roleKey);
    print('🗑️ Cached role cleared');
  }

  /// Send OTP to phone number.
  /// Uses a Completer so this method only returns AFTER codeSent fires,
  /// ensuring _verificationId is always set before the OTP screen is shown.
  Future<bool> sendOTP(String phoneNumber) async {
    print('📱 Sending OTP to: $phoneNumber');
    print('ℹ️ Only Firebase test numbers work without billing enabled.');

    final completer = Completer<bool>();

    await _firebaseAuth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (firebase_auth.PhoneAuthCredential credential) async {
        // Auto-verification (Android only) — sign in immediately.
        print('✅ Auto verification completed');
        try {
          await _signInWithCredential(credential);
        } catch (e) {
          print('❌ Auto sign-in failed: $e');
        }
        if (!completer.isCompleted) completer.complete(true);
      },
      verificationFailed: (firebase_auth.FirebaseAuthException e) {
        print('❌ Verification failed: ${e.code} - ${e.message}');
        if (completer.isCompleted) return;
        if (e.code == 'invalid-phone-number') {
          completer.completeError(
              Exception('Invalid phone number. Use format: +91XXXXXXXXXX'));
        } else if (e.message?.contains('BILLING_NOT_ENABLED') == true) {
          completer.completeError(Exception(
              'Real phone numbers require Firebase billing (Blaze plan). '
              'Please use a Firebase test number instead.'));
        } else {
          completer.completeError(Exception('Verification failed: ${e.message}'));
        }
      },
      codeSent: (String verificationId, int? resendToken) {
        print('✅ OTP sent! Verification ID: ${verificationId.substring(0, 10)}...');
        _verificationId = verificationId;
        if (!completer.isCompleted) completer.complete(true);
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        print('⏱️ Auto-retrieval timeout');
        _verificationId = verificationId;
      },
      timeout: const Duration(seconds: 60),
    );

    // Wait for codeSent or verificationFailed before returning.
    return completer.future;
  }

  /// Verify OTP and sign in with selected role
  /// Returns true if sign-in was successful
  Future<bool> verifyOTPWithRole(String otp, String role) async {
    try {
      print('🔐 Verifying OTP: $otp for role: $role');
      
      if (_verificationId == null) {
        print('❌ No verification ID found');
        throw Exception('Verification ID not found. Please request OTP first.');
      }

      print('✓ Verification ID exists: ${_verificationId!.substring(0, 10)}...');

      // Store the role for profile creation
      _selectedRole = role;

      final credential = firebase_auth.PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp,
      );

      print('📝 Credential created, attempting sign in...');
      await _signInWithCredential(credential);
      print('✅ Sign in successful!');
      return true;
    } on firebase_auth.FirebaseAuthException catch (e) {
      print('❌ Firebase Auth error: ${e.code} - ${e.message}');
      if (e.code == 'invalid-verification-code') {
        throw Exception('Invalid OTP code. Please check:\n'
            '1. For test numbers: Enter the exact code from Firebase Console\n'
            '2. For real numbers: Check the SMS you received');
      } else if (e.code == 'session-expired') {
        throw Exception('OTP session expired. Please request a new OTP.');
      }
      throw Exception('Verification failed: ${e.message}');
    } catch (e) {
      print('❌ OTP verification error: $e');
      throw Exception('Failed to verify OTP: $e');
    }
  }

  /// Verify OTP and sign in
  /// Returns true if sign-in was successful
  Future<bool> verifyOTP(String otp) async {
    return verifyOTPWithRole(otp, 'RAE'); // Default role
  }

  /// Sign in with phone credential
  Future<void> _signInWithCredential(firebase_auth.PhoneAuthCredential credential) async {
    try {
      print('🔄 Signing in with credential...');
      
      // Sign in with Firebase
      final userCredential = await _firebaseAuth.signInWithCredential(credential);
      final user = userCredential.user;
      
      print('👤 Firebase user: ${user?.uid}');

      if (user == null) {
        print('❌ User is null after sign-in');
        throw Exception('User is null after sign-in');
      }

      // Check and create profile in Supabase
      await _ensureProfileExists(user.uid, user.phoneNumber);
    } catch (e) {
      throw Exception('Sign-in failed: $e');
    }
  }

  /// Check if profile exists in Supabase.
  /// - If it doesn't exist: create it with the selected role.
  /// - If it exists AND the user selected a different role at login: update it.
  ///   This allows role switching during development / multi-role accounts.
  Future<void> _ensureProfileExists(String uid, String? phoneNumber) async {
    try {
      print('📊 Checking profile for UID: $uid');

      final response = await _supabase
          .from('profiles')
          .select()
          .eq('uid', uid)
          .maybeSingle();

      final selectedRole = _selectedRole ?? 'RAE';

      if (response == null) {
        // ── New user: create profile ──────────────────────────────
        print('📝 Creating new profile with role: $selectedRole');
        await _supabase.from('profiles').insert({
          'uid': uid,
          'phone': phoneNumber ?? '',
          'role': selectedRole,
          'created_at': DateTime.now().toIso8601String(),
        });
        print('✅ New profile created for UID: $uid with role: $selectedRole');
      } else {
        // ── Existing user: update role if it changed ──────────────
        final storedRole = response['role']?.toString() ?? 'RAE';
        if (_selectedRole != null && _selectedRole != storedRole) {
          print('🔄 Role changed: $storedRole → $selectedRole. Updating profile…');
          await _supabase.from('profiles').update({
            'role': selectedRole,
            'updated_at': DateTime.now().toIso8601String(),
          }).eq('uid', uid);
          print('✅ Profile role updated to: $selectedRole');
        } else {
          print('ℹ️ Profile exists with role: $storedRole (no change)');
        }
      }

      // ── Always cache the role locally so routing survives Supabase failures
      await cacheRole(selectedRole);

      // Always clear the in-memory role selection after use
      _selectedRole = null;
    } on SocketException catch (e) {
      print('⚠️ Network error syncing profile: $e');
      // Still cache whatever role we intended to use
      if (_selectedRole != null) await cacheRole(_selectedRole!);
      _selectedRole = null;
      print('💡 Role cached locally. Supabase will sync on next login.');
      // Don't throw — Firebase auth succeeded, let the user in
    } catch (e) {
      print('⚠️ Error ensuring profile exists: $e');
      // Still cache whatever role we intended to use
      if (_selectedRole != null) await cacheRole(_selectedRole!);
      _selectedRole = null;
      print('💡 Firebase authentication successful. Profile sync will retry later.');
    }
  }

  /// Get user profile from Supabase
  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final user = currentUser;
      if (user == null) return null;

      final response = await _supabase
          .from('profiles')
          .select()
          .eq('uid', user.uid)
          .maybeSingle();

      return response;
    } catch (e) {
      throw Exception('Failed to get user profile: $e');
    }
  }

  /// Update user profile
  Future<void> updateProfile({
    String? name,
    String? email,
    String? role,
  }) async {
    try {
      final user = currentUser;
      if (user == null) throw Exception('No user signed in');

      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (name != null) updates['name'] = name;
      if (email != null) updates['email'] = email;
      if (role != null) updates['role'] = role;

      await _supabase
          .from('profiles')
          .update(updates)
          .eq('uid', user.uid);
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  /// Sign out from both Firebase and Supabase and clear local cache
  Future<void> signOut() async {
    try {
      await clearCachedRole();
      await _firebaseAuth.signOut();
      await _supabase.auth.signOut();
    } catch (e) {
      throw Exception('Failed to sign out: $e');
    }
  }

  /// Check if user is signed in
  bool isSignedIn() {
    return currentUser != null;
  }

  /// Stream of auth state changes
  Stream<firebase_auth.User?> authStateChanges() {
    return _firebaseAuth.authStateChanges();
  }
}
