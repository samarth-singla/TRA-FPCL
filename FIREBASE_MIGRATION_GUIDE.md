# Firebase Account Migration Guide

This guide explains how to connect this project to a different Firebase account/project.

## What Needs to Be Changed

### 1. Create New Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project" (or select existing project)
3. Follow the setup wizard
4. Note down your project ID

### 2. Register Android App

#### 2.1 Add Android App to Firebase

1. In Firebase Console, click "Add app" → Select **Android**
2. Enter package name: `com.example.tra_fpcl_app`
3. (Optional) Add app nickname: "TRA FPCL"
4. Click "Register app"

#### 2.2 Download google-services.json

1. Download the new `google-services.json` file
2. Replace the existing file at:
   ```
   android/app/google-services.json
   ```

### 3. Add SHA Fingerprints

#### 3.1 Generate SHA Keys

**Windows (PowerShell):**
```powershell
cd android
./gradlew signingReport
```

**macOS/Linux:**
```bash
cd android
./gradlew signingReport
```

#### 3.2 Copy SHA Keys

From the output, copy both:
- **SHA-1:** (looks like `8D:D9:96:DF:65:BB:...`)
- **SHA-256:** (looks like `28:D4:FC:77:3E:B9:...`)

#### 3.3 Add to Firebase

1. In Firebase Console → Project Settings
2. Scroll to "Your apps" section
3. Select your Android app
4. Click "Add fingerprint"
5. Paste SHA-1, click "Save"
6. Click "Add fingerprint" again
7. Paste SHA-256, click "Save"

### 4. Configure Firebase Authentication

#### 4.1 Enable Phone Authentication

1. In Firebase Console → Authentication
2. Click "Get started" (if first time)
3. Go to "Sign-in method" tab
4. Click "Phone" in the list
5. Toggle "Enable" switch
6. Click "Save"

#### 4.2 Add Test Phone Numbers (Optional - for Development)

For development without SMS costs:

1. In Firebase Console → Authentication → Sign-in method
2. Scroll to "Phone" section
3. Expand "Phone numbers for testing"
4. Click "Add phone number"
5. Enter:
   - Phone number: `+919999999999`
   - OTP code: `123456`
6. Click "Add"

**Note:** Test phone numbers only work in development. For production, you'll need:
- Firebase Blaze plan (pay-as-you-go)
- Real SMS will be sent to users

### 5. iOS Setup (Optional)

If you plan to support iOS:

#### 5.1 Add iOS App

1. In Firebase Console, click "Add app" → Select **iOS**
2. Enter iOS bundle ID: `com.example.traFpclApp`
3. Download `GoogleService-Info.plist`
4. Replace the file at:
   ```
   ios/Runner/GoogleService-Info.plist
   ```

#### 5.2 Get iOS SHA Fingerprints

```bash
cd ios
openssl x509 -in Runner/Runner.xcodeproj/project.pbxproj -fingerprint -sha256 -noout
```

Add these to Firebase Console as well.

## Files That Need to Be Replaced

### ✅ Required Changes

| File | Location | Action |
|------|----------|--------|
| `google-services.json` | `android/app/` | Replace with new file from Firebase |
| SHA Fingerprints | Firebase Console | Add your debug & release keys |
| Authentication Setup | Firebase Console | Enable Phone auth, add test numbers |

### ✅ Optional (iOS Support)

| File | Location | Action |
|------|----------|--------|
| `GoogleService-Info.plist` | `ios/Runner/` | Add new file from Firebase |

## Files That DON'T Need Changes

- ✓ `lib/main.dart` - No changes needed (Firebase auto-configures)
- ✓ `pubspec.yaml` - Same dependencies
- ✓ `lib/services/auth_service.dart` - Same code
- ✓ All other Dart files - No changes needed

## Verification Steps

After making changes:

### 1. Clean and Rebuild

```bash
flutter clean
flutter pub get
```

### 2. Run the App

```bash
flutter run
```

### 3. Test Authentication

1. Open the app
2. Select role (RAE/SME/ADMIN/SUPPLIER)
3. Enter test phone: `+919999999999`
4. Click "Send OTP"
5. Enter OTP: `123456`
6. Verify successful login

### 4. Check Firebase Console

1. Go to Firebase Console → Authentication → Users
2. You should see the new user listed after successful login

## Troubleshooting

### "Authentication failed" Error

**Problem:** Firebase not recognizing the app

**Solution:**
- Verify package name matches: `com.example.tra_fpcl_app`
- Ensure `google-services.json` is in correct location
- Clean and rebuild: `flutter clean && flutter pub get`

### "Test phone number not working"

**Problem:** Test number not configured in Firebase

**Solution:**
- Go to Firebase Console → Authentication → Sign-in method → Phone
- Add test number `+919999999999` with code `123456`

### "SHA fingerprint mismatch"

**Problem:** SHA keys not registered in Firebase

**Solution:**
- Run `./gradlew signingReport` in android folder
- Copy SHA-1 and SHA-256 from output
- Add both to Firebase Console → Project Settings → Your apps

### "Invalid API key"

**Problem:** Old `google-services.json` file

**Solution:**
- Delete old `android/app/google-services.json`
- Download fresh one from new Firebase project
- Restart IDE and rebuild

## Migration Checklist

Use this checklist when migrating to a new Firebase account:

- [ ] Create new Firebase project
- [ ] Add Android app with package name `com.example.tra_fpcl_app`
- [ ] Download and replace `google-services.json`
- [ ] Generate SHA-1 and SHA-256 keys using `gradlew signingReport`
- [ ] Add SHA keys to Firebase Console
- [ ] Enable Phone authentication
- [ ] Add test phone number `+919999999999` → `123456`
- [ ] Run `flutter clean`
- [ ] Run `flutter pub get`
- [ ] Run `flutter run`
- [ ] Test login with test phone number
- [ ] Verify user appears in Firebase Console → Authentication

## Important Notes

### Package Name

The package name `com.example.tra_fpcl_app` is hardcoded in:
- `android/app/build.gradle.kts`
- `google-services.json` expects this package name

If you change the package name, you'll need to:
1. Update `android/app/build.gradle.kts`
2. Rename package structure in `android/app/src/main/kotlin/`
3. Update Firebase registration accordingly

### Supabase Configuration

**No changes needed!** Supabase credentials are in `lib/main.dart`:
```dart
await Supabase.initialize(
  url: 'https://ootfxnlzoakvrajupnmf.supabase.co/',
  anonKey: '...',
);
```

Firebase and Supabase work independently. Changing Firebase doesn't affect Supabase.

### Production Deployment

For production:
1. Remove test phone numbers from Firebase
2. Upgrade to Firebase Blaze plan (for real SMS)
3. Generate release SHA keys:
   ```bash
   keytool -list -v -keystore release.keystore -alias release
   ```
4. Add release SHA keys to Firebase
5. Test with real phone numbers

## Support

If you encounter issues:
1. Check Firebase Console → Usage for error logs
2. Check Flutter console for detailed error messages
3. Verify all files are in correct locations
4. Ensure internet connectivity for Firebase calls
