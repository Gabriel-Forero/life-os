# NFR Requirements -- Unit 0: Core Foundation

## Purpose

Defines all non-functional requirements for Unit 0 (Core Foundation) of the LifeOS Flutter application. Each requirement includes an ID, description, acceptance criteria, and references to applicable extension rules (SECURITY-XX, PBT-XX).

**Target platforms**: iOS 16+ / Android API 26+
**Architecture**: 100% local-first, no server infrastructure

---

## 1. Security Requirements

### NFR-SEC-01: Encryption at Rest via Platform Defaults

**Applicable Rule**: SECURITY-01
**Status**: COMPLIANT via platform defaults

**Description**: All persistent data is protected at rest through platform-level encryption. Drift/SQLite database files reside in the app sandbox, which is encrypted by the OS when the device has a passcode or biometric enrolled. Sensitive values (future API keys, tokens) are stored via `flutter_secure_storage`, which delegates to iOS Keychain (AES-256) and Android EncryptedSharedPreferences (AES-256-GCM).

**Compliance Approach**:
- Drift database files are stored in the default app-private directory (iOS: `NSDocumentDirectory`, Android: `getDatabasesPath()`). Both platforms encrypt app sandbox storage when device passcode is set.
- `flutter_secure_storage` uses iOS Keychain and Android Keychain/EncryptedSharedPreferences for credential storage.
- No custom encryption layer is needed for Unit 0 since there is no network transit (local-only app).

**Acceptance Criteria**:
- Drift database path resolves to the platform-protected app directory
- `flutter_secure_storage` is used for any sensitive value (API keys, tokens) -- not SharedPreferences or plain files
- No sensitive data is stored in plain text files or unprotected locations
- No database connection strings exist (embedded SQLite, no remote connections)

---

### NFR-SEC-02: Access Logging on Network Intermediaries

**Applicable Rule**: SECURITY-02
**Status**: N/A

**Rationale**: LifeOS Unit 0 is a 100% local-first application with no load balancers, API gateways, CDN distributions, or any network intermediaries. No external traffic is handled.

---

### NFR-SEC-03: Structured Application Logging

**Applicable Rule**: SECURITY-03
**Status**: APPLICABLE

**Description**: The application must include a structured logging framework. Logs must include timestamp, log level, component name, and message. Personally Identifiable Information (PII) must never appear in log output.

**Compliance Approach**:
- Implement a `LogService` in `lib/core/services/` that wraps Dart's `developer.log()` with structured fields.
- All log entries include: ISO 8601 timestamp, log level (debug, info, warning, error), component tag (e.g., `BackupService`, `OnboardingNotifier`), and human-readable message.
- In release mode, only `warning` and `error` levels are emitted. In debug mode, all levels are active.
- PII guard: `LogService` never accepts raw user names, email addresses, or financial amounts. Callers log entity IDs and operation names, not user data.
- Logs are directed to platform console (`developer.log` on debug, `stdout` on release). For a local-only app without a centralized log service, local console output satisfies the spirit of SECURITY-03. Future versions may add Crashlytics or Sentry integration.

**Acceptance Criteria**:
- Every service and Notifier uses `LogService` (no ad-hoc `print()` in production code)
- Log output includes timestamp, level, component tag, and message
- Grep of entire codebase for `print(` in `lib/` yields zero hits outside of `LogService` (enforced via lint rule)
- No PII (userName, financial amounts, health data) appears in any log statement
- Release builds suppress debug-level logs

---

### NFR-SEC-04: HTTP Security Headers

**Applicable Rule**: SECURITY-04
**Status**: N/A

**Rationale**: LifeOS Unit 0 does not serve web content. There are no HTML-serving endpoints, no web server, and no HTTP responses to set headers on. This is a native mobile application only.

---

### NFR-SEC-05: Input Validation on All User Inputs

**Applicable Rule**: SECURITY-05
**Status**: APPLICABLE

**Description**: All user-provided inputs must be validated before processing or persistence. Validation must include type checking, length/size bounds, format validation via allowlists, and sanitization.

**Compliance Approach**:
- **Onboarding fields**: userName validated per BR-ONB-01 (1-50 chars, trimmed, no whitespace-only). Language validated per BR-ONB-02 (allowlist: `es`, `en`). Currency validated per BR-ONB-03 (allowlist of supported ISO 4217 codes). PrimaryGoal validated per BR-ONB-05 (allowlist of 4 enum values). EnabledModules validated per BR-ONB-04 (non-empty list of valid module IDs).
- **Settings fields**: ThemeMode validated (allowlist: `dark`, `light`, `system`). NotificationConfig times validated (0-23 hours, 0-59 minutes).
- **Backup import**: All JSON fields validated during deserialization. `BackupManifest.fromJson()` throws `FormatException` on invalid data. Module JSON records validated before database insertion.
- **Parameterized queries**: Drift uses parameterized SQL exclusively -- no string concatenation for queries.
- **HTML/script injection**: User-facing text inputs (userName) are stored as plain text. No HTML rendering of user content exists in Unit 0, eliminating XSS risk.

