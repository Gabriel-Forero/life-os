# Tech Stack Decisions -- Unit 0: Core Foundation

## Purpose

Documents all technology stack decisions for Unit 0 (Core Foundation). These decisions establish the standard for all subsequent LifeOS units. Every package choice includes version strategy, justification, and applicable security/PBT rule compliance.

**Target platforms**: iOS 16+ / Android API 26+
**Architecture**: 100% local-first, Riverpod + Drift, Result<T> error handling

---

## 1. Core Stack

| Component | Package | Version Strategy | Justification |
|---|---|---|---|
| UI Framework | Flutter SDK | Stable channel, pinned per release (e.g., 3.27.x) | Cross-platform native UI for iOS and Android from a single Dart codebase. Industry standard for multi-platform mobile apps. |
| Language | Dart SDK | Bundled with Flutter SDK | Dart's sound null safety, sealed classes, and pattern matching enable the Result<T> + AppFailure architecture. |
| State Management | `flutter_riverpod` | Exact version (e.g., `2.6.1`) | Compile-safe dependency injection, AsyncNotifier for loading/error/data states, provider scoping for testability. Chosen over Bloc for simpler boilerplate and native async support. |
| Database | `drift` | Exact version (e.g., `2.22.1`) | Type-safe SQLite ORM with compile-time query validation, migration system, and stream-based reactivity. Local-first persistence without a server. |
| SQLite Native | `sqlite3_flutter_libs` | Exact version (e.g., `0.5.28`) | Bundles the native SQLite library for consistent behavior across iOS and Android. Required by Drift. |
| Drift Code Gen | `drift_dev` | Exact version (dev_dependency) | Build runner for generating Drift table classes and DAO code from Dart annotations. |
| Build Runner | `build_runner` | Exact version (dev_dependency) | Required by Drift and other code generation packages. Runs `dart run build_runner build`. |
| Routing | `go_router` | Exact version (e.g., `14.8.1`) | Declarative routing with deep link support, redirect guards (for onboarding and biometric lock), and nested navigation. |
| Local Notifications | `flutter_local_notifications` | Exact version (e.g., `18.0.1`) | Cross-platform local push notifications with scheduling, channels (Android), and timezone support. No server dependency. |
| Biometric Auth | `local_auth` | Exact version (e.g., `2.3.0`) | Platform biometric authentication (fingerprint, Face ID, face unlock). Wraps iOS LocalAuthentication and Android BiometricPrompt. |
| Secure Storage | `flutter_secure_storage` | Exact version (e.g., `9.2.4`) | Encrypted key-value storage using iOS Keychain and Android EncryptedSharedPreferences. For API keys and sensitive tokens. |
| Typography | `google_fonts` | Exact version (e.g., `6.2.1`) | Provides Inter (body text) and JetBrains Mono (numeric/code displays) from bundled assets. No runtime download needed when fonts are pre-bundled. |
| Internationalization | `intl` | Exact version (e.g., `0.19.0`) | Date formatting, number formatting, and currency formatting with locale support (ES/EN). Foundation for l10n. |
| Device Info | `device_info_plus` | Exact version (e.g., `11.2.0`) | Retrieves device model and OS version for BackupManifest `deviceInfo` field. |
| File Picker | `file_picker` | Exact version (e.g., `8.1.7`) | Native file picker for backup import (select ZIP file) and export (save location). Cross-platform. |
| Archive | `archive` | Exact version (e.g., `3.6.1`) | ZIP file creation (backup export) and extraction (backup import). Pure Dart, no native dependencies. |
| Path Provider | `path_provider` | Exact version (e.g., `2.1.5`) | Provides platform-appropriate directories for database files and temporary backup staging. |
| Timezone | `timezone` | Exact version (e.g., `0.9.4`) | Timezone database for `flutter_local_notifications` TZDateTime scheduling. Ensures notifications fire at correct local time. |
| Riverpod Annotations | `riverpod_annotation` | Exact version (e.g., `2.6.1`) | Code generation for Riverpod providers using annotations (`@riverpod`). Reduces boilerplate. |
| Riverpod Generator | `riverpod_generator` | Exact version (dev_dependency) | Build runner plugin that generates provider code from `@riverpod` annotations. |

---

## 2. Testing Stack

