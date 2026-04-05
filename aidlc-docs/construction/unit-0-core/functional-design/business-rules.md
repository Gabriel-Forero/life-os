# Business Rules -- Unit 0: Core Foundation

## Purpose

Defines all business rules for Unit 0 covering onboarding, backup, theme, biometric authentication, notifications, EventBus, and error handling. Each rule includes an ID, description, rationale, and validation criteria.

---

## Onboarding Rules

### BR-ONB-01: User Name Validation

**Description**: User name is required, must be 1-50 characters after trimming, and must not consist of only whitespace. Leading and trailing spaces are automatically stripped before persistence.

**Rationale**: Prevents empty display names in greetings and Dashboard while allowing names with internal spaces and accented characters common in Spanish (e.g., "Maria Jose", "Andres").

**Validation Criteria**:
- Input with only whitespace is rejected with a ValidationFailure
- Input longer than 50 characters after trimming is rejected with a ValidationFailure
- Input with leading/trailing spaces is accepted but stored trimmed
- Input with internal spaces, accents, tildes, and Unicode letters is accepted
- Empty string is rejected with a ValidationFailure

---

### BR-ONB-02: Language Selection

**Description**: Language must be either `'es'` (Spanish) or `'en'` (English). Default is `'es'`. On the language selection screen, the system language is detected and pre-selected if it matches a supported language.

**Rationale**: LifeOS targets a Spanish-speaking primary audience (Colombia) with English as secondary language. Pre-selecting the system language reduces friction.

**Validation Criteria**:
- Only `'es'` and `'en'` are accepted values
- Any other value is rejected with a ValidationFailure
- If no selection is made, `'es'` is used as the default
- System language detection maps `es_*` locale codes to `'es'` and `en_*` to `'en'`
- Unsupported system locales default to `'es'`

---

### BR-ONB-03: Currency Selection

**Description**: Currency must be a valid ISO 4217 code from the app's supported currency list. Default is `'COP'` (Colombian Peso). The currency picker shows a searchable list with the user's locale-appropriate currencies prioritized at the top.

**Rationale**: COP default matches the primary target market. ISO 4217 ensures consistent formatting across the Finance module.

**Validation Criteria**:
- Only ISO 4217 codes from the supported list are accepted
- Arbitrary 3-letter strings not in the supported list are rejected
- Default `'COP'` is pre-selected on the currency screen
- Currency code is stored uppercase (e.g., `'COP'`, never `'cop'`)

---

### BR-ONB-04: Minimum Module Selection

**Description**: At least 1 module must be enabled. The user cannot proceed from the module selection screen with zero modules selected. Deselecting the last active module is prevented (button disabled or shows validation message).

**Rationale**: An app with zero modules has no functionality. Requiring at least one ensures the Dashboard and navigation have something to show.

**Validation Criteria**:
- Attempting to save with an empty module list returns a ValidationFailure
- The UI disables "Continue" when zero modules are selected
- Selecting/deselecting modules updates the list reactively
- The `enabledModules` JSON array always contains at least 1 valid module ID after onboarding

---

### BR-ONB-05: Primary Goal Selection

**Description**: Primary goal is required and must be one of the predefined enum values: `'save_money'`, `'get_fit'`, `'be_disciplined'`, or `'balance'`. Displayed in the user's selected language.

**Rationale**: The primary goal drives Dashboard module prioritization and Intelligence suggestions. Having this from day one enables personalized experience immediately.

**Validation Criteria**:
- Only the four predefined values are accepted
- Any other string is rejected with a ValidationFailure
- The user cannot proceed from the goal screen without selecting one
- Goal labels are displayed in the correct language based on BR-ONB-02 selection

---

### BR-ONB-06: Onboarding Skip After Language

**Description**: After the language selection screen (ONB-02), the user can skip the remaining onboarding steps. If skipped, defaults are applied: name = "Usuario" (ES) / "User" (EN), currency = "COP", primaryGoal = "balance", enabledModules = all available modules. `onboardingCompleted` is set to `true`.

**Rationale**: Power users who want to configure later should not be blocked. Reasonable defaults ensure the app is functional even without full onboarding completion.

