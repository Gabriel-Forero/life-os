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
import 'package:life_os/features/gym/presentation/gym_dashboard_screen.dart';
import 'package:life_os/features/gym/presentation/gym_valuation_screen.dart';
import 'package:life_os/features/gym/presentation/routine_builder_screen.dart';
import 'package:life_os/features/gym/presentation/workout_history_screen.dart';
import 'package:life_os/features/finance/presentation/finance_valuation_screen.dart';
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
import 'package:life_os/features/nutrition/presentation/manual_food_entry_screen.dart';
import 'package:life_os/features/nutrition/presentation/nutrition_valuation_screen.dart';
import 'package:life_os/features/nutrition/presentation/photo_analysis_screen.dart';
import 'package:life_os/features/onboarding/presentation/onboarding_shell.dart';
import 'package:life_os/features/wellness/presentation/wellness_hub_screen.dart';
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
  static const String gymValuation = '/gym/valuation';

  // Finance (valuacion)
  static const String financeValuation = '/finance/valuation';

  // Nutrition
  static const String nutrition = '/nutrition';
  static const String nutritionSearch = '/nutrition/search';
  static const String nutritionMealLog = '/nutrition/meal-log';
  static const String nutritionGoals = '/nutrition/goals';
  static const String barcodeScanner = '/nutrition/scan';
  static const String photoAnalysis = '/nutrition/photo';
  static const String manualFoodEntry = '/nutrition/manual';
  static const String nutritionValuation = '/nutrition/valuation';

  // Settings
  static const String backup = '/settings/backup';

  // Wellness (unified)
  static const String wellness = '/wellness';

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
            builder: (context, state) => const GymDashboardScreen(),
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
          // Wellness hub
          GoRoute(
            path: AppRoutes.wellness,
            builder: (context, state) => const WellnessHubScreen(),
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
        path: AppRoutes.gymValuation,
        pageBuilder: (context, state) =>
            fadeScaleTransition(const GymValuationScreen(), state),
      ),
      GoRoute(
        path: AppRoutes.financeValuation,
        pageBuilder: (context, state) =>
            fadeScaleTransition(const FinanceValuationScreen(), state),
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
        path: AppRoutes.manualFoodEntry,
        pageBuilder: (context, state) =>
            slideUpTransition(const ManualFoodEntryScreen(), state),
      ),
      GoRoute(
        path: AppRoutes.nutritionValuation,
        pageBuilder: (context, state) =>
            fadeScaleTransition(const NutritionValuationScreen(), state),
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
        pageBuilder: (context, state) {
          final habitId =
              int.tryParse(state.uri.queryParameters['id'] ?? '');
          return fadeScaleTransition(
              HabitDetailScreen(habitId: habitId), state);
        },
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

class _AppShell extends StatefulWidget {
  const _AppShell({required this.child});

  final Widget child;

  @override
  State<_AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<_AppShell> {
  Widget get child => widget.child;

  // ---------------------------------------------------------------------------
  // Shared helpers
  // ---------------------------------------------------------------------------

  String _titleForLocation(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/finance')) return 'Finanzas';
    if (location.startsWith('/gym')) return 'Gimnasio';
    if (location.startsWith('/nutrition')) return 'Nutrición';
    if (location.startsWith('/habits')) return 'Hábitos';
    if (location.startsWith('/goals')) return 'Metas';
    if (location.startsWith('/settings')) return 'Configuración';
    if (location.startsWith('/monitoring')) return 'Progreso';
    if (location.startsWith('/wellness')) return 'Bienestar';
    return 'LifeOS';
  }

  Color _colorForLocation(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/finance')) return AppColors.finance;
    if (location.startsWith('/gym')) return AppColors.gym;
    if (location.startsWith('/nutrition')) return AppColors.nutrition;
    if (location.startsWith('/habits')) return AppColors.habits;
    if (location.startsWith('/goals')) return AppColors.goals;
    if (location.startsWith('/wellness')) return AppColors.mental;
    if (location.startsWith('/settings')) return AppColors.lightTextPrimary;
    return AppColors.primary;
  }

  List<Widget> _actionsForLocation(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;

    if (location == AppRoutes.finance) {
      return [
        IconButton(
          key: const ValueKey('transactions-sms-import-button'),
          icon: Icon(Icons.sms_outlined, color: AppColors.finance),
          onPressed: () => GoRouter.of(context).push(AppRoutes.financeSmsImport),
          tooltip: 'Importar SMS',
        ),
        IconButton(
          key: const ValueKey('transactions-budget-button'),
          icon: Icon(Icons.pie_chart_outline, color: AppColors.finance),
          onPressed: () => GoRouter.of(context).push(AppRoutes.financeBudgets),
          tooltip: 'Presupuestos',
        ),
        IconButton(
          key: const ValueKey('transactions-dashboard-button'),
          icon: Icon(Icons.bar_chart, color: AppColors.finance),
          onPressed: () => GoRouter.of(context).push(AppRoutes.financeDashboard),
          tooltip: 'Dashboard',
        ),
        IconButton(
          key: const ValueKey('transactions-savings-button'),
          icon: Icon(Icons.savings_outlined, color: AppColors.finance),
          onPressed: () => GoRouter.of(context).push(AppRoutes.financeSavings),
          tooltip: 'Metas de ahorro',
        ),
        IconButton(
          key: const ValueKey('transactions-valuation-button'),
          icon: Icon(Icons.assessment_outlined, color: AppColors.finance),
          onPressed: () => GoRouter.of(context).push(AppRoutes.financeValuation),
          tooltip: 'Valoracion',
        ),
      ];
    }

    if (location == AppRoutes.nutrition) {
      return [
        IconButton(
          key: const ValueKey('nutrition-photo-analysis-button'),
          icon: Icon(Icons.camera_alt_outlined, color: AppColors.nutrition),
          onPressed: () => GoRouter.of(context).push(AppRoutes.photoAnalysis),
          tooltip: 'Analizar foto',
        ),
        IconButton(
          key: const ValueKey('nutrition-goals-nav-button'),
          icon: Icon(Icons.track_changes_outlined, color: AppColors.nutrition),
          onPressed: () => GoRouter.of(context).push(AppRoutes.nutritionGoals),
          tooltip: 'Metas',
        ),
        IconButton(
          key: const ValueKey('nutrition-valuation-button'),
          icon: Icon(Icons.assessment_outlined, color: AppColors.nutrition),
          onPressed: () => GoRouter.of(context).push(AppRoutes.nutritionValuation),
          tooltip: 'Valoracion',
        ),
      ];
    }

    if (location == AppRoutes.habits) {
      return [
        IconButton(
          key: const ValueKey('habits-add-button'),
          icon: Icon(Icons.add_circle_outline, color: AppColors.habits),
          onPressed: () => GoRouter.of(context).push(AppRoutes.habitsAdd),
          tooltip: 'Agregar habito',
        ),
      ];
    }

    if (location == AppRoutes.goals) {
      return [
        IconButton(
          key: const ValueKey('add_goal_button'),
          icon: Icon(Icons.add, color: AppColors.goals),
          onPressed: () => GoRouter.of(context).push(AppRoutes.goalsAdd),
          tooltip: 'Agregar objetivo',
        ),
      ];
    }

    return [];
  }

  /// Bottom nav indices:
  ///   0 = Home (/)
  ///   1 = Diario  (no route — shows bottom sheet)
  ///   2 = +       (no route — shows quick-add sheet)
  ///   3 = Progreso (/monitoring)
  ///   4 = Perfil  (/settings)
  int _selectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location == AppRoutes.home) return 0;
    if (location.startsWith('/monitoring')) return 3;
    if (location.startsWith('/settings')) return 4;
    return 0;
  }

  // ---------------------------------------------------------------------------
  // Quick-add bottom sheet
  // ---------------------------------------------------------------------------

  void _showDiarySheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _DiarySheet(onNavigate: (route) {
        Navigator.pop(ctx);
        GoRouter.of(context).push(route);
      }),
    );
  }

  void _showQuickAddSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _QuickAddSheet(onNavigate: (route) {
        Navigator.pop(ctx);
        GoRouter.of(context).push(route);
      }),
    );
  }

  // ---------------------------------------------------------------------------
  // Drawer
  // ---------------------------------------------------------------------------

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: AppColors.primary,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Icon(Icons.shield_outlined, color: Colors.white, size: 40),
                const SizedBox(height: 8),
                Text('LifeOS', style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
                Text('Todos los modulos', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70)),
              ],
            ),
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
            title: const Text('Nutrición'),
            onTap: () { Navigator.pop(context); GoRouter.of(context).go(AppRoutes.nutrition); },
          ),
          ListTile(
            leading: Icon(Icons.check_circle, color: AppColors.habits),
            title: const Text('Hábitos'),
            onTap: () { Navigator.pop(context); GoRouter.of(context).go(AppRoutes.habits); },
          ),
          const Divider(),
          ListTile(
            leading: Icon(Icons.spa, color: AppColors.mental),
            title: const Text('Bienestar'),
            subtitle: const Text('Sueno, mood, respiracion, gratitud'),
            onTap: () { Navigator.pop(context); GoRouter.of(context).go(AppRoutes.wellness); },
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
            leading: Icon(Icons.insights, color: AppColors.dayScore),
            title: const Text('Mi Progreso'),
            subtitle: const Text('DayScore, monitoreo, evolucion'),
            onTap: () { Navigator.pop(context); GoRouter.of(context).push(AppRoutes.monitoring); },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.smart_toy_outlined),
            title: const Text('Asistente AI'),
            onTap: () { Navigator.pop(context); GoRouter.of(context).push(AppRoutes.aiConversations); },
          ),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('Configuración'),
            onTap: () { Navigator.pop(context); GoRouter.of(context).go(AppRoutes.settings); },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.summarize_outlined),
            title: const Text('Resumen Semanal'),
            onTap: () { Navigator.pop(context); GoRouter.of(context).push(AppRoutes.weeklySummary); },
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
            backgroundColor: AppColors.lightBackground,
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              surfaceTintColor: Colors.white,
              centerTitle: true,
              leading: Builder(
                builder: (ctx) => IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () => Scaffold.of(ctx).openDrawer(),
                  tooltip: 'Menu',
                ),
              ),
              title: Text(
                _titleForLocation(context),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: _colorForLocation(context),
                ),
              ),
              // Actions moved to body — keeps title centered and unclipped
            ),
            drawer: _buildDrawer(context),
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: selectedIndex,
                  labelType: NavigationRailLabelType.all,
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.home_outlined),
                      selectedIcon: Icon(Icons.home),
                      label: Text('Home'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.book_outlined),
                      selectedIcon: Icon(Icons.book),
                      label: Text('Diario'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.add_circle_outline),
                      selectedIcon: Icon(Icons.add_circle),
                      label: Text('+'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.bar_chart_outlined),
                      selectedIcon: Icon(Icons.bar_chart),
                      label: Text('Progreso'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.person_outlined),
                      selectedIcon: Icon(Icons.person),
                      label: Text('Perfil'),
                    ),
                  ],
                  onDestinationSelected: (index) {
                    switch (index) {
                      case 0:
                        GoRouter.of(context).go(AppRoutes.home);
                      case 1:
                        _showDiarySheet(context);
                      case 2:
                        _showQuickAddSheet(context);
                      case 3:
                        GoRouter.of(context).push(AppRoutes.monitoring);
                      case 4:
                        GoRouter.of(context).go(AppRoutes.settings);
                    }
                  },
                ),
                const VerticalDivider(thickness: 1, width: 1),
                Expanded(
                  child: Column(
                    children: [
                      if (_actionsForLocation(context).isNotEmpty)
                        Container(
                          color: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: _actionsForLocation(context),
                          ),
                        ),
                      Expanded(child: child),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        // --------------------------------------------------------------------
        // Phone: bottom navigation bar (new 5-item layout)
        // --------------------------------------------------------------------
        return Scaffold(
          backgroundColor: AppColors.lightBackground,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            surfaceTintColor: Colors.white,
            shadowColor: Colors.black.withAlpha(20),
            centerTitle: true,
            leading: Builder(
              builder: (ctx) => IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => Scaffold.of(ctx).openDrawer(),
                tooltip: 'Menu',
              ),
            ),
            title: Text(
              _titleForLocation(context),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: _colorForLocation(context),
              ),
            ),
          ),
          body: Column(
            children: [
              if (_actionsForLocation(context).isNotEmpty)
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: _actionsForLocation(context),
                  ),
                ),
              Expanded(child: child),
            ],
          ),
          drawer: _buildDrawer(context),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _selectedIndex(context),
            destinations: [
              const NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: 'Home',
              ),
              const NavigationDestination(
                icon: Icon(Icons.book_outlined),
                selectedIcon: Icon(Icons.book),
                label: 'Diario',
              ),
              NavigationDestination(
                icon: Icon(
                  Icons.add_circle,
                  size: 32,
                  color: AppColors.primary,
                ),
                selectedIcon: Icon(
                  Icons.add_circle,
                  size: 32,
                  color: AppColors.primary,
                ),
                label: '',
              ),
              const NavigationDestination(
                icon: Icon(Icons.bar_chart_outlined),
                selectedIcon: Icon(Icons.bar_chart),
                label: 'Progreso',
              ),
              const NavigationDestination(
                icon: Icon(Icons.person_outlined),
                selectedIcon: Icon(Icons.person),
                label: 'Perfil',
              ),
            ],
            onDestinationSelected: (index) {
              switch (index) {
                case 0:
                  GoRouter.of(context).go(AppRoutes.home);
                case 1:
                  _showDiarySheet(context);
                case 2:
                  _showQuickAddSheet(context);
                case 3:
                  GoRouter.of(context).push(AppRoutes.monitoring);
                case 4:
                  GoRouter.of(context).go(AppRoutes.settings);
              }
            },
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Quick-add sheet widgets
// ---------------------------------------------------------------------------

