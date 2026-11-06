# Campus Events Management Application

A Flutter app for managing campus events, a marketplace, a lost & found board, and a
community forum — built around a soft, rounded "bubble" design system.

The app runs **immediately with mock data** (no backend setup required) so you can demo
every screen and the LLD logic. A drop-in **Firebase** layer is documented in
[§ Firebase Integration](#-firebase-integration-steps-59).

---

## Design System

| Token | Hex | Usage |
|-------|-----|-------|
| Primary | `#4D7FB0` | Main containers, major headers, primary buttons |
| Secondary accent | `#75A6D7` | App bars, text frames, main panels |
| Surface tint | `#C0D9F2` | Secondary card blocks, inactive icons |
| Neutral light base | `#FFFFFF` | Backgrounds, text input surfaces |

- **Typography:** Montserrat (via `google_fonts`) across the whole `TextTheme`.
- **Shapes:** everything is heavily rounded (`BorderRadius.circular(24)`+) with thick
  borders and generous padding.

All tokens live in [`lib/theme/theme.dart`](lib/theme/theme.dart).

---

## Project Structure

```
lib/
├── main.dart                      # Entry point, MaterialApp + theme
├── theme/
│   └── theme.dart                 # Colors, typography, shape tokens
├── models/
│   ├── user_profile.dart          # isValidated / isEnrolled flags
│   ├── event.dart
│   └── item.dart                  # Marketplace + Lost & Found shared template
├── services/                      # Swappable data layer (mock ↔ Firebase)
│   ├── auth_service.dart
│   ├── event_service.dart
│   └── item_service.dart
├── utils/
│   └── formatters.dart            # School ID **-**-**** input mask
├── widgets/                       # Reusable soft-rounded components
│   ├── pill_button.dart
│   ├── soft_card.dart
│   ├── rounded_text_field.dart
│   ├── section_header.dart
│   ├── event_card.dart
│   └── item_board_view.dart
└── screens/
    ├── welcome_screen.dart                 # Screen 1
    ├── signup_screen.dart                  # Screen 2 (School ID mask)
    ├── login_screen.dart                   # Screen 3 (isValidated routing)
    ├── verification_screen.dart            # Screen 4 (4-digit code)
    ├── enrollment_verification_screen.dart # Redirect target for unvalidated users
    ├── main_layout_shell.dart              # Persistent nav shell + Drawer
    ├── dashboard_screen.dart               # Screen 5
    ├── profile_screen.dart                 # Screen 6
    ├── campus_map_screen.dart              # Screen 7 (FAB → event form)
    ├── event_creation_form_screen.dart     # 15-min countdown LLD
    ├── campus_marketplace_screen.dart      # Screen 8
    ├── lost_and_found_screen.dart          # Screen 9
    └── community_forum_screen.dart         # Screen 10
```

---

## How to Run (mock mode — works right now)

```bash
flutter pub get
flutter run            # pick a device/emulator, or:
flutter run -d chrome  # run in the browser
```

### Demo logins (password: `password123`)

| Email | Result |
|-------|--------|
| `validated@campus.edu` | `isValidated = true` → goes straight to the **Dashboard** |
| `pending@campus.edu` | `isValidated = false` → redirected to **Enrollment Verification** |

New sign-ups always start as `isValidated = false`.

### LLD behaviors to try
- **School ID mask:** type digits in the Sign Up "School ID" field — it auto-formats to
  `**-**-****`.
- **Security routing:** log in with each demo account to see both branches.
- **15-minute timeout:** open Campus Map → FAB (`+`) → the banner counts down from `15:00`.
  Publish before `00:00` saves the event; let it hit `00:00` to see the timeout dialog and
  forced pop back to the dashboard.

---

## 🔌 Firebase Integration (Steps 5–9)

The mock services already mirror the Firebase call shapes, so wiring the real backend is a
focused change. Do this **after** the frontend demo is approved.

### Step 1 — Firebase Console (browser)
1. Create a project named **Campus Events App**.
2. **Authentication** → enable the **Email/Password** provider.
3. **Cloud Firestore** → create database in **Test Mode**.
4. **Storage** → enable (for Marketplace / Verification uploads).

### Step 2 — Wire the SDK into the Flutter project
```bash
# one-time tooling
dart pub global activate flutterfire_cli

# add packages
flutter pub add firebase_core firebase_auth cloud_firestore firebase_storage

# generates lib/firebase_options.dart from YOUR console project
flutterfire configure
```
Then in `lib/main.dart`:
```dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const CampusEventsApp());
}
```

> **⚠️ Android config (avoids the most common Firebase build failures).**
> Firebase requires a higher `minSdk` and multidex. In
> `android/app/build.gradle.kts`, set:
> ```kotlin
> android {
>     defaultConfig {
>         minSdk = 23            // firebase_auth requires 23+
>         multiDexEnabled = true
>     }
> }
> ```
> `flutterfire configure` adds `google-services.json` and the Google Services
> Gradle plugin automatically — just make sure that file exists before building.

### Step 3 — Auth + profile creation + `isValidated` check
Replace the bodies of `AuthService.signUp` / `signIn` (`lib/services/auth_service.dart`):
```dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<UserProfile> signUp({
  required String fullName,
  required String schoolEmail,
  required String schoolID,
  required String password,
  required String address,
}) async {
  final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
    email: schoolEmail, password: password,
  );
  final uid = cred.user!.uid;
  final profile = UserProfile(
    uid: uid, schoolID: schoolID, schoolEmail: schoolEmail,
    fullName: fullName, isEnrolled: true, isValidated: false,
  );
  // Document ID == uid
  await FirebaseFirestore.instance.collection('Users').doc(uid).set(profile.toMap());
  _current = profile;
  return profile;
}

Future<UserProfile> signIn({required String email, required String password}) async {
  final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
    email: email, password: password,
  );
  final snap = await FirebaseFirestore.instance
      .collection('Users').doc(cred.user!.uid).get();
  final profile = UserProfile.fromMap(snap.data() ?? {});
  _current = profile;
  return profile;            // login_screen.dart already routes on profile.isValidated
}
```
The routing in `login_screen.dart` is already written:
`isValidated == true → MainLayoutShell`, else `→ EnrollmentVerificationScreen`.
The existing `CircularProgressIndicator` (`PillButton.loading`) covers the network wait.

### Step 4 — Events engine (Firestore stream + timeout-guarded write)
In `lib/services/event_service.dart`, swap the in-memory store for Firestore:
```dart
Stream<List<CampusEvent>> get stream => FirebaseFirestore.instance
    .collection('Events')
    .snapshots()
    .map((s) => s.docs.map((d) => CampusEvent.fromMap(d.id, d.data())).toList());

Future<void> addEvent(CampusEvent e) =>
    FirebaseFirestore.instance.collection('Events').add(e.toMap());
```
`DashboardScreen` and `CampusMapScreen` already consume this via `StreamBuilder`.
`EventCreationFormScreen` already calls `addEvent` only when the user publishes **before**
the 15-minute timer hits `00:00`; on timeout it pops without writing.

### Step 5 — Marketplace & Lost & Found (filtered `Items` stream)
In `lib/services/item_service.dart`:
```dart
Stream<List<MarketItem>> streamByType(PostType type) => FirebaseFirestore.instance
    .collection('Items')
    .where('postType', isEqualTo: type.value)   // 'marketplace' | 'lost_found'
    .snapshots()
    .map((s) => s.docs.map((d) => MarketItem.fromMap(d.id, d.data())).toList());

Future<void> addItem(MarketItem i) =>
    FirebaseFirestore.instance.collection('Items').add(i.toMap());
```
`MarketItem.toMap()` already writes `itemID, title, description, price (null for
lost_found), postType, posterID, imageURL`.

### Step 6 — Image upload (Firebase Storage)
`image_picker` is already a dependency. Add a helper:
```dart
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

Future<String?> pickAndUploadImage() async {
  final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
  if (picked == null) return null;
  final ref = FirebaseStorage.instance
      .ref('item_images/${DateTime.now().millisecondsSinceEpoch}.jpg');
  await ref.putFile(File(picked.path));
  return ref.getDownloadURL();   // store this in the imageURL field before the write
}
```
Call it from the create-listing form, then include the returned URL in `MarketItem.toMap()`.

> **Android setup for image_picker:** none required for gallery on API 33+. For camera,
> add `<uses-permission android:name="android.permission.CAMERA"/>` to
> `android/app/src/main/AndroidManifest.xml`.

---

## Production Build (Step 9)

### Pre-flight audit
```bash
flutter analyze        # currently: No issues found
flutter pub outdated   # optional: review dependency updates
```
All async snapshots use `StreamBuilder`/`FutureBuilder` with loading + empty fallbacks, and
models use null-safe `fromMap` defaults — no unchecked nulls.

### Build a release APK
```bash
flutter build apk --release
# output: build/app/outputs/flutter-apk/app-release.apk

# smaller, per-ABI APKs:
flutter build apk --release --split-per-abi

# Play Store bundle:
flutter build appbundle --release
```

### Avoiding ProGuard / signing errors
- **Debug-signed release for testing:** `flutter build apk --release` works out of the box
  with the default debug keystore for sideloading — no signing config needed.
- **Disable shrinking** if you hit R8/ProGuard stripping issues, in
  `android/app/build.gradle`:
  ```gradle
  buildTypes {
      release {
          minifyEnabled false
          shrinkResources false
          signingConfig signingConfigs.debug   // for test builds only
      }
  }
  ```
- **Real release signing:** create a keystore with `keytool`, add a
  `android/key.properties`, and reference it in `build.gradle` per the
  [official guide](https://docs.flutter.dev/deployment/android#signing-the-app).
- If Firebase is enabled, ensure `android/app/google-services.json` exists (added by
  `flutterfire configure`) before building.
