import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:life_os/core/constants/app_colors.dart';
import 'package:life_os/core/router/page_transitions.dart';
import 'package:life_os/core/providers/providers.dart';
import 'package:life_os/features/dashboard/presentation/dashboard_screen.dart';
import 'package:life_os/features/dashboard/presentation/day_score_screen.dart';
import 'package:life_os/features/dashboard/presentation/evolution_screen.dart';
import 'package:life_os/features/dashboard/presentation/monitoring_screen.dart';
import 'package:life_os/features/dashboard/presentation/score_history_screen.dart';
import 'package:life_os/features/finance/presentation/add_edit_transaction_screen.dart';
import 'package:life_os/features/finance/presentation/budget_overview_screen.dart';
import 'package:life_os/features/finance/presentation/finance_dashboard_screen.dart';
import 'package:life_os/features/finance/presentation/savings_goals_screen.dart';
import 'package:life_os/features/finance/presentation/sms_import_screen.dart';
import 'package:life_os/features/finance/presentation/transactions_list_screen.dart';
import 'package:life_os/features/goals/presentation/add_edit_goal_screen.dart';
import 'package:life_os/features/goals/presentation/goal_detail_screen.dart';
import 'package:life_os/features/goals/presentation/goals_overview_screen.dart';
import 'package:life_os/features/gym/presentation/active_workout_screen.dart';
import 'package:life_os/features/gym/presentation/body_measurements_screen.dart';
import 'package:life_os/features/gym/presentation/exercise_library_screen.dart';
import 'package:life_os/features/gym/presentation/routine_builder_screen.dart';
import 'package:life_os/features/gym/presentation/workout_history_screen.dart';
import 'package:life_os/features/habits/presentation/add_edit_habit_screen.dart';
import 'package:life_os/features/habits/presentation/habit_detail_screen.dart';
import 'package:life_os/features/habits/presentation/habits_dashboard_screen.dart';
import 'package:life_os/features/intelligence/presentation/ai_config_screen.dart';
import 'package:life_os/features/intelligence/presentation/chat_screen.dart';
import 'package:life_os/features/intelligence/presentation/conversation_list_screen.dart';
import 'package:life_os/features/intelligence/presentation/ticket_scanner_screen.dart';
import 'package:life_os/features/intelligence/presentation/weekly_summary_screen.dart';
import 'package:life_os/features/mental/presentation/breathing_screen.dart';
import 'package:life_os/features/mental/presentation/gratitude_screen.dart';
import 'package:life_os/features/mental/presentation/insights_screen.dart';
import 'package:life_os/features/mental/presentation/mental_history_screen.dart';
import 'package:life_os/features/mental/presentation/mood_log_screen.dart';
import 'package:life_os/features/nutrition/presentation/daily_nutrition_screen.dart';
import 'package:life_os/features/nutrition/presentation/food_search_screen.dart';
import 'package:life_os/features/nutrition/presentation/meal_log_screen.dart';
import 'package:life_os/features/nutrition/presentation/nutrition_goals_screen.dart';
import 'package:life_os/features/nutrition/presentation/barcode_scanner_screen.dart';
import 'package:life_os/features/nutrition/presentation/photo_analysis_screen.dart';
import 'package:life_os/features/onboarding/presentation/onboarding_shell.dart';
import 'package:life_os/features/settings/presentation/backup_screen.dart';
import 'package:life_os/features/settings/presentation/settings_screen.dart';
import 'package:life_os/features/sleep/presentation/circadian_screen.dart';
import 'package:life_os/features/sleep/presentation/energy_tracker_screen.dart';
import 'package:life_os/features/sleep/presentation/sleep_history_screen.dart';
import 'package:life_os/features/sleep/presentation/sleep_log_screen.dart';

abstract final class AppRoutes {
  // Core
  static const String onboarding = '/onboarding';
  static const String home = '/';
  static const String settings = '/settings';

  // Finance
  static const String finance = '/finance';
  static const String financeAdd = '/finance/add';
  static const String financeBudgets = '/finance/budgets';
  static const String financeSavings = '/finance/savings';
  static const String financeDashboard = '/finance/dashboard';
  static const String financeSmsImport = '/finance/sms-import';

