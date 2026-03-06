# TRA FPCL — Project Snapshot
*Last updated: March 6, 2026. Hand this file to a new chat to continue work.*

---

## 1. What This Project Is

**TRA FPCL** (Tribal Rural Agripreneur - Farmer Producer Company Limited) is a **Flutter mobile app** for managing a rural agriculture supply chain in India. It connects four types of users:

| Role | Full Name | What They Do |
|---|---|---|
| **RAE** | Rural Agripreneur | Field agent who buys inputs (seeds, fertilisers, pesticides) for farmers, places orders |
| **SME** | Subject Matter Expert / District Advisor | Supervises RAEs in a district, handles farmer issues, monitors field performance |
| **ADMIN** | FPCL Admin | Manages inventory, approves orders, oversees the whole operation |
| **SUPPLIER** | Input Supplier | Fulfils orders, manages stock |

**Tech stack (actual, not the brief):**
- **Flutter** (Dart) — cross-platform mobile app, currently tested on Android
- **Firebase Auth** — phone OTP login only. Firebase UID (a TEXT string) is the primary key everywhere.
- **Supabase** — used purely as a Postgres database (NOT for auth). RLS is **disabled on all tables** because `auth.uid()` is always NULL when using Firebase Auth instead of Supabase Auth.
- **Provider** — state management (used only for `CartService` so far)
- **shared_preferences** — caches the user's role locally for offline/fast routing

**Critical architectural note:** Firebase Auth and Supabase Auth are completely separate systems. This app uses Firebase identity, so Supabase's `auth.uid()` always returns NULL. All tables must have `DISABLE ROW LEVEL SECURITY`. Security is enforced by Firebase Auth on the client side.

---

## 2. Infrastructure & Credentials

### Firebase
- Project is already configured in `android/app/google-services.json`
- Phone auth is enabled
- **Test phone numbers** (the ONLY numbers that work without billing):
  - `+919999999999` → OTP `123456`
  - `+918882207841` → OTP `112233`
- Real phone numbers require Blaze (pay-as-you-go) plan. Don't use real numbers for dev.
- To add more test numbers: Firebase Console → Authentication → Sign-in method → Phone → Test phone numbers

### Supabase (NEW project — created this session)
- **URL:** `https://hwlwxzyrcaxjjlnnokxk.supabase.co`
- **Anon key:** `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imh3bHd4enlyY2F4ampsbm5va3hrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzI3NjcxMDgsImV4cCI6MjA4ODM0MzEwOH0.RnR9KTt-tUVej8qSkOMCpiJy6AzvVzOiJrBZl2r43Fg`
- **Schema was successfully applied** (`SUPABASE_TABLES.sql` ran with "Success. No rows returned")
- All tables use `DISABLE ROW LEVEL SECURITY`

### Database Tables (all created)
| Table | Purpose |
|---|---|
| `profiles` | One row per user. Columns: `uid TEXT PK`, `phone`, `role`, `name`, `email`, `district` |
| `products` | Product catalogue (seeds, fertilisers, pesticides) — sample data seeded |
| `orders` | Orders placed by RAEs |
| `order_items` | Line items for each order |
| `notifications` | In-app notifications per user |
| `conversations` | RAE ↔ SME chat threads |
| `issues` | Complaints/issues raised by RAEs, handled by SMEs |
| `sme_metrics` | Per-SME performance stats (active RAEs, villages, farmers) |

---

## 3. Project File Structure

```
lib/
├── main.dart                          ← App entry, AuthWrapper, DashboardRouter, DashboardShell, LoginScreen
├── services/
│   ├── auth_service.dart              ← Firebase OTP + Supabase profile sync + role caching
│   ├── cart_service.dart              ← Cart state (Provider ChangeNotifier)
│   └── sme_service.dart               ← SME dashboard data (models + Supabase queries)
└── screens/
    ├── auth/
    │   ├── phone_login_screen.dart    ← Role selector + phone input → calls sendOTP
    │   └── otp_verification_screen.dart ← 6-box OTP entry → calls verifyOTPWithRole
    ├── catalog/
    │   ├── product_catalog_screen.dart ← Product grid for RAE
    │   └── shopping_cart_screen.dart   ← Cart for RAE
    └── dashboard/
        ├── rae_dashboard.dart         ← RAE dashboard (green theme, order & catalogue)
        └── sme_dashboard.dart         ← SME dashboard (purple theme, full wireframe)
```

