# Business Logic Model -- Unit 0: Core Foundation

## Purpose

Defines the step-by-step business logic flows for Unit 0. Each flow describes the sequence of operations, decision points, error paths, and expected outcomes using numbered steps.

---

## 1. Onboarding Flow

A linear state machine that drives the user through 6 screens. The user can navigate back to previous screens or skip forward (with defaults) after the language screen.

### States

| State | Screen | Required? |
|---|---|---|
| `welcome` | WelcomeScreen | Yes (cannot skip) |
| `language` | LanguageSelectionScreen | Yes (cannot skip) |
| `profile` | NameInputScreen + CurrencySelectionScreen | No (skippable) |
| `modules` | ModuleSelectionScreen | No (skippable) |
| `goal` | PrimaryGoalScreen | No (skippable) |
| `firstData` | FirstDataScreen (optional budget or habit) | No (skippable) |

### Flow Steps

1. App launches for the first time (`onboardingCompleted == false`).
2. **Welcome state**: Display WelcomeScreen with LifeOS logo, motivational message, and "Comenzar" button.
3. User taps "Comenzar". Transition to `language` state.
4. **Language state**: Detect system locale. If `es_*`, pre-select Spanish. If `en_*`, pre-select English. Otherwise, pre-select Spanish. Display two language cards. A "Skip setup" link becomes visible starting from this screen.
5. User selects a language and taps "Continue". Validate per BR-ONB-02. Transition to `profile` state.
6. **Profile state**: Display name input field and currency picker. Name field is empty. Currency defaults to COP.
   - 6a. If user taps "Skip setup": Apply defaults per BR-ONB-06 (name = "Usuario"/"User", currency = "COP", all modules enabled, goal = "balance"). Set `onboardingCompleted = true`. Navigate to Dashboard. Flow ends.
   - 6b. User enters name and selects currency. Validate name per BR-ONB-01, currency per BR-ONB-03. If validation fails, show inline error and stay on screen. If valid, transition to `modules` state.
7. **Modules state**: Display all available modules with toggle switches. All modules are ON by default.
   - 7a. User toggles modules. Validate at least 1 is enabled per BR-ONB-04.
   - 7b. User taps "Continue". Transition to `goal` state.
8. **Goal state**: Display four goal options as selectable cards. No default selection.
   - 8a. User selects a goal per BR-ONB-05. Taps "Continue". Transition to `firstData` state.
9. **FirstData state**: Based on enabled modules, show relevant first data creation option.
   - 9a. If Finance is enabled: Show "Create your first budget" card with amount input and category picker.
   - 9b. If Habits is enabled (and Finance is not, or as additional option): Show "Create your first habit" card with name input and frequency picker.
   - 9c. If user creates data: Validate using the respective module's rules, persist, then complete.
   - 9d. If user taps "Skip for now": Proceed to completion without creating data.
10. **Completion**: Write all collected values to AppSettings table. Set `onboardingCompleted = true`. Navigate to Dashboard.

### Error Paths

- **Validation failure on name**: Inline error message below the field ("Name must be 1-50 characters"). User corrects and retries.
- **Validation failure on first data**: Inline error on the budget/habit form. User corrects or skips.
- **Database write failure**: Show snackbar with `userMessage` from `DatabaseFailure`. Retry button available. Do not mark onboarding as complete until write succeeds.
- **App killed during onboarding**: On next launch, `onboardingCompleted == false`, so onboarding restarts from the beginning. No partial state is persisted (atomic completion).

### Expected Outcomes

- **Happy path**: AppSettings row created with all user-provided values. `onboardingCompleted = true`. App navigates to Dashboard.
- **Skip path**: AppSettings row created with defaults. `onboardingCompleted = true`. App navigates to Dashboard.
- **Error path**: User is kept on the failing screen with clear error messages until the issue is resolved or they choose to skip.

---

## 2. Backup Export Flow

Exports all user data into a ZIP file with per-module JSON files and a manifest.

