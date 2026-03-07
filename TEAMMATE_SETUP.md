# TRA FPCL — Teammate Onboarding Guide
*For teammates who have an older version of the repo (RAE-only build) and need to catch up.*

---

## What's New Since the RAE-Only Version

| Area | What Was Added |
|---|---|
| **Supplier Dashboard** | Full mobile dashboard (indigo theme) — bulk PO management, dispatch flow, catalogue CRUD |
| **SME Dashboard** | Already existed; now fully wired |
| **FPCL Admin Web Portal** | Separate Flutter web app (`lib/admin_main.dart`) — order approval, district stats, admin login |
| **Mobile app** | ADMIN role removed from login; if an admin logs in on mobile they see a "use web portal" screen |
| **Auth** | `dart:io` import fix in `auth_service.dart`; Firebase web options via `firebase_options.dart` |
| **🔔 Push Notifications (FCM)** | Firebase Cloud Messaging integration — chat, advisory, order notifications (ready, pending Blaze deployment) |

---

## Step 1 — Pull the Latest Code

```bash
git pull origin main
```

If you have local uncommitted changes, stash them first:

```bash
git stash
git pull origin main
git stash pop   # re-apply your changes if needed
```

---

## Step 2 — Install Flutter Dependencies

```bash
flutter pub get
```

This installs all required packages including:
- `firebase_messaging` - Push notifications
- `flutter_local_notifications` - Local notification display
- `cloud_functions` - Firebase Cloud Functions integration
- `http` - HTTP requests
- All existing packages (firebase_auth, supabase_flutter, etc.)

---

## Step 3 — Firebase Functions Setup (Optional for Testing)

> **Note:** This step is **optional** for teammates. Firebase Cloud Functions are already written but not yet deployed (awaiting Firebase Blaze plan upgrade). The app works fully without this step.

If you want to test or modify the Firebase Cloud Functions locally:

### 3a. Install Node.js (if not already installed)

Download and install from: https://nodejs.org/ (LTS version recommended)

Verify installation:
```bash
node --version  # Should show v18 or higher
npm --version
```

### 3b. Install Firebase Functions Dependencies

```bash
cd functions
npm install
cd ..
```

### 3c. Validate Functions Code (Optional)

```bash
cd functions
npm run lint      # Check for code issues
npm run build     # Compile TypeScript
cd ..
```

**What these functions do:**
- `sendChatNotification` - Sends notification when user receives chat message
- `sendAdvisoryNotification` - Notifies all district SMEs when RAE creates request
- `sendAdvisoryAcceptedNotification` - Notifies RAE when SME accepts
- `sendOrderNotification` - Notifies RAE when order dispatched

**Deployment Status:**
- ✅ Code written and validated
- ⏳ Deployment pending Firebase Blaze plan upgrade (requires credit card)
- 📋 See: [FCM_DEPLOYMENT_GUIDE.md](FCM_DEPLOYMENT_GUIDE.md) for deployment steps

---

## Step 4 — What Works Now vs What's Pending

### ✅ Working Now (No Action Needed)

All core features work perfectly:
- Phone authentication (OTP login)
- All user roles (RAE, SME, Admin, Supplier)
- Product catalog & shopping cart
- Order management
- Advisory request system
- Chat messaging (send/receive messages)
- All dashboards
- Database operations

### ⏳ Pending Deployment (After Blaze Upgrade)

Only push notifications are pending:
- Chat message notifications
- Advisory request notifications
- Advisory accepted notifications
- Order dispatch notifications

**The app fully functions** - users just won't receive push notifications until Firebase Cloud Functions are deployed (1-2 days).

---

## Step 5 — Firebase Web Setup (required for the Admin Web Portal only)

The mobile app works without this step. Only do this if you want to run the Admin Web Portal in Chrome.

### 5a. Install the FlutterFire CLI

```bash
dart pub global activate flutterfire_cli
export PATH="$PATH:$HOME/.pub-cache/bin"

# Make it permanent (Linux/macOS):
echo 'export PATH="$PATH:$HOME/.pub-cache/bin"' >> ~/.bashrc
source ~/.bashrc
```

On Windows (PowerShell):
```powershell
$env:PATH += ";$env:USERPROFILE\.pub-cache\bin"
```

### 5b. Generate `firebase_options.dart`

```bash
flutterfire configure --project=tra-fpcl-33738 --platforms=android,web
```

- When prompted to overwrite `google-services.json` → **No** (keep existing)
- When prompted to create `firebase_options.dart` → **Yes**

This generates `lib/firebase_options.dart` which is required for the web portal to initialise Firebase.

> **Note:** `firebase_options.dart` is gitignored on some setups. If you get a "firebase_options.dart not found" error, run the command above — it only takes 30 seconds.

---

## Step 6 — Running the Apps

### Mobile App (Android)

Connect an Android device or start an emulator, then:

```bash
flutter run
```

**Test logins:**

| Phone | Role | OTP | Lands on |
|---|---|---|---|
| `+919999999999` | RAE | `123456` | Green RAE dashboard |
| `+919999999999` | SME | `123456` | Purple SME dashboard |
| `+919999999999` | SUPPLIER | `123456` | Indigo Supplier dashboard |
| `+918882207841` | any | `112233` | Corresponding dashboard |

