import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:life_os/core/constants/app_colors.dart';
import 'package:life_os/features/dashboard/presentation/dashboard_screen.dart';
import 'package:life_os/features/dashboard/presentation/day_score_screen.dart';
import 'package:life_os/features/dashboard/presentation/score_history_screen.dart';
import 'package:life_os/features/finance/presentation/add_edit_transaction_screen.dart';
import 'package:life_os/features/finance/presentation/budget_overview_screen.dart';
import 'package:life_os/features/finance/presentation/finance_dashboard_screen.dart';
import 'package:life_os/features/finance/presentation/savings_goals_screen.dart';
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
import 'package:life_os/features/mental/presentation/breathing_screen.dart';
import 'package:life_os/features/mental/presentation/mental_history_screen.dart';
import 'package:life_os/features/mental/presentation/mood_log_screen.dart';
import 'package:life_os/features/nutrition/presentation/daily_nutrition_screen.dart';
import 'package:life_os/features/nutrition/presentation/food_search_screen.dart';
import 'package:life_os/features/nutrition/presentation/meal_log_screen.dart';
import 'package:life_os/features/nutrition/presentation/nutrition_goals_screen.dart';
import 'package:life_os/features/onboarding/presentation/onboarding_shell.dart';
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

  // Habits
  static const String habits = '/habits';
  static const String habitsAdd = '/habits/add';
  static const String habitsDetail = '/habits/detail';

  // Dashboard
  static const String dayScore = '/day-score';
  static const String scoreHistory = '/score-history';

  // Sleep
  static const String sleep = '/sleep';
  static const String sleepHistory = '/sleep/history';
  static const String energy = '/sleep/energy';

  // Mental
  static const String mood = '/mental/mood';
  static const String breathing = '/mental/breathing';
  static const String mentalHistory = '/mental/history';

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
  return GoRouter(
    initialLocation: AppRoutes.onboarding,
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
          // Settings placeholder
          GoRoute(
            path: AppRoutes.settings,
            builder: (context, state) => const _PlaceholderScreen(title: 'Configuracion'),
          ),
        ],
      ),
      // Full-screen routes (outside shell)
      GoRoute(path: AppRoutes.financeAdd, builder: (context, state) => const AddEditTransactionScreen()),
      GoRoute(path: AppRoutes.financeBudgets, builder: (context, state) => const BudgetOverviewScreen()),
      GoRoute(path: AppRoutes.financeSavings, builder: (context, state) => const SavingsGoalsScreen()),
      GoRoute(path: AppRoutes.financeDashboard, builder: (context, state) => const FinanceDashboardScreen()),
      GoRoute(path: AppRoutes.gymExercises, builder: (context, state) => const ExerciseLibraryScreen()),
      GoRoute(path: AppRoutes.gymRoutineBuilder, builder: (context, state) => const RoutineBuilderScreen()),
      GoRoute(path: AppRoutes.gymWorkout, builder: (context, state) => const ActiveWorkoutScreen()),
      GoRoute(path: AppRoutes.gymHistory, builder: (context, state) => const WorkoutHistoryScreen()),
      GoRoute(path: AppRoutes.gymMeasurements, builder: (context, state) => const BodyMeasurementsScreen()),
      GoRoute(path: AppRoutes.nutritionSearch, builder: (context, state) => const FoodSearchScreen()),
      GoRoute(path: AppRoutes.nutritionMealLog, builder: (context, state) => const MealLogScreen()),
      GoRoute(path: AppRoutes.nutritionGoals, builder: (context, state) => const NutritionGoalsScreen()),
      GoRoute(path: AppRoutes.habitsAdd, builder: (context, state) => const AddEditHabitScreen()),
      GoRoute(path: AppRoutes.habitsDetail, builder: (context, state) => const HabitDetailScreen()),
      GoRoute(path: AppRoutes.dayScore, builder: (context, state) => const DayScoreScreen()),
      GoRoute(path: AppRoutes.scoreHistory, builder: (context, state) => const ScoreHistoryScreen()),
      GoRoute(path: AppRoutes.sleep, builder: (context, state) => const SleepLogScreen()),
      GoRoute(path: AppRoutes.sleepHistory, builder: (context, state) => const SleepHistoryScreen()),
      GoRoute(path: AppRoutes.energy, builder: (context, state) => const EnergyTrackerScreen()),
      GoRoute(path: AppRoutes.mood, builder: (context, state) => const MoodLogScreen()),
      GoRoute(path: AppRoutes.breathing, builder: (context, state) => const BreathingScreen()),
      GoRoute(path: AppRoutes.mentalHistory, builder: (context, state) => const MentalHistoryScreen()),
      GoRoute(path: AppRoutes.goalsAdd, builder: (context, state) => const AddEditGoalScreen()),
      GoRoute(
        path: AppRoutes.goalsDetail,
        builder: (context, state) {
          final goalId = int.tryParse(state.uri.queryParameters['id'] ?? '');
          if (goalId == null) return const _PlaceholderScreen(title: 'Detalle Meta');
          return GoalDetailScreen(goalId: goalId);
        },
      ),
      GoRoute(path: AppRoutes.aiConfig, builder: (context, state) => const AIConfigScreen()),
      GoRoute(path: AppRoutes.aiConversations, builder: (context, state) => const ConversationListScreen()),
      GoRoute(
        path: AppRoutes.aiChat,
        builder: (context, state) {
          final conversationId = int.tryParse(state.uri.queryParameters['id'] ?? '');
          final title = state.uri.queryParameters['title'] ?? 'Chat AI';
          if (conversationId == null) return const _PlaceholderScreen(title: 'Chat AI');
          return ChatScreen(conversationId: conversationId, title: title);
        },
      ),
    ],
  );
});

class _AppShell extends StatelessWidget {
  const _AppShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      drawer: Drawer(
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
              leading: Icon(Icons.flag_outlined, color: AppColors.goals),
              title: const Text('Metas'),
              onTap: () { Navigator.pop(context); GoRouter.of(context).go(AppRoutes.goals); },
            ),
            ListTile(
              leading: Icon(Icons.auto_awesome, color: AppColors.dayScore),
              title: const Text('DayScore'),
              onTap: () { Navigator.pop(context); GoRouter.of(context).push(AppRoutes.dayScore); },
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
          ],
        ),
      ),
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
        ],
        onDestinationSelected: (index) {
          final routes = [
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
  }

  int _selectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/finance')) return 1;
    if (location.startsWith('/gym')) return 2;
    if (location.startsWith('/nutrition')) return 3;
    if (location.startsWith('/habits')) return 4;
    return 0;
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
