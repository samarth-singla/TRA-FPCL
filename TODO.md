# TRA FPCL Project TODO

## 🔴 Critical Setup Tasks (Required to Run)

### 1. Firebase Configuration - COMPLETE ✅

**Android Setup:**
- [x] Add `google-services.json` to `android/app/` directory ✅
  - Firebase project: `tra-fpcl`
  - Package name: `com.example.tra_fpcl_app`
  - File verified and in place

**iOS Setup (if targeting iOS):**
- [ ] Add `GoogleService-Info.plist` to iOS project
  - Download from Firebase Console
  - Add iOS app with bundle ID: `com.example.tra_fpcl_app`
  - Open `ios/Runner.xcworkspace` in Xcode
  - Drag and drop the file into Runner folder

**Web Setup (if targeting web):**
- [ ] Add Firebase config to `web/index.html`
  - Get web config from Firebase Console
  - Add before `</body>` tag

### 2. Firebase Phone Authentication Setup - COMPLETE ✅

- [x] Enable Phone Authentication in Firebase Console
  - Authentication → Sign-in method → Phone enabled
- [x] Add SHA-1 and SHA-256 keys (completed):
    - **SHA-1:** `8D:D9:96:DF:65:BB:4A:5F:DC:9B:7A:49:03:5E:E3:83:42:46:D3:A3`
    - **SHA-256:** `28:D4:FC:77:3E:B9:EA:B5:4F:69:84:B3:20:76:BC:28:63:BF:71:DE:62:9D:5D:9D:38:96:09:E6:A8:38:AA:5E`
  - Added in Project Settings → Your apps → Android app → SHA certificate fingerprints ✅

### 3. Supabase Database Configuration - COMPLETE ✅

- [x] Supabase credentials added to `main.dart`
- [x] Created `profiles` table
- [ ] **Verify profiles table schema has these columns:**
  ```sql
  - uid (text, primary key)
  - phone (text)
  - role (text, default: 'RAE')
  - name (text, optional)
  - email (text, optional)
  - created_at (timestamp)
  - updated_at (timestamp)
  ```

### 4. Windows Developer Mode - OPTIONAL ⚠️

- [ ] Enable Developer Mode (only needed if symlink issues occur)
  - Run: `start ms-settings:developers`
  - Toggle "Developer Mode" to ON
  - Restart your terminal/IDE

---

## 🟢 READY TO RUN! Your app is configured and ready for development.

## 🟡 Implementation Tasks (Next Development Steps)

### Phase 1: Phone Authentication UI (PRIORITY)

- [ ] Create Phone Login Screen
  - [ ] Design phone number input field with country code picker
  - [ ] Add "Send OTP" button
  - [ ] Implement phone number validation
  - [ ] Show loading indicator during OTP sending

- [ ] Create OTP Verification Screen
  - [ ] Design OTP input field (6 digits)
  - [ ] Add "Verify OTP" button
  - [ ] Implement OTP validation
  - [ ] Add "Resend OTP" functionality
  - [ ] Show timer for OTP expiration

- [ ] Integrate with AuthService
  - [ ] Call `authService.sendOTP()` from phone input screen
  - [ ] Call `authService.verifyOTP()` from OTP verification screen
  - [ ] Handle errors and show user-friendly messages
  - [ ] Navigate to Dashboard on successful login

### Phase 2: Project Structure Organization

- [ ] Create folder structure:
  ```
  lib/
    ├── screens/
    │   ├── auth/
    │   │   ├── login_screen.dart
    │   │   ├── otp_verification_screen.dart
    │   ├── dashboard/
    │   │   ├── dashboard_screen.dart
    ├── services/
    │   ├── auth_service.dart ✅ (DONE)
    ├── widgets/
    │   ├── auth_wrapper.dart
    ├── models/
    │   ├── user_profile.dart
    ├── utils/
    │   ├── constants.dart
    │   ├── validators.dart
  ```

- [ ] Move widgets to separate files:
  - [ ] Extract `AuthWrapper` → `lib/widgets/auth_wrapper.dart`
  - [ ] Extract `LoginScreen` → `lib/screens/auth/login_screen.dart`
  - [ ] Extract `DashboardScreen` → `lib/screens/dashboard/dashboard_screen.dart`