| Component | Package | Version | Justification |
|---|---|---|---|
| Unit & Widget Tests | `flutter_test` | Bundled with Flutter SDK | Built-in test framework. Provides `testWidgets`, `find`, `expect`, `pump`. No additional dependency needed. |
| Property-Based Testing | `glados` | Exact version (e.g., `0.5.0`) | Dart PBT framework with automatic shrinking, custom generators via `Arbitrary<T>`, and seed-based reproducibility. Integrates with `dart test`. Selected per PBT-09 for Dart language support. |
| Mocking | `mocktail` | Exact version (e.g., `1.0.4`) | Null-safe mocking without code generation. Used to mock DAOs, services, and platform plugins in unit tests. Chosen over Mockito for zero-codegen simplicity. |
| Integration Tests | `integration_test` | Bundled with Flutter SDK | Built-in integration test driver. Runs on real devices/emulators. Tests full app flows (onboarding, backup, biometric). |
| Coverage | `coverage` | Exact version (dev_dependency) | Generates LCOV coverage reports from `flutter test --coverage` output. Feeds CI coverage gates. |

### Glados Configuration Details

**Why glados over other Dart PBT options**:
- `glados` is the most mature Dart-specific PBT library with automatic shrinking
- Supports custom `Arbitrary<T>` generators for domain types
- Seeds are logged on failure by default (PBT-08 compliance)
- Integrates directly with Dart `test` package (no custom test runner needed)
- Shrinking produces minimal failing examples automatically

**Custom Generators Required** (PBT-07 compliance):
- `Arbitrary<BackupManifest>` -- generates valid manifests with realistic module lists and version strings
- `Arbitrary<BackupModuleEntry>` -- generates valid module entries with constrained names and counts
- `Arbitrary<NotificationConfig>` -- generates valid configs with valid notification types, times, and repeat rules
- `Arbitrary<AppSettings>` -- generates valid settings respecting all field constraints (language in {es, en}, currency in supported list, etc.)
- `Arbitrary<AppEvent>` -- composite generator for all AppEvent subclasses with valid field ranges
- `Arbitrary<AppFailure>` -- composite generator for all AppFailure subclasses with non-empty messages

**Generator Location**: `test/pbt/generators/` directory with one file per domain type family.

---

## 3. Development Tools

### analysis_options.yaml Configuration

```yaml
include: package:flutter_lints/flutter.yaml

analyzer:
  errors:
    avoid_print: error
    prefer_const_constructors: warning
    prefer_const_declarations: warning
    missing_return: error
    dead_code: error
    unused_import: error
    unused_local_variable: warning
  language:
    strict-casts: true
    strict-raw-types: true

linter:
  rules:
    # Enforced rules (beyond flutter_lints defaults)
    - always_declare_return_types
    - avoid_print                          # Forces LogService usage (SECURITY-03)
    - avoid_dynamic_calls
    - avoid_empty_else
    - avoid_relative_lib_imports
    - avoid_returning_null_for_future
    - avoid_slow_async_io
    - avoid_type_to_string
    - avoid_unused_constructor_parameters
    - cancel_subscriptions                 # Prevents stream subscription leaks (SECURITY-15)
    - close_sinks                          # Prevents StreamController leaks (SECURITY-15)
    - collection_methods_unrelated_type
    - comment_references
    - literal_only_boolean_expressions
    - no_adjacent_strings_in_list
    - prefer_const_constructors
    - prefer_const_declarations
    - prefer_final_locals
    - prefer_single_quotes
    - sort_constructors_first
    - test_types_in_equals
    - throw_in_finally
    - unnecessary_await_in_return
    - unnecessary_statements
    - use_build_context_synchronously
```

### Recommended IDE Extensions

**VS Code**:
- Dart (official) -- Dart language support with analyzer integration
- Flutter (official) -- Flutter-specific tooling, hot reload, device management
- Flutter Riverpod Snippets -- Code snippets for Riverpod providers and notifiers
- Drift DB Viewer -- Visual inspection of Drift database schema
- Error Lens -- Inline display of analyzer errors and warnings

**Android Studio / IntelliJ**:
- Dart Plugin (official)
- Flutter Plugin (official)
- Flutter Riverpod Snippets

### CI/CD Approach

**Platform**: GitHub Actions

**Pipeline Stages**:

1. **Analyze**: `dart analyze --fatal-warnings` -- Fail on any analyzer warning or error
2. **Format Check**: `dart format --set-exit-if-changed .` -- Fail if any file is not formatted
3. **Test**: `flutter test --coverage` -- Run all unit, widget, and PBT tests
4. **Coverage Gate**: Check that coverage meets 80% threshold for core services/DAOs/notifiers
5. **Build (Android)**: `flutter build apk --release` -- Verify release build succeeds
6. **Build (iOS)**: `flutter build ios --release --no-codesign` -- Verify iOS release build compiles

**Triggers**:
- Push to `main` branch
- Pull request to `main` branch
- PBT seed logging: Test output is captured in CI artifacts for failure reproduction