**Validation Criteria**:
- A "Skip" action is available on screens after language selection
- Skipping applies all documented defaults and marks onboarding complete
- The user can change all settings later from the Settings screen
- The welcome screen (ONB-01) and language screen (ONB-02) cannot be skipped

---

### BR-ONB-07: Optional First Data Entry

**Description**: On the final onboarding screen, the user may optionally create their first data entry (a budget if Finance is enabled, or a habit if Habits is enabled). If the user skips this step, the relevant module shows an empty state with a call-to-action (CTA) button.

**Rationale**: Offering first data entry reduces the "empty app" feeling and teaches the core interaction pattern. Making it optional respects users who want to explore first.

**Validation Criteria**:
- If Finance is enabled, the option to create a first budget is shown
- If Habits is enabled (and Finance is not, or additionally), the option to create a first habit is shown
- Skipping this step completes onboarding successfully
- Modules without initial data show an empty state with a CTA ("Add your first expense", etc.)
- First data entry follows the same validation rules as normal data entry in the respective module

---

## Backup Rules

### BR-BKP-01: Export ZIP Structure

**Description**: Backup export creates a ZIP archive containing `manifest.json` at the root and one JSON file per enabled module (e.g., `finance.json`, `gym.json`, `settings.json`). The `settings.json` file is always included regardless of module selection.

**Rationale**: Per-module files enable selective import and make debugging easier (user can share only the affected module file).

**Validation Criteria**:
- The ZIP contains exactly one `manifest.json` at the root level
- Each enabled module has a corresponding `{module-name}.json` file
- `settings.json` is always present in the ZIP
- No extraneous files are included in the ZIP
- Each module JSON file contains an array of records from all tables belonging to that module

---

### BR-BKP-02: Manifest Contents

**Description**: The `manifest.json` must include: `appVersion` (semantic versioning), `exportDate` (ISO 8601), `deviceInfo` (model + OS), `driftSchemaVersion` (integer), and `modules` (list with name + recordCount per module).

**Rationale**: The manifest enables pre-import validation without reading the entire backup. Schema version prevents importing data from a newer schema into an older app.

**Validation Criteria**:
- All five top-level fields are present and non-null
- `appVersion` matches semantic versioning format (`X.Y.Z`)
- `exportDate` is a valid ISO 8601 timestamp
- `driftSchemaVersion` is a positive integer
- Each module entry has both `name` (non-empty string) and `recordCount` (non-negative integer)

---

### BR-BKP-03: Schema Version Compatibility

**Description**: On import, the manifest's `driftSchemaVersion` is compared to the current app's schema version. If the backup schema version is strictly greater than the app's current version, the import is rejected with a BackupFailure. Equal or lower schema versions are accepted (the app can migrate forward).

**Rationale**: A backup from a newer app version may reference tables or columns that do not exist in the current version, making import unsafe.

**Validation Criteria**:
- Import of a backup with `driftSchemaVersion` > current version returns `BackupFailure(phase: 'validate')`
- Import of a backup with `driftSchemaVersion` == current version succeeds
- Import of a backup with `driftSchemaVersion` < current version succeeds (data migrated forward if needed)
- The error message clearly tells the user to update the app

---

### BR-BKP-04: Selective Module Import

**Description**: After manifest validation, the user is presented with a list of modules in the backup and can select which ones to restore. Only selected modules' data is imported; unselected modules are left untouched.

**Rationale**: Users may want to restore only Finance data after re-installing, without overwriting their current Gym or Habits data.

**Validation Criteria**:
- The import preview screen shows all modules from the manifest with record counts
- Each module has a toggle (on/off) for selective import
- Only toggled-on modules are processed during import
- Toggled-off modules' existing data remains completely unchanged
- At least one module must be selected to proceed (importing zero modules is prevented)

---

### BR-BKP-05: Merge Import Strategy

**Description**: Import does NOT delete existing data. It merges by inserting new records and skipping duplicates. Duplicate detection is based on primary key (Drift row ID). If a record with the same ID already exists, the existing record is kept and the import record is skipped.

**Rationale**: Non-destructive import prevents accidental data loss. Users importing a backup should gain data, not lose it.

**Validation Criteria**:
- After import, existing records with matching IDs are unchanged
- New records (IDs not present in the current database) are inserted
- No existing records are deleted during import
- The import result report shows counts: inserted, skipped (duplicate), and failed per module
- If all records in a module are duplicates, the import for that module reports 0 inserted and N skipped

