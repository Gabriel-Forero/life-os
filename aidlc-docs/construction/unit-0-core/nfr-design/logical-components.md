# Logical Components -- Unit 0: Core Foundation

## Purpose

Defines the infrastructure-level logical components that implement the NFR design patterns from `nfr-design-patterns.md`. Each component specifies its public interface (Dart method signatures), dependencies, Riverpod provider type, NFR traceability, and testing approach.

**Target platforms**: iOS 16+ / Android API 26+
**Architecture**: 100% local-first, Riverpod + Drift, Result<T> error handling

---

## Component Interaction Diagram

```
+---------------------------------------------------------------------+
|                          main.dart                                   |
|  (Global error handlers: FlutterError.onError,                      |
|   PlatformDispatcher.onError)                                       |
+-----+------+--------------------------------------------------------+
      |      |
      v      v
+----------+    +-----------------------------------------------------+
| ErrorBoun |    |                  ProviderScope                      |
| dary      |    |                                                     |
| (widget)  |    |  +-----------------------------------------------+ |
+----------+    |  |            AppRouter (GoRouter)                 | |
                |  |  redirect guards: onboarding, biometric lock   | |
                |  +----+------------------------------------------+  |
                |       |                                          |  |
                |       v                                          |  |
                |  +------------------+   +---------------------+  |  |
                |  | BiometricLock    |   | Dashboard / Screens |  |  |
                |  | Screen           |   |                     |  |  |
                |  +--------+---------+   +---------+-----------+  |  |
                |           |                       |              |  |
                |           v                       v              |  |
                |  +------------------+   +---------------------+  |  |
                |  | BiometricService |   | ThemeNotifier       |  |  |
                |  | (local_auth)     |   | (dark/light/system) |  |  |
                |  +------------------+   +---------------------+  |  |
                |                                   |              |  |
                |           +-----+---------+-------+              |  |
                |           |     |         |                      |  |
                |           v     v         v                      |  |
                |  +------+ +--------+ +--------------------+      |  |
                |  |Access| |AppLogg | |Accessibility       |      |  |
                |  |ibilit| |er      | |Service             |      |  |
                |  |yServ.| |(struct | |(platform a11y      |      |  |
                |  +------+ |logging)| |settings)           |      |  |
                |           +---+----+ +--------------------+      |  |
                |               |                                  |  |
                |  +------------+----------------------------------+  |
                |  |                                                |  |
                |  v                                                |  |
                |  +---------------------+   +------------------+  |  |
                |  | SettingsNotifier     |   | EventBus         |  |  |
                |  | (AppSettings CRUD)   |   | (typed broadcast)|  |  |
                |  +---------+-----------+   +--------+---------+  |  |
                |            |                        |            |  |
                |            v                        v            |  |
                |  +---------------------+   +------------------+  |  |
                |  | InputValidator      |   | NotificationSche |  |  |
                |  | (pure functions)    |   | duler            |  |  |
                |  +---------------------+   | (local notifs)   |  |  |
                |                            +------------------+  |  |
                |                                                  |  |
                |  +---------------------+   +------------------+  |  |
                |  | SecureStorageService |   | BackupEngine     |  |  |
                |  | (flutter_secure_    |   | (export/import)  |  |  |
                |  |  storage)           |   +--------+---------+  |  |
                |  +---------------------+            |            |  |
                |                                     v            |  |
                |                            +------------------+  |  |
                |                            | IsolateRunner    |  |  |
                |                            | (compute tasks)  |  |  |
                |                            +------------------+  |  |
                |                                                  |  |
                +--------------------------------------------------+  |
                                                                      |
                +-----------------------------------------------------+
```

**Data flow summary**:
- `main.dart` sets up global error handlers and creates the `ProviderScope`
- `ErrorBoundary` wraps the `MaterialApp` to catch widget tree errors
- `AppRouter` uses redirect guards to check onboarding status and biometric lock
- `BiometricService` handles the auth gate; `ThemeNotifier` drives theming
- `SettingsNotifier` uses `InputValidator` before persisting to Drift via DAO
- `BackupEngine` delegates heavy work to `IsolateRunner` for non-blocking export/import
- `EventBus` provides decoupled cross-module communication
- `AppLogger` is used by all components for structured logging
- `AccessibilityService` exposes platform a11y settings to the widget layer

---

## 1. BiometricService

**Purpose**: Wraps the `local_auth` plugin and manages the biometric authentication lifecycle, including failure counting and availability checks.

**Location**: `lib/core/services/biometric_service.dart`

### Public Interface

