import 'package:life_os/features/intelligence/domain/models/ai_configuration_model.dart';
import 'package:life_os/features/intelligence/domain/models/ai_conversation_model.dart';
import 'package:life_os/features/intelligence/domain/models/ai_message_model.dart';

abstract class AiRepository {
  // --- AiConfigurations CRUD ---

  Future<String> insertConfiguration({
    required String providerKey,
    required String modelName,
    required bool isDefault,
    required DateTime createdAt,
    required DateTime updatedAt,
  });

  Future<void> updateConfiguration(AiConfigurationModel config);

  Future<void> setDefaultConfiguration(String configId);

  Future<void> deleteConfiguration(String configId);

  Future<AiConfigurationModel?> getConfigurationById(String configId);

  Future<AiConfigurationModel?> getDefaultConfiguration();

  Stream<List<AiConfigurationModel>> watchAllConfigurations();

  Future<List<AiConfigurationModel>> getAllConfigurations();

  // --- AiConversations CRUD ---

  Future<String> insertConversation({
    String? configId,
    required String title,
    required DateTime createdAt,
    required DateTime updatedAt,
  });

  Future<void> updateConversationTitle(String conversationId, String title);

  Future<void> deleteConversation(String conversationId);

  Future<AiConversationModel?> getConversationById(String conversationId);

  Stream<List<AiConversationModel>> watchAllConversations();

  Future<List<AiConversationModel>> getAllConversations();

  // --- AiMessages CRUD ---

  Future<String> insertMessage({
    required String conversationId,
    required String role,
    required String content,
    int? tokenCount,
    required DateTime createdAt,
  });

  Future<void> updateMessageTokenCount(String messageId, int tokenCount);

  Future<List<AiMessageModel>> getMessagesForConversation(
    String conversationId,
  );

  Stream<List<AiMessageModel>> watchMessagesForConversation(
    String conversationId,
  );

  // --- Backup / export helpers ---

  Future<List<AiConfigurationModel>> getAllConfigsForExport();

  Future<List<AiConversationModel>> getAllConversationsForExport();

  Future<List<AiMessageModel>> getAllMessagesForExport();
}