### Phase 3: Dashboard Features

- [ ] Create basic dashboard layout
  - [ ] Add navigation drawer/bottom nav
  - [ ] Display user profile info from Supabase
  - [ ] Add profile picture placeholder
  - [ ] Show user role badge

- [ ] Profile Management
  - [ ] Create profile edit screen
  - [ ] Implement profile update functionality
  - [ ] Add image picker for profile picture

### Phase 4: Role-Based Access Control

- [ ] Implement role-based routing
  - [ ] Create separate dashboards for different roles (RAE, Admin, etc.)
  - [ ] Add role checking in AuthWrapper
  - [ ] Restrict access to certain features based on role

### Phase 5: Error Handling & UX

- [ ] Add comprehensive error handling
  - [ ] Network error handling
  - [ ] Firebase auth errors
  - [ ] Supabase query errors
  
- [ ] Add loading states
  - [ ] Global loading indicator
  - [ ] Shimmer effects for loading content
  
- [ ] Add user feedback
  - [ ] Success/error snackbars
  - [ ] Toast messages
  - [ ] Dialog confirmations

### Phase 6: Testing & Security

- [ ] Add input validation
  - [ ] Phone number format validation
  - [ ] OTP format validation
  
- [ ] Implement security best practices
  - [ ] Add rate limiting for OTP requests
  - [ ] Secure storage for sensitive data
  
- [ ] Test phone authentication flow
  - [ ] Test with real phone numbers
  - [ ] Test OTP verification
  - [ ] Test profile creation in Supabase
  - [ ] Test sign out functionality

---

## 🟢 Optional Enhancements

- [ ] Add support for other authentication methods
  - [ ] Email/Password (if needed)
  - [ ] Google Sign-In
  - [ ] Apple Sign-In (for iOS)

- [ ] Implement offline support
  - [ ] Cache user profile locally
  - [ ] Handle offline scenarios

- [ ] Add analytics
  - [ ] Firebase Analytics
  - [ ] Track user login events
  - [ ] Track screen views

- [ ] Internationalization (i18n)
  - [ ] Add multi-language support
  - [ ] Localize strings

- [ ] Add app theme customization
  - [ ] Light/Dark mode toggle
  - [ ] Custom color schemes

---

## 📝 Documentation Tasks

- [ ] Document API integration
- [ ] Create user guide
- [ ] Add inline code documentation
- [ ] Create README with setup instructions

---

## 🛠️ Technical Debt

- [ ] Add state management solution (Provider, Riverpod, or Bloc)
- [ ] Implement proper dependency injection
- [ ] Add unit tests
- [ ] Add widget tests
- [ ] Add integration tests
- [ ] Set up CI/CD pipeline

---

## ✅ Completed Tasks

- [x] Initialize Flutter project
- [x] Add Firebase and Supabase dependencies
- [x] Configure Android build files for Firebase
- [x] Initialize Firebase in main.dart
- [x] Initialize Supabase in main.dart
- [x] Create AuthService class with phone authentication
- [x] Implement profile creation in Supabase
- [x] Set up AuthWrapper for authentication routing
- [x] Create placeholder Dashboard and Login screens
- [x] Get SHA-1 and SHA-256 keys for Firebase
- [x] Create Supabase profiles table

---

## 🚀 Quick Start Commands

```bash
# Run the app (after completing critical setup)
flutter run

# Run on specific device
flutter run -d windows
flutter run -d chrome
flutter run -d <device-id>

# Build APK for testing
flutter build apk --debug

# Build release APK
flutter build apk --release

# Check for issues
flutter doctor -v

# Update dependencies
flutter pub get
```

---

## 📞 Support Resources

- Firebase Console: https://console.firebase.google.com
- Supabase Dashboard: https://app.supabase.com
- Flutter Documentation: https://flutter.dev/docs
- Firebase Auth Documentation: https://firebase.google.com/docs/auth
- Supabase Documentation: https://supabase.com/docs

---

**Last Updated:** February 3, 2026
