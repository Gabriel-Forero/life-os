# NFR Design Patterns -- Unit 0: Core Foundation

## Purpose

Defines the concrete design patterns that implement each non-functional requirement category for Unit 0 (Core Foundation). Each pattern includes an ID, description, Flutter/Dart implementation approach, and traceability to the NFR requirements it satisfies.

**Target platforms**: iOS 16+ / Android API 26+
**Architecture**: 100% local-first, Riverpod + Drift, Result<T> error handling

---

## 1. Security Patterns

### SP-01: Biometric Auth Gate Pattern

**Description**: A guard widget at the app root that conditionally shows a biometric authentication screen or the main content. The gate intercepts all access when biometric lock is enabled, using an opaque overlay that prevents content visibility before authentication succeeds.

**Implementation Approach**:

- `BiometricService` wraps `local_auth` and exposes `Future<Result<bool>> authenticate()` and `Future<bool> isAvailable()`.
- On app launch: the `AppRouter` redirect guard reads `AppSettings.useBiometric` from the `SettingsNotifier`. If `true`, the router redirects to a `/lock` route that displays the `BiometricLockScreen`.
- `BiometricLockScreen` calls `BiometricService.authenticate()` on mount and shows an opaque overlay (solid surface color, app logo) with a "Tap to unlock" action.
- `AuthState` is modeled as a Riverpod state with three values: `unauthenticated`, `authenticating`, `authenticated`, plus a `failedAttempts` counter.
- After 3 consecutive failures (tracked in state), the screen offers a "Disable biometric lock" option with a security warning explaining the implications. Disabling sets `AppSettings.useBiometric = false` via `SettingsNotifier`.
- A 30-second grace period is tracked via `AppLifecycleListener`. If the app resumes within 30 seconds of backgrounding, re-authentication is skipped.
- All authentication attempts (success and failure) are logged via `AppLogger` with the `[SECURITY]` tag.

**NFR Requirements Satisfied**: NFR-SEC-08, NFR-SEC-11, NFR-SEC-12, NFR-REL-04

---

### SP-02: Secure Storage Abstraction

**Description**: A typed service layer over `flutter_secure_storage` that provides a domain-specific API for managing sensitive credentials. Raw keys and tokens are never exposed in logs, error messages, or UI.

**Implementation Approach**:

- `SecureStorageService` wraps `FlutterSecureStorage` and provides methods with provider-specific semantics:
  - `Future<Result<void>> saveApiKey(AiProvider provider, String key)`
  - `Future<Result<String?>> getApiKey(AiProvider provider)`
  - `Future<Result<void>> deleteApiKey(AiProvider provider)`
  - `Future<Result<bool>> hasApiKey(AiProvider provider)`
- `AiProvider` is an enum: `openai`, `anthropic`, `gemini`.
- Storage keys are derived with a prefix convention: `'lifeos_apikey_openai'`, `'lifeos_apikey_anthropic'`, `'lifeos_apikey_gemini'`.
- All `FlutterSecureStorage` exceptions are caught within the service and wrapped in `StorageFailure` (an `AppFailure` subclass). No raw platform exceptions propagate.
- The `saveApiKey` method validates that the key string is non-empty and within length bounds before writing.
- `AppLogger` entries for secure storage operations log only the provider name, never the key value. Example: `"API key saved for provider: openai"`.
- iOS: Uses Keychain with `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` for data protection.
- Android: Uses `EncryptedSharedPreferences` (AES-256-GCM via AndroidX Security).

**NFR Requirements Satisfied**: NFR-SEC-01, NFR-SEC-09, NFR-SEC-11, NFR-SEC-12

---

### SP-03: Input Validation Middleware

**Description**: A system of pure validation functions that run in the Notifier layer before any DAO call. Validators are composable, reusable, and return typed `Result<T>` values rather than throwing exceptions.

**Implementation Approach**:

- Validators are top-level pure functions in `lib/core/validators/`:
  - `Result<String> validateUserName(String input)` -- trims, checks 1-50 chars, rejects whitespace-only
  - `Result<String> validateLanguage(String input)` -- allowlist: `{'es', 'en'}`
  - `Result<String> validateCurrency(String input)` -- allowlist of supported ISO 4217 codes
  - `Result<String> validatePrimaryGoal(String input)` -- allowlist: `{'save_money', 'get_fit', 'be_disciplined', 'balance'}`
  - `Result<List<String>> validateEnabledModules(List<String> input)` -- non-empty, all IDs in valid set
  - `Result<String> validateThemeMode(String input)` -- allowlist: `{'dark', 'light', 'system'}`
  - `Result<NotificationTime> validateNotificationTime(int hour, int minute)` -- 0-23 hours, 0-59 minutes
- Composable primitives for reuse:
  - `Result<String> required(String? input, String fieldName)`
  - `Result<String> maxLength(String input, int max, String fieldName)`
  - `Result<String> minLength(String input, int min, String fieldName)`
  - `Result<String> allowlist<T>(T input, Set<T> allowed, String fieldName)`
  - `Result<num> numericRange(num input, num min, num max, String fieldName)`