### Flow Steps

1. User taps "Export backup" in Settings screen.
2. Show a loading overlay with progress text ("Preparing backup..."). Disable data modification actions.
3. Read AppSettings to determine enabled modules.
4. Spawn a Dart isolate (via `Isolate.run()` or `compute()`) for the heavy work.
5. **In the isolate**: For each enabled module plus `settings`:
   - 5a. Query all records from the module's Drift tables.
   - 5b. Serialize each record to a JSON-compatible `Map<String, dynamic>`.
   - 5c. Encode the list of records as a JSON string.
   - 5d. Store as `{module-name}.json` in memory (byte buffer for ZIP entry).
6. Build the BackupManifest object:
   - 6a. `appVersion` from package info.
   - 6b. `exportDate` = `DateTime.now().toUtc()`.
   - 6c. `deviceInfo` from `device_info_plus`.
   - 6d. `driftSchemaVersion` from the current Drift migration version.
   - 6e. `modules` list with name and record count for each exported module.
7. Serialize BackupManifest to JSON. Store as `manifest.json`.
8. Package all JSON byte buffers into a ZIP archive using the `archive` package.
9. Return the ZIP bytes to the main isolate.
10. **On the main isolate**: Save the ZIP file to a user-selected location (via `file_picker` or share sheet). Alternatively, trigger the platform share sheet to let the user choose where to save.
11. Dismiss loading overlay. Show success snackbar ("Backup exported successfully").
12. Re-enable data modification actions.

### Error Paths

- **Isolate failure** (OOM, serialization error): Catch the error, wrap in `BackupFailure(phase: 'export')`. Show error snackbar with `userMessage`. Dismiss loading overlay.
- **File save failure** (permission denied, disk full): Wrap in `BackupFailure(phase: 'export')`. Show error snackbar with guidance ("Check storage permissions").
- **User cancels save dialog**: No error. Dismiss loading overlay. Backup bytes are discarded.

### Expected Outcomes

- **Success**: ZIP file saved to user-selected location. Contains manifest.json + per-module JSON files. Snackbar confirms success.
- **Failure**: Error snackbar shown. No file saved. App returns to normal state.

---

## 3. Backup Import Flow

Restores data from a previously exported ZIP file with selective module import and merge strategy.

### Flow Steps

1. User taps "Import backup" in Settings screen.
2. Open file picker filtered to `.zip` files. User selects a file.
3. **Validate ZIP structure**:
   - 3a. Read the ZIP archive. Check that `manifest.json` exists at the root.
   - 3b. If `manifest.json` is missing: Return `BackupFailure(phase: 'validate')` with message "Invalid backup file: manifest not found".
4. **Parse and validate manifest**:
   - 4a. Decode `manifest.json` to a `BackupManifest` object.
   - 4b. Check `driftSchemaVersion` per BR-BKP-03. If backup schema > current app schema: Return `BackupFailure(phase: 'validate')` with message "Backup was created with a newer version of LifeOS. Please update the app first."
   - 4c. Validate all required fields are present per BR-BKP-02.
5. **Show import preview** (BR-BKP-06):
   - 5a. Display module list from manifest with names and record counts.
   - 5b. Each module has a toggle switch (default: all ON).
   - 5c. Show "Import" and "Cancel" buttons.
6. User selects which modules to import and taps "Import".
7. Validate at least one module is selected (BR-BKP-04).
8. Show loading overlay ("Importing data..."). Disable data modification actions.
9. Spawn a Dart isolate for the heavy work.
10. **In the isolate**: For each selected module:
    - 10a. Read `{module-name}.json` from the ZIP archive.
    - 10b. Decode JSON to a list of record maps.
    - 10c. For each record: Check if a record with the same primary key exists in the database.
      - If exists: Skip (per BR-BKP-05 merge strategy). Increment `skippedCount`.
      - If not exists: Insert the record. Increment `insertedCount`.
      - If insert fails: Log the error. Increment `failedCount`. Continue with next record (do not abort the whole module).
    - 10d. Record the counts (inserted, skipped, failed) for this module.