**Acceptance Criteria**:
- Every Notifier method that accepts user input validates it before calling a DAO
- Validation failures return `Result.Failure(ValidationFailure(...))`, never throw
- All string inputs have explicit maxLength constraints
- All enum-like inputs use allowlist validation (reject unknown values)
- `BackupManifest.fromJson()` rejects manifests with missing or invalid fields
- Zero raw SQL string concatenation in the codebase (Drift enforces this by design)

---

### NFR-SEC-06: Least-Privilege App Permissions

**Applicable Rule**: SECURITY-06
**Status**: APPLICABLE (adapted for mobile permissions)

**Description**: The app requests only the minimum platform permissions required for its functionality. Permissions are requested at the point of use, not at install time.

**Compliance Approach**:
- **Biometric**: `local_auth` permission requested only when user enables biometric lock in Settings (not during onboarding).
- **Notifications**: Notification permission requested only when user enables their first notification type (per BR-NOT-02).
- **File access**: Storage/file picker permission requested only when user initiates backup export or import.
- **No unnecessary permissions**: Camera, location, contacts, microphone, and health permissions are not requested in Unit 0.
- **AndroidManifest.xml and Info.plist**: Declare only the permissions actually used. No blanket permission requests.

**Acceptance Criteria**:
- `AndroidManifest.xml` contains only: `USE_BIOMETRIC`, `USE_FINGERPRINT`, `SCHEDULE_EXACT_ALARM`, `POST_NOTIFICATIONS`, and file-related permissions
- `Info.plist` contains only: `NSFaceIDUsageDescription` and notification-related keys
- No permission is requested during onboarding or at app install
- Each permission request is triggered by an explicit user action (enabling biometric, enabling notifications, initiating backup)

---

### NFR-SEC-07: Restrictive Network Configuration

**Applicable Rule**: SECURITY-07
**Status**: N/A

**Rationale**: LifeOS Unit 0 has no server networking, no security groups, no network ACLs, no route tables. The app makes no outbound network connections in its core functionality.

---

### NFR-SEC-08: Application-Level Access Control

**Applicable Rule**: SECURITY-08
**Status**: APPLICABLE (adapted for local-first mobile app)

**Description**: Access to app content is gated by optional biometric authentication. Since all data is local, there are no IDOR risks. Authorization is binary: the user is either authenticated (biometric passed) or not.

**Compliance Approach**:
- **Deny by default when biometric is enabled**: Full-screen opaque lock overlay prevents content visibility until authentication succeeds (per BR-BIO-02).
- **No IDOR risk**: All data belongs to a single local user. No resource IDs are exposed via APIs or URLs.
- **No CORS**: No web endpoints exist.
- **No token management**: Biometric auth is a platform-level gate, not a session token system.
- **Grace period**: 30-second grace period on background resume prevents excessive authentication while maintaining security (per BR-BIO-02).

**Acceptance Criteria**:
- When `useBiometric == true`, no app content is visible before successful authentication
- Lock overlay is fully opaque (no content visible behind it)
- After 30+ seconds in background, re-authentication is required
- Cold start always requires authentication when biometric is enabled

---

### NFR-SEC-09: Security Hardening

**Applicable Rule**: SECURITY-09
**Status**: APPLICABLE

**Description**: The application must follow a hardening baseline: no default credentials, no debug information in release builds, and generic production error messages.

**Compliance Approach**:
- **No default credentials**: No passwords, tokens, or secrets exist in source code or configuration files. `flutter_secure_storage` is used for any future API keys.
- **No debug info in release**: `kReleaseMode` flag gates debug output. Stack traces are suppressed in production error messages (per BR-ERR-05). `debugPrint` statements compile out in release mode.
- **Generic error messages**: All user-facing errors use `AppFailure.userMessage` which contains only localized generic messages (per BR-ERR-02 and BR-ERR-05).
- **No sample/demo code**: No sample applications, demo pages, or default Flutter counter app code in the release build.
- **Flutter build flags**: Release builds use `--release` flag with tree-shaking and minification. Assert statements are stripped.

**Acceptance Criteria**:
- Grep of codebase for hardcoded passwords, API keys, or tokens yields zero hits
- Release build produces no `debugPrint` output
- All `AppFailure.userMessage` values are generic localized strings (no internal details)
- `assert()` statements do not appear in release builds (Dart compiler handles this)
- Flutter `--release` build completes without including debug artifacts