```dart
/// Service that manages biometric authentication via local_auth.
/// All platform exceptions are caught and returned as Result<T>.
class BiometricService {
  /// Checks if biometric hardware is available and enrolled.
  /// Returns true if at least one biometric type is available.
  Future<Result<bool>> isAvailable();

  /// Returns the list of available biometric types on this device.
  /// (e.g., BiometricType.fingerprint, BiometricType.face)
  Future<Result<List<BiometricType>>> getAvailableBiometrics();

  /// Prompts the user for biometric authentication.
  /// [localizedReason] is shown in the platform dialog.
  /// Returns Success(true) on success, Failure(AuthFailure) on
  /// failure or cancellation.
  Future<Result<bool>> authenticate({required String localizedReason});
}
```

### Dependencies

| Dependency | Type | Purpose |
|---|---|---|
| `local_auth` (LocalAuthentication) | Platform plugin | Biometric hardware access |
| `AppLogger` | Internal service | Log auth attempts with `[SECURITY]` tag |

### Riverpod Provider Type

```dart
@riverpod
BiometricService biometricService(Ref ref) {
  return BiometricService(
    auth: LocalAuthentication(),
    logger: ref.read(appLoggerProvider),
  );
}
```

**Provider type**: `Provider<BiometricService>` (stateless service, single instance)

### NFR Requirements Satisfied

- NFR-SEC-08 (Application-level access control via biometric gate)
- NFR-SEC-11 (Security logic isolated in dedicated service)
- NFR-SEC-12 (Biometric authentication management)
- NFR-SEC-14 (Security event logging of auth attempts)
- NFR-REL-04 (Graceful handling of all local_auth exceptions)

### Testing Approach

- **Mock**: `MockBiometricService extends Mock implements BiometricService` via mocktail
- **Unit tests**: Verify that `authenticate()` returns `AuthFailure` when `LocalAuthentication.authenticate()` throws `PlatformException`
- **Unit tests**: Verify that `isAvailable()` returns `false` when no biometrics are enrolled
- **Widget tests**: Mock `BiometricService` to test lock screen behavior on auth success/failure
- **Never test with real hardware**: `local_auth` requires physical biometric hardware; all tests use mocks

---

## 2. SecureStorageService

**Purpose**: Wraps `flutter_secure_storage` and provides a typed API for managing AI provider API keys and other sensitive credentials. Ensures keys are never exposed in logs or error messages.

**Location**: `lib/core/services/secure_storage_service.dart`

### Public Interface

```dart
/// Typed secure storage for sensitive credentials.
/// All operations return Result<T>; platform errors are wrapped
/// in StorageFailure.
class SecureStorageService {
  /// Saves an API key for the given AI provider.
  /// Validates that [key] is non-empty before writing.
  Future<Result<void>> saveApiKey(AiProvider provider, String key);

  /// Retrieves the API key for the given AI provider.
  /// Returns Success(null) if no key is stored.
  Future<Result<String?>> getApiKey(AiProvider provider);

  /// Deletes the stored API key for the given AI provider.
  /// No-op (returns Success) if no key exists.
  Future<Result<void>> deleteApiKey(AiProvider provider);

  /// Checks whether an API key exists for the given AI provider.
  Future<Result<bool>> hasApiKey(AiProvider provider);

  /// Deletes all stored credentials. Used for full data reset.
  Future<Result<void>> clearAll();
}
```

### Dependencies

| Dependency | Type | Purpose |
|---|---|---|
| `flutter_secure_storage` (FlutterSecureStorage) | Platform plugin | Encrypted key-value storage |
| `AppLogger` | Internal service | Log storage operations (never log key values) |

### Riverpod Provider Type

```dart
@riverpod
SecureStorageService secureStorageService(Ref ref) {
  return SecureStorageService(
    storage: const FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
      iOptions: IOSOptions(accessibility: KeychainAccessibility.unlocked_this_device),
    ),
    logger: ref.read(appLoggerProvider),
  );
}
```

**Provider type**: `Provider<SecureStorageService>` (stateless service, single instance)

### NFR Requirements Satisfied

- NFR-SEC-01 (Encryption at rest for credentials)
- NFR-SEC-09 (No hardcoded secrets; secure storage only)
- NFR-SEC-11 (Credential management isolated in dedicated service)
- NFR-SEC-12 (Secure credential storage mechanism)

### Testing Approach

- **Mock**: `MockSecureStorageService extends Mock implements SecureStorageService` via mocktail
- **Unit tests**: Verify `saveApiKey` rejects empty key strings with `ValidationFailure`
- **Unit tests**: Verify `getApiKey` returns `null` for non-existent provider
- **Unit tests**: Verify `clearAll` completes without error
- **Never use real storage**: `flutter_secure_storage` requires platform keychain; all tests use mocks