> ADMIN is no longer in the mobile login — use the web portal below.

---

### Admin Web Portal (Chrome)

```bash
flutter run -t lib/admin_main.dart -d chrome
```

Login with a phone number that has the ADMIN role in Supabase. For testing, you can temporarily insert a row directly in Supabase:

```sql
INSERT INTO profiles (uid, phone, role, name, district)
VALUES ('test-admin-uid', '+919999999998', 'ADMIN', 'Test Admin', 'Hyderabad')
ON CONFLICT (uid) DO UPDATE SET role = 'ADMIN';
```

Then register that number as a Firebase test number:
- Firebase Console → Authentication → Sign-in method → Phone → Test phone numbers
- Add `+919999999998` with OTP `999999`

---

## Step 7 — Project Structure Overview

```
lib/
├── main.dart                          ← Mobile app entry point
├── admin_main.dart                    ← Admin web portal entry point
├── firebase_options.dart              ← Generated by flutterfire configure (Step 3)
│
├── services/
│   ├── auth_service.dart              ← Firebase OTP + Supabase profile sync + role cache
│   ├── cart_service.dart              ← Cart state (Provider)
│   ├── sme_service.dart               ← SME data layer
│   ├── supplier_service.dart          ← Supplier data layer (NEW)
│   ├── admin_service.dart             ← Admin data layer (NEW)
│   ├── notification_service.dart      ← FCM receiver - handles incoming notifications (NEW)
│   ├── fcm_sender_service.dart        ← FCM sender - sends notifications via Cloud Functions (NEW)
│   └── fcm_sender_service_supabase.dart ← Alternative FCM sender using Supabase Edge Functions (NEW)
│
└── screens/
    ├── auth/
    │   ├── phone_login_screen.dart    ← Role selector + phone input
    │   └── otp_verification_screen.dart
    ├── catalog/
    │   ├── product_catalog_screen.dart
    │   └── shopping_cart_screen.dart
    ├── dashboard/
    │   ├── rae_dashboard.dart         ← Green theme
    │   ├── sme_dashboard.dart         ← Purple theme
    │   └── supplier_dashboard.dart    ← Indigo theme (NEW)
    ├── supplier/
    │   └── catalogue_management_screen.dart  ← Product CRUD (NEW)
    └── admin/
        ├── admin_dashboard.dart       ← Blue theme, web-optimised (NEW)
        └── order_approval_screen.dart ← Pending/Approved tabs (NEW)

functions/                                 ← Firebase Cloud Functions (NEW)
├── src/
│   └── index.ts                          ← FCM notification handlers (4 functions)
├── package.json                           ← Node.js dependencies
└── tsconfig.json                          ← TypeScript config
```

### FCM Documentation

- **[FCM_DEPLOYMENT_GUIDE.md](FCM_DEPLOYMENT_GUIDE.md)** - Step-by-step deployment after Blaze upgrade
- **[FCM_INTEGRATION_GUIDE.md](FCM_INTEGRATION_GUIDE.md)** - Technical documentation
- **[FCM_QUICK_REFERENCE.md](FCM_QUICK_REFERENCE.md)** - Code snippets
- **[FCM_CHECKLIST.md](FCM_CHECKLIST.md)** - Implementation checklist
- **[SUPABASE_MIGRATION_FCM.sql](SUPABASE_MIGRATION_FCM.sql)** - Database migration for FCM tokens
```

---

## Step 8 — Supabase (Database)

No action needed — the Supabase project is already live and shared:

- **URL:** `https://hwlwxzyrcaxjjlnnokxk.supabase.co`
- **Anon key:** already in `main.dart` and `admin_main.dart`

If you need to re-apply the schema (e.g. fresh Supabase project):

```bash
# Open Supabase Dashboard → SQL Editor → paste and run:
cat SUPABASE_TABLES.sql
```

---

## Common Errors & Fixes

| Error | Fix |
|---|---|
| `firebase_options.dart not found` | Run Step 5b |
| `flutterfire: command not found` | Run Step 5a (add to PATH) |
| Blank white screen in Chrome | Firebase not initialised — `firebase_options.dart` missing |
| `SocketException isn't a type` | Already fixed in `auth_service.dart` — make sure you pulled latest |
| `Could not load your profile` on mobile | Sign out and sign back in — profile will be auto-created |
| `No devices found` for Chrome | Run `flutter config --enable-web` once |
| Push notifications not working | Normal - FCM deployment pending Blaze upgrade (see Step 4) |

---

## Hot Reload / Restart (while a `flutter run` session is active)

| Key | Action |
|---|---|
| `r` | Hot reload — applies code changes instantly |
| `R` | Hot restart — restarts app, clears state |
| `q` | Quit |

---

## Build Commands (for sharing / demo)

```bash
# Mobile APK
flutter build apk --release

# Admin web portal (outputs to build/admin_web/)
flutter build web --target lib/admin_main.dart --output build/admin_web
```