---

### NFR-SEC-10: Software Supply Chain Security

**Applicable Rule**: SECURITY-10
**Status**: APPLICABLE

**Description**: All dependencies must be version-pinned, the lock file must be committed, and no unused packages may be included.

**Compliance Approach**:
- **Dependency pinning**: All packages in `pubspec.yaml` use exact versions (e.g., `flutter_riverpod: 2.6.1`, not `^2.6.1`). Minor/patch updates are intentional, not automatic.
- **Lock file**: `pubspec.lock` is committed to version control and included in `.gitignore` exclusion (i.e., NOT ignored).
- **No unused dependencies**: Every package in `pubspec.yaml` has at least one import in `lib/`. Quarterly audit removes unused packages.
- **Trusted sources**: All packages sourced from `pub.dev` (official Dart/Flutter registry). No git dependencies or path overrides in production.
- **Vulnerability scanning**: `dart pub outdated` run as part of quarterly audit. Future CI integration with `dart pub deps --json` for automated scanning.

**Acceptance Criteria**:
- `pubspec.lock` exists and is committed to git
- Every `pubspec.yaml` dependency uses an exact version (no `^` or `>=` prefixes)
- Running `dart pub deps --no-dev` lists only actively-used packages
- No packages are sourced from git URLs or local paths in release configuration
- Quarterly audit process is documented in tech-stack-decisions.md

---

### NFR-SEC-11: Secure Design Principles

**Applicable Rule**: SECURITY-11
**Status**: APPLICABLE

**Description**: Security-critical logic must be isolated in dedicated modules. Defense in depth must be applied with layered controls.

**Compliance Approach**:
- **Separation of concerns**: Biometric authentication logic is isolated in `lib/core/services/biometric_service.dart`. Secure storage access is isolated in `lib/core/services/secure_storage_service.dart`. Input validation logic is centralized in Notifier methods with shared validation utilities.
- **Defense in depth**:
  - Layer 1: Platform biometric gate (local_auth)
  - Layer 2: Input validation at Notifier level
  - Layer 3: Drift column constraints at database level
  - Layer 4: Platform-level encryption at rest (OS sandbox)
- **No rate limiting needed**: No public-facing endpoints exist. Biometric failure counting (3 attempts per BR-BIO-03) serves as the equivalent for the authentication gate.
- **Misuse case addressed**: Biometric bypass after 3 failures (BR-BIO-03) is documented with security warning to the user.

**Acceptance Criteria**:
- `BiometricService` and `SecureStorageService` are standalone services in `lib/core/services/`
- No biometric or secure storage logic exists outside these dedicated services
- Input validation occurs at the Notifier layer before DAO calls
- Drift table definitions include column constraints (maxLength, non-null) as a defense layer
- At least one misuse/abuse scenario is documented (biometric bypass)

---

### NFR-SEC-12: Authentication and Credential Management

**Applicable Rule**: SECURITY-12
**Status**: APPLICABLE (adapted for biometric-only auth)

**Description**: The app uses biometric authentication (no passwords). Credentials (future API keys) are stored securely. No hardcoded secrets exist.

**Compliance Approach**:
- **No passwords**: LifeOS uses biometric authentication only (fingerprint, face). No password policy, hashing, or brute-force protection for passwords is needed.
- **Biometric auth**: Managed via `local_auth` plugin. Failure handling includes 3-attempt lockout with disable option (per BR-BIO-03).
- **Credential storage**: Any API keys or tokens (for future AI providers, Open Food Facts) are stored in `flutter_secure_storage`, never in source code or SharedPreferences.
- **No hardcoded credentials**: Grep-enforced rule -- no string literals matching API key patterns in `lib/` directory.
- **No session tokens**: Local-only app with no server sessions. Biometric auth is a local gate.

**Acceptance Criteria**:
- No password fields, password hashing, or password storage exists in the codebase
- Biometric auth uses `local_auth.authenticate()` with `biometricOnly: true` option
- Grep of `lib/` for patterns like `apiKey =`, `secret =`, `password =`, `token =` yields zero hardcoded values
- `flutter_secure_storage` is the only mechanism for storing sensitive strings
- Biometric failure count tracks 3 consecutive failures before offering disable option

---

### NFR-SEC-13: Software and Data Integrity

**Applicable Rule**: SECURITY-13
**Status**: APPLICABLE

**Description**: Backup import must validate data integrity before modifying the database. JSON deserialization must be safe.