- `ValidationFailure` extends `AppFailure` and carries `fieldName` and `violation` strings for precise error reporting.
- Notifiers call validators before DAO operations:
  ```
  final nameResult = validateUserName(input.userName);
  if (nameResult is Failure) return nameResult; // propagate
  // ... proceed with validated value
  ```
- Drift column constraints (maxLength, non-null) serve as a defense-in-depth layer behind the Notifier validation.

**NFR Requirements Satisfied**: NFR-SEC-05, NFR-SEC-11, NFR-SEC-15

---

### SP-04: Structured Logging

**Description**: A centralized logging service that enforces structured log entries with PII scrubbing, level filtering by build mode, and tagged output for security event filtering.

**Implementation Approach**:

- `AppLogger` class in `lib/core/services/app_logger.dart` with static methods:
  - `AppLogger.debug(String tag, String message)`
  - `AppLogger.info(String tag, String message)`
  - `AppLogger.warning(String tag, String message)`
  - `AppLogger.error(String tag, String message, {Object? error, StackTrace? stackTrace})`
- Each log entry is formatted as: `[LEVEL] [timestamp] [tag] message`
  - Timestamp: ISO 8601 format
  - Tag: module/service name (e.g., `BackupService`, `BiometricService`, `OnboardingNotifier`)
  - Message: human-readable description of the operation
- **Level filtering**: In release mode (`kReleaseMode == true`), only `warning` and `error` entries are emitted. In debug mode, all levels are active.
- **PII scrubber**: A `_scrubPii(String message)` private method runs before every log emission. It replaces patterns matching:
  - Email addresses (regex: `\b[\w.+-]+@[\w-]+\.[\w.]+\b`)
  - Phone numbers (regex: sequences of 7+ digits with optional separators)
  - The content is replaced with `[REDACTED]`
- **Security tag**: Security-relevant operations use a `[SECURITY]` prefix in the tag (e.g., `[SECURITY] BiometricService`). This enables filtering security events from general application logs.
- **Output target**: Uses `developer.log()` in debug mode (appears in Flutter DevTools). In release mode, logs write to a rotating in-memory buffer (`List<LogEntry>`, max 500 entries) accessible for crash reporting context.
- **Lint enforcement**: The `avoid_print` analyzer rule (configured as `error` in `analysis_options.yaml`) prevents direct `print()` calls in `lib/`, forcing all output through `AppLogger`.

**NFR Requirements Satisfied**: NFR-SEC-03, NFR-SEC-09, NFR-SEC-14

---

### SP-05: Safe Deserialization

**Description**: All JSON import operations go through typed deserializers with validation. No dynamic deserialization or reflection is used. Each record is validated against the Drift schema constraints before database insertion.

**Implementation Approach**:

- **Manifest deserialization**: `BackupManifest.fromJson(Map<String, dynamic> json)` is a factory constructor that:
  1. Checks for required top-level fields: `appVersion`, `schemaVersion`, `createdAt`, `deviceInfo`, `modules`
  2. Validates field types (e.g., `schemaVersion` is `int`, `modules` is `List`)
  3. Validates field values (e.g., `schemaVersion <= currentSchemaVersion`)
  4. Parses each module entry via `BackupModuleEntry.fromJson()` with its own validation
  5. Returns a typed `BackupManifest` object on success
  6. Throws `FormatException` with a descriptive message on any validation failure (caught by `BackupEngine` and wrapped in `BackupFailure(phase: 'validate')`)

- **Per-record deserialization**: Each module's JSON records are deserialized individually:
  1. The deserializer reads each JSON object from the module's data array
  2. Type checking validates every field against the expected Dart type
  3. Constraint checking validates values against Drift column constraints (maxLength, allowlists, numeric ranges)
  4. Valid records are collected for batch insertion
  5. Invalid records increment `failedCount` with the specific field and reason logged
  6. The deserializer never aborts on a single bad record -- it processes all records and reports aggregate results

- **Forward compatibility**: Unknown JSON fields are silently ignored (the deserializer reads only expected fields). This allows backups from newer app versions to be partially imported by older versions.
- **No unsafe patterns**: `dart:mirrors` is not imported. No `dynamic` casts without subsequent type checking. No `jsonDecode` results used without field-by-field extraction and validation.

**NFR Requirements Satisfied**: NFR-SEC-13, NFR-SEC-15, NFR-REL-02

---

## 2. Performance Patterns

### PP-01: Lazy Initialization

**Description**: Resources are initialized only when first accessed, keeping cold launch time under the 2-second budget. Riverpod's lazy-by-default provider model is the primary mechanism.

**Implementation Approach**:

- **Riverpod lazy providers**: All providers are lazy by default in Riverpod. Module-specific providers (Finance, Gym, Nutrition, etc.) are not instantiated until their respective screens are navigated to. Only the providers needed for the initial screen (Dashboard or Lock) are evaluated at launch.
- **Drift database deferred open**: The `AppDatabase` provider is defined as an `AsyncNotifierProvider`. The database connection opens on the first `await ref.read(appDatabaseProvider.future)`, not at provider registration time. This means:
  - If biometric lock is enabled, the database opens during the lock screen (while user authenticates)
  - If biometric lock is disabled, the database opens during the splash/loading screen
