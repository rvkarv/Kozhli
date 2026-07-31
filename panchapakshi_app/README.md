# கோழி பட்சி — Panchapakshi Master App (Flutter)

Real-time Panchapakshi Sastra engine + app for **கோழி (Hen)**, built to be
the master template for the remaining four birds (ஆந்தை, காகம், மயில்,
வல்லூறு) — see "Extending to the other 4 birds" below.

## 1. What's in this codebase

```
lib/
  models/
    pakshi.dart              enums: Pakshi, Thozhil, Paksham, DayNight
    panchapakshi_state.dart  one computed real-time snapshot
  core/
    panchapakshi_rules.dart  ALL lookup tables, transcribed from your
                             "Panchapatchi_Rules_1.xlsx" workbook
                             (Tables 5–10, Gowri Panchangam, Horai)
    sun_calculator.dart      NOAA sunrise/sunset algorithm (lat/lng/date)
    moon_phase.dart          வளர்பிறை/தேய்பிறை (waxing/waning) calculator
    panchapakshi_engine.dart the real-time engine: Jamam → Antharam →
                             Vinadi countdown, next activity, per the
                             Excel "Standard Alignment" formula
    gowri_horai.dart         Gowri Panchangam + Horai (fixed-clock tables)
  services/
    location_service.dart    GPS + manual search + sunrise/sunset window
    app_state.dart           1-second ticking state, feeds the UI
  screens/
    home_screen.dart         live dashboard
    location_picker_screen.dart
    forecast_screen.dart     tomorrow → 7 days ahead
  widgets/
    activity_card.dart, countdown_ring.dart
  main.dart
pubspec.yaml
android/AndroidManifest_ADDITIONS.xml   (permissions to merge in)
ios_Info_plist_ADDITIONS.xml            (permissions to merge in)
```

**This is real, complete Dart/Flutter source — not a mockup.** Every
number in `panchapakshi_rules.dart` was transcribed directly from your
workbook's `பஞ்சபட்சி RULES` sheet (Tables 5 through 10), and the
Jamam/Antharam math in `panchapakshi_engine.dart` implements your
Excel formula exactly:

```
Day Length            = Sunset - Sunrise
Jamam Duration         = Day Length / 5
Antara Duration        = Jamam Duration / 5
Night Jamam Duration   = (Next Sunrise - Sunset) / 5
Night Antara Duration  = Night Jamam Duration / 5
```

## 2. How to turn this into a runnable app (you or your developer)

### Option A — no installation needed on your computer (recommended)
This project includes `.github/workflows/build-apk.yml`, which builds
the release APK for you automatically on GitHub's free servers:

1. Create a free GitHub account, create a new **private** repository.
2. Upload this whole `panchapakshi_app/` folder into it.
3. Open the repo's **Actions** tab — the build starts by itself.
4. When it finishes (green check, ~5-8 min), open that run → under
   **Artifacts** download `app-release-apk` → unzip it →
   `app-release.apk` is your installable file.
5. Send that APK file directly (WhatsApp, Drive, email) to install on
   any Android phone — nothing is published anywhere public.

A private repo is never listed publicly; it's just where the source
code sits while GitHub's robot builds it. This path needs no Flutter,
Android Studio, or Mac — just a free GitHub account.

### Option B — build locally (if you have a developer's machine)

I can't run Xcode/Android Studio or sign builds from this chat, so the
remaining steps need a machine with Flutter installed:

1. Install Flutter: https://docs.flutter.dev/get-started/install
2. Copy this whole folder somewhere, then inside it run:
   ```
   flutter create . --org com.yourcompany.panchapakshi --project-name panchapakshi_kozhi
   ```
   This generates the missing native `android/` and `ios/` scaffolding
   (Gradle files, Xcode project, etc.) around the `lib/` code you
   already have — it will NOT overwrite the `lib/` folder.
3. Merge `android/AndroidManifest_ADDITIONS.xml` into the generated
   `android/app/src/main/AndroidManifest.xml`.
4. Merge `ios_Info_plist_ADDITIONS.xml` into the generated
   `ios/Runner/Info.plist`.
5. `flutter pub get`
6. Run on a device/emulator: `flutter run`
7. Build release artifacts:
   - Android APK: `flutter build apk --release`
   - Android App Bundle: `flutter build appbundle --release`
   - iOS (needs a Mac + Apple Developer account):
     `flutter build ipa --release`