---

### BR-BKP-06: Import Preview

**Description**: Before confirming import, the user sees a preview showing each module's name and record count from the backup manifest. The preview also indicates which modules are currently present in the app's database (for merge context).

**Rationale**: Preview prevents surprise data changes and helps the user make an informed decision about which modules to restore.

**Validation Criteria**:
- Preview displays module name and record count for each module in the backup
- Preview is generated from the manifest without reading the full module JSON files
- User must explicitly confirm after reviewing the preview to start import
- Cancel from the preview screen aborts the import with no side effects

---

### BR-BKP-07: Background Processing

**Description**: Both export and import operations run in a Dart isolate to avoid blocking the UI thread. A progress indicator is shown during the operation. The user can continue viewing the app (read-only) but cannot make data changes until the operation completes.

**Rationale**: Large datasets (hundreds of workouts, thousands of transactions) can take seconds to serialize/deserialize. Blocking the main isolate causes UI jank and ANR dialogs.

**Validation Criteria**:
- Export and import functions use `Isolate.run()` or `compute()` for heavy processing
- A progress indicator or loading overlay is shown during the operation
- The UI remains responsive (no frame drops) during export/import
- Data modification operations are temporarily blocked during import to prevent race conditions

---

## Theme Rules

### BR-THM-01: Default Dark Theme

**Description**: The default theme mode is dark. On first launch and after onboarding, the app displays in dark mode unless the user explicitly changes it.

**Rationale**: Dark mode is the primary design aesthetic for LifeOS, designed with a custom near-black surface palette, not the default Material dark theme.

**Validation Criteria**:
- New installations default to `themeMode = 'dark'`
- The dark theme uses custom colors (not `ThemeData.dark()` defaults)
- Background surfaces use near-black tones with subtle elevation differences

---

### BR-THM-02: Theme Mode Options

**Description**: Three theme modes are available: `'dark'` (always dark), `'light'` (always light), and `'system'` (follows OS dark/light setting via `MediaQuery.platformBrightness`).

**Rationale**: Providing all three options accommodates user preferences and accessibility needs (some users need light mode for readability).

**Validation Criteria**:
- `'dark'` mode always applies the dark theme regardless of OS setting
- `'light'` mode always applies the light theme regardless of OS setting
- `'system'` mode switches between dark and light based on OS setting
- Theme change is applied immediately without app restart
- Selected mode is persisted to AppSettings

---

### BR-THM-03: Module Accent Colors

**Description**: Each module has a fixed accent color used consistently across its screens, charts, icons, and indicators. These colors are not user-configurable.

| Module | Color | Hex Code |
|---|---|---|
| Finance | Green | `#10B981` |
| Gym | Amber | `#F59E0B` |
| Nutrition | Orange | `#F97316` |
| Habits | Purple | `#8B5CF6` |
| Sleep | Indigo | `#6366F1` |
| Mental | Pink | `#EC4899` |
| Goals | Cyan | `#06B6D4` |
| DayScore | Gold | `#EAB308` |

**Rationale**: Fixed colors create visual consistency and help users quickly identify which module they are in. Color coding reinforces navigation.

**Validation Criteria**:
- Each module's UI uses its assigned color for accent elements
- Module colors are defined as constants in the theme system
- Module colors are used in Dashboard cards, navigation icons, and charts
- Colors remain the same in both dark and light theme modes

---

### BR-THM-04: Dynamic Font Scaling

**Description**: All text sizes respect the system's Dynamic Type (iOS) or font scale setting (Android). Font sizes are defined using relative units that scale with the platform's accessibility text size multiplier. The minimum readable size is enforced to prevent text from becoming too small.

**Rationale**: Accessibility requirement. Users with visual impairments use system-level font scaling and expect apps to respect it.

**Validation Criteria**:
- Text scales proportionally when the system font scale changes
- No text is clipped or overflows its container at 200% font scale
- Minimum font size is enforced (body text never smaller than 12sp equivalent)
- Typography uses Inter for body text and JetBrains Mono for numeric/code displays
- Font weights and line heights scale appropriately with size changes

---

## Biometric Rules