- **Splash screen budget**: The splash screen (native splash on both platforms) covers only the core init sequence:
  1. Flutter engine initialization (platform-managed)
  2. Riverpod container creation
  3. `ThemeNotifier` initialization (synchronous, reads cached theme or uses default)
  4. `AppRouter` creation (synchronous)
  5. First frame render (Dashboard shell or Lock screen)
- **Heavy resources deferred**: Exercise library data, food databases, and other large datasets from feature modules are loaded only when the user navigates to that module for the first time.
- **Measurement**: Cold launch time is verified using `flutter run --trace-startup` and Flutter DevTools timeline.

**NFR Requirements Satisfied**: NFR-PERF-01, NFR-PERF-02, NFR-PERF-06

---

### PP-02: Isolate-Based Processing

**Description**: Computationally expensive operations (backup export/import, large JSON serialization) run in a Dart isolate to prevent UI jank. Progress is communicated back to the main isolate for UI updates.

**Implementation Approach**:

- **IsolateRunner utility**: A generic utility class in `lib/core/services/isolate_runner.dart`:
  ```
  class IsolateRunner {
    static Future<Result<T>> run<T>(
      FutureOr<T> Function(SendPort progressPort) task,
      void Function(double progress) onProgress,
    )
  }
  ```
  - Uses `Isolate.spawn()` (or `compute` for simpler cases)
  - The `task` function receives a `SendPort` for sending progress updates (double 0.0 to 1.0)
  - The main isolate listens on a `ReceivePort` and calls `onProgress` on each update
  - Errors in the isolate are caught and returned as `Result.failure(IsolateFailure(...))`
  - The isolate is automatically killed if the calling widget is disposed (cancellation)

- **Backup export in isolate**:
  1. Main isolate reads all module data from Drift into `List<Map<String, dynamic>>` per module
  2. Data is sent to the isolate (Dart objects are copied, not shared)
  3. Isolate serializes each module's data to JSON strings
  4. Isolate creates the ZIP archive in memory using the `archive` package
  5. Isolate sends progress updates after each module is serialized
  6. Final ZIP bytes are returned to the main isolate for file writing

- **Backup import in isolate**:
  1. Main isolate reads the ZIP file bytes
  2. Bytes are sent to the isolate for extraction and JSON parsing
  3. Isolate validates the manifest and deserializes all records
  4. Validated records are returned to the main isolate
  5. Main isolate performs database insertions (Drift requires main isolate access)
  6. Progress updates sent after each module is parsed

- **UI integration**: Notifiers expose an `AsyncValue<BackupProgress>` state where `BackupProgress` contains `currentModule`, `totalModules`, and `progressFraction`. Widgets show a `LinearProgressIndicator` bound to this state.

**NFR Requirements Satisfied**: NFR-PERF-04, NFR-PERF-05

---

### PP-03: Efficient Drift Queries

**Description**: Database operations use Drift's reactive streams, pagination, indexing, and batch operations to maintain performance as data grows.

**Implementation Approach**:

- **Reactive queries with `watch()`**: All list-displaying screens use Drift's `.watch()` method which returns a `Stream` that re-emits whenever the underlying table data changes. The Riverpod provider wraps this stream via `StreamProvider` or `AsyncNotifierProvider` that listens to the stream. This eliminates manual refresh calls and ensures the UI always reflects the current database state.

- **Pagination**: Large lists (transaction history, workout log, food diary) use limit/offset pagination:
  ```
  Future<List<Transaction>> getTransactions({required int limit, required int offset}) {
    return (select(transactions)
      ..orderBy([(t) => OrderingTerm.desc(t.date)])
      ..limit(limit, offset: offset)
    ).get();
  }
  ```
  The UI uses an infinite-scroll pattern with a `ScrollController` that loads the next page when near the bottom.

- **Database indexes**: Frequently queried columns get explicit indexes in the Drift table definitions:
  - `date` column on all transaction/entry tables (for date-range queries and sorting)
  - `categoryId` column on transaction tables (for category-based filtering and aggregation)
  - `moduleId` in module registry tables (for module-specific queries)
  - Indexes are defined in the Drift table class using `@TableIndex` annotations or in the `customConstraints` override.

- **Batch inserts**: Backup import uses Drift's `batch()` method for inserting multiple records:
  ```
  await database.batch((batch) {
    batch.insertAll(transactions, importedRecords,
      mode: InsertMode.insertOrReplace);
  });
  ```
  Batch inserts are wrapped in a single database transaction, reducing disk I/O and improving import speed significantly compared to individual inserts.

- **Query optimization**: Aggregate queries (monthly totals, category sums) use Drift's expression API with SQL functions (`sum`, `count`, `avg`) computed server-side in SQLite rather than loading all records into Dart memory.

**NFR Requirements Satisfied**: NFR-PERF-04, NFR-PERF-05, NFR-PERF-06

---

## 3. Accessibility Patterns

### AP-01: Semantic Widget Pattern

**Description**: Every custom widget provides meaningful semantic information for screen readers (VoiceOver/TalkBack). Decorative elements are excluded, compound widgets are merged, and custom actions provide alternatives to gesture-based interactions.

**Implementation Approach**:

