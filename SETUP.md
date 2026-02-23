# TRA FPCL Project Setup Guide

## 📋 Prerequisites

Before you begin, ensure you have the following installed:

### Required Software

1. **Flutter SDK (3.38.7 or higher)**
   - Download: https://flutter.dev/docs/get-started/install
   - Verify installation: `flutter doctor`

2. **Android Studio** (for Android development)
   - Download: https://developer.android.com/studio
   - Install Android SDK and emulator
   - Install Flutter and Dart plugins

3. **Visual Studio Build Tools 2019 or later** (for Windows development)
   - Already installed if you have Visual Studio

4. **Git**
   - Download: https://git-scm.com/downloads

### Accounts Required

- **Firebase Account**: https://console.firebase.google.com
- **Supabase Account**: https://app.supabase.com

---

## 🚀 Quick Start

### 1. Clone the Repository

```bash
git clone <your-repository-url>
cd tra_fpcl_app
```

### 2. Install Flutter Dependencies

```bash
flutter pub get
```

This will install all dependencies listed in `pubspec.yaml`:
- firebase_core: ^3.8.1
- firebase_auth: ^5.3.4
- supabase_flutter: ^2.9.2
- And all their transitive dependencies

### 3. Configure Firebase

#### Step 3.1: Add google-services.json

**You must add your own Firebase configuration file:**

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select the `tra-fpcl` project (or create a new one)
3. Add an Android app with package name: `com.example.tra_fpcl_app`
4. Download `google-services.json`
5. Place it at: `android/app/google-services.json`

**⚠️ IMPORTANT**: The `google-services.json` file is not included in the repository for security reasons. You MUST add your own.

#### Step 3.2: Enable Phone Authentication

1. Go to Firebase Console → Authentication → Sign-in method
2. Enable "Phone" provider
3. Save changes

#### Step 3.3: Add SHA Keys (for Android)

Generate your debug keystore SHA keys:

**Windows:**
```powershell
keytool -list -v -keystore "$env:USERPROFILE\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
```

**Mac/Linux:**
```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

Then add both SHA-1 and SHA-256 keys to your Firebase project:
- Firebase Console → Project Settings → Your Android App → Add fingerprint

### 4. Configure Supabase

#### Step 4.1: Update Supabase Credentials

**Update `lib/main.dart` with your Supabase credentials:**

```dart
await Supabase.initialize(
  url: 'YOUR_SUPABASE_URL',        // Replace this
  anonKey: 'YOUR_SUPABASE_ANON_KEY', // Replace this
);
```

Get your credentials from:
- Supabase Dashboard → Settings → API
- Copy "Project URL" and "anon public" key

#### Step 4.2: Create Profiles Table

Run this SQL in Supabase SQL Editor:

```sql
CREATE TABLE profiles (
  uid TEXT PRIMARY KEY,
  phone TEXT NOT NULL,
  role TEXT DEFAULT 'RAE',
  name TEXT,
  email TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP
);

-- Enable Row Level Security
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Create policies (adjust as needed)
CREATE POLICY "Users can view their own profile"
  ON profiles FOR SELECT
  USING (auth.uid() = uid);

CREATE POLICY "Users can update their own profile"
  ON profiles FOR UPDATE
  USING (auth.uid() = uid);