**Compliance Approach**:
- **Safe deserialization**: `BackupManifest.fromJson()` validates all fields with type checking and constraint validation before returning an object. Invalid JSON throws `FormatException`, caught by `BackupService` and wrapped in `BackupFailure(phase: 'validate')`.
- **Manifest validation before data modification**: Import flow validates the manifest (schema version, required fields, module entries) before any database writes occur (per BR-BKP-03). Fail-closed: invalid manifest aborts import with no side effects.
- **Per-record validation**: Each record deserialized from module JSON files is validated before insertion. Invalid records increment `failedCount` and are skipped without aborting the module import.
- **Data integrity auditing**: BackupManifest includes `recordCount` per module. After import, actual inserted + skipped + failed counts can be compared against manifest counts for integrity verification.

**Acceptance Criteria**:
- `BackupManifest.fromJson()` rejects manifests with missing fields, wrong types, or invalid values
- Import aborts before any database modification if manifest validation fails
- Individual record deserialization failures do not crash the import process
- Import results report includes per-module counts (inserted, skipped, failed) for audit
- No `dart:mirrors` or dynamic code execution is used for deserialization

---

### NFR-SEC-14: Security Event Logging and Audit

**Applicable Rule**: SECURITY-14
**Status**: APPLICABLE (adapted for local-only context)

**Description**: Security-relevant events must be logged locally. Since there is no server infrastructure, this translates to local audit logging of authentication events and security-significant operations.

**Compliance Approach**:
- **Security event logging via LogService**:
  - Biometric authentication attempts (success and failure) logged with timestamp
  - Biometric lock enable/disable operations logged
  - Backup export and import operations logged (start, success, failure)
  - Biometric failure count threshold reached (3 failures) logged as a warning
- **Log retention**: Logs persist for the duration of the app session (console output). No persistent log file in Unit 0. Future versions may add persistent local logging.
- **Tamper resistance**: N/A for local console logs. The audit trail is informational, not legally binding.
- **No server monitoring dashboards**: N/A for local-first app.

**Acceptance Criteria**:
- `LogService` emits log entries for: biometric success, biometric failure, biometric enabled/disabled, backup export started/completed/failed, backup import started/completed/failed
- Security events include log level `warning` or `info` as appropriate
- No security event is silently swallowed without logging
- Log entries for security events include a `[SECURITY]` tag for easy filtering

---

### NFR-SEC-15: Exception Handling and Fail-Safe Defaults

**Applicable Rule**: SECURITY-15
**Status**: APPLICABLE

**Description**: All external calls must have explicit error handling. The system must fail closed on errors. Resources must be cleaned up in error paths.

**Compliance Approach**:
- **Result type pattern**: All business methods return `Future<Result<T>>`. Exceptions from Drift, `local_auth`, `flutter_local_notifications`, and file I/O are caught and wrapped in appropriate `AppFailure` subclasses (per BR-ERR-01).
- **Global error handler**: `FlutterError.onError` and `PlatformDispatcher.instance.onError` configured in `main()` (per BR-ERR-04). Catches framework errors, isolate errors, and platform channel errors.
- **Fail closed**: Backup import validates manifest before any data modification. Biometric failure does not grant access. Invalid input returns `ValidationFailure`, never proceeds with invalid data.
- **Resource cleanup**: Drift database connections are closed on app termination. EventBus `StreamController` is closed via Riverpod `onDispose`. Backup isolates clean up file handles on error.
- **User-facing errors**: Only `AppFailure.userMessage` is shown to users. No stack traces, SQL errors, or internal paths (per BR-ERR-05).

**Acceptance Criteria**:
- Every Drift DAO call is wrapped in try-catch within the Notifier layer
- `FlutterError.onError` and `PlatformDispatcher.instance.onError` are set in `main()`
- Backup import aborts with no data modification on manifest validation failure (fail closed)
- Biometric failure (3 attempts) does not grant access -- user must explicitly disable biometric
- All `StreamSubscription` instances are cancelled in `onDispose` callbacks
- No `AppFailure.debugMessage` or `originalError` is displayed in UI widgets

---

## 2. Performance Requirements

### NFR-PERF-01: App Cold Launch Time

**Description**: The application must complete cold launch (from process start to first interactive frame on Dashboard or Lock screen) in under 2 seconds on a mid-range device (e.g., Samsung Galaxy A54, iPhone 12).

**Acceptance Criteria**:
- Measured using Flutter DevTools timeline or `flutter run --trace-startup`
- First frame rendered in < 2000ms on a mid-range test device
- Drift database open and AppSettings read completes before first frame
- Biometric prompt (if enabled) appears within 1 second of launch

---

### NFR-PERF-02: Database Initialization Time

**Description**: Drift database initialization (open connection, run pending migrations, read AppSettings) must complete in under 500ms.

**Acceptance Criteria**:
- Measured with `Stopwatch` in debug mode around database initialization code
- `openConnection()` + `migration` + `SELECT * FROM app_settings WHERE id = 1` < 500ms
- Tested on cold start (no database in memory cache)
- Schema migration for Unit 0 (version 1, initial creation) completes within this budget