### Tamil font
Add a Tamil-supporting font (e.g. Noto Sans Tamil) under `assets/fonts/`
and register it in `pubspec.yaml` under `flutter: fonts:` — the theme
in `main.dart` already references `NotoSansTamil` by name.

### Google Maps / geocoding key
Manual place search uses the `geocoding` plugin, which uses the native
OS geocoder (no API key needed on most devices) with Apple/Google's
built-in services. If you want the higher-accuracy **Google Places
Autocomplete** experience instead, swap `location_service.dart`'s
`searchPlace()` to call the Google Places API with your own key — the
rest of the app is unaffected since it only consumes `ResolvedLocation`.

## 3. Known accuracy notes (read before publishing)

- **Paksham (waxing/waning)** in `moon_phase.dart` uses a mean-synodic-
  month approximation, accurate to roughly ±1 day. True Panchapakshi
  Sastra should use precise Thithi from actual Sun-Moon longitude. For
  production, swap this one function for a proper ephemeris/panchangam
  API — nothing else in the app needs to change.
- **Time zones**: `location_service.dart` converts sunrise/sunset to
  the *device's* local time zone. This is correct for GPS mode. For
  manual search of a place in a different time zone than the device,
  add a lat/lng → timezone lookup before the `.toLocal()` call (flagged
  in code with a comment).
- Nakshatra-based லக்னப் பட்சி / ராசிப் பட்சி (birth-star/rasi bird
  lookup) tables (Table 5) are included in `panchapakshi_rules.dart`
  (`birdForStar`) but not yet wired into a UI screen — the engine
  currently always uses the fixed கோழி bird as the "self" bird. Add a
  birth-star input screen and call `birdForStar()` if you want a
  personalized (not just species-level) reading.

## 4. Extending to the other 4 Pakshi apps

The engine is species-agnostic — `Pakshi.kozhi` is just one of five
enum values, and every rule table already lists all 5 birds. To ship
ஆந்தை/காகம்/மயில்/வல்லூறு:

1. Duplicate this project.
2. Change `AppState.bird` default to the new `Pakshi` value.
3. Change app name/icon/title strings.

No engine or rules-table changes needed — same core, per your request
to build and test கோழி first, then reuse the engine.

## 5. Licensing / device-binding / admin panel

This is now implemented — see the sibling `panchapakshi_backend/`
folder (Cloud Functions + admin web panel) and
`lib/services/activation_service.dart` + `lib/screens/activation_screen.dart`
in this app, which gate the dashboard behind mobile+OTP activation.
Follow `panchapakshi_backend/README.md` to deploy it to your own
Firebase project — that part needs your own accounts/billing, which I
can't provision for you.

Design summary (already built, per `panchapakshi_backend/README.md`):

**Mobile app side:**
- On first launch, show a registration screen: mobile number → OTP
  (Firebase Phone Auth handles send/verify).
- On success, generate a stable device fingerprint (e.g.
  `device_info_plus` package: device ID + install ID) and register
  `{mobile_number, device_id}` in Firestore via a Cloud Function.
- On every subsequent launch, the app calls a Cloud Function that
  checks `{mobile_number, device_id}` is still the *active* pair for
  that user. If not (e.g. admin deactivated it), show "Activation
  Required" and block the dashboard.

**Cloud Functions (backend logic):**
- `registerDevice(mobile, deviceId)` — enforces "one active device per
  mobile number" by deactivating any prior device on new activation
  approval.
- `checkActivation(mobile, deviceId)` — called on app launch.
- `generateActivationKey(mobile)` — admin-triggered, for manual device
  transfers.

**Firestore schema (suggested):**
```
users/{mobileNumber}
  status: active | blocked
  validity: lifetime | { subscriptionEnd: timestamp }
  activeDeviceId: string
  loginHistory: [ { deviceId, timestamp, ipHash } ]
```

**Admin portal (web):**
- A simple Flutter Web or React app, restricted to your login only
  (Firebase Auth with your email, or a fixed admin password + IP
  allowlist).
- Screens: pending registrations, approve/block user, deactivate old
  device / activate new device, view login history, set validity type.

I've scoped this in detail so it's a well-defined follow-on project,
but actually building and hosting it needs your Firebase project, an
SMS OTP provider account, and a place to deploy the admin web app —
say the word and I can write the Cloud Functions and admin panel code
next.
