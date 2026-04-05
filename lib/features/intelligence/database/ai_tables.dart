import 'package:drift/drift.dart';

// ---------------------------------------------------------------------------
// AiConfigurations table
// ---------------------------------------------------------------------------

class AiConfigurations extends Table {
  @override
  String get tableName => 'ai_configurations';

  IntColumn get id => integer().autoIncrement()();

  /// 'openai' | 'anthropic' | 'custom'
  TextColumn get providerKey => text()();

  /// e.g. 'gpt-4o', 'claude-3-5-sonnet-20241022'
  TextColumn get modelName => text()();

  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}

// ---------------------------------------------------------------------------
// AiConversations table
// ---------------------------------------------------------------------------

class AiConversations extends Table {
  @override
  String get tableName => 'ai_conversations';

  IntColumn get id => integer().autoIncrement()();

  /// Nullable FK — config may be deleted while conversation persists.
  IntColumn get configId =>
      integer().nullable().references(AiConfigurations, #id)();

  /// 1–100 characters
  TextColumn get title => text().withLength(min: 1, max: 100)();

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}

// ---------------------------------------------------------------------------
// AiMessages table
// ---------------------------------------------------------------------------

class AiMessages extends Table {
  @override
  String get tableName => 'ai_messages';

  IntColumn get id => integer().autoIncrement()();

  IntColumn get conversationId =>
      integer().references(AiConversations, #id)();

  /// 'user' | 'assistant' | 'system'
  TextColumn get role => text()();

  TextColumn get content => text()();

  /// Filled after receiving the full response; null while streaming.
  IntColumn get tokenCount => integer().nullable()();

  DateTimeColumn get createdAt => dateTime()();
}