```

---

## 🏃 Running the Project

### Option 1: Run on Android (Recommended for Phone Auth)

```bash
# Start an Android emulator or connect a physical device
flutter run
```

When prompted, select the Android device.

### Option 2: Run on Chrome/Edge (Web)

```bash
flutter run -d chrome
```

**Note**: Phone authentication on web requires additional Firebase web configuration.

### Option 3: Run on Windows Desktop

```bash
flutter run -d windows
```

**Note**: Windows desktop has known issues with Firebase Auth. Use Android or Web for testing.

---

## 📦 Installed Dependencies

### Main Dependencies (from pubspec.yaml)

```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  firebase_core: ^3.8.1      # Firebase SDK initialization
  firebase_auth: ^5.3.4      # Firebase Authentication
  supabase_flutter: ^2.9.2   # Supabase client for Flutter

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0
```

### Transitive Dependencies (Installed Automatically)

The following packages are installed as dependencies of the main packages:
- firebase_core_platform_interface
- firebase_auth_platform_interface
- firebase_auth_web
- gotrue (Supabase authentication)
- postgrest (Supabase database)
- realtime_client (Supabase realtime)
- storage_client (Supabase storage)
- And many more...

**To see all dependencies:**
```bash
flutter pub deps
```

**To check for outdated packages:**
```bash
flutter pub outdated
```

---

## 🔧 Troubleshooting

### Build Fails

```bash
# Clean build files and reinstall dependencies
flutter clean
flutter pub get
flutter run
```

### "google-services.json not found"

- Make sure you've added your Firebase config file to `android/app/google-services.json`
- File must be named exactly `google-services.json`

### "FirebaseOptions cannot be null" (on web)

- Web requires additional Firebase configuration in `web/index.html`
- Or run on Android instead

### Phone Authentication Not Working

- Verify Phone Authentication is enabled in Firebase Console
- Check that SHA keys are added to Firebase
- Ensure phone number format includes country code (+1234567890)
- Make sure you're testing on Android (not Windows desktop)

### Symlink Issues on Windows

Enable Windows Developer Mode:
```powershell
start ms-settings:developers
```
Toggle "Developer Mode" to ON, then restart your terminal.

---

## 📂 Project Structure

```
tra_fpcl_app/
├── lib/
│   ├── main.dart                    # App entry point
│   └── services/
│       └── auth_service.dart        # Firebase/Supabase auth service
├── android/
│   ├── app/
│   │   ├── build.gradle.kts
│   │   └── google-services.json     # ⚠️ YOU MUST ADD THIS
│   └── build.gradle.kts
├── pubspec.yaml                     # Dependencies configuration
├── SETUP.md                         # This file
├── TODO.md                          # Development roadmap
└── SETUP_STATUS.md                  # Current setup status
```

---

## 🎯 Next Steps After Setup

1. **Verify Setup**
   ```bash
   flutter doctor -v
   flutter run
   ```

2. **Implement Phone Login UI** (see TODO.md)
   - Create phone number input screen
   - Create OTP verification screen
   - Connect to AuthService

3. **Test Authentication Flow**
   - Send OTP to real phone number
   - Verify OTP
   - Check profile creation in Supabase

---

## 📚 Useful Commands

```bash
# Check Flutter installation
flutter doctor -v

# Install dependencies
flutter pub get

# Update dependencies
flutter pub upgrade

# List all devices
flutter devices

# Run on specific device
flutter run -d <device-id>

# Build APK (Android)
flutter build apk

# Build for release
flutter build apk --release

# Clean build cache
flutter clean

# Analyze code
flutter analyze

# Format code
flutter format .
```

---

## 🔗 Resources

- **Flutter Documentation**: https://flutter.dev/docs
- **Firebase Flutter Setup**: https://firebase.google.com/docs/flutter/setup
- **Supabase Flutter Guide**: https://supabase.com/docs/guides/getting-started/quickstarts/flutter
- **Firebase Console**: https://console.firebase.google.com
- **Supabase Dashboard**: https://app.supabase.com

---

## 🤝 Contributing

Before contributing:
1. Ensure all tests pass: `flutter test`
2. Format your code: `flutter format .`
3. Check for issues: `flutter analyze`
4. Follow the existing code structure

---

## ⚠️ Important Notes

- **Never commit** `google-services.json` to version control
- **Never commit** API keys or secrets
- **Always use** environment variables for sensitive data in production
- **Test on Android** for phone authentication (Windows has issues)

---

## 📞 Support

For issues or questions:
1. Check [TODO.md](TODO.md) for development roadmap
2. Check [SETUP_STATUS.md](SETUP_STATUS.md) for setup status
3. Review Firebase and Supabase documentation
4. Check Flutter GitHub issues

---

**Last Updated**: February 3, 2026
