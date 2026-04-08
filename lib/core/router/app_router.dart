import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:life_os/core/constants/app_breakpoints.dart';
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
import 'package:life_os/features/finance/presentation/budget_analytics_screen.dart';
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
  static const String financeBudgetAnalytics = '/finance/budget-analytics';

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
          // Monitoring (inside shell so sidebar stays visible)
          GoRoute(
            path: AppRoutes.monitoring,
            builder: (context, state) => const MonitoringScreen(),
          ),
          // AI Conversations
          GoRoute(
            path: AppRoutes.aiConversations,
            builder: (context, state) => const ConversationListScreen(),
          ),
          // --- Overview/detail screens (sidebar stays visible) ---
          // Finance
          GoRoute(path: AppRoutes.financeBudgets, builder: (context, state) => const BudgetOverviewScreen()),
          GoRoute(path: AppRoutes.financeBudgetAnalytics, builder: (context, state) => const BudgetAnalyticsScreen()),
          GoRoute(path: AppRoutes.financeSavings, builder: (context, state) => const SavingsGoalsScreen()),
          GoRoute(path: AppRoutes.financeDashboard, builder: (context, state) => const FinanceDashboardScreen()),
          GoRoute(path: AppRoutes.financeValuation, builder: (context, state) => const FinanceValuationScreen()),
          // Gym
          GoRoute(path: AppRoutes.gymExercises, builder: (context, state) => const ExerciseLibraryScreen()),
          GoRoute(path: AppRoutes.gymHistory, builder: (context, state) => const WorkoutHistoryScreen()),
          GoRoute(path: AppRoutes.gymValuation, builder: (context, state) => const GymValuationScreen()),
          // Nutrition
          GoRoute(path: AppRoutes.nutritionGoals, builder: (context, state) => const NutritionGoalsScreen()),
          GoRoute(path: AppRoutes.nutritionValuation, builder: (context, state) => const NutritionValuationScreen()),
          // Habits
          GoRoute(
            path: AppRoutes.habitsDetail,
            builder: (context, state) {
              final habitId = int.tryParse(state.uri.queryParameters['id'] ?? '');
              return HabitDetailScreen(habitId: habitId);
            },
          ),
          // Dashboard/Scores
          GoRoute(path: AppRoutes.dayScore, builder: (context, state) => const DayScoreScreen()),
          GoRoute(path: AppRoutes.scoreHistory, builder: (context, state) => const ScoreHistoryScreen()),
          GoRoute(path: AppRoutes.evolution, builder: (context, state) => const EvolutionScreen()),
          // Sleep/Mental overviews
          GoRoute(path: AppRoutes.sleepHistory, builder: (context, state) => const SleepHistoryScreen()),
          GoRoute(path: AppRoutes.energy, builder: (context, state) => const EnergyTrackerScreen()),
          GoRoute(path: AppRoutes.circadian, builder: (context, state) => const CircadianScreen()),
          GoRoute(path: AppRoutes.breathing, builder: (context, state) => const BreathingScreen()),
          GoRoute(path: AppRoutes.mentalHistory, builder: (context, state) => const MentalHistoryScreen()),
          GoRoute(path: AppRoutes.mentalInsights, builder: (context, state) => const InsightsScreen()),
          // Sleep/Mental input forms (inside shell so sidebar stays on web)
          GoRoute(path: AppRoutes.sleep, builder: (context, state) => const SleepLogScreen()),
          GoRoute(path: AppRoutes.mood, builder: (context, state) => const MoodLogScreen()),
          GoRoute(path: AppRoutes.gratitude, builder: (context, state) => const GratitudeScreen()),
          // Goals
          GoRoute(
            path: AppRoutes.goalsDetail,
            builder: (context, state) {
              final goalId = int.tryParse(state.uri.queryParameters['id'] ?? '');
              if (goalId == null) return const _PlaceholderScreen(title: 'Detalle Meta');
              return GoalDetailScreen(goalId: goalId);
            },
          ),
          // AI
          GoRoute(path: AppRoutes.aiConfig, builder: (context, state) => const AIConfigScreen()),
          GoRoute(
            path: AppRoutes.aiChat,
            builder: (context, state) {
              final conversationId = int.tryParse(state.uri.queryParameters['id'] ?? '');
              final title = state.uri.queryParameters['title'] ?? 'Chat AI';
              if (conversationId == null) return const _PlaceholderScreen(title: 'Chat AI');
              return ChatScreen(conversationId: conversationId, title: title);
            },
          ),
          GoRoute(path: AppRoutes.weeklySummary, builder: (context, state) => const WeeklySummaryScreen()),
          // --- Form/modal routes (inside shell so sidebar stays on web) ---
          GoRoute(path: AppRoutes.financeAdd, builder: (context, state) => const AddEditTransactionScreen()),
          GoRoute(path: AppRoutes.gymRoutineBuilder, builder: (context, state) => const RoutineBuilderScreen()),
          GoRoute(path: AppRoutes.gymWorkout, builder: (context, state) => const ActiveWorkoutScreen()),
          GoRoute(path: AppRoutes.nutritionSearch, builder: (context, state) => const FoodSearchScreen()),
          GoRoute(path: AppRoutes.nutritionMealLog, builder: (context, state) => const MealLogScreen()),
          GoRoute(path: AppRoutes.manualFoodEntry, builder: (context, state) => const ManualFoodEntryScreen()),
          GoRoute(path: AppRoutes.habitsAdd, builder: (context, state) => const AddEditHabitScreen()),
          GoRoute(path: AppRoutes.goalsAdd, builder: (context, state) => const AddEditGoalScreen()),
          GoRoute(path: AppRoutes.ticketScanner, builder: (context, state) => const TicketScannerScreen()),
        ],
      ),
      // Full-screen routes (outside shell) — mobile-only features that redirect on web
      GoRoute(path: AppRoutes.financeSmsImport, redirect: (context, state) => kIsWeb ? AppRoutes.finance : null, pageBuilder: (context, state) => slideUpTransition(const SmsImportScreen(), state)),
      GoRoute(path: AppRoutes.gymMeasurements, redirect: (context, state) => kIsWeb ? AppRoutes.gym : null, pageBuilder: (context, state) => fadeScaleTransition(const BodyMeasurementsScreen(), state)),
      GoRoute(path: AppRoutes.barcodeScanner, redirect: (context, state) => kIsWeb ? AppRoutes.nutrition : null, pageBuilder: (context, state) => slideUpTransition(const BarcodeScannerScreen(), state)),
      GoRoute(path: AppRoutes.photoAnalysis, redirect: (context, state) => kIsWeb ? AppRoutes.nutrition : null, pageBuilder: (context, state) => slideUpTransition(const PhotoAnalysisScreen(), state)),
      GoRoute(path: AppRoutes.backup, redirect: (context, state) => kIsWeb ? AppRoutes.settings : null, pageBuilder: (context, state) => fadeScaleTransition(const BackupScreen(), state)),
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
    if (location.startsWith('/ai')) return 'Asistente AI';
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
    if (location.startsWith('/monitoring')) return AppColors.dayScore;
    if (location.startsWith('/ai')) return AppColors.primary;
    if (location.startsWith('/settings')) return AppColors.lightTextPrimary;
    return AppColors.primary;
  }

  List<Widget> _actionsForLocation(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;

    if (location == AppRoutes.finance) {
      return [
        if (!kIsWeb)
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
        if (!kIsWeb)
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

    if (location == AppRoutes.gym) {
      return [
        IconButton(
          key: const ValueKey('gym-action-workout'),
          icon: Icon(Icons.play_circle_outline, color: AppColors.gym),
          onPressed: () => GoRouter.of(context).push(AppRoutes.gymWorkout),
          tooltip: 'Libre',
        ),
        IconButton(
          key: const ValueKey('gym-action-history'),
          icon: Icon(Icons.history_outlined, color: AppColors.gym),
          onPressed: () => GoRouter.of(context).push(AppRoutes.gymHistory),
          tooltip: 'Historial',
        ),
        IconButton(
          key: const ValueKey('gym-action-exercises'),
          icon: Icon(Icons.library_books_outlined, color: AppColors.gym),
          onPressed: () => GoRouter.of(context).push(AppRoutes.gymExercises),
          tooltip: 'Ejercicios',
        ),
        if (!kIsWeb)
          IconButton(
            key: const ValueKey('gym-action-measurements'),
            icon: Icon(Icons.monitor_weight_outlined, color: AppColors.gym),
            onPressed: () => GoRouter.of(context).push(AppRoutes.gymMeasurements),
            tooltip: 'Medidas',
          ),
        IconButton(
          key: const ValueKey('gym-action-valuation'),
          icon: Icon(Icons.assessment_outlined, color: AppColors.gym),
          onPressed: () => GoRouter.of(context).push(AppRoutes.gymValuation),
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
        IconButton(
          key: const ValueKey('habits-action-score'),
          icon: Icon(Icons.insights, color: AppColors.habits),
          onPressed: () => GoRouter.of(context).push(AppRoutes.dayScore),
          tooltip: 'DayScore',
        ),
        IconButton(
          key: const ValueKey('habits-action-history'),
          icon: Icon(Icons.history, color: AppColors.habits),
          onPressed: () => GoRouter.of(context).push(AppRoutes.scoreHistory),
          tooltip: 'Historial',
        ),
        IconButton(
          key: const ValueKey('habits-action-monitoring'),
          icon: Icon(Icons.bar_chart, color: AppColors.habits),
          onPressed: () => GoRouter.of(context).go(AppRoutes.monitoring),
          tooltip: 'Monitoreo',
        ),
        IconButton(
          key: const ValueKey('habits-action-evolution'),
          icon: Icon(Icons.trending_up, color: AppColors.habits),
          onPressed: () => GoRouter.of(context).push(AppRoutes.evolution),
          tooltip: 'Evolucion',
        ),
      ];
    }

    if (location == AppRoutes.goals) {
      return [
        IconButton(
          key: const ValueKey('goals-action-add'),
          icon: Icon(Icons.add, color: AppColors.goals),
          onPressed: () => GoRouter.of(context).push(AppRoutes.goalsAdd),
          tooltip: 'Agregar objetivo',
        ),
        IconButton(
          key: const ValueKey('goals-action-evolution'),
          icon: Icon(Icons.trending_up, color: AppColors.goals),
          onPressed: () => GoRouter.of(context).push(AppRoutes.evolution),
          tooltip: 'Evolucion',
        ),
      ];
    }

    if (location == AppRoutes.wellness) {
      return [
        IconButton(
          key: const ValueKey('wellness-action-mood'),
          icon: Icon(Icons.mood, color: AppColors.mental),
          onPressed: () => GoRouter.of(context).push(AppRoutes.mood),
          tooltip: 'Mood',
        ),
        IconButton(
          key: const ValueKey('wellness-action-gratitude'),
          icon: Icon(Icons.favorite, color: AppColors.mental),
          onPressed: () => GoRouter.of(context).push(AppRoutes.gratitude),
          tooltip: 'Gratitud',
        ),
        IconButton(
          key: const ValueKey('wellness-action-sleep'),
          icon: Icon(Icons.bedtime, color: AppColors.sleep),
          onPressed: () => GoRouter.of(context).push(AppRoutes.sleep),
          tooltip: 'Sueno',
        ),
        IconButton(
          key: const ValueKey('wellness-action-energy'),
          icon: Icon(Icons.bolt, color: AppColors.gym),
          onPressed: () => GoRouter.of(context).push(AppRoutes.energy),
          tooltip: 'Energia',
        ),
        IconButton(
          key: const ValueKey('wellness-action-breathing'),
          icon: Icon(Icons.self_improvement, color: AppColors.mental),
          onPressed: () => GoRouter.of(context).push(AppRoutes.breathing),
          tooltip: 'Respiracion',
        ),
        IconButton(
          key: const ValueKey('wellness-action-history'),
          icon: Icon(Icons.calendar_month, color: AppColors.mental),
          onPressed: () => GoRouter.of(context).push(AppRoutes.mentalHistory),
          tooltip: 'Historial',
        ),
        IconButton(
          key: const ValueKey('wellness-action-circadian'),
          icon: Icon(Icons.show_chart, color: AppColors.sleep),
          onPressed: () => GoRouter.of(context).push(AppRoutes.circadian),
          tooltip: 'Circadiano',
        ),
        IconButton(
          key: const ValueKey('wellness-action-insights'),
          icon: Icon(Icons.psychology, color: AppColors.goals),
          onPressed: () => GoRouter.of(context).push(AppRoutes.mentalInsights),
          tooltip: 'Patrones IA',
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
            onTap: () { Navigator.pop(context); GoRouter.of(context).go(AppRoutes.monitoring); },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.smart_toy_outlined),
            title: const Text('Asistente AI'),
            onTap: () { Navigator.pop(context); GoRouter.of(context).go(AppRoutes.aiConversations); },
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
  // Sidebar item data
  // ---------------------------------------------------------------------------

  static const _sidebarModules = [
    (icon: Icons.account_balance_wallet, label: 'Finanzas', route: AppRoutes.finance, color: AppColors.finance),
    (icon: Icons.fitness_center, label: 'Gimnasio', route: AppRoutes.gym, color: AppColors.gym),
    (icon: Icons.restaurant, label: 'Nutricion', route: AppRoutes.nutrition, color: AppColors.nutrition),
    (icon: Icons.check_circle, label: 'Habitos', route: AppRoutes.habits, color: AppColors.habits),
  ];

  static const _sidebarMore = [
    (icon: Icons.spa, label: 'Bienestar', route: AppRoutes.wellness, color: AppColors.mental),
    (icon: Icons.flag_outlined, label: 'Metas', route: AppRoutes.goals, color: AppColors.goals),
    (icon: Icons.insights, label: 'Mi Progreso', route: '/monitoring', color: AppColors.dayScore),
    (icon: Icons.smart_toy_outlined, label: 'Asistente AI', route: '/ai/conversations', color: AppColors.primary),
  ];

  bool _isRouteActive(BuildContext context, String route) {
    final location = GoRouterState.of(context).uri.path;
    if (route == '/') return location == '/';
    return location.startsWith(route);
  }

  /// Main hub pages that show the shell content header with actions.
  /// Sub-pages use their own AppBar with back button instead.
  static const _mainHubRoutes = {
    '/', '/finance', '/gym', '/nutrition', '/habits',
    '/goals', '/wellness', '/settings', '/monitoring',
    '/ai/conversations',
  };

  bool _isMainHub(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    return _mainHubRoutes.contains(location);
  }

  /// Routes that should be full-screen on mobile (no shell chrome).
  /// On web/desktop these still show with the sidebar.
  static const _mobileFullScreenRoutes = {
    '/finance/add',
    '/gym/routine-builder',
    '/gym/workout',
    '/nutrition/search',
    '/nutrition/meal-log',
    '/nutrition/manual',
    '/habits/add',
    '/goals/add',
    '/ai/ticket',
  };

  bool _isMobileFullScreen(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    return _mobileFullScreenRoutes.contains(location);
  }

  // ---------------------------------------------------------------------------
  // Desktop layout (>= 1200px)
  // ---------------------------------------------------------------------------

  Widget _buildDesktopLayout(BuildContext context) {
    final theme = Theme.of(context);
    final location = GoRouterState.of(context).uri.path;
    final actions = _actionsForLocation(context);

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      body: Row(
        children: [
          // --- Permanent sidebar ---
          Container(
            width: 260,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(right: BorderSide(color: AppColors.lightBorder, width: 1)),
            ),
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
                  child: Row(
                    children: [
                      Icon(Icons.shield_outlined, size: 28, color: AppColors.primary),
                      const SizedBox(width: 10),
                      Text('LifeOS', style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                        letterSpacing: 0.5,
                      )),
                    ],
                  ),
                ),
                // Home
                _SidebarItem(
                  icon: Icons.home_outlined,
                  selectedIcon: Icons.home,
                  label: 'Home',
                  color: AppColors.primary,
                  selected: location == '/',
                  onTap: () => GoRouter.of(context).go(AppRoutes.home),
                ),
                _SidebarItem(
                  icon: Icons.book_outlined,
                  selectedIcon: Icons.book,
                  label: 'Diario',
                  color: AppColors.primary,
                  selected: false,
                  onTap: () => _showDiarySheet(context),
                ),
                const SizedBox(height: 8),
                // Section: Modules
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('MODULOS', style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.lightTextSecondary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    )),
                  ),
                ),
                for (final mod in _sidebarModules)
                  _SidebarItem(
                    icon: mod.icon,
                    label: mod.label,
                    color: mod.color,
                    selected: _isRouteActive(context, mod.route),
                    onTap: () => GoRouter.of(context).go(mod.route),
                  ),
                const SizedBox(height: 8),
                // Section: More
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('MAS', style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.lightTextSecondary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    )),
                  ),
                ),
                for (final item in _sidebarMore)
                  _SidebarItem(
                    icon: item.icon,
                    label: item.label,
                    color: item.color,
                    selected: _isRouteActive(context, item.route),
                    onTap: () => GoRouter.of(context).go(item.route),
                  ),
                const Spacer(),
                // Bottom actions
                const Divider(height: 1),
                _SidebarItem(
                  icon: Icons.settings_outlined,
                  label: 'Configuracion',
                  color: AppColors.lightTextSecondary,
                  selected: _isRouteActive(context, AppRoutes.settings),
                  onTap: () => GoRouter.of(context).go(AppRoutes.settings),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
          // --- Content area ---
          Expanded(
            child: Column(
              children: [
                // Content header — only for main hub pages;
                // sub-pages use their own AppBar with back button.
                if (_isMainHub(context))
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Row(
                      children: [
                        Text(
                          _titleForLocation(context),
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: _colorForLocation(context),
                          ),
                        ),
                        if (actions.isNotEmpty) ...[
                          const SizedBox(width: 16),
                          ...actions.map((btn) {
                            final iconBtn = btn as IconButton;
                            return Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: TextButton.icon(
                                icon: iconBtn.icon,
                                label: Text(iconBtn.tooltip ?? ''),
                                style: TextButton.styleFrom(
                                  foregroundColor: _colorForLocation(context),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                                onPressed: iconBtn.onPressed,
                              ),
                            );
                          }),
                        ],
                        const Spacer(),
                      ],
                    ),
                  ),
                // Scrollable content with max-width
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: AppBreakpoints.maxContentWidth),
                      child: child,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Tablet layout (600–1199px)
  // ---------------------------------------------------------------------------

  Widget _buildTabletLayout(BuildContext context) {
    // Full-screen modal routes skip shell chrome on mobile
    if (_isMobileFullScreen(context)) return child;

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
      ),
      drawer: _buildDrawer(context),
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: selectedIndex,
            labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: Text('Home')),
              NavigationRailDestination(icon: Icon(Icons.book_outlined), selectedIcon: Icon(Icons.book), label: Text('Diario')),
              NavigationRailDestination(icon: Icon(Icons.add_circle_outline), selectedIcon: Icon(Icons.add_circle), label: Text('+')),
              NavigationRailDestination(icon: Icon(Icons.bar_chart_outlined), selectedIcon: Icon(Icons.bar_chart), label: Text('Progreso')),
              NavigationRailDestination(icon: Icon(Icons.person_outlined), selectedIcon: Icon(Icons.person), label: Text('Perfil')),
            ],
            onDestinationSelected: (index) {
              switch (index) {
                case 0: GoRouter.of(context).go(AppRoutes.home);
                case 1: _showDiarySheet(context);
                case 2: _showQuickAddSheet(context);
                case 3: GoRouter.of(context).go(AppRoutes.monitoring);
                case 4: GoRouter.of(context).go(AppRoutes.settings);
              }
            },
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: AppBreakpoints.maxContentWidthMedium),
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
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Phone layout (< 600px)
  // ---------------------------------------------------------------------------

  Widget _buildPhoneLayout(BuildContext context) {
    // Full-screen modal routes skip shell chrome on mobile
    if (_isMobileFullScreen(context)) return child;

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
          const NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          const NavigationDestination(icon: Icon(Icons.book_outlined), selectedIcon: Icon(Icons.book), label: 'Diario'),
          NavigationDestination(icon: Icon(Icons.add_circle, size: 32, color: AppColors.primary), selectedIcon: Icon(Icons.add_circle, size: 32, color: AppColors.primary), label: ''),
          const NavigationDestination(icon: Icon(Icons.bar_chart_outlined), selectedIcon: Icon(Icons.bar_chart), label: 'Progreso'),
          const NavigationDestination(icon: Icon(Icons.person_outlined), selectedIcon: Icon(Icons.person), label: 'Perfil'),
        ],
        onDestinationSelected: (index) {
          switch (index) {
            case 0: GoRouter.of(context).go(AppRoutes.home);
            case 1: _showDiarySheet(context);
            case 2: _showQuickAddSheet(context);
            case 3: GoRouter.of(context).go(AppRoutes.monitoring);
            case 4: GoRouter.of(context).go(AppRoutes.settings);
          }
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    // On web: always show permanent sidebar (desktop layout)
    if (kIsWeb) return _buildDesktopLayout(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= AppBreakpoints.expanded) {
          return _buildDesktopLayout(context);
        }
        if (constraints.maxWidth >= AppBreakpoints.compact) {
          return _buildTabletLayout(context);
        }
        return _buildPhoneLayout(context);
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Desktop sidebar item
// ---------------------------------------------------------------------------

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
    this.selectedIcon,
  });

  final IconData icon;
  final IconData? selectedIcon;
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 1),
      child: Material(
        color: selected ? color.withAlpha(20) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              border: selected
                  ? Border(left: BorderSide(color: color, width: 3))
                  : null,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  selected ? (selectedIcon ?? icon) : icon,
                  size: 20,
                  color: selected ? color : AppColors.lightTextSecondary,
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    color: selected ? color : AppColors.lightTextPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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
