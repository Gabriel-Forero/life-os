import 'package:drift/drift.dart';
import 'package:life_os/core/database/daos/app_settings_dao.dart';
import 'package:life_os/core/database/tables/app_settings_table.dart';
import 'package:life_os/features/finance/database/finance_dao.dart';
import 'package:life_os/features/finance/database/finance_tables.dart';
import 'package:life_os/features/gym/database/gym_dao.dart';
import 'package:life_os/features/gym/database/gym_tables.dart';
import 'package:life_os/features/nutrition/database/nutrition_dao.dart';
import 'package:life_os/features/nutrition/database/nutrition_tables.dart';
import 'package:life_os/features/habits/database/habits_dao.dart';
import 'package:life_os/features/habits/database/habits_tables.dart';
import 'package:life_os/features/dashboard/database/dashboard_dao.dart';
import 'package:life_os/features/dashboard/database/dashboard_tables.dart';
import 'package:life_os/features/sleep/database/sleep_dao.dart';
import 'package:life_os/features/sleep/database/sleep_tables.dart';
import 'package:life_os/features/mental/database/mental_dao.dart';
import 'package:life_os/features/mental/database/mental_tables.dart';
import 'package:life_os/features/goals/database/goals_dao.dart';
import 'package:life_os/features/goals/database/goals_tables.dart';
import 'package:life_os/features/intelligence/database/ai_dao.dart';
import 'package:life_os/features/intelligence/database/ai_tables.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    AppSettingsTable,
    // Finance
    Transactions,
    Categories,
    Budgets,
    SavingsGoals,
    RecurringTransactions,
    CategoryGroups,
    CategoryGroupMembers,
    GroupBudgets,
    BudgetTemplates,
    BudgetTemplateItems,
    MonthlyBudgetConfigs,
    // Gym
    Exercises,
    Routines,
    RoutineExercises,
    Workouts,
    WorkoutSets,
    BodyMeasurements,
    // Nutrition
    FoodItems,
    MealLogs,
    MealLogItems,
    MealTemplates,
    NutritionGoals,
    WaterLogs,
    // Habits
    Habits,
    HabitLogs,
    // Dashboard
    DayScores,
    ScoreComponents,
    DayScoreConfigs,
    LifeSnapshots,
    // Sleep
    SleepLogs,
    SleepInterruptions,
    EnergyLogs,
    // Mental
    MoodLogs,
    BreathingSessions,
    // Goals
    LifeGoals,
    SubGoals,
    GoalMilestones,
    // Intelligence (Unit 8)
    AiConfigurations,
    AiConversations,
    AiMessages,
  ],
  daos: [
    AppSettingsDao,
    FinanceDao,
    GymDao,
    NutritionDao,
    HabitsDao,
    DashboardDao,
    SleepDao,
    MentalDao,
    GoalsDao,
    AiDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 13;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          if (from < 2) {
            await m.createTable(categories);
            await m.createTable(transactions);
            await m.createTable(budgets);
            await m.createTable(savingsGoals);
            await m.createTable(recurringTransactions);
          }
          if (from < 3) {
            await m.createTable(exercises);
            await m.createTable(routines);
            await m.createTable(routineExercises);
            await m.createTable(workouts);
            await m.createTable(workoutSets);
            await m.createTable(bodyMeasurements);
          }
          if (from < 4) {
            await m.createTable(foodItems);
            await m.createTable(mealLogs);
            await m.createTable(mealLogItems);
            await m.createTable(mealTemplates);
            await m.createTable(nutritionGoals);
            await m.createTable(waterLogs);
          }
          if (from < 5) {
            await m.createTable(habits);
            await m.createTable(habitLogs);
          }
          if (from < 6) {
            await m.createTable(dayScores);
            await m.createTable(scoreComponents);
            await m.createTable(dayScoreConfigs);
            await m.createTable(lifeSnapshots);
          }
          if (from < 7) {
            await m.createTable(sleepLogs);
            await m.createTable(sleepInterruptions);
            await m.createTable(energyLogs);
            await m.createTable(moodLogs);
            await m.createTable(breathingSessions);
          }
          if (from < 8) {
            await m.createTable(lifeGoals);
            await m.createTable(subGoals);
            await m.createTable(goalMilestones);
          }
          if (from < 9) {
            await m.createTable(aiConfigurations);
            await m.createTable(aiConversations);
            await m.createTable(aiMessages);
          }
          if (from < 10) {
            await m.addColumn(routineExercises, routineExercises.dayNumber);
            await m.addColumn(routineExercises, routineExercises.dayName);
          }
          if (from < 11) {
            // v11: Body measurements expansion

            await m.addColumn(bodyMeasurements, bodyMeasurements.neckCm);
            await m.addColumn(bodyMeasurements, bodyMeasurements.shouldersCm);
            await m.addColumn(bodyMeasurements, bodyMeasurements.forearmCm);
            await m.addColumn(bodyMeasurements, bodyMeasurements.thighCm);
            await m.addColumn(bodyMeasurements, bodyMeasurements.calfCm);
            await m.addColumn(bodyMeasurements, bodyMeasurements.hipCm);
            await m.addColumn(bodyMeasurements, bodyMeasurements.muscleMassKg);
            await m.addColumn(
                bodyMeasurements, bodyMeasurements.bodyWaterPercent);
            await m.addColumn(bodyMeasurements, bodyMeasurements.heightCm);
            await m.addColumn(
                bodyMeasurements, bodyMeasurements.photoFrontPath);
            await m.addColumn(
                bodyMeasurements, bodyMeasurements.photoSidePath);
            await m.addColumn(
                bodyMeasurements, bodyMeasurements.photoBackPath);
            await m.addColumn(bodyMeasurements, bodyMeasurements.note);
          }
          if (from < 12) {
            await m.addColumn(budgets, budgets.autoRepeat);
            await m.createTable(budgetTemplates);
            await m.createTable(budgetTemplateItems);
            await m.createTable(monthlyBudgetConfigs);
          }
          if (from < 13) {
            await m.createTable(categoryGroups);
            await m.createTable(categoryGroupMembers);
            await m.createTable(groupBudgets);
          }
        },
      );
}