11. Return the import results to the main isolate.
12. Dismiss loading overlay.
13. **Show import results**:
    - 13a. For each module: "{moduleName}: {inserted} imported, {skipped} skipped (already existed), {failed} failed".
    - 13b. If any failures: Show a warning icon with "Some records could not be imported. This may be due to data format differences."
14. Re-enable data modification actions.

### Error Paths

- **Invalid ZIP file** (corrupted, not a ZIP): `BackupFailure(phase: 'validate')`. "The selected file is not a valid backup."
- **Missing module JSON in ZIP**: Skip that module, report it as failed in results. Do not abort other modules.
- **Malformed JSON in a module file**: `BackupFailure(phase: 'import')` for that module. Other modules continue.
- **Database constraint violation on insert**: Skip that record, increment `failedCount`. Continue.
- **User cancels file picker**: No error. Return to Settings screen.

### Expected Outcomes

- **Full success**: All selected modules imported. Results screen shows inserted counts. Snackbar confirms.
- **Partial success**: Some records imported, some skipped (duplicates), some failed. Results screen shows per-module breakdown.
- **Validation failure**: Error message shown before any data is modified. App state unchanged.

---

## 4. Biometric Auth Flow

Controls access to the app when biometric lock is enabled.

### Flow Steps

1. App enters foreground (cold start or resumed from background).
2. Check `AppSettings.useBiometric`:
   - 2a. If `false`: Skip authentication. Show normal app. Flow ends.
   - 2b. If `true`: Continue to step 3.
3. Check if this is a background resume within the grace period (less than 30 seconds since last foreground exit):
   - 3a. If within grace period: Skip authentication. Show normal app. Flow ends.
   - 3b. If beyond grace period or cold start: Continue to step 4.
4. Display full-screen lock overlay (opaque, no content visible behind it).
5. Check biometric availability via `local_auth`:
   - 5a. `canCheckBiometrics == false` or `isDeviceSupported == false`: Log warning ("Biometric was enabled but hardware is unavailable"). Skip authentication. Show normal app. Set `useBiometric = false` in AppSettings to prevent future attempts. Flow ends.
   - 5b. Biometric available: Continue to step 6.
6. Trigger biometric prompt via `local_auth.authenticate()`.
7. **Authentication result**:
   - 7a. **Success**: Dismiss lock overlay. Reset failure counter to 0. Show normal app. Flow ends.
   - 7b. **Failure** (user cancels or biometric not recognized): Increment failure counter.
8. Check failure counter:
   - 8a. Counter < 3: Show "Try again" button on lock overlay. User taps to return to step 6.
   - 8b. Counter == 3: Show dialog per BR-BIO-03. "Authentication failed 3 times. Would you like to disable biometric lock?"
     - If user confirms disable: Set `useBiometric = false`. Dismiss lock overlay. Show normal app. Reset counter. Flow ends.
     - If user cancels: Reset counter to 0. Return to step 6 (retry).

### Error Paths

- **PlatformException from local_auth**: Wrap in `AuthFailure`. Log the error. Fallback: skip authentication, show normal app, log a warning.
- **Device biometric unenrolled between launches**: Caught at step 5a. Biometric disabled automatically.

### Expected Outcomes

- **Authenticated**: Lock overlay dismissed. Normal app visible.
- **Disabled after failures**: `useBiometric` set to `false`. Lock overlay dismissed.
- **Hardware unavailable**: Biometric silently disabled. Normal app visible.

---

## 5. Theme Switching Flow

Allows the user to change theme mode with immediate visual feedback.

### Flow Steps

