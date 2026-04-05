import 'package:life_os/core/domain/app_failure.dart';
import 'package:life_os/core/domain/result.dart';
import 'package:life_os/features/goals/domain/goals_input.dart';

// ---------------------------------------------------------------------------
// Goal validators
// ---------------------------------------------------------------------------

Result<String> validateGoalName(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) {
    return const Failure(ValidationFailure(
      userMessage: 'El nombre del objetivo no puede estar vacio',
      debugMessage: 'goal name is empty after trim',
      field: 'name',
    ));
  }
  if (trimmed.length > 100) {
    return const Failure(ValidationFailure(
      userMessage: 'El nombre no puede superar los 100 caracteres',
      debugMessage: 'goal name exceeds 100 chars',
      field: 'name',
    ));
  }
  return Success(trimmed);
}

Result<String?> validateGoalDescription(String? description) {
  if (description != null && description.length > 500) {
    return const Failure(ValidationFailure(
      userMessage: 'La descripcion no puede superar los 500 caracteres',
      debugMessage: 'goal description exceeds 500 chars',
      field: 'description',
    ));
  }
  return Success(description);
}

Result<String> validateGoalCategory(String category) {
  final cat = GoalCategory.fromString(category);
  if (cat == null) {
    return Failure(ValidationFailure(
      userMessage: 'Categoria no valida',
      debugMessage:
          'category "$category" not in ${GoalCategory.values.map((c) => c.name)}',
      field: 'category',
      value: category,
    ));
  }
  return Success(cat.name);
}

Result<DateTime?> validateGoalTargetDate(DateTime? targetDate) {
  if (targetDate != null && targetDate.isBefore(DateTime.now())) {
    return const Failure(ValidationFailure(
      userMessage: 'La fecha objetivo debe ser una fecha futura',
      debugMessage: 'targetDate is in the past',
      field: 'targetDate',
    ));
  }
  return Success(targetDate);
}

// ---------------------------------------------------------------------------
// Sub-goal validators
// ---------------------------------------------------------------------------

Result<String> validateSubGoalName(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) {
    return const Failure(ValidationFailure(
      userMessage: 'El nombre del sub-objetivo no puede estar vacio',
      debugMessage: 'sub-goal name is empty after trim',
      field: 'name',
    ));
  }
  if (trimmed.length > 100) {
    return const Failure(ValidationFailure(
      userMessage: 'El nombre del sub-objetivo no puede superar los 100 caracteres',
      debugMessage: 'sub-goal name exceeds 100 chars',
      field: 'name',
    ));
  }
  return Success(trimmed);
}

Result<String?> validateSubGoalDescription(String? description) {
  if (description != null && description.length > 200) {
    return const Failure(ValidationFailure(
      userMessage: 'La descripcion del sub-objetivo no puede superar los 200 caracteres',
      debugMessage: 'sub-goal description exceeds 200 chars',
      field: 'description',
    ));
  }
  return Success(description);
}

Result<double> validateSubGoalWeight(double weight) {
  if (weight <= 0.0 || weight > 1.0) {
    return Failure(ValidationFailure(
      userMessage: 'El peso debe estar entre 0 y 1 (exclusivo de 0)',
      debugMessage: 'sub-goal weight $weight out of range (0, 1.0]',
      field: 'weight',
      value: weight,
    ));
  }
  return Success(weight);
}

/// Validates that existing weights + newWeight sums to 1.0 (within tolerance).
Result<double> validateWeightSum(
  List<double> existingWeights,
  double newWeight,
) {
  const tolerance = 0.001;
  final total = existingWeights.fold(0.0, (sum, w) => sum + w) + newWeight;
  if (total > 1.0 + tolerance) {
    return Failure(ValidationFailure(
      userMessage:
          'La suma de pesos excede 1.0 (actual: ${total.toStringAsFixed(3)})',
      debugMessage: 'weights sum to $total, exceeds 1.0 + $tolerance',
      field: 'weight',
      value: total,
    ));
  }
  return Success(newWeight);
}

Result<int> validateSubGoalProgress(int progress) {
  if (progress < 0 || progress > 100) {
    return Failure(ValidationFailure(
      userMessage: 'El progreso debe estar entre 0 y 100',
      debugMessage: 'sub-goal progress $progress out of range [0, 100]',
      field: 'progress',
      value: progress,
    ));
  }
  return Success(progress);
}

// ---------------------------------------------------------------------------
// Milestone validators
// ---------------------------------------------------------------------------

Result<String> validateMilestoneName(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) {
    return const Failure(ValidationFailure(
      userMessage: 'El nombre del hito no puede estar vacio',
      debugMessage: 'milestone name is empty after trim',
      field: 'name',
    ));
  }
  if (trimmed.length > 100) {
    return const Failure(ValidationFailure(
      userMessage: 'El nombre del hito no puede superar los 100 caracteres',
      debugMessage: 'milestone name exceeds 100 chars',
      field: 'name',
    ));
  }
  return Success(trimmed);
}

Result<int> validateMilestoneTargetProgress(int targetProgress) {
  if (targetProgress < 0 || targetProgress > 100) {
    return Failure(ValidationFailure(
      userMessage: 'El progreso objetivo del hito debe estar entre 0 y 100',
      debugMessage:
          'milestone targetProgress $targetProgress out of range [0, 100]',
      field: 'targetProgress',
      value: targetProgress,
    ));
  }
  return Success(targetProgress);
}

Result<DateTime?> validateMilestoneTargetDate(DateTime? targetDate) {
  if (targetDate != null && targetDate.isBefore(DateTime.now())) {
    return const Failure(ValidationFailure(
      userMessage: 'La fecha del hito debe ser una fecha futura',
      debugMessage: 'milestone targetDate is in the past',
      field: 'targetDate',
    ));
  }
  return Success(targetDate);
}
