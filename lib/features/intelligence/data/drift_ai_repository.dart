import 'package:drift/drift.dart';
import 'package:life_os/core/database/app_database.dart';
import 'package:life_os/features/intelligence/data/ai_repository.dart';
import 'package:life_os/features/intelligence/database/ai_dao.dart';
import 'package:life_os/features/intelligence/domain/models/ai_configuration_model.dart';
import 'package:life_os/features/intelligence/domain/models/ai_conversation_model.dart';
import 'package:life_os/features/intelligence/domain/models/ai_message_model.dart';

class DriftAiRepository implements AiRepository {
  DriftAiRepository({required this.dao});

  final AiDao dao;

  // --- Mapping helpers ---

  static AiConfigurationModel _toConfigModel(AiConfiguration row) =>
      AiConfigurationModel(
        id: row.id.toString(),
        providerKey: row.providerKey,
        modelName: row.modelName,
        isDefault: row.isDefault,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
      );

  static AiConversationModel _toConversationModel(AiConversation row) =>
      AiConversationModel(
        id: row.id.toString(),
        configId: row.configId?.toString(),
        title: row.title,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
      );

  static AiMessageModel _toMessageModel(AiMessage row) => AiMessageModel(
        id: row.id.toString(),
        conversationId: row.conversationId.toString(),
        role: row.role,
        content: row.content,
        tokenCount: row.tokenCount,
        createdAt: row.createdAt,
      );

  // --- AiConfigurations CRUD ---

  @override
  Future<String> insertConfiguration({
    required String providerKey,
    required String modelName,
    required bool isDefault,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) async {
    final id = await dao.insertConfiguration(
      AiConfigurationsCompanion.insert(
        providerKey: providerKey,
        modelName: modelName,
        isDefault: Value(isDefault),
        createdAt: createdAt,
        updatedAt: updatedAt,
      ),
    );
    return id.toString();
  }

  @override
  Future<void> updateConfiguration(AiConfigurationModel config) async {
    final intId = int.tryParse(config.id);
    if (intId == null) return;
    final driftConfig = AiConfiguration(
      id: intId,
      providerKey: config.providerKey,
      modelName: config.modelName,
      isDefault: config.isDefault,
      createdAt: config.createdAt,
      updatedAt: config.updatedAt,
    );
    await dao.updateConfiguration(driftConfig);
  }

  @override
  Future<void> setDefaultConfiguration(String configId) async {
    final intId = int.tryParse(configId);
    if (intId == null) return;
    await dao.setDefaultConfiguration(intId);
  }

  @override
  Future<void> deleteConfiguration(String configId) async {
    final intId = int.tryParse(configId);
    if (intId == null) return;
    await dao.deleteConfiguration(intId);
  }

  @override
  Future<AiConfigurationModel?> getConfigurationById(String configId) async {
    final intId = int.tryParse(configId);
    if (intId == null) return null;
    final row = await dao.getConfigurationById(intId);
    return row != null ? _toConfigModel(row) : null;
  }

  @override
  Future<AiConfigurationModel?> getDefaultConfiguration() async {
    final row = await dao.getDefaultConfiguration();
    return row != null ? _toConfigModel(row) : null;
  }

  @override
  Stream<List<AiConfigurationModel>> watchAllConfigurations() {
    return dao
        .watchAllConfigurations()
        .map((rows) => rows.map(_toConfigModel).toList());
  }

  @override
  Future<List<AiConfigurationModel>> getAllConfigurations() async {
    final rows = await dao.getAllConfigurations();
    return rows.map(_toConfigModel).toList();
  }

  // --- AiConversations CRUD ---

  @override
  Future<String> insertConversation({
    String? configId,
    required String title,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) async {
    final intConfigId = configId != null ? int.tryParse(configId) : null;
    final id = await dao.insertConversation(
      AiConversationsCompanion.insert(
        configId: Value(intConfigId),
        title: title,
        createdAt: createdAt,
        updatedAt: updatedAt,
      ),
    );
    return id.toString();
  }

  @override
  Future<void> updateConversationTitle(
    String conversationId,
    String title,
  ) async {
    final intId = int.tryParse(conversationId);
    if (intId == null) return;
    await dao.updateConversationTitle(intId, title);
  }

  @override
  Future<void> deleteConversation(String conversationId) async {
    final intId = int.tryParse(conversationId);
    if (intId == null) return;
    await dao.deleteConversation(intId);
  }

  @override
  Future<AiConversationModel?> getConversationById(
    String conversationId,
  ) async {
    final intId = int.tryParse(conversationId);
    if (intId == null) return null;
    final row = await dao.getConversationById(intId);
    return row != null ? _toConversationModel(row) : null;
  }

  @override
  Stream<List<AiConversationModel>> watchAllConversations() {
    return dao
        .watchAllConversations()
        .map((rows) => rows.map(_toConversationModel).toList());
  }

  @override
  Future<List<AiConversationModel>> getAllConversations() async {
    final rows = await dao.getAllConversations();
    return rows.map(_toConversationModel).toList();
  }

  // --- AiMessages CRUD ---

  @override
  Future<String> insertMessage({
    required String conversationId,
    required String role,
    required String content,
    int? tokenCount,
    required DateTime createdAt,
  }) async {
    final intConvId = int.parse(conversationId);
    final id = await dao.insertMessage(
      AiMessagesCompanion.insert(
        conversationId: intConvId,
        role: role,
        content: content,
        tokenCount: Value(tokenCount),
        createdAt: createdAt,
      ),
    );
    return id.toString();
  }

  @override
  Future<void> updateMessageTokenCount(
    String messageId,
    int tokenCount,
  ) async {
    final intId = int.tryParse(messageId);
    if (intId == null) return;
    await dao.updateMessageTokenCount(intId, tokenCount);
  }

  @override
  Future<List<AiMessageModel>> getMessagesForConversation(
    String conversationId,
  ) async {
    final intId = int.tryParse(conversationId);
    if (intId == null) return [];
    final rows = await dao.getMessagesForConversation(intId);
    return rows.map(_toMessageModel).toList();
  }

  @override
  Stream<List<AiMessageModel>> watchMessagesForConversation(
    String conversationId,
  ) {
    final intId = int.tryParse(conversationId);
    if (intId == null) return Stream.value([]);
    return dao
        .watchMessagesForConversation(intId)
        .map((rows) => rows.map(_toMessageModel).toList());
  }

  // --- Backup / export helpers ---

  @override
  Future<List<AiConfigurationModel>> getAllConfigsForExport() async {
    final rows = await dao.getAllConfigsForExport();
    return rows.map(_toConfigModel).toList();
  }

  @override
  Future<List<AiConversationModel>> getAllConversationsForExport() async {
    final rows = await dao.getAllConversationsForExport();
    return rows.map(_toConversationModel).toList();
  }

  @override
  Future<List<AiMessageModel>> getAllMessagesForExport() async {
    final rows = await dao.getAllMessagesForExport();
    return rows.map(_toMessageModel).toList();
  }
}
