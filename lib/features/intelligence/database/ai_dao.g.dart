// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ai_dao.dart';

// ignore_for_file: type=lint
mixin _$AiDaoMixin on DatabaseAccessor<AppDatabase> {
  $AiConfigurationsTable get aiConfigurations =>
      attachedDatabase.aiConfigurations;
  $AiConversationsTable get aiConversations => attachedDatabase.aiConversations;
  $AiMessagesTable get aiMessages => attachedDatabase.aiMessages;
  AiDaoManager get managers => AiDaoManager(this);
}

class AiDaoManager {
  final _$AiDaoMixin _db;
  AiDaoManager(this._db);
  $$AiConfigurationsTableTableManager get aiConfigurations =>
      $$AiConfigurationsTableTableManager(
        _db.attachedDatabase,
        _db.aiConfigurations,
      );
  $$AiConversationsTableTableManager get aiConversations =>
      $$AiConversationsTableTableManager(
        _db.attachedDatabase,
        _db.aiConversations,
      );
  $$AiMessagesTableTableManager get aiMessages =>
      $$AiMessagesTableTableManager(_db.attachedDatabase, _db.aiMessages);
}