- **Semantic wrapping**: Every custom interactive widget includes a `Semantics` widget:
  ```
  Semantics(
    label: l10n.settingsBiometricToggle, // localized
    toggled: isEnabled,
    child: Switch(value: isEnabled, onChanged: onChanged),
  )
  ```
- **Decorative exclusion**: Icons, dividers, and background decorations that carry no informational value are wrapped in `ExcludeSemantics`:
  ```
  ExcludeSemantics(child: Icon(Icons.chevron_right))
  ```
- **Compound merging**: When an icon and text together form a single semantic concept (e.g., a module card with icon + name + status), they are wrapped in `MergeSemantics`:
  ```
  MergeSemantics(
    child: Row(children: [
      Icon(module.icon),
      Text(module.name),
      Text(module.status),
    ]),
  )
  ```
  The screen reader announces this as a single element: "Finance module, active".

- **Custom semantic actions**: For swipe-to-dismiss or long-press interactions, alternative `CustomSemanticsAction` entries are provided so screen reader users can access the same functionality via the rotor/action menu:
  ```
  Semantics(
    customSemanticsActions: {
      CustomSemanticsAction(label: l10n.delete): () => onDelete(),
    },
    child: Dismissible(...),
  )
  ```
- **Localized labels**: All `Semantics.label` values reference `AppLocalizations` (l10n) to support both ES and EN languages.

**NFR Requirements Satisfied**: NFR-A11Y-02, NFR-A11Y-07

---

### AP-02: Responsive Typography

**Description**: All text sizes scale with the system font size setting. A maximum scale cap prevents layout breakage at extreme sizes while maintaining accessibility.

**Implementation Approach**:

- **AppTypography class**: Defined in `lib/core/theme/app_typography.dart`, this class builds `TextTheme` instances with sizes relative to a base scale:
  ```
  class AppTypography {
    static TextTheme buildTextTheme({required double textScaleFactor}) {
      final clampedScale = textScaleFactor.clamp(1.0, 2.0);
      return TextTheme(
        headlineLarge: TextStyle(
          fontFamily: 'Inter',
          fontSize: 28.0 * clampedScale,
          fontWeight: FontWeight.bold,
        ),
        bodyMedium: TextStyle(
          fontFamily: 'Inter',
          fontSize: 14.0 * clampedScale,
        ),
        // ... all text styles
      );
    }
  }
  ```
- **Scale clamping at 2.0x**: `MediaQuery.textScalerOf(context)` is read by the `ThemeNotifier` and clamped to a maximum of 2.0 to prevent layout overflow. Values below 1.0 are preserved (some users prefer smaller text).
- **No hardcoded font sizes**: Widget code never uses literal `fontSize` values. All text uses the theme's `TextTheme` (e.g., `Theme.of(context).textTheme.bodyMedium`).
- **Numeric displays**: JetBrains Mono is used for numeric content (financial amounts, scores, timers) and follows the same scaling system.
- **Testing matrix**: Widget tests verify layout at three scale factors (1.0x, 1.5x, 2.0x) to catch overflow issues:
  ```
  testWidgets('renders without overflow at 2.0x scale', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    await tester.pumpWidget(MaterialApp(home: SettingsScreen()));
    expect(tester.takeException(), isNull); // no overflow
  });
  ```

**NFR Requirements Satisfied**: NFR-A11Y-01

---

### AP-03: Accessible Color System

**Description**: Every color in the design system has a high-contrast alternative. Status indicators always use icon + color + text, never color alone. All color pairs are verified against WCAG AA contrast ratios.

**Implementation Approach**:

- **AppColors with dual palettes**: `lib/core/theme/app_colors.dart` defines both standard and high-contrast color sets:
  ```
  class AppColors {
    // Standard palette
    static const primaryDark = Color(0xFF6C63FF);
    static const primaryLight = Color(0xFF5A52D5);

    // High-contrast alternatives
    static const primaryDarkHC = Color(0xFF8A83FF);
    static const primaryLightHC = Color(0xFF3D35A8);

    static Color primary(bool highContrast, Brightness brightness) {
      if (brightness == Brightness.dark) {
        return highContrast ? primaryDarkHC : primaryDark;
      }
      return highContrast ? primaryLightHC : primaryLight;
    }
  }
  ```
- **High-contrast toggle in ThemeNotifier**: `ThemeNotifier` stores a `highContrast` boolean in its state. When toggled, it rebuilds the `ThemeData` using the high-contrast palette. This setting persists in `AppSettings` (future field addition).
- **Contrast verification**: Every color combination is documented with its contrast ratio:
  - Normal text on surface: minimum 4.5:1 in both themes
  - Large text (18pt+ or 14pt bold) on surface: minimum 3:1
  - Module accent colors on card backgrounds: verified at 3:1 minimum
  - Error/warning/success text on their respective backgrounds: minimum 4.5:1
- **Triple-encoding for status**: All status indicators use three channels:
  - Color (green/yellow/red for budget thresholds)
  - Icon (checkmark/warning/alert icons)
  - Text label ("On track" / "Caution" / "Over budget")
  Example: `Row(children: [Icon(statusIcon), Text(statusLabel)])` styled with `statusColor`.
