# TRA FPCL App

Agricultural platform Flutter application with Firebase authentication, Supabase backend, and role-based dashboards for RAE (Rural Agricultural Extension), SME, Admin, and Supplier users.

## Features

- 📱 Phone number authentication with OTP verification (Firebase)
- 👥 Role-based access control (RAE, SME, ADMIN, SUPPLIER)
- 🛒 Product catalog with shopping cart functionality
- 📦 Order management with real-time updates
- 💰 GST calculation (18%) for orders
- 🔔 Real-time notifications
- 📊 Dashboard with active orders tracking

## Prerequisites

Before setting up this project, ensure you have the following installed:

- **Flutter SDK** (version 3.38.7 or higher)
  ```bash
  flutter --version
  ```
- **Android Studio** or **VS Code** with Flutter extensions
- **Git** for version control

> **Note:** Firebase and Supabase are already configured! All API keys and configuration files are included in the repository.

## Setup Instructions

### 1. Clone the Repository

```bash
git clone https://github.com/samarth-singla/TRA-FPCL.git
cd TRA-FPCL
```

### 2. Navigate to the Flutter App Directory

```bash
cd tra_fpcl_app
```

### 3. Install Flutter Dependencies

```bash
flutter pub get
```

### 4. Run the Application

#### Android

```bash
flutter run
```

Or use VS Code/Android Studio to run the app on an emulator or physical device.

#### iOS (macOS only)

```bash
cd ios
pod install
cd ..
flutter run
```

### 5. Test Login

Use the test phone number configured in Firebase:

- **Phone Number:** `+919999999999`
- **OTP Code:** `123456`
- **Select Role:** RAE (or any other role)

## Firebase & Supabase Configuration

### Already Configured! ✅

All Firebase and Supabase configurations are already included in the repository:

- **Firebase Config:** `android/app/google-services.json`
- **Supabase URL & Keys:** Pre-configured in `lib/main.dart`
- **SHA-1/SHA-256 Keys:** Already registered with Firebase
- **Database Tables:** Already created and populated with sample data
- **Test Phone Numbers:** Pre-configured for development

You don't need to create new Firebase or Supabase projects. Just clone and run!

## Project Structure

```
lib/
├── main.dart                          # App entry point
├── services/
│   ├── auth_service.dart             # Authentication logic (Firebase + Supabase)
│   └── cart_service.dart             # Shopping cart state management
├── screens/
│   ├── auth/
│   │   ├── phone_login_screen.dart   # Phone number input
│   │   └── otp_verification_screen.dart  # OTP verification
│   ├── dashboard/
│   │   └── rae_dashboard.dart        # RAE user dashboard
│   └── catalog/
│       ├── product_catalog_screen.dart   # Product listing
│       └── shopping_cart_screen.dart     # Shopping cart & checkout
```

## Key Dependencies

- `firebase_core: ^3.8.1` - Firebase initialization
- `firebase_auth: ^5.3.4` - Phone authentication
- `firebase_messaging: ^15.1.5` - Push notifications (FCM)
- `flutter_local_notifications: ^18.0.1` - Local notification display
- `cloud_functions: ^5.1.5` - Firebase Cloud Functions integration
- `supabase_flutter: ^2.9.2` - Backend database & realtime
- `provider: ^6.1.1` - State management
- `http: ^1.2.2` - HTTP requests

## Environment Configuration

### Shared Firebase & Supabase

This project uses shared Firebase and Supabase instances:

- **Firebase Project:** `tra-fpcl`
- **Package Name:** `com.example.tra_fpcl_app`
- **Supabase Project:** Pre-configured with all tables and sample data

All configuration files (including API keys) are committed to the repository for easy setup.

### Using a Different Firebase Account

If you want to connect this project to your own Firebase account:

**Quick Steps:**
1. Replace `android/app/google-services.json` with your Firebase config file
2. Add your SHA-1 and SHA-256 keys to Firebase Console
3. Enable Phone authentication in Firebase
4. Add test phone number in Firebase Console

📖 **See detailed instructions:** [FIREBASE_MIGRATION_GUIDE.md](FIREBASE_MIGRATION_GUIDE.md)

### Firebase Test Numbers (Development)

For development without SMS costs, Firebase test numbers are configured:

- `+919999999999` → OTP: `123456`

**Note:** For production deployment, test numbers should be removed and real SMS authentication enabled.