1. User opens Settings screen. Current theme mode displayed (dark/light/system).
2. User selects a new theme mode from a segmented control or radio group.
3. **Immediate preview**: ThemeNotifier updates `themeMode` in its internal state.
4. ThemeNotifier rebuilds the `ThemeData` object:
   - 4a. If `'dark'`: Build custom dark ThemeData with near-black surfaces, module accent colors, Inter + JetBrains Mono typography.
   - 4b. If `'light'`: Build custom light ThemeData with light surfaces, same accent colors, same typography.
   - 4c. If `'system'`: Read `MediaQuery.platformBrightness`. Build dark or light based on OS setting.
5. Riverpod notifies all widgets watching `themeNotifierProvider`. The entire widget tree rebuilds with the new theme.
6. **Persist**: Write new `themeMode` value to AppSettings table.
7. If persist fails (DatabaseFailure): Revert ThemeNotifier state to the previous mode. Show error snackbar. The UI reverts to the previous theme.

### Error Paths

- **Database write failure**: Revert in-memory state. UI shows previous theme. Error snackbar displayed.
- **Invalid theme mode value**: Rejected by validation (not reachable from UI, but enforced in Notifier).

### Expected Outcomes

- **Success**: Theme changes instantly. All screens reflect the new theme. Setting persisted.
- **Failure**: Theme reverts to previous. Error snackbar shown. No data corruption.

---

## 6. EventBus Lifecycle

Manages the full lifecycle of the cross-module event bus.

### Flow Steps

1. **Initialization**: When the Riverpod `ProviderScope` is created (in `main()`), `eventBusProvider` instantiates a new `EventBus`.
   - 1a. EventBus creates an internal `StreamController<AppEvent>.broadcast()`.
   - 1b. The broadcast controller supports multiple listeners and does not buffer events.
2. **Subscription**: Feature Notifiers subscribe during their initialization.
   - 2a. Notifier calls `ref.read(eventBusProvider).on<SpecificEventType>()` to get a typed stream.
   - 2b. Notifier listens to the stream and processes events in a `listen()` callback.
   - 2c. The subscription `StreamSubscription` is stored for later cancellation.
   - 2d. Subscription happens in the Notifier's `build()` method or `init()` method, triggered by Riverpod lifecycle.
3. **Event Emission**: When a domain action completes (e.g., workout finished), the responsible Notifier emits an event.
   - 3a. Notifier creates the event object. `timestamp` is auto-set by the `AppEvent` constructor.
   - 3b. Notifier calls `ref.read(eventBusProvider).emit(event)`.
   - 3c. `emit()` adds the event to the `StreamController` sink. Returns void immediately (fire-and-forget per BR-EVT-01).
   - 3d. All active subscribers to that event type receive the event asynchronously.
4. **Event Processing**: Each subscriber processes the event independently.
   - 4a. Subscriber checks for idempotency (per BR-EVT-03) using event entity IDs.
   - 4b. Subscriber performs its logic (e.g., DayScoreNotifier recalculates score, NotificationService checks budget threshold).
   - 4c. If processing fails: Subscriber logs the error. Does not re-throw (isolated failure per BR-EVT-01).
5. **Notifier Disposal**: When a Notifier is disposed (e.g., user navigates away from a module):
   - 5a. The stored `StreamSubscription` is cancelled in the Notifier's `onDispose` callback.
   - 5b. The EventBus itself remains alive (singleton provider, not disposed with individual Notifiers).
6. **App Termination**: When the Riverpod container is disposed (app shutdown):
   - 6a. `eventBusProvider`'s `onDispose` callback calls `eventBus.dispose()`.
   - 6b. `dispose()` closes the `StreamController`.
   - 6c. After disposal, `emit()` is a no-op and `on<T>()` returns an empty stream (per BR-EVT-05).

### Error Paths

- **Subscriber throws during event processing**: Exception is caught by the stream listener's `onError` handler. Logged to console. Does not affect other subscribers or the emitter.
- **EventBus used after disposal**: `emit()` is a no-op. `on<T>()` returns `Stream.empty()`. No exceptions thrown.

### Expected Outcomes

