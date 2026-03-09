import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'firebase_options.dart';
import 'dart:async';
import 'services/auth_service.dart';
import 'screens/admin/admin_dashboard.dart';

/// ─────────────────────────────────────────────────────────────────────────
/// FPCL Admin Web Portal — entry point
///
/// Run:   flutter run -t lib/admin_main.dart -d chrome
/// Build: flutter build web --target lib/admin_main.dart --output build/admin_web
/// ─────────────────────────────────────────────────────────────────────────

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await Supabase.initialize(
    url: 'https://hwlwxzyrcaxjjlnnokxk.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imh3bHd4enlyY2F4ampsbm5va3hrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzI3NjcxMDgsImV4cCI6MjA4ODM0MzEwOH0.RnR9KTt-tUVej8qSkOMCpiJy6AzvVzOiJrBZl2r43Fg',
  );

  runApp(const AdminPortalApp());
}

/// Global navigator key — used by AdminAuthWrapper to clear the route stack
/// when sign-out fires so the login screen is immediately visible.
final _navigatorKey = GlobalKey<NavigatorState>();

class AdminPortalApp extends StatelessWidget {
  const AdminPortalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'FPCL Admin Portal',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2563EB)),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const AdminAuthWrapper(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Auth Wrapper — listens to Firebase, verifies ADMIN role, shows login if needed
// ─────────────────────────────────────────────────────────────────────────────

class AdminAuthWrapper extends StatefulWidget {
  const AdminAuthWrapper({super.key});

  @override
  State<AdminAuthWrapper> createState() => _AdminAuthWrapperState();
}

class _AdminAuthWrapperState extends State<AdminAuthWrapper> {
  final _firebaseAuth = firebase_auth.FirebaseAuth.instance;
  firebase_auth.User? _user;
  bool _checkingRole = false;
  String? _roleError; // non-null when logged in but not ADMIN

  @override
  void initState() {
    super.initState();
    _user = _firebaseAuth.currentUser;
    _firebaseAuth.authStateChanges().listen((user) async {
      // When signed out: clear the navigator stack so any pushed sub-routes
      // (reports, RAE management, etc.) don't hide the login screen.
      if (user == null) {
        _navigatorKey.currentState?.popUntil((route) => route.isFirst);
      }
      if (mounted) {
        setState(() {
          _user = user;
          _roleError = null;
        });
        if (user != null) _verifyAdminRole(user.uid);
      }
    });
    if (_user != null) _verifyAdminRole(_user!.uid);
  }

  Future<void> _verifyAdminRole(String uid) async {
    setState(() => _checkingRole = true);
    try {
      // 1. Fast path: SharedPreferences cache
      final cached = await AuthService().getCachedRole();
      if (cached != null) {
        if (cached != 'ADMIN') {
          setState(() {
            _roleError = 'This portal is for FPCL Admins only.';
            _checkingRole = false;
          });
          return;
        }
        setState(() => _checkingRole = false);
        return;
      }
      // 2. Fallback: Supabase
      final row = await Supabase.instance.client
          .from('profiles')
          .select('role')
          .eq('uid', uid)
          .maybeSingle()
          .timeout(const Duration(seconds: 6));

      final role = row?['role']?.toString();
      if (role == 'ADMIN') {
        await AuthService().cacheRole('ADMIN');
        setState(() => _checkingRole = false);
      } else {
        setState(() {
          _roleError = 'This portal is for FPCL Admins only.';
          _checkingRole = false;
        });
      }
    } catch (e) {
      // If Supabase is unreachable, allow cached ADMIN through
      setState(() => _checkingRole = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null) return const AdminLoginScreen();

    if (_checkingRole) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_roleError != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(_roleError!,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w500)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  await AuthService().signOut();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Sign Out'),
              ),
            ],
          ),
        ),
      );
    }

    return const AdminDashboard();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Admin Login Screen — phone OTP, role hardcoded to ADMIN