---

## 3. AppLogger

**Purpose**: Provides structured logging with level filtering, PII scrubbing, and security event tagging. Replaces all `print()` calls across the codebase.

**Location**: `lib/core/services/app_logger.dart`

### Public Interface

```dart
/// Structured logging service with PII scrubbing and level gating.
/// In release mode, only warning and error levels are emitted.
/// All methods are static for convenient access without injection
/// (though a provider is available for testability).
class AppLogger {
  /// Debug-level log. Suppressed in release builds.
  static void debug(String tag, String message);

  /// Info-level log. Suppressed in release builds.
  static void info(String tag, String message);

  /// Warning-level log. Always emitted.
  static void warning(String tag, String message);

  /// Error-level log. Always emitted.
  /// [error] and [stackTrace] are included in debug output only.
  static void error(String tag, String message, {
    Object? error,
    StackTrace? stackTrace,
  });

  /// Returns the most recent log entries from the in-memory buffer.
  /// Used for crash reporting context in release builds.
  /// Returns at most [count] entries (default 100).
  static List<LogEntry> getRecentEntries({int count = 100});
}

/// A single structured log entry.
class LogEntry {
  final DateTime timestamp;
  final LogLevel level;
  final String tag;
  final String message;
  final Object? error;
}

/// Log severity levels.
enum LogLevel { debug, info, warning, error }
```

### Dependencies

| Dependency | Type | Purpose |
|---|---|---|
| `dart:developer` (log) | Dart SDK | Console output in debug mode |
| `kReleaseMode` (foundation) | Flutter SDK | Level filtering by build mode |

### Riverpod Provider Type

```dart
@riverpod
AppLogger appLogger(Ref ref) {
  return AppLogger();
}
```

**Provider type**: `Provider<AppLogger>` (stateless service; static methods also available for convenience in non-Riverpod contexts like `main()`)

### NFR Requirements Satisfied

- NFR-SEC-03 (Structured application logging with timestamps, levels, tags)
- NFR-SEC-09 (No debug info in release builds; level gating)
- NFR-SEC-14 (Security event logging via `[SECURITY]` tagged entries)

### Testing Approach

- **Mock**: `MockAppLogger extends Mock implements AppLogger` for verifying log calls
- **Unit tests**: Verify PII scrubbing replaces email patterns and phone numbers with `[REDACTED]`
- **Unit tests**: Verify level filtering suppresses debug/info in release mode simulation
- **Unit tests**: Verify `getRecentEntries` returns entries in correct order with buffer rotation
- **Unit tests**: Verify `[SECURITY]` tag appears in security-related log output

---

## 4. InputValidator

**Purpose**: A collection of pure validation functions that validate user input before any DAO call. Functions are composable, stateless, and return `Result<T>` values.

**Location**: `lib/core/validators/input_validator.dart`

### Public Interface

```dart
/// Pure validation functions for user input.
/// All functions are top-level (not class methods) for easy testability
/// and composability.

// --- Domain-specific validators ---

/// Validates userName: trims whitespace, checks 1-50 char length,
/// rejects whitespace-only input.
Result<String> validateUserName(String input);

/// Validates language code against allowlist: {'es', 'en'}.
Result<String> validateLanguage(String input);

/// Validates currency code against supported ISO 4217 codes.
Result<String> validateCurrency(String input);

/// Validates primary goal against allowlist:
/// {'save_money', 'get_fit', 'be_disciplined', 'balance'}.
Result<String> validatePrimaryGoal(String input);

/// Validates enabled modules list: non-empty, all IDs in valid set.
Result<List<String>> validateEnabledModules(List<String> input);

/// Validates theme mode against allowlist: {'dark', 'light', 'system'}.
Result<String> validateThemeMode(String input);

/// Validates notification time: hours 0-23, minutes 0-59.
Result<({int hour, int minute})> validateNotificationTime(int hour, int minute);

// --- Composable primitive validators ---

/// Rejects null or empty string.
Result<String> validateRequired(String? input, {required String fieldName});

/// Rejects strings exceeding [max] characters.
Result<String> validateMaxLength(String input, int max, {required String fieldName});

/// Rejects strings shorter than [min] characters.
Result<String> validateMinLength(String input, int min, {required String fieldName});

/// Rejects values not in [allowed] set.
Result<T> validateAllowlist<T>(T input, Set<T> allowed, {required String fieldName});

/// Rejects numbers outside [min]..[max] range (inclusive).
Result<num> validateNumericRange(num input, num min, num max, {required String fieldName});
```

