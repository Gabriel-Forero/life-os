import 'package:drift/drift.dart';
import 'package:life_os/core/database/app_database.dart';
import 'package:life_os/features/intelligence/database/ai_tables.dart';

part 'ai_dao.g.dart';

@DriftAccessor(tables: [AiConfigurations, AiConversations, AiMessages])
class AiDao extends DatabaseAccessor<AppDatabase> with _$AiDaoMixin {
  AiDao(super.db);

  // ---------------------------------------------------------------------------
  // AiConfigurations CRUD
  // ---------------------------------------------------------------------------

  Future<int> insertConfiguration(AiConfigurationsCompanion entry) =>
      into(aiConfigurations).insert(entry);

  Future<void> updateConfiguration(AiConfiguration entry) =>
      (update(aiConfigurations)..where((c) => c.id.equals(entry.id))).write(
        AiConfigurationsCompanion(
          providerKey: Value(entry.providerKey),
          modelName: Value(entry.modelName),
          isDefault: Value(entry.isDefault),
          updatedAt: Value(DateTime.now()),
        ),
      );

  /// Sets a single config as default; clears isDefault on all others.
  Future<void> setDefaultConfiguration(int configId) async {
    await (update(aiConfigurations)).write(
      AiConfigurationsCompanion(
        isDefault: const Value(false),
        updatedAt: Value(DateTime.now()),
      ),
    );
    await (update(aiConfigurations)..where((c) => c.id.equals(configId))).write(
      AiConfigurationsCompanion(
        isDefault: const Value(true),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> deleteConfiguration(int configId) =>
      (delete(aiConfigurations)..where((c) => c.id.equals(configId))).go();

  Future<AiConfiguration?> getConfigurationById(int configId) =>
      (select(aiConfigurations)..where((c) => c.id.equals(configId)))
          .getSingleOrNull();

  Future<AiConfiguration?> getDefaultConfiguration() =>
      (select(aiConfigurations)..where((c) => c.isDefault.equals(true)))
          .getSingleOrNull();

  Stream<List<AiConfiguration>> watchAllConfigurations() =>
      (select(aiConfigurations)
            ..orderBy([
              (c) => OrderingTerm.desc(c.isDefault),
              (c) => OrderingTerm.asc(c.createdAt),
            ]))
          .watch();

  Future<List<AiConfiguration>> getAllConfigurations() =>
      (select(aiConfigurations)
            ..orderBy([
              (c) => OrderingTerm.desc(c.isDefault),
              (c) => OrderingTerm.asc(c.createdAt),
            ]))
          .get();

  // ---------------------------------------------------------------------------
  // AiConversations CRUD
  // ---------------------------------------------------------------------------

  Future<int> insertConversation(AiConversationsCompanion entry) =>
      into(aiConversations).insert(entry);

  Future<void> updateConversationTitle(int conversationId, String title) =>
      (update(aiConversations)
            ..where((c) => c.id.equals(conversationId)))
          .write(
        AiConversationsCompanion(
          title: Value(title),
          updatedAt: Value(DateTime.now()),
        ),
      );

  Future<void> deleteConversation(int conversationId) async {
    await (delete(aiMessages)
          ..where((m) => m.conversationId.equals(conversationId)))
        .go();
    await (delete(aiConversations)..where((c) => c.id.equals(conversationId)))
        .go();
  }

  Future<AiConversation?> getConversationById(int conversationId) =>
      (select(aiConversations)..where((c) => c.id.equals(conversationId)))
          .getSingleOrNull();

  Stream<List<AiConversation>> watchAllConversations() =>
      (select(aiConversations)
            ..orderBy([(c) => OrderingTerm.desc(c.updatedAt)]))
          .watch();

  Future<List<AiConversation>> getAllConversations() =>
      (select(aiConversations)
            ..orderBy([(c) => OrderingTerm.desc(c.updatedAt)]))
          .get();

  // ---------------------------------------------------------------------------
  // AiMessages CRUD
  // ---------------------------------------------------------------------------

  Future<int> insertMessage(AiMessagesCompanion entry) =>
      into(aiMessages).insert(entry);

  Future<void> updateMessageTokenCount(int messageId, int tokenCount) =>
      (update(aiMessages)..where((m) => m.id.equals(messageId))).write(
        AiMessagesCompanion(tokenCount: Value(tokenCount)),
      );

  Future<List<AiMessage>> getMessagesForConversation(int conversationId) =>
      (select(aiMessages)
            ..where((m) => m.conversationId.equals(conversationId))
            ..orderBy([(m) => OrderingTerm.asc(m.createdAt)]))
          .get();

  Stream<List<AiMessage>> watchMessagesForConversation(int conversationId) =>
      (select(aiMessages)
            ..where((m) => m.conversationId.equals(conversationId))
            ..orderBy([(m) => OrderingTerm.asc(m.createdAt)]))
          .watch();

  // ---------------------------------------------------------------------------
  // Backup / export helpers
  // ---------------------------------------------------------------------------

  Future<List<AiConfiguration>> getAllConfigsForExport() =>
      select(aiConfigurations).get();

  Future<List<AiConversation>> getAllConversationsForExport() =>
      select(aiConversations).get();

  Future<List<AiMessage>> getAllMessagesForExport() =>
      select(aiMessages).get();
}