// ─────────────────────────────────────────────────────────────────────────────

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  static const _blue = Color(0xFF2563EB);

  final _authService = AuthService();
  final _phoneCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    String phone = _phoneCtrl.text.trim();
    if (!phone.startsWith('+')) phone = '+91$phone';

    _authService.setRole('ADMIN');

    try {
      await _authService.sendOTP(phone);
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AdminOtpScreen(
              phoneNumber: phone,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Card(
            margin: const EdgeInsets.all(24),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo / title block
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: _blue,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.admin_panel_settings,
                          color: Colors.white, size: 36),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'FPCL Admin Portal',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Sign in with your registered admin phone number',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 13, color: Color(0xFF6B7280)),
                    ),
                    const SizedBox(height: 28),
                    // Phone input
                    TextFormField(
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                      decoration: InputDecoration(
                        labelText: 'Phone Number',
                        prefixText: '+91 ',
                        prefixStyle: const TextStyle(
                            color: Color(0xFF374151),
                            fontWeight: FontWeight.w500),
                        prefixIcon: const Icon(Icons.phone_outlined,
                            color: Color(0xFF6B7280)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              const BorderSide(color: _blue, width: 2),
                        ),
                        hintText: '10-digit mobile number',
                      ),
                      validator: (v) {
                        if (v == null || v.trim().length < 10) {
                          return 'Enter a valid 10-digit phone number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _sendOtp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white),
                              )
                            : const Text('Send OTP',
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Only registered FPCL Admin accounts can access this portal.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 11, color: Color(0xFF9CA3AF)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// OTP Entry Screen (6-box style matching main app)
// ─────────────────────────────────────────────────────────────────────────────

class AdminOtpScreen extends StatefulWidget {
  final String phoneNumber;
  const AdminOtpScreen({super.key, required this.phoneNumber});

  @override
  State<AdminOtpScreen> createState() => _AdminOtpScreenState();
}

class _AdminOtpScreenState extends State<AdminOtpScreen> {
  static const _blue = Color(0xFF2563EB);

  final _authService = AuthService();
  final _controllers =
      List.generate(6, (_) => TextEditingController());
  final _focusNodes = List.generate(6, (_) => FocusNode());

  bool _isLoading = false;
  int _resendTimer = 60;
  bool _canResend = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    setState(() { _canResend = false; _resendTimer = 60; });
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_resendTimer <= 1) {
        t.cancel();
        if (mounted) setState(() => _canResend = true);
      } else {
        if (mounted) setState(() => _resendTimer--);
      }
    });
  }

  String get _otp =>
      _controllers.map((c) => c.text).join();

  Future<void> _verify() async {
    final otp = _otp;
    if (otp.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter all 6 digits')),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      await _authService.verifyOTPWithRole(otp, 'ADMIN');
      // Pop back to the root route so AdminAuthWrapper (which has already
      // rebuilt to AdminDashboard) becomes visible instead of this OTP screen.
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Card(
            margin: const EdgeInsets.all(24),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.sms_outlined, size: 48, color: _blue),
                  const SizedBox(height: 16),
                  const Text(
                    'Enter OTP',
                    style: TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Sent to ${widget.phoneNumber}',
                    style: const TextStyle(
                        fontSize: 13, color: Color(0xFF6B7280)),
                  ),
                  const SizedBox(height: 28),
                  // 6-box OTP
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(6, (i) {
                      return SizedBox(
                        width: 44,
                        child: TextFormField(
                          controller: _controllers[i],
                          focusNode: _focusNodes[i],
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          maxLength: 1,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          decoration: InputDecoration(
                            counterText: '',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                  color: _blue, width: 2),
                            ),
                          ),
                          onChanged: (v) {
                            if (v.isNotEmpty && i < 5) {
                              _focusNodes[i + 1].requestFocus();
                            }
                            if (v.isEmpty && i > 0) {
                              _focusNodes[i - 1].requestFocus();
                            }
                          },
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _verify,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _blue,
                        foregroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Verify & Sign In',
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _canResend
                        ? () async {
                            _authService.setRole('ADMIN');
                            await _authService.sendOTP(widget.phoneNumber);
                            _startTimer();
                          }
                        : null,
                    child: Text(
                      _canResend
                          ? 'Resend OTP'
                          : 'Resend in ${_resendTimer}s',
                      style: TextStyle(
                          color: _canResend ? _blue : Colors.grey),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