### Dependencies

| Dependency | Type | Purpose |
|---|---|---|
| `Result<T>` | Internal model | Return type for all validators |
| `ValidationFailure` | Internal model | Failure type with field name and violation |

### Riverpod Provider Type

**No provider needed.** Validators are pure top-level functions with no dependencies or state. They are called directly by Notifiers:

```dart
final result = validateUserName(nameInput);
```

### NFR Requirements Satisfied

- NFR-SEC-05 (Input validation on all user inputs)
- NFR-SEC-11 (Validation centralized as reusable functions)
- NFR-SEC-15 (Validation failures return Result, never throw)

### Testing Approach

- **Never mock**: Pure functions with no dependencies; test with real implementation
- **Unit tests**: Test each validator with valid and invalid inputs
- **Unit tests**: Test composable primitives independently
- **PBT tests**: `INV-01` (AppSettings mutations preserve field constraints) uses validators indirectly
- **Edge cases**: Empty strings, max-length strings, unicode characters, whitespace-only, null input

---

## 5. IsolateRunner

**Purpose**: A utility for running computationally expensive tasks in a Dart isolate with progress reporting. Prevents UI jank during backup export/import and large data processing.

**Location**: `lib/core/services/isolate_runner.dart`

### Public Interface

```dart
/// Utility for running heavy computation in a background isolate.
/// Provides progress reporting via callback and cancellation support.
class IsolateRunner {
  /// Runs [task] in a background isolate.
  /// [onProgress] is called on the main isolate with a value 0.0..1.0.
  /// Returns the task result wrapped in Result<T>.
  /// Catches all isolate errors and wraps them in IsolateFailure.
  static Future<Result<T>> run<T>({
    required FutureOr<T> Function(void Function(double progress) reportProgress) task,
    required void Function(double progress) onProgress,
  });

  /// Runs a simple computation without progress reporting.
  /// Equivalent to Flutter's compute() but returns Result<T>.
  static Future<Result<T>> compute<T, P>({
    required T Function(P param) computation,
    required P param,
  });
}
```

### Dependencies

| Dependency | Type | Purpose |
|---|---|---|
| `dart:isolate` (Isolate, SendPort, ReceivePort) | Dart SDK | Background isolate management |
| `AppLogger` | Internal service | Log isolate lifecycle events |

### Riverpod Provider Type

**No provider needed.** `IsolateRunner` uses only static methods and manages isolate lifecycle internally. It is called by `BackupEngine` which is itself a provider.

### NFR Requirements Satisfied

- NFR-PERF-04 (Backup export in under 5 seconds, non-blocking)
- NFR-PERF-05 (Backup import in under 10 seconds, non-blocking)

### Testing Approach

- **Mock**: `MockIsolateRunner extends Mock implements IsolateRunner` for unit testing BackupEngine without spawning real isolates
- **Integration tests**: Test real isolate execution with small datasets to verify progress reporting works
- **Unit tests**: Verify error handling when isolate task throws
- **Unit tests**: Verify progress callback receives monotonically increasing values

---

## 6. BackupEngine

**Purpose**: Orchestrates backup export and import operations. Delegates heavy work to `IsolateRunner`, validates manifests, handles selective module merge, and reports detailed results.

**Location**: `lib/core/services/backup_engine.dart`

### Public Interface

```dart
/// Orchestrates backup export and import with isolate processing,
/// manifest validation, and per-module result tracking.
class BackupEngine {
  /// Exports all enabled modules to a ZIP archive.
  /// Returns the ZIP file bytes on success.
  /// [onProgress] reports progress 0.0..1.0 across all modules.
  Future<Result<Uint8List>> exportBackup({
    required List<String> enabledModules,
    required void Function(double progress) onProgress,
  });

  /// Imports a backup from ZIP file bytes.
  /// Validates manifest before any data modification (fail-closed).
  /// Returns detailed per-module import results.
  /// [onProgress] reports progress 0.0..1.0 across all modules.
  /// [mergeStrategy] controls duplicate handling: skip or replace.
  Future<Result<BackupImportResult>> importBackup({
    required Uint8List zipBytes,
    required MergeStrategy mergeStrategy,
    required void Function(double progress) onProgress,
  });

  /// Validates a backup manifest without performing import.
  /// Used for preview (show user what the backup contains).
  Future<Result<BackupManifest>> validateManifest(Uint8List zipBytes);
}

/// Result of a backup import operation with per-module details.
class BackupImportResult {
  final int totalModules;
  final int successModules;
  final List<ModuleImportResult> moduleResults;
}

/// Per-module import result with record counts.
class ModuleImportResult {
  final String moduleId;
  final int insertedCount;
  final int skippedCount;
  final int failedCount;
  final List<String> errors; // Per-record error descriptions
}

/// Strategy for handling duplicate records during import.
enum MergeStrategy { skip, replace }
```