---

## 4. Dependency Management Rules (SECURITY-10)

### Version Pinning Policy

All dependencies in `pubspec.yaml` use **exact versions** (no caret `^` or range `>=` syntax).

**Correct**:
```yaml
dependencies:
  flutter_riverpod: 2.6.1
  drift: 2.22.1
  go_router: 14.8.1
```

**Incorrect**:
```yaml
dependencies:
  flutter_riverpod: ^2.6.1    # NOT ALLOWED - allows minor/patch auto-updates
  drift: ">=2.22.0 <3.0.0"    # NOT ALLOWED - range specifier
```

### Lock File Policy

- `pubspec.lock` MUST be committed to version control
- `pubspec.lock` MUST NOT be in `.gitignore`
- All CI builds use `flutter pub get` (which respects the lock file), not `flutter pub upgrade`
- Lock file changes should be reviewed in pull requests (indicates dependency version changes)

### Dependency Audit Process

**Frequency**: Quarterly (every 3 months)

**Audit Steps**:
1. Run `dart pub outdated` to identify packages with newer versions
2. Review changelogs and release notes for each outdated package
3. Check for known vulnerabilities in outdated versions
4. Update packages one at a time with focused testing
5. Run full test suite after each update
6. Update `pubspec.yaml` with new exact versions
7. Commit updated `pubspec.lock`

### Unused Dependency Policy

- Run `dart pub deps --no-dev` and verify every listed package has at least one import in `lib/`
- Remove any package that is not actively imported
- `dev_dependencies` are audited separately (must be used in `test/` or build scripts)
- No "just in case" dependencies -- add packages when needed, not speculatively

### Trusted Sources Policy

- All packages MUST come from `pub.dev` (official Dart/Flutter package registry)
- No `git:` dependencies in `pubspec.yaml` for production code
- No `path:` dependencies in `pubspec.yaml` for production code (only allowed temporarily during local development of shared packages, never committed)
- Package publisher verification: prefer packages published by `dart.dev`, `google.dev`, or verified publishers with significant download counts

---

## 5. Project Directory Structure (Code Organization)

```
lib/
  core/
    database/
      app_database.dart          # Drift database definition
      app_database.g.dart        # Generated Drift code
      tables/
        app_settings_table.dart  # AppSettings Drift table
      daos/
        app_settings_dao.dart    # AppSettings DAO
    services/
      biometric_service.dart     # SECURITY-11: isolated security logic
      secure_storage_service.dart # SECURITY-11: isolated credential management
      notification_service.dart  # Local notification scheduling
      backup_service.dart        # Backup export/import with validation
      log_service.dart           # SECURITY-03: structured logging
      event_bus.dart             # Cross-module event bus
    models/
      app_failure.dart           # Sealed class hierarchy
      app_event.dart             # Sealed event hierarchy
      result.dart                # Result<T> type
      backup_manifest.dart       # BackupManifest value object
      notification_config.dart   # NotificationConfig value object
    notifiers/
      onboarding_notifier.dart   # Onboarding state machine
      theme_notifier.dart        # Theme mode management
      settings_notifier.dart     # AppSettings CRUD
    providers/
      providers.dart             # Riverpod provider definitions
    theme/
      app_theme.dart             # Dark and light ThemeData
      app_colors.dart            # Module accent colors, surface colors
      app_typography.dart        # Inter + JetBrains Mono text styles
    router/
      app_router.dart            # GoRouter configuration with guards
    l10n/
      app_localizations.dart     # Localization delegates
      arb/
        app_es.arb               # Spanish strings
        app_en.arb               # English strings
  features/
    onboarding/
      screens/                   # Onboarding screen widgets
      widgets/                   # Onboarding-specific widgets
    settings/
      screens/                   # Settings screen widgets
      widgets/                   # Settings-specific widgets
  main.dart                      # App entry point with global error handlers

test/
  unit/                          # Example-based unit tests
    core/
      services/
      models/
      notifiers/
      database/
  widget/                        # Widget tests
    features/
      onboarding/
      settings/
  pbt/                           # Property-based tests (glados)
    generators/                  # Custom Arbitrary<T> generators
      backup_manifest_gen.dart
      app_settings_gen.dart
      notification_config_gen.dart
      app_event_gen.dart
      app_failure_gen.dart
    roundtrip/                   # RT-01 through RT-05
    invariant/                   # INV-01 through INV-05
    idempotence/                 # IDP-01 through IDP-04
  integration/                   # Integration tests
    onboarding_flow_test.dart
```

---

## 6. Compliance Summary

### Security Extension (SECURITY-01 to SECURITY-15)

