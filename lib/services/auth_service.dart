import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
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
  
  /// Selected role for new user registration
  String? _selectedRole;

  /// Send OTP to phone number
  /// Returns true if OTP was sent successfully
  Future<bool> sendOTP(String phoneNumber) async {
    try {
      print('📱 Sending OTP to: $phoneNumber');
      print('ℹ️ If using test number, enter the test code you configured in Firebase');
      
      await _firebaseAuth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (firebase_auth.PhoneAuthCredential credential) async {
          // Auto-verification completed (Android only)
          print('✅ Auto verification completed');
          await _signInWithCredential(credential);
        },
        verificationFailed: (firebase_auth.FirebaseAuthException e) {
          print('❌ Verification failed: ${e.code} - ${e.message}');
          if (e.code == 'invalid-phone-number') {
            throw Exception('Invalid phone number format. Use: +919999999999');
          }
          throw Exception('Verification failed: ${e.message}');
        },
        codeSent: (String verificationId, int? resendToken) {
          print('✅ OTP sent! Verification ID: ${verificationId.substring(0, 10)}...');
          print('📝 For test numbers: Enter your configured test code (e.g., 123456)');
          _verificationId = verificationId;
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          print('⏱️ Auto-retrieval timeout');
          _verificationId = verificationId;
        },
        timeout: const Duration(seconds: 60),
      );
      return true;
    } catch (e) {
      print('❌ Failed to send OTP: $e');
      throw Exception('Failed to send OTP: $e');
    }
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

  /// Check if profile exists in Supabase, create if it doesn't
  Future<void> _ensureProfileExists(String uid, String? phoneNumber) async {
    try {
      print('📊 Checking profile for UID: $uid');
      
      // Check if profile exists
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('uid', uid)
          .maybeSingle();

      if (response == null) {
        // Profile doesn't exist, create it with the selected role
        final role = _selectedRole ?? 'RAE'; // Use selected role or default to RAE
        
        print('📝 Creating new profile with role: $role');
        
        await _supabase.from('profiles').insert({
          'uid': uid,
          'phone': phoneNumber ?? '',
          'role': role,
          'created_at': DateTime.now().toIso8601String(),
        });

        print('✅ New profile created for UID: $uid with role: $role');
        
        // Clear the selected role after use
        _selectedRole = null;
      } else {
        print('ℹ️ Profile already exists for UID: $uid');
      }
    } on SocketException catch (e) {
      print('⚠️ Network error creating profile: $e');
      print('💡 Continuing without Supabase - profile will be created on next login');
      // Don't throw - allow user to proceed
    } catch (e) {
      print('⚠️ Error ensuring profile exists: $e');
      // Don't throw - allow Firebase auth to succeed even if Supabase fails
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

  /// Sign out from both Firebase and Supabase
  Future<void> signOut() async {
    try {
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