### Dependencies

| Dependency | Type | Purpose |
|---|---|---|
| `IsolateRunner` | Internal service | Run serialization/deserialization off main isolate |
| `AppDatabase` | Drift database | Read module data for export, write module data for import |
| `AppLogger` | Internal service | Log backup operations with `[SECURITY]` tag |
| `archive` package | External package | ZIP creation and extraction |

### Riverpod Provider Type

```dart
@riverpod
BackupEngine backupEngine(Ref ref) {
  return BackupEngine(
    database: ref.read(appDatabaseProvider).requireValue,
    logger: ref.read(appLoggerProvider),
  );
}
```

**Provider type**: `Provider<BackupEngine>` (stateless service that uses injected database)

### NFR Requirements Satisfied

- NFR-SEC-13 (Manifest validation before import, safe deserialization)
- NFR-SEC-14 (Backup operations logged as security events)
- NFR-SEC-15 (Fail-closed on invalid manifest, Result<T> returns)
- NFR-PERF-04 (Export under 5 seconds via isolate)
- NFR-PERF-05 (Import under 10 seconds via isolate)
- NFR-REL-02 (No data modification if manifest validation fails)

### Testing Approach

- **Mock**: `IsolateRunner` mocked to avoid real isolate spawn; DAO methods mocked for data reads/writes
- **Unit tests with Drift in-memory DB**: Test full export-import round trip with small dataset
- **Unit tests**: Verify manifest validation rejects invalid manifests (missing fields, wrong types, unsupported schema version)
- **Unit tests**: Verify per-record validation skips bad records without aborting
- **PBT tests**: RT-01, RT-02 (BackupManifest round-trip), IDP-02 (import idempotence)

---

## 7. ThemeNotifier

**Purpose**: Manages the app's visual theme including dark/light/system mode, high contrast, font scale factor, and per-module accent colors. Persists theme preferences to `AppSettings` via DAO.

**Location**: `lib/core/notifiers/theme_notifier.dart`

### Public Interface

```dart
/// Riverpod AsyncNotifier that manages theme state.
/// Synchronously provides ThemeData for instant theme switching.
class ThemeNotifier extends AsyncNotifier<ThemeState> {
  /// Sets the theme mode (dark, light, or system).
  /// Persists to AppSettings and rebuilds ThemeData.
  Future<void> setThemeMode(ThemeMode mode);

  /// Toggles high-contrast mode for accessibility.
  /// Uses alternative color palette with higher contrast ratios.
  Future<void> setHighContrast(bool enabled);

  /// Updates the font scale factor (clamped to 1.0..2.0).
  Future<void> setFontScale(double scale);

  /// Returns the current ThemeData (dark or light based on mode
  /// and system brightness).
  ThemeData get currentTheme;

  /// Returns the accent color for the given module ID.
  Color moduleAccentColor(String moduleId);
}

/// Immutable state holding all theme configuration.
class ThemeState {
  final ThemeMode mode;           // dark, light, system
  final bool highContrast;        // accessibility toggle
  final double fontScale;         // 1.0 to 2.0
  final ThemeData lightTheme;     // pre-built light ThemeData
  final ThemeData darkTheme;      // pre-built dark ThemeData
}
```

### Dependencies

| Dependency | Type | Purpose |
|---|---|---|
| `AppSettingsDao` | Drift DAO | Persist theme preferences |
| `AppColors` | Internal constants | Color palette (standard + high contrast) |
| `AppTypography` | Internal class | Font scale-aware TextTheme builder |
| `AppLogger` | Internal service | Log theme changes |

### Riverpod Provider Type

```dart
@riverpod
class ThemeNotifier extends _$ThemeNotifier {
  @override
  Future<ThemeState> build() async {
    final settings = await ref.read(settingsNotifierProvider.future);
    return _buildThemeState(settings);
  }
}
```

**Provider type**: `AsyncNotifierProvider<ThemeNotifier, ThemeState>` (async because initial load reads from database)

### NFR Requirements Satisfied