---

### NFR-PERF-03: Theme Switching Responsiveness

**Description**: Theme switching (dark to light, light to dark, or system change) must appear instant to the user with no perceivable delay (< 100ms from user action to visual update).

**Acceptance Criteria**:
- Theme toggle triggers `ThemeNotifier` state update which triggers widget tree rebuild
- No asynchronous operations block the theme rebuild path (database persist is fire-and-forget for the UI)
- Measured perceived delay < 100ms (no visible flash, flicker, or loading state during switch)
- Both dark and light `ThemeData` objects are pre-built or built synchronously

---

### NFR-PERF-04: Backup Export Speed

**Description**: Backup export of 1000 records per module (across all enabled modules) must complete in under 5 seconds.

**Acceptance Criteria**:
- Benchmark with 7 modules x 1000 records each (7000 total records)
- Measured from "Export" button tap to ZIP file ready (before file picker dialog)
- Heavy work runs in a Dart isolate (per BR-BKP-07) -- no UI jank during export
- Tested on a mid-range device

---

### NFR-PERF-05: Backup Import Speed

**Description**: Backup import with manifest validation and merge-insert of 1000 records per module must complete in under 10 seconds.

**Acceptance Criteria**:
- Benchmark with 7 modules x 1000 records each
- Measured from "Import" confirmation to results screen display
- Includes manifest validation, per-record duplicate check, and merge insert
- Heavy work runs in a Dart isolate (per BR-BKP-07) -- no UI jank during import
- Tested on a mid-range device

---

### NFR-PERF-06: Idle Memory Usage

**Description**: With only Core Foundation loaded (no feature modules initialized), the app must consume less than 50MB of RAM at idle.

**Acceptance Criteria**:
- Measured using Flutter DevTools memory profiler or Android Studio profiler
- Measurement taken after app launch, onboarding complete, Dashboard visible, 5 seconds of idle
- Includes Dart heap + native allocations
- No memory leaks detected after repeated navigation (navigate away and back to Dashboard 10 times)

---

## 3. Accessibility Requirements (WCAG 2.1 AA)

### NFR-A11Y-01: Dynamic Font Scaling

**Description**: All text elements must scale with the system font size setting (Dynamic Type on iOS, font scale on Android). The app must remain usable at 200% font scale without text clipping or overflow.

**Acceptance Criteria**:
- All `Text` widgets use `TextStyle` defined through the theme's `TextTheme` (no hardcoded font sizes)
- At 200% system font scale, no text is clipped, truncated, or overflows its container
- Layout adapts (scrolling, wrapping) to accommodate larger text
- Minimum body text size is 12sp equivalent even at default scale
- Tested on both iOS (Dynamic Type: Accessibility Sizes) and Android (Display > Font size: Largest)

**Applicable Rule**: BR-THM-04

---

### NFR-A11Y-02: Screen Reader Semantics

**Description**: All interactive elements (buttons, toggles, sliders, pickers) must have `Semantics` labels that accurately describe their purpose for VoiceOver (iOS) and TalkBack (Android).

**Acceptance Criteria**:
- Every `IconButton`, `Switch`, `Slider`, and custom interactive widget has a `Semantics` label or `tooltip`
- `Semantics` labels are localized (ES/EN based on app language)
- Screen reader can navigate the entire onboarding flow and Settings screen without encountering unlabeled elements
- Decorative images/icons are marked with `excludeFromSemantics: true`
- Tested with VoiceOver on iOS simulator and TalkBack on Android emulator

---

### NFR-A11Y-03: Minimum Touch Target Size

**Description**: All interactive elements must have a minimum touch target of 48x48 dp (density-independent pixels), meeting Material Design guidelines and exceeding the iOS 44pt minimum.

**Acceptance Criteria**:
- All buttons, toggles, checkboxes, and tappable areas are at least 48x48 dp
- Small icons that are tappable are wrapped in a `GestureDetector` or `InkWell` with sufficient padding to meet 48x48 dp
- Verified using Flutter Inspector (widget bounds) or accessibility scanner
- No interactive element is smaller than 48x48 dp on either platform

---

### NFR-A11Y-04: Color Contrast Ratios

**Description**: Text must meet WCAG 2.1 AA contrast ratios: 4.5:1 for normal text (< 18pt) and 3:1 for large text (>= 18pt or >= 14pt bold).

**Acceptance Criteria**:
- All text/background color combinations in the dark theme meet 4.5:1 ratio for normal text
- All text/background color combinations in the light theme meet 4.5:1 ratio for normal text
- Module accent colors on their respective backgrounds meet 3:1 ratio for large text usage
- Contrast ratios verified using a contrast checker tool (e.g., WebAIM Contrast Checker) for all theme color pairs
- Error text, hint text, and disabled text colors also meet minimum ratios