| Rule | Status | Rationale |
|---|---|---|
| SECURITY-01 | Compliant | Platform-level encryption at rest (OS sandbox for Drift/SQLite). flutter_secure_storage (Keychain / EncryptedSharedPreferences) for credentials. No network transit in local-only app. |
| SECURITY-02 | N/A | No network intermediaries (no load balancers, API gateways, or CDNs). 100% local-first app. |
| SECURITY-03 | Compliant | LogService provides structured logging with timestamp, level, component tag. `avoid_print` lint rule enforces usage. No PII in logs. |
| SECURITY-04 | N/A | No web endpoints. Native mobile app only, no HTML serving. |
| SECURITY-05 | Compliant | All inputs validated via allowlists, length bounds, and type checks in Notifier layer. Drift uses parameterized queries exclusively. |
| SECURITY-06 | Compliant | Minimum platform permissions (biometric, notifications, file access). All requested at point of use, not at install. AndroidManifest.xml and Info.plist declare only required permissions. |
| SECURITY-07 | N/A | No server networking, security groups, or network ACLs. |
| SECURITY-08 | Compliant | Biometric gate with opaque lock overlay when enabled. No IDOR risk (single local user). No CORS or token management needed. |
| SECURITY-09 | Compliant | No default credentials in codebase. Release builds strip debug info and asserts. AppFailure.userMessage is always generic. No sample/demo code. |
| SECURITY-10 | Compliant | All pubspec.yaml versions pinned exactly. pubspec.lock committed. Quarterly audit process documented. pub.dev only source. No unused packages. |
| SECURITY-11 | Compliant | BiometricService and SecureStorageService isolated in core/services/. Defense in depth: biometric gate + input validation + DB constraints + OS encryption. Misuse case documented (biometric bypass after 3 failures). |
| SECURITY-12 | Compliant | Biometric auth via local_auth. Credentials in flutter_secure_storage. No hardcoded secrets (lint-enforced). No password system. |
| SECURITY-13 | Compliant | BackupManifest.fromJson validates all fields before import. Fail-closed: invalid manifest aborts with no DB changes. Per-record validation during import. No unsafe deserialization. |
| SECURITY-14 | Compliant | Security events (auth attempts, backup operations, biometric enable/disable) logged via LogService with [SECURITY] tag. Console-based for local-only app. |
| SECURITY-15 | Compliant | Result<T> pattern for all business methods. Global error handler in main(). Fail closed on backup import. Resource cleanup via onDispose. Generic user-facing errors. cancel_subscriptions and close_sinks lint rules enabled. |

### PBT Extension (PBT-01 to PBT-10)

| Rule | Status | Rationale |
|---|---|---|
| PBT-01 | Compliant | 15 testable properties identified in Functional Design: 5 round-trip, 5 invariant, 4 idempotence, 1 commutativity. Components with no properties documented with rationale. |
| PBT-02 | Compliant | Round-trip PBT tests required for RT-01 through RT-05 (serialization/deserialization of BackupManifest, NotificationConfig, enabledModules, AppEvent). |
| PBT-03 | Compliant | Invariant PBT tests required for INV-01 through INV-05 (AppSettings constraints, onboarding completeness, event timestamps, failure messages, manifest record counts). |
| PBT-04 | Compliant | Idempotence PBT tests required for IDP-01 through IDP-04 (event processing, backup import, theme setting, notification scheduling). |
| PBT-05 | N/A | No reference implementations or oracle algorithms exist in Unit 0. All components are original implementations with no known brute-force alternative. |
| PBT-06 | N/A | Stateful components (EventBus, Notifiers) are tested via example-based state machine tests. Stateful PBT deferred -- the complexity of mocking platform plugins (local_auth, flutter_local_notifications) makes stateful PBT impractical for Unit 0. |
| PBT-07 | Compliant | Custom Arbitrary generators required for all domain types. Generators centralized in test/pbt/generators/. Generators respect business constraints (valid language codes, currency codes, module IDs, value ranges). |
| PBT-08 | Compliant | Glados logs seed and shrunk minimal example on failure by default. CI pipeline captures test output as artifacts. Instructions for seed replay documented. No shrinking override permitted. |
| PBT-09 | Compliant | Glados selected as PBT framework. Listed as dev_dependency with exact version. Supports custom generators, automatic shrinking, seed reproducibility, and Dart test integration. |
| PBT-10 | Compliant | Example-based tests cover all critical business paths (onboarding, backup, biometric, theme). PBT tests cover identified properties. Clear directory separation: test/unit/ and test/widget/ for example-based, test/pbt/ for property-based. PBT failures produce regression examples. |