- **Normal operation**: Events flow from emitters to all active subscribers without blocking.
- **Module deactivation**: Disposed Notifiers stop receiving events. No memory leaks.
- **App shutdown**: All streams closed cleanly. No "Bad state" exceptions.

---

## 7. Notification Scheduling

Manages the scheduling, cancellation, and rescheduling of local notifications for each notification type.

### Flow Steps

#### 7.1 Initialization

1. `NotificationService.initialize()` is called during app startup (after Riverpod container is ready).
2. Configure `flutter_local_notifications` with:
   - Android: Notification channel "LifeOS Reminders" with default importance.
   - iOS: Request alert, badge, and sound permissions (only when first notification is enabled, per BR-NOT-02).
3. Load existing `NotificationConfig` from AppSettings.
4. For each enabled notification type, verify that its scheduled notification still exists in the OS notification queue. Reschedule if missing (handles app update or OS clearing notifications).

#### 7.2 Enabling a Notification Type

1. User toggles a notification type ON in Settings.
2. Check if notification permission has been granted:
   - 2a. If not: Request permission via `flutter_local_notifications` (per BR-NOT-02).
   - 2b. If denied: Revert toggle to OFF. Show message "Enable notifications in system settings." Return.
   - 2c. If granted: Continue.
3. Update `NotificationConfig` for this type: `enabled = true`.
4. Schedule the notification based on its `repeatRule`:
   - 4a. **daily** (habitReminder, sleepBedtime, recurringTransaction): Call `NotificationService.scheduleDaily()` with the configured time and a unique notification ID.
   - 4b. **interval** (waterReminder): Schedule multiple daily notifications at 2-hour intervals between 08:00 and 22:00 (08:00, 10:00, 12:00, 14:00, 16:00, 18:00, 20:00, 22:00 = 8 notifications).
   - 4c. **eventDriven** (budgetAlert): No scheduling needed. The notification is triggered in real-time by the BudgetThresholdEvent handler.
5. Persist updated NotificationConfig to AppSettings.

#### 7.3 Disabling a Notification Type

1. User toggles a notification type OFF in Settings.
2. Cancel all scheduled notifications for this type using their unique notification IDs.
3. Update `NotificationConfig`: `enabled = false`.
4. Persist to AppSettings.

#### 7.4 Changing Notification Time

1. User changes the time for a notification type (e.g., habit reminder from 09:00 to 07:00).
2. Cancel existing scheduled notifications for this type.
3. Reschedule with the new time.
4. Update `NotificationConfig.time` with new value.
5. Persist to AppSettings.

#### 7.5 Event-Driven Notification (Budget Alert)

1. EventBus delivers a `BudgetThresholdEvent` to `NotificationService`.
2. Check if `budgetAlert` is enabled in NotificationConfig.
   - If disabled: Ignore. Return.
3. Check the threshold percentage:
   - 3a. `percentage >= 0.8 && percentage < 1.0`: Show notification "Budget for {categoryName} is at {percentage}%".
   - 3b. `percentage >= 1.0`: Show notification "Budget for {categoryName} exceeded! {percentage}%".
4. Use `NotificationService.showImmediate()` to display the notification.
5. Apply idempotency: Do not show the same alert for the same budget + threshold level more than once per day. Track shown alerts in memory (reset daily).

#### 7.6 Timezone Change Handling

1. App resumes from background.
2. Compare current timezone offset to the last known offset (stored in memory or a lightweight preference).
3. If timezone changed:
   - 3a. Cancel all time-based scheduled notifications.
   - 3b. Reschedule all enabled time-based notifications using the new local timezone.
   - 3c. Update the stored timezone offset.

### Error Paths

- **Permission denied**: Toggle reverts. User informed. No notifications scheduled.
- **Schedule fails** (platform error): Wrap in `PermissionFailure`. Log error. Show snackbar. Toggle reverts.
- **Notification not delivered** (OS killed app, power saving): Out of app control. Mitigated by rescheduling on next app launch (step 7.1.4).