  // Gym
  static const String gym = '/gym';
  static const String gymExercises = '/gym/exercises';
  static const String gymRoutineBuilder = '/gym/routine-builder';
  static const String gymWorkout = '/gym/workout';
  static const String gymHistory = '/gym/history';
  static const String gymMeasurements = '/gym/measurements';

  // Nutrition
  static const String nutrition = '/nutrition';
  static const String nutritionSearch = '/nutrition/search';
  static const String nutritionMealLog = '/nutrition/meal-log';
  static const String nutritionGoals = '/nutrition/goals';
  static const String barcodeScanner = '/nutrition/scan';
  static const String photoAnalysis = '/nutrition/photo';

  // Settings
  static const String backup = '/settings/backup';

  // Habits
  static const String habits = '/habits';
  static const String habitsAdd = '/habits/add';
  static const String habitsDetail = '/habits/detail';

  // Dashboard
  static const String dayScore = '/day-score';
  static const String scoreHistory = '/score-history';
  static const String monitoring = '/monitoring';
  static const String evolution = '/evolution';

  // Sleep
  static const String sleep = '/sleep';
  static const String sleepHistory = '/sleep/history';
  static const String energy = '/sleep/energy';
  static const String circadian = '/sleep/circadian';

  // Mental
  static const String mood = '/mental/mood';
  static const String breathing = '/mental/breathing';
  static const String mentalHistory = '/mental/history';
  static const String gratitude = '/mental/gratitude';
  static const String mentalInsights = '/mental/insights';

  // AI
  static const String ticketScanner = '/ai/ticket';
  static const String weeklySummary = '/ai/weekly';

  // Goals
  static const String goals = '/goals';
  static const String goalsAdd = '/goals/add';
  static const String goalsDetail = '/goals/detail';

  // Intelligence
  static const String aiConfig = '/ai/config';
  static const String aiConversations = '/ai/conversations';
  static const String aiChat = '/ai/chat';
}

