sealed class AppFailure {
  const AppFailure({
    required this.userMessage,
    required this.debugMessage,
  });

  final String userMessage;
  final String debugMessage;

  @override
  String toString() => '$runtimeType(userMessage: $userMessage)';
}

final class DatabaseFailure extends AppFailure {
  const DatabaseFailure({
    required super.userMessage,
    required super.debugMessage,
    this.originalError,
  });

  final Object? originalError;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DatabaseFailure &&
          other.userMessage == userMessage &&
          other.debugMessage == debugMessage;

  @override
  int get hashCode => Object.hash(userMessage, debugMessage);
}

final class NetworkFailure extends AppFailure {
  const NetworkFailure({
    required super.userMessage,
    required super.debugMessage,
    this.statusCode,
    this.url,
  });

  final int? statusCode;
  final String? url;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NetworkFailure &&
          other.userMessage == userMessage &&
          other.debugMessage == debugMessage &&
          other.statusCode == statusCode;

  @override
  int get hashCode => Object.hash(userMessage, debugMessage, statusCode);
}

final class ValidationFailure extends AppFailure {
  const ValidationFailure({
    required super.userMessage,
    required super.debugMessage,
    this.field,
    this.value,
  });

  final String? field;
  final Object? value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ValidationFailure &&
          other.userMessage == userMessage &&
          other.debugMessage == debugMessage &&
          other.field == field;

  @override
  int get hashCode => Object.hash(userMessage, debugMessage, field);
}

final class NotFoundFailure extends AppFailure {
  const NotFoundFailure({
    required super.userMessage,
    required super.debugMessage,
    required this.entityType,
    required this.entityId,
  });

  final String entityType;
  final Object entityId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotFoundFailure &&
          other.userMessage == userMessage &&
          other.entityType == entityType &&
          other.entityId == entityId;

  @override
  int get hashCode => Object.hash(userMessage, entityType, entityId);
}

final class PermissionFailure extends AppFailure {
  const PermissionFailure({
    required super.userMessage,
    required super.debugMessage,
    required this.permission,
  });

  final String permission;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PermissionFailure &&
          other.userMessage == userMessage &&
          other.permission == permission;

  @override
  int get hashCode => Object.hash(userMessage, permission);
}

final class BackupFailure extends AppFailure {
  const BackupFailure({
    required super.userMessage,
    required super.debugMessage,
    required this.phase,
  });

  final String phase;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BackupFailure &&
          other.userMessage == userMessage &&
          other.phase == phase;

  @override
  int get hashCode => Object.hash(userMessage, phase);
}

final class AuthFailure extends AppFailure {
  const AuthFailure({
    required super.userMessage,
    required super.debugMessage,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthFailure &&
          other.userMessage == userMessage &&
          other.debugMessage == debugMessage;

  @override
  int get hashCode => Object.hash(userMessage, debugMessage);
}