### BR-BIO-01: Biometric Lock Default Off

**Description**: Biometric lock is disabled by default. The user must explicitly enable it from the Settings screen. The toggle is only visible if the device supports biometric authentication.

**Rationale**: Biometric lock adds friction to every app launch. It should be opt-in so users who do not need it are not burdened.

**Validation Criteria**:
- New installations have `useBiometric = false`
- The biometric toggle is only shown in Settings if the device has biometric hardware
- Enabling biometric requires a successful biometric authentication first (prove you can authenticate before enabling)

---

### BR-BIO-02: Biometric on Every Launch

**Description**: When biometric lock is enabled, the app requires biometric authentication every time it is opened (cold start or resumed from background after a timeout). A full-screen lock overlay is shown until authentication succeeds.

**Rationale**: Protects sensitive financial, health, and personal data from unauthorized access if someone picks up the user's unlocked phone.

**Validation Criteria**:
- App launch with `useBiometric = true` shows the biometric prompt before any content
- Content behind the lock screen is not visible (full-screen overlay, not transparent)
- Successful authentication dismisses the lock and shows the normal app
- The lock activates on cold start and when resuming from background after more than 30 seconds

---

### BR-BIO-03: Biometric Failure Handling

**Description**: If biometric authentication fails 3 consecutive times, the app shows an option to disable biometric lock. Disabling requires the user to acknowledge a security warning. The failure counter resets on successful authentication or app restart.

**Rationale**: Users should not be permanently locked out of their own data. Three attempts balance security with usability.

**Validation Criteria**:
- First and second failures show "Try again" with the biometric prompt
- Third failure shows a dialog: "Disable biometric lock?" with a warning that data will be accessible without authentication
- Confirming disable sets `useBiometric = false` and dismisses the lock screen
- Canceling the disable dialog allows retrying biometric authentication (counter resets)
- The failure counter does not persist across app restarts

---

### BR-BIO-04: Biometric Availability Check

**Description**: Biometric capability is checked at runtime using `local_auth`. If the device does not support biometrics (no hardware, no enrolled biometrics), the biometric toggle is hidden in Settings and `useBiometric` cannot be set to `true`.

**Rationale**: Showing a non-functional toggle creates confusion. Runtime check handles device capability changes (e.g., user unenrolls all fingerprints).

**Validation Criteria**:
- `local_auth.canCheckBiometrics` and `local_auth.isDeviceSupported()` are checked before showing the toggle
- If the device has hardware but no enrolled biometrics, the toggle is shown but disabled with a message ("Set up biometrics in system settings first")
- If the device has no biometric hardware, the toggle is completely hidden
- If biometric was enabled but hardware becomes unavailable (e.g., after OS update), the lock screen falls through gracefully (skip auth, log a warning)

---

## Notification Rules

### BR-NOT-01: Local Notifications Only

**Description**: All notifications are local push notifications using `flutter_local_notifications`. No server-side push notifications or Firebase Cloud Messaging. All scheduling happens on-device.

**Rationale**: LifeOS is an offline-first app with no backend server. Local notifications keep the architecture simple and avoid requiring Google Play Services or APNs setup.

**Validation Criteria**:
- No Firebase or APNs dependencies in the project
- All notifications are scheduled via `flutter_local_notifications` APIs
- Notifications work without internet connectivity
- Notifications survive app termination (OS-level scheduling)

---

### BR-NOT-02: Deferred Permission Request

**Description**: Notification permission is NOT requested at app install or during onboarding. It is requested the first time the user performs a notification-worthy action: enabling a notification type in Settings, setting a budget alert, or enabling a habit reminder.

**Rationale**: Requesting permissions in context (when the user wants a specific notification) has higher acceptance rates than requesting at install time. Avoids permission fatigue.

**Validation Criteria**:
- Onboarding does not trigger a notification permission request
- The first toggle-on of any notification type in Settings triggers the permission request
- If permission is denied, the toggle reverts to off with a message explaining how to enable it in system settings
- If permission was previously granted, subsequent toggles do not re-request

---

### BR-NOT-03: Independent Notification Toggles

**Description**: Each notification type (habitReminder, budgetAlert, waterReminder, sleepBedtime, recurringTransaction) has its own independent enabled/disabled toggle. Enabling one type does not affect others.

