import 'dart:ui';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_os/app.dart';
import 'package:life_os/core/providers/providers.dart';
import 'package:life_os/core/services/app_logger.dart';
import 'package:life_os/features/finance/database/predefined_categories.dart';
import 'package:life_os/features/gym/database/bundled_exercises.dart';
import 'package:life_os/features/integration/event_wiring.dart';
import 'package:life_os/features/nutrition/database/bundled_foods.dart';

// ---------------------------------------------------------------------------
// App initialization
// ---------------------------------------------------------------------------

Future<void> _initializeApp(ProviderContainer container) async {
  final logger = AppLogger(tag: 'Init');
  final db = container.read(appDatabaseProvider);

  try {
    // 1. Seed predefined finance categories
    logger.info('Seeding finance categories...');
    await seedPredefinedCategories(db.financeDao);

    // 2. Load bundled exercise library
    logger.info('Loading bundled exercises...');
    await loadBundledExercises(db.gymDao);

    // 3. Load bundled food database
    logger.info('Loading bundled foods...');
    await loadBundledFoods(db.nutritionDao);

    // 4. Seed DayScore configs
    logger.info('Seeding DayScore configs...');
    await db.dashboardDao.seedDefaultConfigsIfEmpty();

    // 5. Wire EventBus subscriptions
    logger.info('Wiring EventBus...');
    final eventBus = container.read(eventBusProvider);
    wireEventBus(
      eventBus: eventBus,
      habitsNotifier: container.read(habitsNotifierProvider),
      nutritionDao: db.nutritionDao,
      dayScoreNotifier: container.read(dayScoreNotifierProvider),
      dashboardNotifier: container.read(dashboardNotifierProvider),
      notificationScheduler: container.read(notificationSchedulerProvider),
      logger: logger,
    );

    // 6. Initialize notification scheduler (not available on web)
    if (!kIsWeb) {
      logger.info('Initializing notification scheduler...');
      await container.read(notificationSchedulerProvider).initialize();
    }

    // 7. Process any overdue recurring transactions
    logger.info('Processing recurring transactions...');
    final recurringResult =
        await container.read(financeNotifierProvider).processRecurringTransactions();
    final recurringCreated = recurringResult.valueOrNull ?? 0;
    if (recurringCreated > 0) {
      logger.info('Created $recurringCreated recurring transaction(s).');
      container.read(recurringCreatedCountProvider.notifier).state =
          recurringCreated;
    }

    logger.info('App initialization complete.');
  } catch (e, st) {
    logger.error(
      'App initialization error (non-fatal): $e',
      error: e,
      stackTrace: st,
    );
    // Continue app launch even if initialization fails.
  }
}

// ---------------------------------------------------------------------------
// Entry point
// ---------------------------------------------------------------------------

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final logger = AppLogger(tag: 'Main');

  // Global error handlers
  FlutterError.onError = (details) {
    logger.error(
      'Flutter framework error: ${details.exceptionAsString()}',
      error: details.exception,
      stackTrace: details.stack,
    );
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    logger.error(
      'Unhandled platform error: $error',
      error: error,
      stackTrace: stack,
    );
    return true;
  };

  // Error widget for production-style error display
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      child: Center(
        child: Text(
          'Algo salio mal',
          style: const TextStyle(color: Colors.red),
        ),
      ),
    );
  };

  // Create a ProviderContainer so we can run async initialization before
  // runApp, then hand it to UncontrolledProviderScope.
  final container = ProviderContainer();

  runApp(_SplashWrapper(container: container));
}

// ---------------------------------------------------------------------------
// Splash wrapper — shows a simple native-style splash while initializing,
// then hands off to the real app once ready.
// ---------------------------------------------------------------------------

class _SplashWrapper extends StatefulWidget {
  const _SplashWrapper({required this.container});

  final ProviderContainer container;

  @override
  State<_SplashWrapper> createState() => _SplashWrapperState();
}

class _SplashWrapperState extends State<_SplashWrapper> {
  late final Future<void> _initFuture;

  @override
  void initState() {
    super.initState();
    _initFuture = _initializeApp(widget.container);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _SplashScreen();
        }
        // Initialization done (or failed gracefully) — show real app.
        return UncontrolledProviderScope(
          container: widget.container,
          child: const LifeOsApp(),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Splash screen UI — black background with centered shield icon
// ---------------------------------------------------------------------------

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Color(0xFF0A0A0A),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.shield_outlined,
                size: 80,
                color: Color(0xFF10B981),
              ),
              SizedBox(height: 16),
              Text(
                'LifeOS',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