---

## 4. Auth Flow (How Login Works)

```
PhoneLoginScreen
  1. User selects role (RAE/SME/ADMIN/SUPPLIER) and enters 10-digit phone
  2. _authService.setRole(_selectedRole)   ← MUST be before sendOTP (race condition fix)
  3. await _authService.sendOTP(phoneNumber)
     ├── Uses Completer — waits for codeSent callback before returning
     ├── _verificationId is guaranteed set when function returns
     └── verificationFailed with BILLING_NOT_ENABLED → clear error shown
  4. Navigator.push → OTPVerificationScreen

OTPVerificationScreen
  5. User enters 6-digit OTP
  6. await _authService.verifyOTPWithRole(otp, role)
     ├── Creates PhoneAuthCredential
     ├── _signInWithCredential → Firebase sign in
     ├── _ensureProfileExists → upsert into Supabase profiles table
     └── cacheRole(role) → SharedPreferences

AuthWrapper (listens to Firebase authStateChanges)
  7. Firebase user != null → DashboardRouter

DashboardRouter
  8. _getUserProfile():
     ├── Fast path: SharedPreferences cache → returns {role, uid}
     └── Fallback: Supabase profiles table → caches result
  9. switch(role) → RAEDashboard / SMEDashboard / Placeholder / Placeholder
```

---

## 5. What Has Been Built

### ✅ Auth System
- Phone OTP login with Firebase
- Role selection on login screen
- Race condition fixed: `sendOTP()` uses `Completer`, only returns after Firebase `codeSent` fires
- Role cached in SharedPreferences for instant offline routing
- Sign-out clears cache
- Error recovery screen when profile can't be loaded (instead of silently defaulting to RAE)

### ✅ RAE Dashboard (`rae_dashboard.dart`)
- Green-themed dashboard
- Shows order history, product catalogue shortcut
- `DashboardShell` wrapper (AppBar + drawer)

### ✅ RAE Product Catalogue & Cart
- `product_catalog_screen.dart` — browse products by category, add to cart
- `shopping_cart_screen.dart` — view cart, place order
- `CartService` (Provider) manages cart state

### ✅ SME Dashboard (`sme_dashboard.dart`)
Built to match Figma wireframes exactly:
- **Purple gradient header** (`#7B2FDC` → `#5B1FA8`) with district advisor title
- **2×2 stat cards grid** — Active RAEs, Open Issues, Villages Covered, Farmers Served
- **Active Conversations** section — realtime stream from Supabase, green left border for unread
- **Issues list** — open=orange badge, resolved=green badge. Tapping shows "View Details" dialog with resolve action
- **District Performance** section — overview of RAE activity
- **Activity Log** section — recent events
- **Dark green FAB** (`#1B8C4E`) with bottom sheet menu

### ✅ SME Service (`sme_service.dart`)
Models: `ConversationItem`, `IssueItem`, `SmeDashboardStats`, `SmeActivityLog`, `SmeDistrictPerformance`

Methods:
- `getDashboardStats()` — pulls from `sme_metrics`
- `conversationsStream()` — realtime stream from `conversations`
- `issuesStream()` — realtime stream from `issues`
- `getDistrictPerformance()`, `getActivityLog()`, `getSmeProfile()`
- `resolveIssue()`, `markConversationRead()`

### ✅ Database Schema
`SUPABASE_TABLES.sql` — fully applied on new Supabase project. Includes indexes, realtime subscriptions, sample product seed data.

---

## 6. What Is Left (TODO)

### 🔴 High Priority — Missing Dashboards

#### ADMIN Dashboard
- File to create: `lib/screens/dashboard/admin_dashboard.dart`
- Service to create: `lib/services/admin_service.dart`
- Supabase tables needed: possibly none (uses existing `orders`, `products`, `profiles`)
- Features needed:
  - Order management (view all orders, approve/reject)
  - Product/inventory management (add/edit products)
  - User management (view all RAEs, SMEs, Suppliers)
  - System metrics overview
- Currently: `Placeholder()` widget in `DashboardRouter`