- **Color-blind safe module accents**: The 7 module accent colors are chosen from a palette that remains distinguishable under common color vision deficiencies (protanopia, deuteranopia, tritanopia).

**NFR Requirements Satisfied**: NFR-A11Y-04, NFR-A11Y-07

---

### AP-04: Motion Control

**Description**: All non-essential animations respect the platform's reduce-motion accessibility setting. When reduce motion is enabled, transitions show the final state immediately without animation.

**Implementation Approach**:

- **Motion-aware AnimatedWidget wrapper**: A reusable `MotionAware` widget (or extension on `AnimationController`) that checks the platform setting before running:
  ```
  class MotionAwareTransition extends StatelessWidget {
    final Widget child;
    final Animation<double> animation;

    Widget build(BuildContext context) {
      final reduceMotion = MediaQuery.of(context).disableAnimations;
      if (reduceMotion) return child; // show final state immediately
      return FadeTransition(opacity: animation, child: child);
    }
  }
  ```
- **Page transitions**: `GoRouter` custom transition builders check `MediaQuery.disableAnimations`:
  - If reduce motion is enabled: `transitionDuration = Duration.zero` (instant transition)
  - If reduce motion is disabled: standard slide/fade transitions
- **Loading indicators**: When reduce motion is enabled, `CircularProgressIndicator` is replaced with a static "Loading..." text or a simple pulsing dot (minimal animation).
- **Haptic feedback**: Haptic feedback via `HapticFeedback.lightImpact()` is also gated on accessibility settings. The `AccessibilityService` provider exposes a `shouldUseHaptics` flag that checks both the platform setting and user preference.
- **Essential feedback preserved**: Button press ripple effects (Material `InkWell`) are retained even with reduce motion, as they are brief and provide essential interaction confirmation. Only transitions, loaders, and decorative animations are suppressed.

**NFR Requirements Satisfied**: NFR-A11Y-05

---

## 4. Error Handling Patterns

### EH-01: Result Type Pattern

**Description**: All business operations return a sealed `Result<T>` type instead of throwing exceptions. Pattern matching at the Notifier level converts `Result` values into Riverpod `AsyncValue` states for UI consumption.

**Implementation Approach**:

- **Result type definition** in `lib/core/models/result.dart`:
  ```
  sealed class Result<T> {
    const Result();
  }

  final class Success<T> extends Result<T> {
    final T value;
    const Success(this.value);
  }

  final class Failure<T> extends Result<T> {
    final AppFailure failure;
    const Failure(this.failure);
  }
  ```
- **DAO layer**: All DAO methods return `Future<Result<T>>`. Try-catch blocks exist only at the DAO/repository boundary where external calls happen (Drift operations, file I/O, platform plugin calls):
  ```
  Future<Result<AppSettings>> getSettings() async {
    try {
      final row = await (select(appSettingsTable)
        ..where((t) => t.id.equals(1))
      ).getSingleOrNull();
      if (row == null) return Failure(DatabaseFailure('Settings not found'));
      return Success(row.toDomain());
    } on DriftWrappedException catch (e) {
      return Failure(DatabaseFailure(e.toString()));
    }
  }
  ```
- **Notifier layer**: Notifiers pattern-match the `Result` and update their `AsyncValue` state:
  ```
  Future<void> loadSettings() async {
    state = const AsyncLoading();
    final result = await settingsDao.getSettings();
    state = switch (result) {
      Success(:final value) => AsyncData(value),
      Failure(:final failure) => AsyncError(failure, StackTrace.current),
    };
  }
  ```
- **No try-catch in business logic**: Validation functions, score calculations, formatters, and other pure business logic never throw. They return `Result<T>` values. Only the infrastructure boundary (DAO, Service) uses try-catch.
- **Composability**: Sequential operations chain with early return on failure:
  ```
  final nameResult = validateUserName(input);
  if (nameResult case Failure()) return nameResult;
  final saveResult = await dao.updateName(nameResult.value);
  return saveResult;
  ```

**NFR Requirements Satisfied**: NFR-SEC-15, NFR-REL-01

---

### EH-02: Global Error Boundary

**Description**: Framework-level and platform-level errors are captured globally, logged, and presented to the user as generic messages. The app never crashes -- it always degrades gracefully to a usable state.

**Implementation Approach**:

- **Configuration in `main()`**:
  ```
  void main() {
    FlutterError.onError = (FlutterErrorDetails details) {
      AppLogger.error('[GLOBAL]', 'Flutter framework error',
        error: details.exception, stackTrace: details.stack);
      // In debug: rethrow for red screen. In release: swallow.
    };

    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      AppLogger.error('[GLOBAL]', 'Platform/async error',
        error: error, stackTrace: stack);
      return true; // Prevents app crash
    };

    runApp(
      ProviderScope(child: LifeOsApp()),
    );
  }
  ```
- **ErrorBoundary widget**: A `StatefulWidget` placed below `MaterialApp` that catches errors from the widget tree using `ErrorWidget.builder`:
  ```
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return ErrorCard(
      message: l10n.genericError,
      onRetry: () => Navigator.of(context).pop(),
    );
  };
  ```
  In debug mode, the default red error screen is preserved for developer visibility.