- NFR-PERF-03 (Theme switch < 100ms; ThemeData objects pre-built in state)
- NFR-A11Y-01 (Font scale support via `setFontScale` and AppTypography integration)
- NFR-A11Y-04 (High-contrast mode with WCAG AA verified color pairs)
- NFR-A11Y-07 (Module accent colors always paired with icons and text)

### Testing Approach

- **Mock**: `AppSettingsDao` mocked to isolate theme logic from database
- **Unit tests**: Verify `setThemeMode` updates state and calls DAO persist
- **Unit tests**: Verify font scale clamping at boundaries (0.5 -> 1.0, 3.0 -> 2.0)
- **Unit tests**: Verify high-contrast toggle rebuilds ThemeData with HC palette
- **Widget tests**: Verify theme switch produces no visible delay or flicker
- **PBT tests**: IDP-03 (setting same theme mode twice yields identical state)

---

## 8. AccessibilityService

**Purpose**: Reads platform accessibility settings (reduce motion, screen reader active, text scale) and exposes them as a Riverpod provider. Widgets use this to adapt their behavior for accessibility.

**Location**: `lib/core/services/accessibility_service.dart`

### Public Interface

```dart
/// Reads and exposes platform-level accessibility settings.
/// Values update when the platform settings change (via
/// WidgetsBindingObserver).
class AccessibilityService {
  /// Whether the user has enabled "Reduce Motion" / "Remove Animations".
  bool get reduceMotionEnabled;

  /// Whether a screen reader (VoiceOver / TalkBack) is currently active.
  bool get screenReaderActive;

  /// The current system text scale factor (1.0 = default).
  double get textScaleFactor;

  /// Whether haptic feedback should be used (considers platform settings).
  bool get shouldUseHaptics;
}

/// Immutable snapshot of all accessibility settings.
class AccessibilityState {
  final bool reduceMotion;
  final bool screenReaderActive;
  final double textScaleFactor;
  final bool hapticsEnabled;
}
```

### Dependencies

| Dependency | Type | Purpose |
|---|---|---|
| `WidgetsBinding` | Flutter SDK | Access to `MediaQueryData` and platform accessibility flags |
| `MediaQuery` | Flutter SDK | `disableAnimations`, `textScaleFactor`, `accessibleNavigation` |

### Riverpod Provider Type

```dart
@riverpod
class AccessibilityNotifier extends _$AccessibilityNotifier {
  @override
  AccessibilityState build() {
    // Read initial values from platform
    final binding = WidgetsBinding.instance;
    final window = binding.platformDispatcher.views.first;
    return AccessibilityState(
      reduceMotion: window.accessibilityFeatures.disableAnimations,
      screenReaderActive: window.accessibilityFeatures.accessibleNavigation,
      textScaleFactor: window.platformDispatcher.textScaleFactor,
      hapticsEnabled: true, // default, can be toggled by user
    );
  }
}
```

**Provider type**: `NotifierProvider<AccessibilityNotifier, AccessibilityState>` (synchronous, reads platform values directly)

### NFR Requirements Satisfied

- NFR-A11Y-01 (Exposes text scale factor for dynamic font scaling)
- NFR-A11Y-05 (Exposes reduce motion flag for animation control)

### Testing Approach

- **Mock**: Use `TestWidgetsFlutterBinding` to set accessibility feature flags in tests
- **Widget tests**: Verify animations are skipped when `reduceMotionEnabled == true`
- **Widget tests**: Verify text scale factor is propagated to `AppTypography`
- **Unit tests**: Verify `shouldUseHaptics` returns false when platform accessibility disables it

---

## 9. ErrorBoundary

**Purpose**: A widget-level error handler that catches unhandled widget tree errors and presents user-friendly error UI. Works in conjunction with the global error handlers set in `main()`.

**Location**: `lib/core/widgets/error_boundary.dart`

### Public Interface

```dart
/// Widget that catches errors in its child widget tree.
/// Shows ErrorCard in release mode, default red error screen in debug.
class ErrorBoundary extends StatefulWidget {
  final Widget child;

  /// Optional callback invoked when an error is caught.
  final void Function(FlutterErrorDetails details)? onError;

  const ErrorBoundary({required this.child, this.onError});
}

/// Reusable widget for displaying error states inline.
class ErrorCard extends StatelessWidget {
  final String message;
  final IconData icon;
  final VoidCallback? onRetry;

  const ErrorCard({
    required this.message,
    this.icon = Icons.error_outline,
    this.onRetry,
  });
}

/// Full-screen error for unrecoverable states (DB corruption, etc.).
class CriticalErrorScreen extends StatelessWidget {
  final String message;
  final VoidCallback? onResetApp;

  const CriticalErrorScreen({required this.message, this.onResetApp});
}
```