**Rationale**: Users should control exactly which notifications they receive. Some may want budget alerts but not water reminders.

**Validation Criteria**:
- Each notification type has a separate toggle in the Settings screen
- Toggling one type does not change the state of other types
- Disabled notification types do not fire even if their trigger conditions are met
- The notification configuration is persisted per-type in AppSettings

---

### BR-NOT-04: Timezone Awareness

**Description**: Scheduled notification times are stored and interpreted in the user's local timezone. Notifications fire at the correct local time regardless of timezone changes (e.g., travel). When the timezone changes, pending notifications are rescheduled to maintain the correct local time.

**Rationale**: A bedtime reminder at 22:00 should always fire at 10 PM local time, even if the user travels across timezones.

**Validation Criteria**:
- Notification times are stored as `TimeOfDay` (hour + minute, no timezone offset)
- `flutter_local_notifications` `TZDateTime` is used for scheduling with the current local timezone
- When the app detects a timezone change (on resume), pending notifications are rescheduled
- Notifications fire at the correct local time regardless of device timezone

---

## EventBus Rules

### BR-EVT-01: Fire-and-Forget Semantics

**Description**: Event emission is synchronous and non-blocking. The emitter calls `eventBus.emit(event)` and continues execution immediately without waiting for any subscriber to process the event. Subscribers receive events asynchronously via stream subscription.

**Rationale**: Fire-and-forget prevents circular dependencies and performance coupling between modules. A slow subscriber (e.g., DayScore recalculation) must not slow down the emitting module (e.g., completing a workout).

**Validation Criteria**:
- `emit()` returns `void`, not `Future<void>`
- No `await` is used when calling `emit()`
- Subscribers process events in their own async context
- A subscriber throwing an exception does not affect other subscribers or the emitter

---

### BR-EVT-02: Singleton Riverpod Provider

**Description**: The EventBus is a singleton provided via `Provider<EventBus>` in Riverpod. All modules access the same instance via `ref.read(eventBusProvider)` or `ref.watch(eventBusProvider)`.

**Rationale**: A single shared instance ensures all events flow through one stream, enabling consistent subscription and disposal behavior.

**Validation Criteria**:
- `eventBusProvider` is defined once in the Core module
- All modules use `ref.read(eventBusProvider)` to emit events
- All modules use `ref.read(eventBusProvider).on<T>()` to subscribe
- No module creates its own EventBus instance

---

### BR-EVT-03: Idempotent Subscribers

**Description**: Subscribers must handle events idempotently. Processing the same event twice (e.g., due to stream replay or resubscription) must produce the same result as processing it once. Subscribers should use the event's `timestamp` and entity ID fields for deduplication if needed.

**Rationale**: Stream-based architectures can deliver duplicate events during error recovery or widget rebuilds. Idempotent processing prevents double-counting or duplicate side effects.

**Validation Criteria**:
- Subscribers that modify state check for existing data before applying changes
- DayScore recalculation from the same event twice yields the same score
- Notification triggered by the same BudgetThresholdEvent twice results in one notification (not two)
- Subscribers use event entity IDs (e.g., `workoutId`, `transactionId`) for deduplication

---

### BR-EVT-04: Automatic Timestamp

**Description**: Every `AppEvent` instance automatically gets a `timestamp` field set to `DateTime.now()` at construction time. The timestamp is immutable and cannot be overridden by the emitter (except in tests where a clock can be injected).

**Rationale**: Consistent timestamps enable event ordering, deduplication, and audit logging without requiring each emitter to remember to set the timestamp.

**Validation Criteria**:
- The `AppEvent` base class constructor sets `timestamp = DateTime.now()`
- No subclass constructor allows overriding the timestamp in production code
- Test constructors or a `@visibleForTesting` named parameter may accept a custom timestamp
- All events in a stream are ordered by their timestamp

---

### BR-EVT-05: Disposal on App Termination

**Description**: The EventBus's internal `StreamController` is closed when the app terminates or the Riverpod container is disposed. Active stream subscriptions are cancelled. No events can be emitted after disposal.

**Rationale**: Unclosed stream controllers leak memory and can cause "Bad state: Stream has been closed" errors if events are emitted after disposal.