---

### NFR-A11Y-05: Reduced Motion Support

**Description**: When the user has enabled "Reduce Motion" (iOS) or "Remove animations" (Android), the app must disable or minimize all non-essential animations.

**Acceptance Criteria**:
- `MediaQuery.disableAnimations` (or `MediaQuery.of(context).disableAnimations`) is checked before running animations
- Page transitions use instant transitions (no slide/fade) when reduced motion is enabled
- Loading spinners are replaced with static indicators when reduced motion is enabled
- Essential feedback animations (e.g., button press states) may remain but should be minimal

---

### NFR-A11Y-06: Focus Management

**Description**: When modal sheets, dialogs, or new screens appear, keyboard/screen reader focus must move to the new content. When dismissed, focus must return to the triggering element.

**Acceptance Criteria**:
- Opening a modal bottom sheet moves focus to the sheet's first interactive element or title
- Dismissing a dialog returns focus to the element that triggered it
- Navigation to a new screen moves focus to the screen's first element or app bar title
- Focus order follows a logical reading order (top-to-bottom, left-to-right for LTR layouts)
- No focus traps exist (user can always navigate away from any element)

---

### NFR-A11Y-07: Color Not Sole Information Carrier

**Description**: Color must not be the only means of conveying information. All color-coded elements must have supplementary indicators (icons, text labels, patterns).

**Acceptance Criteria**:
- Module identification uses both color AND icon/text label
- Budget threshold indicators use both color (green/yellow/red) AND percentage text
- Toggle states use both color AND position/icon
- Charts and graphs include labels or patterns in addition to color coding
- A user who cannot perceive color can still understand all information presented

---

## 4. Testing Requirements

### NFR-TEST-01: PBT Framework Selection

**Applicable Rule**: PBT-09

**Description**: The project uses **glados** as its property-based testing framework for Dart. Glados supports custom generators (via `Arbitrary`), automatic shrinking, and seed-based reproducibility. It integrates with Dart's built-in `test` package.

**Acceptance Criteria**:
- `glados` is listed as a `dev_dependency` in `pubspec.yaml` with an exact version
- PBT tests import `package:glados/glados.dart`
- Custom `Arbitrary` instances are defined for domain types (BackupManifest, AppSettings, NotificationConfig, AppEvent subclasses)
- Glados shrinking is not disabled in any test file
- All PBT tests are runnable via `flutter test`

---

### NFR-TEST-02: Unit Test Coverage Target

**Description**: Unit test coverage must exceed 80% for all services, DAOs, and Notifiers in Unit 0.

**Acceptance Criteria**:
- `flutter test --coverage` reports > 80% line coverage for files in `lib/core/services/`, `lib/core/database/`, and `lib/core/notifiers/`
- Coverage measured after running all unit tests and PBT tests
- Coverage report generated as `coverage/lcov.info` for CI integration
- Untested code paths are documented with justification if coverage cannot reach 80% for specific files

---

### NFR-TEST-03: Widget Test Coverage for Onboarding

**Description**: Every onboarding screen must have widget tests verifying rendering, user interaction, and validation feedback.

**Acceptance Criteria**:
- Widget tests exist for: WelcomeScreen, LanguageSelectionScreen, NameInputScreen, CurrencySelectionScreen, ModuleSelectionScreen, PrimaryGoalScreen, FirstDataScreen
- Tests verify correct initial state (default selections, empty fields)
- Tests verify validation errors are displayed for invalid input
- Tests verify navigation between screens (forward and back)
- Tests verify the "Skip" action applies correct defaults

---

### NFR-TEST-04: Integration Test for Onboarding Flow

**Description**: An end-to-end integration test verifies the complete onboarding flow from Welcome screen to Dashboard.

**Acceptance Criteria**:
- Integration test uses `integration_test` package
- Test completes the full happy path: Welcome > Language > Name/Currency > Modules > Goal > FirstData > Dashboard
- Test verifies AppSettings are correctly persisted after onboarding
- Test verifies the skip path (skip after language screen, verify defaults applied)
- Test runs successfully on both iOS simulator and Android emulator

---

### NFR-TEST-05: PBT Tests for Identified Properties

**Applicable Rules**: PBT-01, PBT-02, PBT-03, PBT-04

**Description**: All testable properties identified in the Functional Design (PBT-01 compliance section) must have corresponding PBT tests using glados.

**Required PBT Tests (from Functional Design)**:

