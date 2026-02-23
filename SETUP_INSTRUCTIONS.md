# Firebase and Supabase Setup Instructions

## ✅ Completed Steps

1. ✅ Added Firebase and Supabase dependencies to `pubspec.yaml`
2. ✅ Updated `main.dart` with initialization code
3. ✅ Configured Android build files for Firebase
4. ✅ Installed all dependencies

## 🔧 Next Steps

### 1. Configure Supabase

In `lib/main.dart`, replace the placeholder values:

```dart
await Supabase.initialize(
  url: 'YOUR_SUPABASE_URL',  // Replace with your project URL
  anonKey: 'YOUR_SUPABASE_ANON_KEY',  // Replace with your anon key
);
```

**Get your credentials:**
1. Go to [Supabase Dashboard](https://app.supabase.com)
2. Select your project (or create a new one)
3. Go to Settings → API
4. Copy the "Project URL" and "anon public" key

### 2. Configure Firebase

#### For Android:

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Create a new project or select an existing one
3. Add an Android app to your Firebase project
4. Use package name: `com.example.tra_fpcl_app`
5. Download the `google-services.json` file
6. Place it in: `android/app/google-services.json`

#### For iOS:

1. In Firebase Console, add an iOS app
2. Use bundle ID: `com.example.tra_fpcl_app`
3. Download `GoogleService-Info.plist`
4. Open `ios/Runner.xcworkspace` in Xcode
5. Drag and drop `GoogleService-Info.plist` into the Runner folder
6. Make sure "Copy items if needed" is checked

#### For Web:

1. In Firebase Console, add a Web app
2. Copy the Firebase configuration
3. Add it to `web/index.html` before `</body>`:

```html
<script type="module">
  import { initializeApp } from "https://www.gstatic.com/firebasejs/10.7.0/firebase-app.js";
  const firebaseConfig = {
    apiKey: "YOUR_API_KEY",
    authDomain: "YOUR_AUTH_DOMAIN",
    projectId: "YOUR_PROJECT_ID",
    storageBucket: "YOUR_STORAGE_BUCKET",
    messagingSenderId: "YOUR_MESSAGING_SENDER_ID",
    appId: "YOUR_APP_ID"
  };
  initializeApp(firebaseConfig);
</script>
```

### 3. Enable Developer Mode (Windows)

To build with plugins on Windows, enable Developer Mode:

1. Run: `start ms-settings:developers`
2. Toggle "Developer Mode" to ON
3. Restart your terminal

### 4. Test Your Setup

Run the app to verify everything is configured correctly:

```bash
flutter run
```

## 📦 Installed Packages

- `firebase_core: ^3.8.1` - Firebase SDK initialization
- `firebase_auth: ^5.3.4` - Firebase Authentication
- `supabase_flutter: ^2.9.2` - Supabase client for Flutter

## 🔗 Useful Resources

- [Firebase Documentation](https://firebase.google.com/docs/flutter/setup)
- [Supabase Documentation](https://supabase.com/docs/guides/getting-started/quickstarts/flutter)
- [FlutterFire GitHub](https://github.com/firebase/flutterfire)