- **Snackbar notification**: When a global error is caught in release mode, a generic snackbar is shown:
  `"Something went wrong. Please try again."` (localized ES/EN).
  The snackbar is triggered via a global `ScaffoldMessengerKey` accessible from the error handler.
- **Post-error state**: After a global error, the app remains on the current screen (or navigates back to Dashboard if the current route is corrupted). No blank screens or frozen UI states.

**NFR Requirements Satisfied**: NFR-SEC-15, NFR-REL-01

---

### EH-03: Error Display Pattern

**Description**: A consistent set of error presentation widgets that map `AppFailure` severity to appropriate UI treatments. All error messages are localized and never expose internal details.

**Implementation Approach**:

- **ErrorCard widget**: A reusable widget for inline error display within screens:
  ```
  class ErrorCard extends StatelessWidget {
    final IconData icon;
    final String message;       // from AppFailure.userMessage (localized)
    final VoidCallback? onRetry;

    // Renders: [icon] [message] [Retry button if onRetry != null]
  }
  ```
  Used when a section of a screen fails to load (e.g., settings section fails to read from DB).

- **Snackbar for transient errors**: Short-lived errors that resolve on retry (file picker cancelled, biometric timeout):
  ```
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(failure.userMessage),
      action: SnackBarAction(label: l10n.retry, onPressed: onRetry),
      duration: Duration(seconds: 4),
    ),
  );
  ```

- **Full-screen error for critical failures**: Database corruption, migration failure, or unrecoverable states:
  ```
  class CriticalErrorScreen extends StatelessWidget {
    // Full screen with icon, message, and "Contact Support" / "Reset App" options
  }
  ```
  Navigated to via `AppRouter` redirect when the database provider enters an unrecoverable error state.

- **Localization**: All error messages come from `AppFailure.userMessage`, which returns a localization key. The UI widget resolves the key to the current locale string:
  - `AppFailure.userMessage` returns a constant string key (e.g., `'error_backup_import_failed'`)
  - The widget maps this to `AppLocalizations.of(context).errorBackupImportFailed`
  - Internal details (`debugMessage`, `originalError`) are logged but never displayed

- **Severity mapping**:
  | AppFailure Subclass | UI Treatment |
  |---|---|
  | `ValidationFailure` | Inline form error text (below the field) |
  | `DatabaseFailure` | ErrorCard with retry |
  | `BackupFailure` | Snackbar or ErrorCard depending on phase |
  | `AuthFailure` | Lock screen retry prompt |
  | `StorageFailure` | Snackbar with retry |
  | `NotificationFailure` | Snackbar (non-blocking) |
  | `IsolateFailure` | ErrorCard with retry |

**NFR Requirements Satisfied**: NFR-SEC-09, NFR-SEC-15, NFR-REL-01

---

## 5. Testing Patterns

### TP-01: Glados PBT Architecture

**Description**: Property-based tests use the glados framework with custom `Arbitrary` generators for every domain type. Generators respect all business constraints, and seed logging ensures reproducibility.

**Implementation Approach**:

- **Directory structure**:
  ```
  test/pbt/
    generators/
      backup_manifest_gen.dart      # Arbitrary<BackupManifest>, Arbitrary<BackupModuleEntry>
      app_settings_gen.dart         # Arbitrary<AppSettings>
      notification_config_gen.dart  # Arbitrary<NotificationConfig>
      app_event_gen.dart            # Arbitrary<AppEvent> and all subclasses
      app_failure_gen.dart          # Arbitrary<AppFailure> and all subclasses
    roundtrip/
      backup_manifest_rt_test.dart  # RT-01, RT-02
      notification_config_rt_test.dart  # RT-03
      app_event_rt_test.dart        # RT-04
      enabled_modules_rt_test.dart  # RT-05
    invariant/
      app_settings_inv_test.dart    # INV-01
      onboarding_inv_test.dart      # INV-02
      app_event_inv_test.dart       # INV-03
      app_failure_inv_test.dart     # INV-04
      backup_manifest_inv_test.dart # INV-05
    idempotence/
      event_bus_idp_test.dart       # IDP-01
      backup_import_idp_test.dart   # IDP-02
      theme_setting_idp_test.dart   # IDP-03
      notification_idp_test.dart    # IDP-04
  ```

- **Generator design**: Each generator respects domain constraints:
  ```
  // Example: arbitraryAppSettings
  extension ArbitraryAppSettings on Arbitrary<AppSettings> {
    static Arbitrary<AppSettings> get instance => Arbitrary.combine7(
      Arbitrary<String>.forStrings(minLength: 1, maxLength: 50),  // userName
      Arbitrary<String>.oneOf(['es', 'en']),                       // language
      Arbitrary<String>.oneOf(['COP', 'USD', 'EUR', ...]),         // currency
      Arbitrary<String>.oneOf(['save_money', 'get_fit', ...]),     // primaryGoal
      arbitraryEnabledModules,                                     // enabledModules
      Arbitrary<String>.oneOf(['dark', 'light', 'system']),        // themeMode
      Arbitrary<bool>.simple(),                                    // useBiometric
      (name, lang, curr, goal, mods, theme, bio) => AppSettings(
        userName: name.trim().isEmpty ? 'A' : name,
        language: lang,
        currency: curr,
        primaryGoal: goal,
        enabledModules: mods,
        themeMode: theme,
        useBiometric: bio,
        onboardingCompleted: true,
      ),
    );
  }
  ```