#### SUPPLIER Dashboard
- File to create: `lib/screens/dashboard/supplier_dashboard.dart`
- Service to create: `lib/services/supplier_service.dart`
- Features needed:
  - View assigned orders
  - Update order status (processing → shipped → delivered)
  - Inventory/stock management
- Currently: `Placeholder()` widget in `DashboardRouter`

### 🟡 Medium Priority — Incomplete Features

#### Chat Screen (within SME dashboard)
- Tapping a conversation currently shows: `"Chat interface – Coming Soon"` SnackBar
- Need to build: `lib/screens/chat/chat_screen.dart`
- Need to build: `messages` table in Supabase (id, conversation_id, sender_uid, content, created_at)
- Realtime messaging using Supabase streams

#### Farmer Registration (RAE flow)
- Mentioned in project brief but not yet built
- RAEs should be able to register farmers they serve
- New table needed: `farmers` (id, rae_uid, name, village, phone, crop_type, land_area)

#### Order Flow Completion
- RAE can add to cart and place order (basic flow exists)
- Missing: Order status updates visible to RAE
- Missing: FPCL Admin order approval step
- Missing: Supplier assignment and fulfilment flow

#### Advisory / Content
- SME should be able to send advisories/alerts to RAEs in their district
- New table needed: `advisories` (id, sme_uid, district, title, content, created_at)

### 🟢 Low Priority / Polish

- **Offline sync** — no `sqflite` local cache yet; app requires internet
- **Push notifications** — Firebase Cloud Messaging not integrated
- **Profile screen** — users can't view/edit their own profile
- **DashboardShell drawer** — currently shows hardcoded "Role: RAE" text instead of actual role
- **SME Dashboard chat** — conversations are view-only; full chat not built
- **Input validation** — phone login limits input to 10 digits but doesn't validate Indian number patterns
- **Password/PIN** — no second factor beyond Firebase OTP

---

## 7. Key Code Patterns to Follow

### Adding a new dashboard
1. Create `lib/screens/dashboard/xxx_dashboard.dart` — give it its own `Scaffold` (like `sme_dashboard.dart`) OR use `DashboardShell` (like `rae_dashboard.dart`)
2. Create `lib/services/xxx_service.dart` — singleton pattern (`static final _instance = ...`)
3. Import in `lib/main.dart` and add `case 'XXX':` in `DashboardRouter`'s switch

### Querying Supabase
```dart
// Always filter by Firebase UID (TEXT), never by Supabase auth
final uid = firebase_auth.FirebaseAuth.instance.currentUser!.uid;
final data = await Supabase.instance.client
    .from('your_table')
    .select()
    .eq('uid_column', uid)
    .order('created_at', ascending: false);
```

### Realtime streams
```dart
Supabase.instance.client
    .from('issues')
    .stream(primaryKey: ['id'])
    // Client-side filter (Supabase stream doesn't support .eq() server-side)
    .map((rows) => rows.where((r) => r['sme_uid'] == uid).toList())
```

### Role caching pattern
```dart
// On login — set role BEFORE sendOTP
_authService.setRole(_selectedRole);
await _authService.sendOTP(phoneNumber);

// On verify — auto-cached inside _ensureProfileExists

// On dashboard load — read from SharedPreferences first (fast path)
final cachedRole = await AuthService().getCachedRole();
```

---

## 8. Running the Project

```bash
# Install dependencies
flutter pub get

# Run on connected Android device
flutter run

# Hot reload (while running)
r   # hot reload
R   # hot restart (clears state)
q   # quit
```

**Test login:**
- Phone: `+919999999999`, Role: `SME`, OTP: `123456` → should land on purple SME dashboard
- Phone: `+919999999999`, Role: `RAE`, OTP: `123456` → should land on green RAE dashboard
- Phone: `+918882207841`, any role, OTP: `112233` → works too

**If you see "Could not load your profile" screen:** The Supabase profile wasn't created. Sign out, log back in — `_ensureProfileExists` will create/update the profile row.

---

## 9. Dependencies (`pubspec.yaml`)

```yaml
dependencies:
  firebase_core: ^3.8.1
  firebase_auth: ^5.3.4
  supabase_flutter: ^2.9.2
  provider: ^6.1.1
  shared_preferences: ^2.3.3
  cupertino_icons: ^1.0.8
```