### Dependencies

| Dependency | Type | Purpose |
|---|---|---|
| `AppLogger` | Internal service | Log caught errors |
| `FlutterError.onError` | Flutter SDK | Widget tree error capture |
| `AppLocalizations` | Internal l10n | Localized error messages |

### Riverpod Provider Type

**No provider needed.** `ErrorBoundary` is a `StatefulWidget` placed in the widget tree. `ErrorCard` and `CriticalErrorScreen` are stateless widgets used declaratively.

### NFR Requirements Satisfied

- NFR-SEC-09 (Generic user-facing error messages, no internal details)
- NFR-SEC-15 (Global error capture, fail gracefully, never crash)
- NFR-REL-01 (App remains usable after catching errors)

### Testing Approach

- **Widget tests**: Verify `ErrorCard` renders message and retry button
- **Widget tests**: Verify `CriticalErrorScreen` renders with reset action
- **Widget tests**: Verify `ErrorBoundary` catches thrown errors and shows `ErrorCard` in release mode
- **Unit tests**: Verify error logging is called when `ErrorBoundary` catches an error

---

## 10. EventBus

**Purpose**: A typed broadcast event system using `StreamController` for decoupled cross-module communication. Modules publish events without knowing about subscribers.

**Location**: `lib/core/services/event_bus.dart`

### Public Interface

```dart
/// Broadcast event bus for typed cross-module communication.
/// Uses a single StreamController<AppEvent> in broadcast mode.
class EventBus {
  /// Publishes an event to all subscribers.
  void publish(AppEvent event);

  /// Subscribes to events of a specific type [T].
  /// Returns a StreamSubscription that MUST be cancelled on dispose.
  StreamSubscription<T> on<T extends AppEvent>(void Function(T event) handler);

  /// Returns a Stream of events of type [T] for use with
  /// Riverpod StreamProvider.
  Stream<T> streamOf<T extends AppEvent>();

  /// Disposes the underlying StreamController.
  /// Called via Riverpod onDispose.
  void dispose();
}
```

### Dependencies

| Dependency | Type | Purpose |
|---|---|---|
| `dart:async` (StreamController, StreamSubscription) | Dart SDK | Broadcast stream infrastructure |
| `AppEvent` sealed class hierarchy | Internal model | Typed event definitions |
| `AppLogger` | Internal service | Log published events at debug level |

### Riverpod Provider Type

```dart
@riverpod
EventBus eventBus(Ref ref) {
  final bus = EventBus();
  ref.onDispose(() => bus.dispose());
  return bus;
}
```

**Provider type**: `Provider<EventBus>` (singleton, disposed when provider scope is disposed)

### NFR Requirements Satisfied

- NFR-SEC-15 (StreamController disposed via `ref.onDispose`, preventing resource leaks)

### Testing Approach

- **Never mock**: Use real `EventBus` instance in tests (it is a simple in-memory stream)
- **Unit tests**: Verify `publish` delivers event to subscriber of matching type
- **Unit tests**: Verify `on<T>` filters events by type (publishes WorkoutCompletedEvent, subscription to MealLoggedEvent receives nothing)
- **Unit tests**: Verify `dispose` closes the stream and subsequent `publish` calls do not throw
- **PBT tests**: IDP-01 (duplicate event processing yields same result)

---

## 11. NotificationScheduler

**Purpose**: Wraps `flutter_local_notifications` and provides a typed API for scheduling, cancelling, and managing local notifications. Supports timezone-aware scheduling and per-type notification management.

**Location**: `lib/core/services/notification_scheduler.dart`

### Public Interface

```dart
/// Manages local notification scheduling via flutter_local_notifications.
/// All platform exceptions are caught and returned as Result<T>.
class NotificationScheduler {
  /// Initializes the notification plugin with platform-specific settings.
  /// Must be called once before any other method.
  Future<Result<void>> initialize();

  /// Requests notification permission from the user.
  /// Returns true if permission granted, false if denied.
  Future<Result<bool>> requestPermission();

  /// Schedules a daily notification at the given time.
  /// [id] is a unique notification ID per type.
  /// [time] is the local time of day to fire.
  /// [title] and [body] are the notification content (localized).
  Future<Result<void>> scheduleDailyNotification({
    required int id,
    required TimeOfDay time,
    required String title,
    required String body,
    required String channelId,
    required String channelName,
  });

  /// Cancels a scheduled notification by [id].
  Future<Result<void>> cancelNotification(int id);

  /// Cancels all scheduled notifications.
  Future<Result<void>> cancelAll();

  /// Returns the list of currently pending notification requests.
  Future<Result<List<PendingNotificationRequest>>> getPendingNotifications();
}
```

