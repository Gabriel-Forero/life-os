import 'package:life_os/core/domain/app_failure.dart';
import 'package:life_os/core/domain/result.dart';

const supportedCurrencies = <String>{
  'COP', 'USD', 'EUR', 'MXN', 'ARS', 'PEN', 'CLP', 'BRL',
  'GBP', 'CAD', 'JPY', 'CHF', 'AUD', 'NZD', 'CNY', 'KRW',
  'INR', 'SEK', 'NOK', 'DKK', 'PLN', 'CZK', 'HUF', 'RON',
  'BGN', 'HRK', 'TRY', 'ZAR', 'SGD', 'HKD', 'TWD', 'THB',
};

const validLanguages = <String>{'es', 'en'};

const validPrimaryGoals = <String>{
  'save_money',
  'get_fit',
  'be_disciplined',
  'balance',
};

const validModuleIds = <String>{
  'finance',
  'gym',
  'nutrition',
  'habits',
  'sleep',
  'mental',
  'goals',
};

Result<String> validateRequired(String? value, {required String field}) {
  if (value == null || value.trim().isEmpty) {
    return Failure(
      ValidationFailure(
        userMessage: 'Este campo es obligatorio',
        debugMessage: '$field failed required check: value was ${value == null ? "null" : "empty/whitespace"}',
        field: field,
        value: value,
      ),
    );
  }
  return Success(value.trim());
}

Result<String> validateMaxLength(
  String value, {
  required int maxLength,
  required String field,
}) {
  if (value.length > maxLength) {
    return Failure(
      ValidationFailure(
        userMessage: 'Maximo $maxLength caracteres',
        debugMessage: '$field failed maxLength($maxLength) check: length was ${value.length}',
        field: field,
        value: value,
      ),
    );
  }
  return Success(value);
}

Result<String> validateMinLength(
  String value, {
  required int minLength,
  required String field,
}) {
  if (value.length < minLength) {
    return Failure(
      ValidationFailure(
        userMessage: 'Minimo $minLength caracteres',
        debugMessage: '$field failed minLength($minLength) check: length was ${value.length}',
        field: field,
        value: value,
      ),
    );
  }
  return Success(value);
}

Result<String> validateEnum(
  String value, {
  required Set<String> allowed,
  required String field,
}) {
  if (!allowed.contains(value)) {
    return Failure(
      ValidationFailure(
        userMessage: 'Valor no valido',
        debugMessage: '$field failed enum check: "$value" not in $allowed',
        field: field,
        value: value,
      ),
    );
  }
  return Success(value);
}

Result<num> validateNumericRange(
  num value, {
  required num min,
  required num max,
  required String field,
}) {
  if (value < min || value > max) {
    return Failure(
      ValidationFailure(
        userMessage: 'El valor debe estar entre $min y $max',
        debugMessage: '$field failed range($min..$max) check: value was $value',
        field: field,
        value: value,
      ),
    );
  }
  return Success(value);
}

Result<double> validateCurrency(double value, {required String field}) {
  if (value <= 0) {
    return Failure(
      ValidationFailure(
        userMessage: 'El monto debe ser mayor a cero',
        debugMessage: '$field failed currency check: value was $value (must be positive)',
        field: field,
        value: value,
      ),
    );
  }
  return Success(value);
}

Result<String> validateUserName(String? input) {
  return validateRequired(input, field: 'userName').when(
    success: (trimmed) => validateMinLength(trimmed, minLength: 1, field: 'userName').when(
      success: (value) => validateMaxLength(value, maxLength: 50, field: 'userName'),
      failure: (f) => Failure(f),
    ),
    failure: (f) => Failure(f),
  );
}

Result<String> validateLanguage(String value) =>
    validateEnum(value, allowed: validLanguages, field: 'language');

Result<String> validateCurrencyCode(String value) =>
    validateEnum(
      value.toUpperCase(),
      allowed: supportedCurrencies,
      field: 'currency',
    );

Result<String> validatePrimaryGoal(String value) =>
    validateEnum(value, allowed: validPrimaryGoals, field: 'primaryGoal');

Result<List<String>> validateEnabledModules(List<String> modules) {
  if (modules.isEmpty) {
    return const Failure(
      ValidationFailure(
        userMessage: 'Selecciona al menos un modulo',
        debugMessage: 'enabledModules failed minLength(1) check: list was empty',
        field: 'enabledModules',
      ),
    );
  }
  for (final moduleId in modules) {
    if (!validModuleIds.contains(moduleId)) {
      return Failure(
        ValidationFailure(
          userMessage: 'Modulo no valido: $moduleId',
          debugMessage: 'enabledModules contains invalid module ID: "$moduleId"',
          field: 'enabledModules',
          value: moduleId,
        ),
      );
    }
  }
  return Success(modules);
}
