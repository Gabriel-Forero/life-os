import 'package:life_os/core/domain/app_failure.dart';
import 'package:life_os/core/domain/result.dart';

const validFrequencyTypes = {'daily', 'weekly', 'custom'};

Result<String> validateHabitName(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) {
    return const Failure(ValidationFailure(
      userMessage: 'El nombre del habito es obligatorio',
      debugMessage: 'habit name is empty',
      field: 'name',
    ));
  }
  if (trimmed.length > 50) {
    return const Failure(ValidationFailure(
      userMessage: 'Maximo 50 caracteres',
      debugMessage: 'habit name exceeds 50 chars',
      field: 'name',
    ));
  }
  return Success(trimmed);
}

Result<String> validateFrequencyType(String type) {
  if (!validFrequencyTypes.contains(type)) {
    return Failure(ValidationFailure(
      userMessage: 'Frecuencia no valida',
      debugMessage: 'frequencyType "$type" not valid',
      field: 'frequencyType',
      value: type,
    ));
  }
  return Success(type);
}

Result<double> validateQuantitativeValue(double value) {
  if (value <= 0) {
    return const Failure(ValidationFailure(
      userMessage: 'Ingresa una cantidad mayor a 0',
      debugMessage: 'quantitative value must be positive',
      field: 'value',
    ));
  }
  return Success(value);
}