**Round-trip properties (5 tests)**:
- RT-01: BackupManifest export/import round-trip (BackupService serialization)
- RT-02: `BackupManifest.fromJson(manifest.toJson()) == manifest`
- RT-03: `NotificationConfig.fromJson(config.toJson()) == config`
- RT-04: `AppEvent` subclass serialization round-trip (if serialization is implemented)
- RT-05: `enabledModules` JSON encode/decode round-trip

**Invariant properties (5 tests)**:
- INV-01: AppSettings mutations preserve all field constraints
- INV-02: Onboarding completion guarantees all required fields are valid
- INV-03: AppEvent timestamp is never in the future
- INV-04: Every AppFailure instance has non-empty userMessage and debugMessage
- INV-05: BackupManifest module recordCounts sum matches total exported records

**Idempotence properties (4 tests)**:
- IDP-01: EventBus duplicate event processing yields same result
- IDP-02: Backup import twice yields same database state as import once
- IDP-03: Setting same theme mode twice produces same result
- IDP-04: Scheduling same notification twice results in exactly one set of notifications

**Acceptance Criteria**:
- At least 14 PBT test functions exist covering the properties listed above
- Each test uses glados with custom `Arbitrary` generators for domain types
- Each test documents which property category it covers (round-trip, invariant, idempotence)
- Tests are located in `test/pbt/` directory, separate from example-based tests

---

### NFR-TEST-06: PBT Seed Logging on Failure

**Applicable Rule**: PBT-08

**Description**: All PBT tests must log the random seed on failure to enable deterministic reproduction of failing cases.

**Acceptance Criteria**:
- Glados default behavior logs the seed on failure (verify this is not overridden)
- CI configuration captures test output including seeds
- When a PBT failure is found, the seed is included in the test failure message
- A shrunk minimal failing input is produced alongside the seed
- Documentation includes instructions for replaying a failure with a specific seed

---

### NFR-TEST-07: PBT and Example-Based Test Coexistence

**Applicable Rule**: PBT-10

**Description**: PBT tests complement but do not replace example-based tests. Critical business scenarios must have both types of tests.

**Acceptance Criteria**:
- Example-based tests exist for all critical business paths (onboarding happy path, backup export/import, biometric auth flow, theme switching)
- PBT tests exist for all identified properties (NFR-TEST-05)
- Test files are organized to clearly distinguish PBT from example-based tests:
  - `test/unit/` -- example-based unit tests
  - `test/widget/` -- example-based widget tests
  - `test/pbt/` -- property-based tests
  - `test/integration/` -- integration tests
- When a PBT discovers a new failure, the shrunk example is added as a permanent example-based regression test
- Business-critical paths are never tested by PBT alone

---

## 5. Reliability Requirements

### NFR-REL-01: Global Error Handler

**Description**: The app must have a global error handler that catches all unhandled exceptions, logs them, and presents a generic user-friendly error message. The app must not crash.

**Applicable Rule**: SECURITY-15

**Acceptance Criteria**:
- `FlutterError.onError` is configured in `main()` to catch framework errors
- `PlatformDispatcher.instance.onError` is configured to catch async unhandled errors
- Caught exceptions are logged via `LogService` with full stack trace in debug mode
- The UI shows a generic "Something went wrong" snackbar (never a stack trace)
- After a global error, the app remains in a usable state (does not freeze or show a blank screen)

---

### NFR-REL-02: Fail-Closed Backup Import

**Description**: Backup import validates the manifest completely before any data modification. If manifest validation fails, no database records are inserted, updated, or deleted.

**Applicable Rule**: SECURITY-13, SECURITY-15

**Acceptance Criteria**:
- Manifest validation (schema version check, field validation) completes before any DAO insert call
- If validation fails, the function returns `BackupFailure(phase: 'validate')` immediately
- A database transaction count before and after a failed validation shows zero changes
- Individual record failures during import do not roll back successfully imported records from other modules (partial success is acceptable, but manifest failure is total abort)

---

### NFR-REL-03: Database Migration Versioning

**Description**: Drift database migrations must be versioned, tested, and handle upgrades from any previous version to the current version.

**Acceptance Criteria**:
- Drift migration uses the `MigrationStrategy` with explicit `onCreate` and `onUpgrade` callbacks
- Unit 0 starts at schema version 1 (initial creation, no upgrade path yet)
- A unit test verifies that `onCreate` creates all expected tables with correct columns
- Migration version number is stored in the Drift database and used for backup compatibility checks (BR-BKP-03)
- Future schema changes must add migration steps (never recreate from scratch)

---

### NFR-REL-04: Biometric Auth Failure Resilience

**Description**: Biometric authentication failure must never crash the app. All `local_auth` exceptions must be caught and handled gracefully.