- **Constraint enforcement in generators**:
  - `userName`: 1-50 chars, non-empty after trim (post-generation fixup if needed)
  - `enabledModules`: Non-empty list, all IDs from valid set `{'finance', 'gym', 'nutrition', 'habits', 'sleep', 'mental', 'goals'}`
  - `language`: Exactly one of `{'es', 'en'}`
  - `currency`: From the supported ISO 4217 code set
  - `NotificationConfig` times: hours 0-23, minutes 0-59
  - `AppEvent.timestamp`: Never in the future (clamped to `DateTime.now()`)
  - `AppFailure`: Non-empty `userMessage` and `debugMessage`

- **Seed logging**: Glados prints the seed and shrunk minimal example on failure by default. No test file overrides this behavior. CI captures full test output as artifacts for seed replay.

**NFR Requirements Satisfied**: NFR-TEST-01, NFR-TEST-05, NFR-TEST-06

---

### TP-02: Test Organization

**Description**: Tests are organized into four directories by type, with clear separation between example-based and property-based tests. Each test type has a specific purpose and scope.

**Implementation Approach**:

- **Directory responsibilities**:
  | Directory | Purpose | What runs here |
  |---|---|---|
  | `test/unit/` | Example-based unit tests | Pure functions (validators, formatters, score calculations), DAO tests with Drift in-memory DB, Notifier tests with mocked DAOs |
  | `test/pbt/` | Property-based tests | All 14 PBT tests (RT-01..RT-05, INV-01..INV-05, IDP-01..IDP-04) using glados |
  | `test/widget/` | Widget rendering tests | Screen rendering, user interaction, validation feedback display, accessibility checks |
  | `test/integration/` | End-to-end flow tests | Full onboarding flow, backup export/import flow, settings modification flow |

- **Naming convention**: Test files mirror the source file path:
  - `lib/core/services/backup_service.dart` -> `test/unit/core/services/backup_service_test.dart`
  - PBT files use descriptive names with property category prefix: `backup_manifest_rt_test.dart`

- **Example-based tests pin BDD scenarios**: Each example-based test corresponds to a specific scenario from user stories or business rules:
  ```
  test('BR-ONB-01: userName rejects empty string after trim', () {
    final result = validateUserName('   ');
    expect(result, isA<Failure<String>>());
  });
  ```

- **PBT tests verify general properties**: PBT tests check universal properties across the input space:
  ```
  Glados(arbitraryBackupManifest).test(
    'RT-02: BackupManifest.fromJson(manifest.toJson()) == manifest',
    (manifest) {
      final json = manifest.toJson();
      final restored = BackupManifest.fromJson(json);
      expect(restored, equals(manifest));
    },
  );
  ```

- **Regression pinning**: When a PBT test discovers a failing case, the shrunk minimal example is added as a new example-based test in `test/unit/` with a comment referencing the original PBT test ID and seed.

**NFR Requirements Satisfied**: NFR-TEST-02, NFR-TEST-03, NFR-TEST-05, NFR-TEST-07

---

### TP-03: Mocking Strategy

**Description**: A clear mocking policy that uses `mocktail` for external dependencies while using real implementations for pure functions and in-memory databases. Riverpod overrides enable clean dependency injection in tests.

**Implementation Approach**:

- **What to mock** (external dependencies with side effects):
  | Component | Mock Class | Reason |
  |---|---|---|
  | `AppSettingsDao` | `MockAppSettingsDao` | Isolate Notifier logic from DB |
  | `BiometricService` | `MockBiometricService` | `local_auth` requires device hardware |
  | `SecureStorageService` | `MockSecureStorageService` | `flutter_secure_storage` requires platform |
  | `NotificationScheduler` | `MockNotificationScheduler` | `flutter_local_notifications` requires platform |
  | `AppLogger` | `MockAppLogger` | Verify logging calls without side effects |
  | `IsolateRunner` | `MockIsolateRunner` | Avoid real isolate spawn in unit tests |
  | `file_picker` | `MockFilePicker` | Requires platform file dialog |

- **What to never mock** (use real implementations):
  | Component | Reason |
  |---|---|
  | Drift in-memory database | DAO tests use `AppDatabase(NativeDatabase.memory())` for real SQL execution |
  | Pure validators | No side effects, test real behavior directly |
  | `BackupManifest.fromJson()` | Pure deserialization logic, test with real JSON |
  | `AppFailure` subclasses | Value objects, test real construction |
  | `Result<T>` pattern matching | Core type, test real behavior |

- **Mock creation with mocktail**:
  ```
  class MockBiometricService extends Mock implements BiometricService {}

  // In test setup:
  late MockBiometricService mockBiometric;
  setUp(() {
    mockBiometric = MockBiometricService();
  });
  ```

- **Riverpod overrides for injection**:
  ```
  testWidgets('lock screen shows on biometric failure', (tester) async {
    final mockBiometric = MockBiometricService();
    when(() => mockBiometric.authenticate())
      .thenAnswer((_) async => Failure(AuthFailure('Cancelled')));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          biometricServiceProvider.overrideWithValue(mockBiometric),
        ],
        child: LifeOsApp(),
      ),
    );
  });
  ```