class _QuickAddAction {
  const _QuickAddAction({
    required this.label,
    required this.icon,
    required this.color,
    required this.route,
  });

  final String label;
  final IconData icon;
  final Color color;
  final String route;
}

class _QuickAddSheet extends StatelessWidget {
  const _QuickAddSheet({required this.onNavigate});

  final void Function(String route) onNavigate;

  static const _actions = [
    _QuickAddAction(
      label: '+ Transaccion',
      icon: Icons.account_balance_wallet_outlined,
      color: AppColors.finance,
      route: AppRoutes.financeAdd,
    ),
    _QuickAddAction(
      label: '+ Comida',
      icon: Icons.restaurant_outlined,
      color: AppColors.nutrition,
      route: AppRoutes.nutritionMealLog,
    ),
    _QuickAddAction(
      label: '+ Habito',
      icon: Icons.check_circle_outline,
      color: AppColors.habits,
      route: AppRoutes.habits,
    ),
    _QuickAddAction(
      label: '+ Workout',
      icon: Icons.fitness_center_outlined,
      color: AppColors.gym,
      route: AppRoutes.gymWorkout,
    ),
    _QuickAddAction(
      label: '+ Mood',
      icon: Icons.sentiment_satisfied_outlined,
      color: AppColors.mental,
      route: AppRoutes.mood,
    ),
    _QuickAddAction(
      label: '+ Sueno',
      icon: Icons.bedtime_outlined,
      color: AppColors.sleep,
      route: AppRoutes.sleep,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withAlpha(80),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Agregar rapido',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.1,
              children: _actions.map((action) {
                return Semantics(
                  label: action.label,
                  button: true,
                  child: InkWell(
                    onTap: () => onNavigate(action.route),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: action.color.withAlpha(20),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: action.color.withAlpha(60),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(action.icon, color: action.color, size: 28),
                          const SizedBox(height: 6),
                          Text(
                            action.label,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: action.color,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _DiarySheet extends StatelessWidget {
  const _DiarySheet({required this.onNavigate});

  final void Function(String route) onNavigate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final weekdays = ['Lun', 'Mar', 'Mie', 'Jue', 'Vie', 'Sab', 'Dom'];
    final months = [
      'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
    ];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withAlpha(80),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Diario',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${weekdays[now.weekday - 1]}, ${now.day} ${months[now.month - 1]} ${now.year}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 20),
            _DiaryQuickLink(
              icon: Icons.account_balance_wallet_outlined,
              color: AppColors.finance,
              label: 'Finanzas',
              onTap: () => onNavigate(AppRoutes.finance),
            ),
            _DiaryQuickLink(
              icon: Icons.restaurant_outlined,
              color: AppColors.nutrition,
              label: 'Nutricion de hoy',
              onTap: () => onNavigate(AppRoutes.nutrition),
            ),
            _DiaryQuickLink(
              icon: Icons.check_circle_outline,
              color: AppColors.habits,
              label: 'Habitos de hoy',
              onTap: () => onNavigate(AppRoutes.habits),
            ),
            _DiaryQuickLink(
              icon: Icons.fitness_center_outlined,
              color: AppColors.gym,
              label: 'Entrenamiento',
              onTap: () => onNavigate(AppRoutes.gym),
            ),
            _DiaryQuickLink(
              icon: Icons.sentiment_satisfied_outlined,
              color: AppColors.mental,
              label: 'Estado de animo',
              onTap: () => onNavigate(AppRoutes.mood),
            ),
          ],
        ),
      ),
    );
  }
}

class _DiaryQuickLink extends StatelessWidget {
  const _DiaryQuickLink({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withAlpha(25),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Icon(Icons.chevron_right, color: AppColors.lightTextSecondary, size: 20),
          ],
        ),
      ),
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
