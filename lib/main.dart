import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'services/cart_service.dart';
import 'screens/auth/phone_login_screen.dart';
import 'screens/dashboard/rae_dashboard.dart';
import 'screens/dashboard/sme_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp();
  
  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://hwlwxzyrcaxjjlnnokxk.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imh3bHd4enlyY2F4ampsbm5va3hrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzI3NjcxMDgsImV4cCI6MjA4ODM0MzEwOH0.RnR9KTt-tUVej8qSkOMCpiJy6AzvVzOiJrBZl2r43Fg',
  );
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => CartService(),
      child: MaterialApp(
        title: 'TRA FPCL',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const AuthWrapper(),
      ),
    );
  }
}

/// AuthWrapper listens to Supabase auth state and routes accordingly
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final firebase_auth.FirebaseAuth _firebaseAuth = firebase_auth.FirebaseAuth.instance;
  firebase_auth.User? _currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeAuth();
  }

  /// Initialize auth state and set up listener
  void _initializeAuth() {
    // Get initial Firebase user
    setState(() {
      _currentUser = _firebaseAuth.currentUser;
      _isLoading = false;
    });

    // Listen to Firebase auth state changes (works offline!)
    _firebaseAuth.authStateChanges().listen((firebase_auth.User? user) {
      setState(() {
        _currentUser = user;
      });

      // Optional: Log auth events for debugging
      if (_currentUser != null) {
        debugPrint('Firebase user signed in: ${_currentUser!.uid}');
      } else {
        debugPrint('User signed out');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Show loading screen while checking auth state
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Route based on authentication state
    // Similar to React Router: user ? <Dashboard /> : <Login />
    return _currentUser != null 
        ? const DashboardRouter() 
        : const LoginScreen();
  }
}

/// Dashboard Router - Routes to role-specific dashboard
class DashboardRouter extends StatelessWidget {
  const DashboardRouter({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _getUserProfile(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final profile = snapshot.data;

        // If BOTH cache and Supabase failed, show a recovery screen instead of
        // silently routing to RAE (which was masking the real error before).
        if (profile == null) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.cloud_off, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text(
                      'Could not load your profile',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Check your internet connection and try again.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () async {
                        await AuthService().signOut();
                      },
                      child: const Text('Sign Out & Retry'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final role = profile['role']?.toString() ?? 'RAE';

        // Route to role-specific dashboard
        switch (role) {
          case 'RAE':
            return const DashboardShell(
              title: 'RAE Dashboard',
              child: RAEDashboard(),
            );
          case 'SME':
            // SMEDashboard has its own full-bleed Scaffold (purple header + FAB).
            // Return it directly — no DashboardShell wrapper needed.
            return const SMEDashboard();
          case 'ADMIN':
            return const DashboardShell(
              title: 'Admin Dashboard',
              child: Placeholder(), // TODO: Create AdminDashboard
            );
          case 'SUPPLIER':
            return const DashboardShell(
              title: 'Supplier Dashboard',
              child: Placeholder(), // TODO: Create SupplierDashboard
            );
          default:
            return const DashboardShell(
              title: 'Dashboard',
              child: RAEDashboard(),
            );
        }
      },
    );
  }

  Future<Map<String, dynamic>?> _getUserProfile() async {
    final firebaseUser = firebase_auth.FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) return null;

    // ── 1. Fast path: SharedPreferences (set during login, no network needed)
    final cachedRole = await AuthService().getCachedRole();
    if (cachedRole != null) {
      debugPrint('✅ Role loaded from cache: $cachedRole');
      return {'role': cachedRole, 'uid': firebaseUser.uid};
    }

    // ── 2. Fallback: fetch from Supabase (first install or cache cleared)
    final supabase = Supabase.instance.client;
    try {
      final response = await supabase
          .from('profiles')
          .select()
          .eq('uid', firebaseUser.uid)
          .maybeSingle()
          .timeout(const Duration(seconds: 5));

      if (response != null && response['role'] != null) {
        // Populate cache from Supabase result so future launches are instant
        await AuthService().cacheRole(response['role'].toString());
        debugPrint('✅ Role loaded from Supabase: ${response['role']}');
      }
      return response;
    } catch (e) {
      debugPrint('⚠️ Error fetching profile from Supabase: $e');
      // Return null — the switch default below will show a "role unknown" screen
      // rather than silently falling back to RAE.
      return null;
    }
  }
}

/// Dashboard Shell - Main container for authenticated users
class DashboardShell extends StatelessWidget {
  final String title;
  final Widget child;

  const DashboardShell({
    super.key,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final user = firebase_auth.FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          // User info badge
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Center(
              child: Chip(
                avatar: const Icon(Icons.person, size: 18),
                label: Text(
                  user?.phoneNumber ?? 'User',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
          ),
          // Sign out button
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              // Show confirmation dialog
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Sign Out'),
                  content: const Text('Are you sure you want to sign out?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Sign Out'),
                    ),
                  ],
                ),
              );

              if (confirmed == true && context.mounted) {
                try {
                  await authService.signOut();
                  // AuthWrapper will automatically navigate to LoginScreen
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error signing out: $e')),
                    );
                  }
                }
              }
            },
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: child,
      // TODO: Add navigation drawer or bottom navigation
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.inversePrimary,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const CircleAvatar(
                    radius: 30,
                    child: Icon(Icons.person, size: 30),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    user?.phoneNumber ?? 'User',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'Role: RAE',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Dashboard'),
              selected: true,
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Profile'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to profile screen
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Sign Out', style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(context);
                await authService.signOut();
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Login Screen - Entry point for unauthenticated users
/// TODO: Move to separate file: lib/screens/auth/login_screen.dart
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App Logo/Icon
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.phone_android,
                      size: 80,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // App Title
                  const Text(
                    'TRA FPCL',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sign in to continue',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 48),
                  
                  // Info Card
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            size: 48,
                            color: Colors.blue,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Phone Authentication',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'We\'ll send you an OTP to verify your phone number',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Login Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PhoneLoginScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.phone),
                      label: const Text(
                        'Sign In with Phone',
                        style: TextStyle(fontSize: 16),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Development Note
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.code, color: Colors.orange, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'TODO: Implement phone number input and OTP verification screens',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
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