**Validation Criteria**:
- `EventBus.dispose()` is called during app shutdown (via Riverpod `onDispose`)
- After disposal, calling `emit()` is a no-op (does not throw)
- After disposal, calling `on<T>()` returns an empty stream (does not throw)
- No stream subscription leaks are detected in integration tests

---

## Error Handling Rules

### BR-ERR-01: Result Type in Business Layer

**Description**: All business-layer methods (Notifier methods that perform validation, computation, or side effects) return `Future<Result<T>>` where `Result<T>` is a sealed class with `Success<T>` and `Failure<T>` variants. Business methods never throw exceptions; all errors are captured in `Failure<AppFailure>`.

**Rationale**: Explicit error handling via Result types forces callers to handle both success and failure cases at compile time. Eliminates unhandled exceptions in business logic.

**Validation Criteria**:
- All Notifier public methods returning data use `Future<Result<T>>` signature
- No `throw` statements in Notifier methods (exceptions are caught and wrapped)
- DAO-level exceptions are caught in the Notifier and wrapped in appropriate AppFailure subclass
- Callers pattern-match on `Result` to handle both cases

---

### BR-ERR-02: Dual Message Fields

**Description**: Every `AppFailure` subclass carries two message fields: `userMessage` (localized, safe to show in UI snackbars and dialogs) and `debugMessage` (technical, logged to console/analytics, never shown to users). Both fields are required and non-empty.

**Rationale**: Users need friendly error messages in their language. Developers need technical details for debugging. Separating them prevents accidental exposure of stack traces or SQL errors to users.

**Validation Criteria**:
- All AppFailure subclasses have both `userMessage` and `debugMessage` fields
- `userMessage` is translated to the user's language (ES/EN based on AppSettings)
- `debugMessage` may contain technical details (SQL errors, HTTP responses, exception messages)
- No AppFailure instance has an empty `userMessage` or `debugMessage`

---

### BR-ERR-03: Result to AsyncValue Conversion

**Description**: Notifiers convert `Result<T>` to Riverpod `AsyncValue<T>` for UI consumption. `Success<T>` maps to `AsyncData<T>`, `Failure<AppFailure>` maps to `AsyncError`. This conversion happens in the Notifier's state update logic.

**Rationale**: Riverpod's `AsyncValue` provides `.when(data:, loading:, error:)` pattern in widgets, which is the standard way to render loading, success, and error states in Flutter with Riverpod.

**Validation Criteria**:
- Notifiers expose state as `AsyncValue<T>` (via `AsyncNotifier`)
- `Result.Success` updates state to `AsyncData`
- `Result.Failure` updates state to `AsyncError` with the `AppFailure` as the error object
- Widgets use `.when()` to handle all three states (data, loading, error)

---

### BR-ERR-04: Global Exception Catch

**Description**: Uncaught exceptions at the top level (framework errors, isolate errors, platform channel errors) are caught by a global error handler (`FlutterError.onError` and `PlatformDispatcher.instance.onError`). Caught exceptions are wrapped in a generic `DatabaseFailure` (for Drift errors) or `AppFailure`-like logged error and reported to the console.

**Rationale**: No exception should crash the app. The global handler is a safety net for bugs that escape the Result pattern.

**Validation Criteria**:
- `FlutterError.onError` is configured in `main()`
- `PlatformDispatcher.instance.onError` is configured for async errors
- Caught exceptions are logged with full stack trace (debug mode) or summary (release mode)
- The UI shows a generic "Something went wrong" message for uncaught errors
- The app does not crash; it recovers to a usable state

---

### BR-ERR-05: No Stack Traces in UI

**Description**: Stack traces, SQL error messages, HTTP response bodies, and other technical information are never displayed to the user. Only the `userMessage` field of `AppFailure` is shown in UI elements (snackbars, dialogs, error screens).

**Rationale**: Stack traces confuse non-technical users and may expose internal implementation details (table names, API endpoints, file paths) that constitute a minor security concern.

**Validation Criteria**:
- UI error displays only use `AppFailure.userMessage`
- No widget directly renders `Exception.toString()` or `Error.toString()`
- `debugMessage` and `originalError` are only used in `debugPrint()` or logging calls
- Error screens show a user-friendly message with an optional "Report" button (for future analytics integration)