## Push Notifications (FCM)

### Firebase Cloud Messaging Setup

This app includes Firebase Cloud Messaging for real-time push notifications:

- 💬 **Chat Messages** - Receive notifications when someone sends you a message
- 📋 **Advisory Requests** - SMEs notified when RAE creates request in their district
- ✅ **Advisory Accepted** - RAE notified when SME accepts their request
- 📦 **Order Dispatched** - RAE notified when admin dispatches their order

### Current Status

**✅ Already Completed:**
- Firebase Cloud Messaging integrated in Flutter app
- Notification services implemented (`notification_service.dart`, `fcm_sender_service.dart`)
- Firebase Cloud Functions code written and validated (`functions/src/index.ts`)
- Android permissions configured
- Database migration file ready (`SUPABASE_MIGRATION_FCM.sql`)

**⚠️ Requires Firebase Blaze Plan:**
- FCM deployment is **ready but blocked** by Firebase billing requirements
- Cloud Functions require **Blaze (pay-as-you-go) plan** to deploy
- **Free tier is generous:** 2M function invocations/month, unlikely to exceed for this app

### FCM Deployment

**📋 See:** [FCM_DEPLOYMENT_GUIDE.md](FCM_DEPLOYMENT_GUIDE.md) for complete deployment steps after upgrading to Firebase Blaze plan.

**Quick Summary:**
1. Upgrade Firebase project to Blaze plan
2. Deploy Cloud Functions: `cd functions && firebase deploy --only functions`
3. Enable Firebase Cloud Messaging API in Google Cloud Console
4. Run database migration: `SUPABASE_MIGRATION_FCM.sql`
5. Test notifications on physical device

### Until FCM is Deployed

**All other app features work normally:**
- ✅ Authentication (Phone OTP)
- ✅ Product catalog
- ✅ Shopping cart & orders
- ✅ Advisory requests
- ✅ Chat messaging
- ✅ Dashboards & role-based access

**Only push notifications are pending** deployment after Blaze upgrade.

## Features by Role

### RAE (Rural Agricultural Extension)
- Order agricultural inputs (fertilizers, seeds, pesticides)
- Track order status
- View farming advisories
- Check earnings/payments

### SME (Small & Medium Enterprise)
- Coming soon

### Admin
- Coming soon

### Supplier
- Coming soon

## Troubleshooting

### Common Issues

**1. "Build errors after cloning"**
- Run `flutter clean`
- Run `flutter pub get`
- Restart your IDE

**2. "OTP not received"**
- Use the test phone number: `+919999999999` with OTP: `123456`
- Ensure you have internet connection for Firebase authentication

**3. "Product catalog empty"**
- Check internet connection
- Database is already populated - just ensure Supabase URL in `lib/main.dart` is correct

**4. "Supabase connection error"**
- Verify internet connection
- Configuration is already set - no changes needed

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## Additional Documentation

- **[FCM_DEPLOYMENT_GUIDE.md](FCM_DEPLOYMENT_GUIDE.md)** - 🔔 **Deploy FCM after Firebase Blaze upgrade**
- [FCM_INTEGRATION_GUIDE.md](FCM_INTEGRATION_GUIDE.md) - Detailed FCM technical documentation
- [FCM_QUICK_REFERENCE.md](FCM_QUICK_REFERENCE.md) - Quick FCM code snippets
- [FCM_CHECKLIST.md](FCM_CHECKLIST.md) - FCM implementation checklist
- [FIREBASE_MIGRATION_GUIDE.md](FIREBASE_MIGRATION_GUIDE.md) - How to connect to a different Firebase account
- [SETUP_INSTRUCTIONS.md](SETUP_INSTRUCTIONS.md) - Detailed setup guide
- [SUPABASE_TABLES.sql](SUPABASE_TABLES.sql) - Database schema
- [SUPABASE_MIGRATION_FCM.sql](SUPABASE_MIGRATION_FCM.sql) - FCM database migration
- [FIREBASE_TEST_NUMBERS_SETUP.md](FIREBASE_TEST_NUMBERS_SETUP.md) - Firebase test configuration
- [RAE_DASHBOARD_README.md](RAE_DASHBOARD_README.md) - RAE Dashboard documentation

## License

This project is part of TRA FPCL agricultural platform.

## Support

For issues or questions, please open an issue on the GitHub repository.