- **No code generation for mocks**: `mocktail` is chosen over `mockito` specifically because it requires no `build_runner` code generation for mocks. Mock classes are written by hand as one-line declarations.

**NFR Requirements Satisfied**: NFR-TEST-02, NFR-TEST-05, NFR-TEST-07

---

## Pattern-to-NFR Traceability Matrix

| Pattern ID | Pattern Name | NFR Requirements |
|---|---|---|
| SP-01 | Biometric Auth Gate | NFR-SEC-08, NFR-SEC-11, NFR-SEC-12, NFR-REL-04 |
| SP-02 | Secure Storage Abstraction | NFR-SEC-01, NFR-SEC-09, NFR-SEC-11, NFR-SEC-12 |
| SP-03 | Input Validation Middleware | NFR-SEC-05, NFR-SEC-11, NFR-SEC-15 |
| SP-04 | Structured Logging | NFR-SEC-03, NFR-SEC-09, NFR-SEC-14 |
| SP-05 | Safe Deserialization | NFR-SEC-13, NFR-SEC-15, NFR-REL-02 |
| PP-01 | Lazy Initialization | NFR-PERF-01, NFR-PERF-02, NFR-PERF-06 |
| PP-02 | Isolate-Based Processing | NFR-PERF-04, NFR-PERF-05 |
| PP-03 | Efficient Drift Queries | NFR-PERF-04, NFR-PERF-05, NFR-PERF-06 |
| AP-01 | Semantic Widget Pattern | NFR-A11Y-02, NFR-A11Y-07 |
| AP-02 | Responsive Typography | NFR-A11Y-01 |
| AP-03 | Accessible Color System | NFR-A11Y-04, NFR-A11Y-07 |
| AP-04 | Motion Control | NFR-A11Y-05 |
| EH-01 | Result Type Pattern | NFR-SEC-15, NFR-REL-01 |
| EH-02 | Global Error Boundary | NFR-SEC-15, NFR-REL-01 |
| EH-03 | Error Display Pattern | NFR-SEC-09, NFR-SEC-15, NFR-REL-01 |
| TP-01 | Glados PBT Architecture | NFR-TEST-01, NFR-TEST-05, NFR-TEST-06 |
| TP-02 | Test Organization | NFR-TEST-02, NFR-TEST-03, NFR-TEST-05, NFR-TEST-07 |
| TP-03 | Mocking Strategy | NFR-TEST-02, NFR-TEST-05, NFR-TEST-07 |

---

## NFR Coverage Verification

Every applicable NFR from `nfr-requirements.md` is covered by at least one design pattern:

| NFR Requirement | Covered By |
|---|---|
| NFR-SEC-01 | SP-02 |
| NFR-SEC-03 | SP-04 |
| NFR-SEC-05 | SP-03 |
| NFR-SEC-08 | SP-01 |
| NFR-SEC-09 | SP-02, SP-04, EH-03 |
| NFR-SEC-11 | SP-01, SP-02, SP-03 |
| NFR-SEC-12 | SP-01, SP-02 |
| NFR-SEC-13 | SP-05 |
| NFR-SEC-14 | SP-04 |
| NFR-SEC-15 | SP-03, SP-05, EH-01, EH-02, EH-03 |
| NFR-PERF-01 | PP-01 |
| NFR-PERF-02 | PP-01 |
| NFR-PERF-04 | PP-02, PP-03 |
| NFR-PERF-05 | PP-02, PP-03 |
| NFR-PERF-06 | PP-01, PP-03 |
| NFR-A11Y-01 | AP-02 |
| NFR-A11Y-02 | AP-01 |
| NFR-A11Y-04 | AP-03 |
| NFR-A11Y-05 | AP-04 |
| NFR-A11Y-07 | AP-01, AP-03 |
| NFR-TEST-01 | TP-01 |
| NFR-TEST-02 | TP-02, TP-03 |
| NFR-TEST-03 | TP-02 |
| NFR-TEST-05 | TP-01, TP-02, TP-03 |
| NFR-TEST-06 | TP-01 |
| NFR-TEST-07 | TP-02, TP-03 |
| NFR-REL-01 | EH-01, EH-02, EH-03 |
| NFR-REL-02 | SP-05 |
| NFR-REL-04 | SP-01 |
| NFR-PERF-03 | ThemeNotifier (see logical-components.md, component 7) |
| NFR-A11Y-03 | Widget implementation guideline (48x48dp minimum enforced in code review and widget tests) |
| NFR-A11Y-06 | Focus management implemented per-screen in widget code (GoRouter focus callbacks) |
| NFR-REL-03 | Drift migration strategy (configured in AppDatabase, tested in DAO unit tests) |
| NFR-MNT-01 | analysis_options.yaml configuration (see tech-stack-decisions.md) |
| NFR-MNT-02 | dart format + CI enforcement (see tech-stack-decisions.md) |
| NFR-MNT-03 | dartdoc comment policy (enforced via code review and linter rules) |
| NFR-TEST-04 | Integration test structure (see TP-02 integration directory) |
