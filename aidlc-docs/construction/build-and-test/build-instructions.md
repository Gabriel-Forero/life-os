# Build Instructions — LifeOS

## Prerequisites

- **Flutter SDK**: 3.35.7+ (stable channel)
- **Dart SDK**: 3.9.2+ (bundled with Flutter)
- **Platform**: Windows 11 / macOS 14+ / Linux
- **Android SDK**: API 26+ (for Android builds)
- **Xcode**: 15+ (for iOS builds, macOS only)
- **Disk Space**: ~2GB (Flutter SDK + dependencies + build artifacts)

## Build Steps

### 1. Install Dependencies

```bash
flutter pub get
```

**Expected**: "Got dependencies!" with 0 errors. ~100 packages resolved.

### 2. Generate Drift Code

```bash
dart run build_runner clean
dart run build_runner build --delete-conflicting-outputs
```

**Expected**: ~220 outputs generated. Creates `.g.dart` files for:
- `lib/core/database/app_database.g.dart`
- `lib/core/database/daos/app_settings_dao.g.dart`
- `lib/features/finance/database/finance_dao.g.dart`
- `lib/features/gym/database/gym_dao.g.dart`
- `lib/features/nutrition/database/nutrition_dao.g.dart`
- `lib/features/habits/database/habits_dao.g.dart`
- `lib/features/dashboard/database/dashboard_dao.g.dart`
- `lib/features/sleep/database/sleep_dao.g.dart`
- `lib/features/mental/database/mental_dao.g.dart`
- `lib/features/goals/database/goals_dao.g.dart`
- `lib/features/intelligence/database/ai_dao.g.dart`

### 3. Generate Localizations

```bash
flutter gen-l10n
```

**Expected**: Generates `lib/l10n/app_localizations.dart`, `app_localizations_es.dart`, `app_localizations_en.dart`.

### 4. Run Static Analysis

```bash
dart analyze lib/
```

**Expected**: 0 errors. Warnings acceptable (const suggestions, deprecated API usage).

### 5. Build Android APK

```bash
flutter build apk --release
```

**Expected**: `build/app/outputs/flutter-apk/app-release.apk`

### 6. Build iOS (macOS only)

```bash
flutter build ios --release --no-codesign
```

**Expected**: Successful build (codesigning requires provisioning profile).

## Troubleshooting

### "Target of URI hasn't been generated"
**Cause**: Drift code generation not run.
**Fix**: `dart run build_runner build --delete-conflicting-outputs`

### "pubspec.lock out of date"
**Cause**: Dependencies changed.
**Fix**: `flutter pub get`

### Build runner skips files
**Cause**: Stale build cache.
**Fix**: `dart run build_runner clean && dart run build_runner build --delete-conflicting-outputs`

### Schema version mismatch at runtime
**Cause**: Database migration not updated.
**Fix**: Check `app_database.dart` schemaVersion matches latest migration (currently v9).
