import 'package:life_os/core/domain/app_failure.dart';
import 'package:life_os/core/domain/result.dart';

const _validTransactionTypes = {'income', 'expense'};

Result<int> validateTransactionAmount(int amountCents) {
  if (amountCents <= 0) {
    return const Failure(
      ValidationFailure(
        userMessage: 'El monto debe ser mayor a \$0',
        debugMessage: 'amountCents must be positive, got: 0 or negative',
        field: 'amountCents',
      ),
    );
  }
  return Success(amountCents);
}

Result<String> validateTransactionType(String type) {
  if (!_validTransactionTypes.contains(type)) {
    return Failure(
      ValidationFailure(
        userMessage: 'Tipo de transaccion no valido',
        debugMessage: 'type must be income or expense, got: $type',
        field: 'type',
        value: type,
      ),
    );
  }
  return Success(type);
}

Result<String?> validateTransactionNote(String? note) {
  if (note == null || note.trim().isEmpty) {
    return const Success(null);
  }
  if (note.length > 200) {
    return const Failure(
      ValidationFailure(
        userMessage: 'La nota no puede exceder 200 caracteres',
        debugMessage: 'note exceeds 200 character limit',
        field: 'note',
      ),
    );
  }
  return Success(note.trim());
}

Result<DateTime> validateTransactionDate(DateTime date) {
  if (date.isAfter(DateTime.now().add(const Duration(minutes: 1)))) {
    return const Failure(
      ValidationFailure(
        userMessage: 'La fecha no puede ser futura',
        debugMessage: 'date is in the future',
        field: 'date',
      ),
    );
  }
  return Success(date);
}

Result<String> validateCategoryName(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) {
    return const Failure(
      ValidationFailure(
        userMessage: 'El nombre es obligatorio',
        debugMessage: 'category name is empty after trim',
        field: 'name',
      ),
    );
  }
  if (trimmed.length > 30) {
    return const Failure(
      ValidationFailure(
        userMessage: 'Maximo 30 caracteres',
        debugMessage: 'category name exceeds 30 chars',
        field: 'name',
      ),
    );
  }
  return Success(trimmed);
}

Result<int> validateBudgetAmount(int amountCents) {
  if (amountCents <= 0) {
    return const Failure(
      ValidationFailure(
        userMessage: 'El presupuesto debe ser mayor a \$0',
        debugMessage: 'budget amountCents must be positive',
        field: 'amountCents',
      ),
    );
  }
  return Success(amountCents);
}

Result<int> validateSavingsGoalTarget(int targetCents) {
  if (targetCents <= 0) {
    return const Failure(
      ValidationFailure(
        userMessage: 'La meta debe ser mayor a \$0',
        debugMessage: 'savings goal targetCents must be positive',
        field: 'targetCents',
      ),
    );
  }
  return Success(targetCents);
}

Result<DateTime?> validateSavingsGoalDeadline(DateTime? deadline) {
  if (deadline == null) {
    return const Success(null);
  }
  if (deadline.isBefore(DateTime.now())) {
    return const Failure(
      ValidationFailure(
        userMessage: 'La fecha limite debe ser futura',
        debugMessage: 'savings goal deadline is in the past',
        field: 'deadline',
      ),
    );
  }
  return Success(deadline);
}