final _shellNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  final settingsDao = ref.watch(appSettingsDaoProvider);

  return GoRouter(
    initialLocation: AppRoutes.home,
    redirect: (context, state) async {
      final settings = await settingsDao.getSettings();
      final onboardingDone = settings?.onboardingCompleted ?? false;
      final isOnboarding = state.uri.path == AppRoutes.onboarding;

      if (!onboardingDone && !isOnboarding) return AppRoutes.onboarding;
      if (onboardingDone && isOnboarding) return AppRoutes.home;
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingShell(),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => _AppShell(child: child),
        routes: [
          // Dashboard (home)
          GoRoute(
            path: AppRoutes.home,
            builder: (context, state) => const DashboardScreen(),
          ),
          // Finance
          GoRoute(
            path: AppRoutes.finance,
            builder: (context, state) => const TransactionsListScreen(),
          ),
          // Gym
          GoRoute(
            path: AppRoutes.gym,
            builder: (context, state) => const WorkoutHistoryScreen(),
          ),
          // Nutrition
          GoRoute(
            path: AppRoutes.nutrition,
            builder: (context, state) => const DailyNutritionScreen(),
          ),
          // Habits
          GoRoute(
            path: AppRoutes.habits,
            builder: (context, state) => const HabitsDashboardScreen(),
          ),
          // Goals
          GoRoute(
            path: AppRoutes.goals,
            builder: (context, state) => const GoalsOverviewScreen(),
          ),
          // Settings
          GoRoute(
            path: AppRoutes.settings,
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
      // Full-screen routes (outside shell) — add/edit screens use slideUp,
      // detail/overview screens use fadeScale.
      GoRoute(
        path: AppRoutes.financeAdd,
        pageBuilder: (context, state) =>
            slideUpTransition(const AddEditTransactionScreen(), state),
      ),
      GoRoute(
        path: AppRoutes.financeBudgets,
        pageBuilder: (context, state) =>
            fadeScaleTransition(const BudgetOverviewScreen(), state),
      ),
      GoRoute(
        path: AppRoutes.financeSavings,
        pageBuilder: (context, state) =>
            fadeScaleTransition(const SavingsGoalsScreen(), state),
      ),
      GoRoute(
        path: AppRoutes.financeDashboard,
        pageBuilder: (context, state) =>
            fadeScaleTransition(const FinanceDashboardScreen(), state),
      ),
      GoRoute(
        path: AppRoutes.financeSmsImport,
        pageBuilder: (context, state) =>
            slideUpTransition(const SmsImportScreen(), state),
      ),
      GoRoute(
        path: AppRoutes.gymExercises,
        pageBuilder: (context, state) =>
            fadeScaleTransition(const ExerciseLibraryScreen(), state),
      ),
      GoRoute(
        path: AppRoutes.gymRoutineBuilder,
        pageBuilder: (context, state) =>
            slideUpTransition(const RoutineBuilderScreen(), state),
      ),
      GoRoute(
        path: AppRoutes.gymWorkout,
        pageBuilder: (context, state) =>
            slideUpTransition(const ActiveWorkoutScreen(), state),
      ),
      GoRoute(
        path: AppRoutes.gymHistory,
        pageBuilder: (context, state) =>
            fadeScaleTransition(const WorkoutHistoryScreen(), state),
      ),
      GoRoute(
        path: AppRoutes.gymMeasurements,
        pageBuilder: (context, state) =>
            fadeScaleTransition(const BodyMeasurementsScreen(), state),
      ),
      GoRoute(
        path: AppRoutes.nutritionSearch,
        pageBuilder: (context, state) =>
            slideUpTransition(const FoodSearchScreen(), state),
      ),
      GoRoute(
        path: AppRoutes.nutritionMealLog,
        pageBuilder: (context, state) =>
            slideUpTransition(const MealLogScreen(), state),
      ),
      GoRoute(
        path: AppRoutes.nutritionGoals,
        pageBuilder: (context, state) =>
            fadeScaleTransition(const NutritionGoalsScreen(), state),
      ),
      GoRoute(
        path: AppRoutes.barcodeScanner,
        pageBuilder: (context, state) =>
            slideUpTransition(const BarcodeScannerScreen(), state),
      ),
      GoRoute(
        path: AppRoutes.photoAnalysis,
        pageBuilder: (context, state) =>
            slideUpTransition(const PhotoAnalysisScreen(), state),
      ),
      GoRoute(
        path: AppRoutes.backup,
        pageBuilder: (context, state) =>
            fadeScaleTransition(const BackupScreen(), state),
      ),
      GoRoute(
        path: AppRoutes.habitsAdd,
        pageBuilder: (context, state) =>
            slideUpTransition(const AddEditHabitScreen(), state),
      ),
      GoRoute(
        path: AppRoutes.habitsDetail,
        pageBuilder: (context, state) =>
            fadeScaleTransition(const HabitDetailScreen(), state),
      ),
      GoRoute(
        path: AppRoutes.dayScore,
        pageBuilder: (context, state) =>
            fadeScaleTransition(const DayScoreScreen(), state),
      ),
      GoRoute(
        path: AppRoutes.scoreHistory,
        pageBuilder: (context, state) =>
            fadeScaleTransition(const ScoreHistoryScreen(), state),
      ),
      GoRoute(
        path: AppRoutes.monitoring,
        pageBuilder: (context, state) =>
            fadeScaleTransition(const MonitoringScreen(), state),
      ),
      GoRoute(
        path: AppRoutes.evolution,
        pageBuilder: (context, state) =>
            slideUpTransition(const EvolutionScreen(), state),
      ),
      GoRoute(
        path: AppRoutes.sleep,
        pageBuilder: (context, state) =>
            slideUpTransition(const SleepLogScreen(), state),
      ),
      GoRoute(
        path: AppRoutes.sleepHistory,
        pageBuilder: (context, state) =>
            fadeScaleTransition(const SleepHistoryScreen(), state),
      ),
      GoRoute(
        path: AppRoutes.energy,
        pageBuilder: (context, state) =>
            fadeScaleTransition(const EnergyTrackerScreen(), state),
      ),
      GoRoute(
        path: AppRoutes.circadian,
        pageBuilder: (context, state) =>
            fadeScaleTransition(const CircadianScreen(), state),
      ),
      GoRoute(
        path: AppRoutes.mood,
        pageBuilder: (context, state) =>
            slideUpTransition(const MoodLogScreen(), state),
      ),
      GoRoute(
        path: AppRoutes.breathing,
        pageBuilder: (context, state) =>
            fadeScaleTransition(const BreathingScreen(), state),
      ),
      GoRoute(
        path: AppRoutes.mentalHistory,
        pageBuilder: (context, state) =>
            fadeScaleTransition(const MentalHistoryScreen(), state),
      ),
      GoRoute(
        path: AppRoutes.gratitude,
        pageBuilder: (context, state) =>
            slideUpTransition(const GratitudeScreen(), state),
      ),
      GoRoute(
        path: AppRoutes.mentalInsights,
        pageBuilder: (context, state) =>
            fadeScaleTransition(const InsightsScreen(), state),
      ),
      GoRoute(
        path: AppRoutes.goalsAdd,
        pageBuilder: (context, state) =>
            slideUpTransition(const AddEditGoalScreen(), state),
      ),
      GoRoute(
        path: AppRoutes.goalsDetail,
        pageBuilder: (context, state) {
          final goalId =
              int.tryParse(state.uri.queryParameters['id'] ?? '');
          if (goalId == null) {
            return fadeScaleTransition(
                const _PlaceholderScreen(title: 'Detalle Meta'), state);
          }
          return fadeScaleTransition(GoalDetailScreen(goalId: goalId), state);
        },
      ),
      GoRoute(
        path: AppRoutes.aiConfig,
        pageBuilder: (context, state) =>
            fadeScaleTransition(const AIConfigScreen(), state),
      ),
      GoRoute(
        path: AppRoutes.aiConversations,
        pageBuilder: (context, state) =>
            fadeScaleTransition(const ConversationListScreen(), state),
      ),
      GoRoute(
        path: AppRoutes.aiChat,
        pageBuilder: (context, state) {
          final conversationId =
              int.tryParse(state.uri.queryParameters['id'] ?? '');
          final title = state.uri.queryParameters['title'] ?? 'Chat AI';
          if (conversationId == null) {
            return fadeScaleTransition(
                const _PlaceholderScreen(title: 'Chat AI'), state);
          }
          return fadeScaleTransition(
              ChatScreen(conversationId: conversationId, title: title), state);
        },
      ),
      GoRoute(
        path: AppRoutes.ticketScanner,
        pageBuilder: (context, state) =>
            slideUpTransition(const TicketScannerScreen(), state),
      ),
      GoRoute(
        path: AppRoutes.weeklySummary,
        pageBuilder: (context, state) =>
            fadeScaleTransition(const WeeklySummaryScreen(), state),
      ),
    ],
  );
});