### Expected Outcomes

- **Enable**: Notification scheduled at correct local time. Config persisted.
- **Disable**: Notification cancelled. Config persisted.
- **Time change**: Old notification cancelled, new one scheduled at new time.
- **Budget alert**: Immediate notification shown when threshold crossed (if enabled).
- **Timezone change**: All scheduled notifications adjusted to maintain correct local time.

---

## Testable Properties (PBT-01 Compliance)

Properties identified for property-based testing in Unit 0. Each property references a category from the PBT-01 rule.

### Round-Trip Properties

| Property | Component | Category | Description |
|---|---|---|---|
| RT-01 | BackupService | Round-trip | For any valid AppSettings state, `export(settings) |> importMerge` produces a database state containing all original records. Serialize to JSON then deserialize yields equal objects. |
| RT-02 | BackupManifest | Round-trip | `BackupManifest.fromJson(manifest.toJson()) == manifest` for all valid manifests. |
| RT-03 | NotificationConfig | Round-trip | `NotificationConfig.fromJson(config.toJson()) == config` for all valid configurations. |
| RT-04 | AppEvent subclasses | Round-trip | If events are serialized for logging, `Event.fromJson(event.toJson()) == event` for each event subclass (if serialization is implemented). |
| RT-05 | enabledModules | Round-trip | JSON encode then decode of the `enabledModules` list produces the same list. `jsonDecode(jsonEncode(modules)) == modules`. |

### Invariant Properties

| Property | Component | Category | Description |
|---|---|---|---|
| INV-01 | AppSettings | Invariant | After any valid mutation of AppSettings, the following hold: `language` is `'es'` or `'en'`, `currency` is a valid ISO 4217 code, `enabledModules` decoded list has length >= 1, `primaryGoal` is one of the four valid enum values. |
| INV-02 | OnboardingNotifier | Invariant | At onboarding completion, `onboardingCompleted == true` and all required fields (userName, language, currency, primaryGoal, enabledModules) are non-null and valid. |
| INV-03 | AppEvent.timestamp | Invariant | For any AppEvent emitted, `timestamp <= DateTime.now()` (timestamp is never in the future). |
| INV-04 | AppFailure | Invariant | Every AppFailure instance has `userMessage.isNotEmpty && debugMessage.isNotEmpty`. |
| INV-05 | BackupManifest.modules | Invariant | Sum of all `recordCount` values in the manifest matches the total number of records in the exported module JSON files. |

### Idempotence Properties

| Property | Component | Category | Description |
|---|---|---|---|
| IDP-01 | EventBus subscribers | Idempotence | Processing the same `WorkoutCompletedEvent` twice through DayScoreNotifier produces the same DayScore as processing it once. |
| IDP-02 | BackupService merge import | Idempotence | Importing the same backup file twice produces the same database state as importing it once (duplicates are skipped). |
| IDP-03 | ThemeNotifier | Idempotence | Setting the same theme mode twice produces the same ThemeData and the same persisted AppSettings value. |
| IDP-04 | NotificationService | Idempotence | Scheduling the same notification type twice results in exactly one set of scheduled notifications (old ones cancelled before new ones created). |

### Commutativity Properties

| Property | Component | Category | Description |
|---|---|---|---|
| COM-01 | EventBus | Commutativity | The order in which independent events are emitted (e.g., WorkoutCompletedEvent then ExpenseAddedEvent, or vice versa) does not affect the final DayScore or Dashboard state, given both events are eventually processed. |

### Components with No PBT Properties Identified

| Component | Rationale |
|---|---|
| HapticService | Pure side-effect service (triggers device vibration). No data transformation or state to verify with properties. |
| SecureStorageService | Thin wrapper around `flutter_secure_storage`. Round-trip testing is covered by the plugin's own tests. No business logic to verify. |
| BiometricAuth flow | Depends on platform `local_auth` plugin behavior. State machine transitions are best verified with example-based tests and integration tests rather than property generation. |