**Acceptance Criteria**:
- `local_auth.authenticate()` call is wrapped in try-catch
- `PlatformException` from `local_auth` is caught and wrapped in `AuthFailure`
- If biometric hardware becomes unavailable, the app disables biometric and allows access (per BR-BIO-04)
- After any auth error, the app is in a usable state (lock screen with retry option, or bypassed to Dashboard)
- Unit tests verify error handling for all known `local_auth` exception types

---

## 6. Maintainability Requirements

### NFR-MNT-01: Strict Dart Analyzer Rules

**Description**: The project must use strict Dart analyzer rules based on `flutter_lints` with additional custom rules to enforce code quality.

**Acceptance Criteria**:
- `analysis_options.yaml` includes `flutter_lints` (or `very_good_analysis`) as the base rule set
- Additional rules enabled: `prefer_const_constructors`, `prefer_const_declarations`, `avoid_print` (enforces LogService usage), `prefer_final_locals`, `always_declare_return_types`
- `dart analyze` reports zero warnings and zero errors on the full codebase
- CI pipeline fails on any analyzer warning (warnings treated as errors)

---

### NFR-MNT-02: Consistent Code Style

**Description**: Code style must be consistent across the codebase, enforced by `analysis_options.yaml` and `dart format`.

**Acceptance Criteria**:
- `dart format` with default line length (80 characters) produces zero changes when run on the full codebase
- All files follow the Dart style guide (effective Dart conventions)
- Import ordering follows: dart:, package:, relative imports -- each group separated by a blank line
- No `// ignore:` comments without accompanying justification comments
- Pre-commit check or CI step enforces formatting

---

### NFR-MNT-03: Public API Documentation

**Description**: All public APIs (classes, methods, enums, extensions) in `lib/` must have dartdoc comments explaining their purpose, parameters, and return values.

**Acceptance Criteria**:
- Every public class has a dartdoc comment (`///`) describing its responsibility
- Every public method has a dartdoc comment describing what it does, its parameters, and its return value
- Every public enum has a dartdoc comment, and each enum value has a brief description
- `dart doc` generates documentation without warnings for missing documentation
- Private members (`_prefixed`) are not required to have dartdoc comments (but encouraged for complex logic)

---

## Compliance Summary

### Security Extension Compliance

| Rule | Status | Rationale |
|---|---|---|
| SECURITY-01 | Compliant | Platform encryption at rest via OS sandbox + flutter_secure_storage for credentials |
| SECURITY-02 | N/A | No network intermediaries in local-first app |
| SECURITY-03 | Compliant | LogService with structured logging, no PII, level-gated output |
| SECURITY-04 | N/A | No web endpoints or HTML-serving components |
| SECURITY-05 | Compliant | All inputs validated (allowlists, length bounds, type checks). Drift parameterized queries |
| SECURITY-06 | Compliant | Minimum permissions, requested at point of use only |
| SECURITY-07 | N/A | No server networking or firewall configurations |
| SECURITY-08 | Compliant | Biometric gate with opaque overlay, no IDOR risk (local data) |
| SECURITY-09 | Compliant | No default credentials, no debug info in release, generic error messages |
| SECURITY-10 | Compliant | Pinned versions, lock file committed, no unused deps, pub.dev only |
| SECURITY-11 | Compliant | Security logic isolated in dedicated services, defense in depth layers |
| SECURITY-12 | Compliant | Biometric auth, secure credential storage, no hardcoded secrets |
| SECURITY-13 | Compliant | Manifest validation before import, safe JSON deserialization, per-record validation |
| SECURITY-14 | Compliant | Security event logging via LogService with [SECURITY] tag |
| SECURITY-15 | Compliant | Result type pattern, global error handler, fail closed, resource cleanup |

### PBT Extension Compliance

| Rule | Status | Rationale |
|---|---|---|
| PBT-01 | Compliant | Properties identified in Functional Design (5 round-trip, 5 invariant, 4 idempotence, 1 commutativity) |
| PBT-02 | Compliant | Round-trip tests required for RT-01 through RT-05 |
| PBT-03 | Compliant | Invariant tests required for INV-01 through INV-05 |
| PBT-04 | Compliant | Idempotence tests required for IDP-01 through IDP-04 |
| PBT-05 | N/A | No reference/oracle implementations exist for Unit 0 components |
| PBT-06 | N/A | Stateful PBT deferred -- EventBus and Notifiers tested via example-based state machine tests |
| PBT-07 | Compliant | Custom Arbitrary generators required for all domain types (NFR-TEST-01) |
| PBT-08 | Compliant | Glados logs seed on failure by default; CI captures output (NFR-TEST-06) |
| PBT-09 | Compliant | Glados selected and documented in tech-stack-decisions.md (NFR-TEST-01) |
| PBT-10 | Compliant | PBT and example-based tests coexist with clear separation (NFR-TEST-07) |