class _AppShell extends StatelessWidget {
  const _AppShell({required this.child});

  final Widget child;

  // ---------------------------------------------------------------------------
  // Shared helpers
  // ---------------------------------------------------------------------------

  String _titleForLocation(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/finance')) return 'Finanzas';
    if (location.startsWith('/gym')) return 'Gimnasio';
    if (location.startsWith('/nutrition')) return 'Nutricion';
    if (location.startsWith('/habits')) return 'Habitos';
    if (location.startsWith('/goals')) return 'Metas';
    if (location.startsWith('/settings')) return 'Configuracion';
    return 'LifeOS';
  }

  int _selectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/finance')) return 1;
    if (location.startsWith('/gym')) return 2;
    if (location.startsWith('/nutrition')) return 3;
    if (location.startsWith('/habits')) return 4;
    return 0;
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: AppColors.darkSurface),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(Icons.shield_outlined, color: AppColors.finance, size: 40),
                const SizedBox(height: 8),
                Text('LifeOS', style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white)),
                Text('Todos los modulos', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.darkTextSecondary)),
              ],
            ),
          ),
          ListTile(
            leading: Icon(Icons.dashboard, color: AppColors.finance),
            title: const Text('Dashboard'),
            onTap: () { Navigator.pop(context); GoRouter.of(context).go(AppRoutes.home); },
          ),
          ListTile(
            leading: Icon(Icons.account_balance_wallet, color: AppColors.finance),
            title: const Text('Finanzas'),
            onTap: () { Navigator.pop(context); GoRouter.of(context).go(AppRoutes.finance); },
          ),
          ListTile(
            leading: Icon(Icons.fitness_center, color: AppColors.gym),
            title: const Text('Gimnasio'),
            onTap: () { Navigator.pop(context); GoRouter.of(context).go(AppRoutes.gym); },
          ),
          ListTile(
            leading: Icon(Icons.restaurant, color: AppColors.nutrition),
            title: const Text('Nutricion'),
            onTap: () { Navigator.pop(context); GoRouter.of(context).go(AppRoutes.nutrition); },
          ),
          ListTile(
            leading: Icon(Icons.check_circle, color: AppColors.habits),
            title: const Text('Habitos'),
            onTap: () { Navigator.pop(context); GoRouter.of(context).go(AppRoutes.habits); },
          ),
          const Divider(),
          ListTile(
            leading: Icon(Icons.bedtime_outlined, color: AppColors.sleep),
            title: const Text('Sueno'),
            onTap: () { Navigator.pop(context); GoRouter.of(context).push(AppRoutes.sleep); },
          ),
          ListTile(
            leading: Icon(Icons.psychology_outlined, color: AppColors.mental),
            title: const Text('Bienestar Mental'),
            onTap: () { Navigator.pop(context); GoRouter.of(context).push(AppRoutes.mood); },
          ),
          ListTile(
            leading: Icon(Icons.self_improvement_outlined, color: AppColors.mental),
            title: const Text('Respiracion'),
            onTap: () { Navigator.pop(context); GoRouter.of(context).push(AppRoutes.breathing); },
          ),
          ListTile(
            leading: Icon(Icons.favorite_outline, color: AppColors.mental),
            title: const Text('Gratitud'),
            onTap: () { Navigator.pop(context); GoRouter.of(context).push(AppRoutes.gratitude); },
          ),
          ListTile(
            leading: Icon(Icons.auto_awesome, color: AppColors.mental),
            title: const Text('Patrones de IA'),
            onTap: () { Navigator.pop(context); GoRouter.of(context).push(AppRoutes.mentalInsights); },
          ),
          ListTile(
            leading: Icon(Icons.flag_outlined, color: AppColors.goals),
            title: const Text('Metas'),
            onTap: () { Navigator.pop(context); GoRouter.of(context).go(AppRoutes.goals); },
          ),
          ListTile(
            leading: Icon(Icons.auto_awesome, color: AppColors.dayScore),
            title: const Text('DayScore'),
            onTap: () { Navigator.pop(context); GoRouter.of(context).push(AppRoutes.dayScore); },
          ),
          ListTile(
            leading: Icon(Icons.monitor_heart_outlined, color: AppColors.dayScore),
            title: const Text('Monitoreo'),
            onTap: () { Navigator.pop(context); GoRouter.of(context).push(AppRoutes.monitoring); },
          ),
          ListTile(
            leading: Icon(Icons.timeline_outlined, color: AppColors.dayScore),
            title: const Text('Evolucion'),
            onTap: () { Navigator.pop(context); GoRouter.of(context).push(AppRoutes.evolution); },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.smart_toy_outlined),
            title: const Text('Asistente AI'),
            onTap: () { Navigator.pop(context); GoRouter.of(context).push(AppRoutes.aiConversations); },
          ),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('Configuracion'),
            onTap: () { Navigator.pop(context); GoRouter.of(context).go(AppRoutes.settings); },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.receipt_long_outlined),
            title: const Text('Escanear Ticket'),
            onTap: () { Navigator.pop(context); GoRouter.of(context).push(AppRoutes.ticketScanner); },
          ),
          ListTile(
            leading: const Icon(Icons.summarize_outlined),
            title: const Text('Resumen Semanal'),
            onTap: () { Navigator.pop(context); GoRouter.of(context).push(AppRoutes.weeklySummary); },
          ),
          ListTile(
            leading: Icon(Icons.bolt_outlined, color: AppColors.gym),
            title: const Text('Energia'),
            onTap: () { Navigator.pop(context); GoRouter.of(context).push(AppRoutes.energy); },
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 600) {
          // ------------------------------------------------------------------
          // Tablet: permanent NavigationRail on the left, no bottom bar
          // ------------------------------------------------------------------
          final selectedIndex = _selectedIndex(context);
          return Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: Builder(
                builder: (ctx) => IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () => Scaffold.of(ctx).openDrawer(),
                  tooltip: 'Menu',
                ),
              ),
              title: Text(
                _titleForLocation(context),
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            drawer: _buildDrawer(context),
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: selectedIndex,
                  labelType: NavigationRailLabelType.all,
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.dashboard_outlined),
                      selectedIcon: Icon(Icons.dashboard),
                      label: Text('Dashboard'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.account_balance_wallet_outlined),
                      selectedIcon: Icon(Icons.account_balance_wallet),
                      label: Text('Finanzas'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.fitness_center_outlined),
                      selectedIcon: Icon(Icons.fitness_center),
                      label: Text('Gym'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.restaurant_outlined),
                      selectedIcon: Icon(Icons.restaurant),
                      label: Text('Nutricion'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.check_circle_outline),
                      selectedIcon: Icon(Icons.check_circle),
                      label: Text('Habitos'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.grid_view_outlined),
                      selectedIcon: Icon(Icons.grid_view),
                      label: Text('Mas'),
                    ),
                  ],
                  onDestinationSelected: (index) {
                    if (index == 5) {
                      Scaffold.of(context).openDrawer();
                      return;
                    }
                    const routes = [
                      AppRoutes.home,
                      AppRoutes.finance,
                      AppRoutes.gym,
                      AppRoutes.nutrition,
                      AppRoutes.habits,
                    ];
                    GoRouter.of(context).go(routes[index]);
                  },
                ),
                const VerticalDivider(thickness: 1, width: 1),
                Expanded(child: child),
              ],
            ),
          );
        }

        // --------------------------------------------------------------------
        // Phone: bottom navigation bar (original layout)
        // --------------------------------------------------------------------
        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: Builder(
              builder: (ctx) => IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => Scaffold.of(ctx).openDrawer(),
                tooltip: 'Menu',
              ),
            ),
            title: Text(
              _titleForLocation(context),
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          body: child,
          drawer: _buildDrawer(context),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _selectedIndex(context),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: 'Dashboard',
              ),
              NavigationDestination(
                icon: Icon(Icons.account_balance_wallet_outlined),
                selectedIcon: Icon(Icons.account_balance_wallet),
                label: 'Finanzas',
              ),
              NavigationDestination(
                icon: Icon(Icons.fitness_center_outlined),
                selectedIcon: Icon(Icons.fitness_center),
                label: 'Gym',
              ),
              NavigationDestination(
                icon: Icon(Icons.restaurant_outlined),
                selectedIcon: Icon(Icons.restaurant),
                label: 'Nutricion',
              ),
              NavigationDestination(
                icon: Icon(Icons.check_circle_outline),
                selectedIcon: Icon(Icons.check_circle),
                label: 'Habitos',
              ),
              NavigationDestination(
                icon: Icon(Icons.grid_view_outlined),
                selectedIcon: Icon(Icons.grid_view),
                label: 'Mas',
              ),
            ],
            onDestinationSelected: (index) {
              if (index == 5) {
                Scaffold.of(context).openDrawer();
                return;
              }
              const routes = [
                AppRoutes.home,
                AppRoutes.finance,
                AppRoutes.gym,
                AppRoutes.nutrition,
                AppRoutes.habits,
              ];
              GoRouter.of(context).go(routes[index]);
            },
          ),
        );
      },
    );
  }
}

class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(title, style: Theme.of(context).textTheme.headlineMedium),
    );
  }
}