### Dependencies

| Dependency | Type | Purpose |
|---|---|---|
| `flutter_local_notifications` (FlutterLocalNotificationsPlugin) | Platform plugin | Native notification scheduling |
| `timezone` (TZDateTime) | External package | Timezone-aware scheduling |
| `AppLogger` | Internal service | Log scheduling operations |

### Riverpod Provider Type

```dart
@riverpod
NotificationScheduler notificationScheduler(Ref ref) {
  final scheduler = NotificationScheduler(
    plugin: FlutterLocalNotificationsPlugin(),
    logger: ref.read(appLoggerProvider),
  );
  // Initialize lazily on first access
  return scheduler;
}
```

**Provider type**: `Provider<NotificationScheduler>` (stateless service with lazy initialization)

### NFR Requirements Satisfied

- NFR-SEC-06 (Notification permission requested at point of use, not at install)
- NFR-SEC-15 (All plugin exceptions caught and wrapped in NotificationFailure)

### Testing Approach

- **Mock**: `MockNotificationScheduler extends Mock implements NotificationScheduler` via mocktail
- **Unit tests**: Verify `scheduleDailyNotification` constructs correct TZDateTime for the given TimeOfDay
- **Unit tests**: Verify `cancelNotification` calls plugin cancel with correct ID
- **Unit tests**: Verify error handling when plugin throws PlatformException
- **PBT tests**: IDP-04 (scheduling same notification twice results in exactly one set of notifications)
- **Never test with real plugin**: `flutter_local_notifications` requires platform channels; all tests use mocks

---

## Component Summary Matrix

| # | Component | Location | Provider Type | Key Pattern(s) | Primary NFRs |
|---|---|---|---|---|---|
| 1 | BiometricService | `core/services/` | `Provider` | SP-01 | NFR-SEC-08, NFR-SEC-12, NFR-REL-04 |
| 2 | SecureStorageService | `core/services/` | `Provider` | SP-02 | NFR-SEC-01, NFR-SEC-12 |
| 3 | AppLogger | `core/services/` | `Provider` (+ static) | SP-04 | NFR-SEC-03, NFR-SEC-14 |
| 4 | InputValidator | `core/validators/` | None (pure functions) | SP-03 | NFR-SEC-05, NFR-SEC-11 |
| 5 | IsolateRunner | `core/services/` | None (static methods) | PP-02 | NFR-PERF-04, NFR-PERF-05 |
| 6 | BackupEngine | `core/services/` | `Provider` | SP-05, PP-02 | NFR-SEC-13, NFR-PERF-04, NFR-REL-02 |
| 7 | ThemeNotifier | `core/notifiers/` | `AsyncNotifierProvider` | AP-02, AP-03 | NFR-PERF-03, NFR-A11Y-01, NFR-A11Y-04 |
| 8 | AccessibilityService | `core/services/` | `NotifierProvider` | AP-04 | NFR-A11Y-01, NFR-A11Y-05 |
| 9 | ErrorBoundary | `core/widgets/` | None (widget) | EH-02, EH-03 | NFR-SEC-15, NFR-REL-01 |
| 10 | EventBus | `core/services/` | `Provider` | -- | NFR-SEC-15 (resource cleanup) |
| 11 | NotificationScheduler | `core/services/` | `Provider` | -- | NFR-SEC-06, NFR-SEC-15 |

---

## Dependency Graph (Components Only)

```
BiometricService -----> AppLogger
SecureStorageService --> AppLogger
BackupEngine ---------> IsolateRunner
BackupEngine ---------> AppDatabase (Drift)
BackupEngine ---------> AppLogger
ThemeNotifier --------> AppSettingsDao
ThemeNotifier --------> AppColors, AppTypography
NotificationScheduler -> AppLogger
EventBus -------------> AppLogger (debug-level only)
ErrorBoundary --------> AppLogger
SettingsNotifier -----> InputValidator (direct function call)
SettingsNotifier -----> AppSettingsDao
SettingsNotifier -----> EventBus (publishes SettingsChangedEvent)
```

**Key observations**:
- `AppLogger` is the most depended-upon component (used by 7 of 11 components)
- `InputValidator` has zero dependencies (pure functions) -- easiest to test
- `IsolateRunner` has no Riverpod provider (static utility) -- used only by `BackupEngine`
- `ErrorBoundary` is a widget, not a provider -- placed in the widget tree declaratively
- All provider-based components use constructor injection for testability via Riverpod overrides
