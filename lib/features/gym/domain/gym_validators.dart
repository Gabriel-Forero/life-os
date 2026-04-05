import 'package:life_os/core/domain/app_failure.dart';
import 'package:life_os/core/domain/result.dart';

Result<String> validateExerciseName(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) {
    return const Failure(ValidationFailure(
      userMessage: 'El nombre del ejercicio es obligatorio',
      debugMessage: 'exercise name is empty',
      field: 'name',
    ));
  }
  if (trimmed.length > 100) {
    return const Failure(ValidationFailure(
      userMessage: 'Maximo 100 caracteres',
      debugMessage: 'exercise name exceeds 100 chars',
      field: 'name',
    ));
  }
  return Success(trimmed);
}

Result<int> validateReps(int reps) {
  if (reps <= 0) {
    return const Failure(ValidationFailure(
      userMessage: 'Las repeticiones deben ser mayor a 0',
      debugMessage: 'reps must be positive',
      field: 'reps',
    ));
  }
  return Success(reps);
}

Result<double?> validateWeight(double? weightKg) {
  if (weightKg == null) return const Success(null); // bodyweight
  if (weightKg <= 0) {
    return const Failure(ValidationFailure(
      userMessage: 'El peso debe ser mayor a 0',
      debugMessage: 'weight must be positive or null (bodyweight)',
      field: 'weightKg',
    ));
  }
  return Success(weightKg);
}

Result<int?> validateRIR(int? rir) {
  if (rir == null) return const Success(null);
  if (rir < 0 || rir > 5) {
    return const Failure(ValidationFailure(
      userMessage: 'RIR debe estar entre 0 y 5',
      debugMessage: 'RIR out of range 0-5',
      field: 'rir',
    ));
  }
  return Success(rir);
}

Result<String> validateRoutineName(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) {
    return const Failure(ValidationFailure(
      userMessage: 'El nombre de la rutina es obligatorio',
      debugMessage: 'routine name is empty',
      field: 'name',
    ));
  }
  if (trimmed.length > 50) {
    return const Failure(ValidationFailure(
      userMessage: 'Maximo 50 caracteres',
      debugMessage: 'routine name exceeds 50 chars',
      field: 'name',
    ));
  }
  return Success(trimmed);
}

double? calculate1RM(double? weightKg, int reps) {
  if (weightKg == null || reps <= 0) return null;
  if (reps == 1) return weightKg;
  return weightKg * (1 + reps / 30.0);
}

double kgToLbs(double kg) => kg * 2.20462;
double lbsToKg(double lbs) => lbs / 2.20462;
