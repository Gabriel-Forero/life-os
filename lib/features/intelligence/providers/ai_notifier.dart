import 'dart:async';

import 'package:drift/drift.dart';
import 'package:life_os/core/database/app_database.dart';
import 'package:life_os/core/domain/app_failure.dart';
import 'package:life_os/core/domain/result.dart';
import 'package:life_os/core/services/app_logger.dart';
import 'package:life_os/features/intelligence/database/ai_dao.dart';
import 'package:life_os/features/intelligence/domain/ai_context_builder.dart';
import 'package:life_os/features/intelligence/domain/ai_provider.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class AIState {
  const AIState({
    this.configurations = const [],
    this.conversations = const [],
    this.activeConversationId,
    this.messages = const [],
    this.isStreaming = false,
    this.streamBuffer = '',
    this.isLoading = false,
    this.errorMessage,
  });

  final List<AiConfiguration> configurations;
  final List<AiConversation> conversations;
  final int? activeConversationId;
  final List<AiMessage> messages;
  final bool isStreaming;
  final String streamBuffer;
  final bool isLoading;
  final String? errorMessage;

  AIState copyWith({
    List<AiConfiguration>? configurations,
    List<AiConversation>? conversations,
    int? activeConversationId,
    List<AiMessage>? messages,
    bool? isStreaming,
    String? streamBuffer,
    bool? isLoading,
    String? errorMessage,
  }) {
    return AIState(
      configurations: configurations ?? this.configurations,
      conversations: conversations ?? this.conversations,
      activeConversationId: activeConversationId ?? this.activeConversationId,
      messages: messages ?? this.messages,
      isStreaming: isStreaming ?? this.isStreaming,
      streamBuffer: streamBuffer ?? this.streamBuffer,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

/// Manages AI conversations, messages, and provider configuration.
class AINotifier {
  AINotifier({
    required this.dao,
    required this.providerFactory,
    AppLogger? logger,
  }) : _logger = logger ?? AppLogger(tag: 'AINotifier');

  final AiDao dao;

  /// Factory that returns an [AIProvider] given a configuration.
  /// Injected so tests can provide a mock provider.
  final AIProvider Function(AiConfiguration config) providerFactory;

  final AppLogger _logger;
  final _subscriptions = <StreamSubscription<dynamic>>[];

  AIState _state = const AIState();
  AIState get state => _state;

  void Function(AIState)? onStateChanged;

  void _emit(AIState next) {
    _state = next;
    onStateChanged?.call(next);
  }

  // ---------------------------------------------------------------------------
  // Initialization
  // ---------------------------------------------------------------------------

  Future<void> initialize() async {
    _emit(_state.copyWith(isLoading: true));
    try {
      final configs = await dao.getAllConfigurations();
      final conversations = await dao.getAllConversations();
      _emit(_state.copyWith(
        configurations: configs,
        conversations: conversations,
        isLoading: false,
      ));

      _subscriptions.add(
        dao.watchAllConfigurations().listen((configs) {
          _emit(_state.copyWith(configurations: configs));
        }),
      );
      _subscriptions.add(
        dao.watchAllConversations().listen((convs) {
          _emit(_state.copyWith(conversations: convs));
        }),
      );
    } on Exception catch (e) {
      _logger.error('AINotifier.initialize failed: $e');
      _emit(_state.copyWith(
        isLoading: false,
        errorMessage: 'Error al inicializar el asistente',
      ));
    }
  }

  void dispose() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();
  }

  // ---------------------------------------------------------------------------
  // Provider Configuration
  // ---------------------------------------------------------------------------

  Future<Result<int>> addConfiguration({
    required String providerKey,
    required String modelName,
    bool isDefault = false,
  }) async {
    if (providerKey.isEmpty) {
      return const Failure(ValidationFailure(
        userMessage: 'Selecciona un proveedor de IA',
        debugMessage: 'providerKey is empty',
        field: 'providerKey',
      ));
    }
    if (!const ['openai', 'anthropic', 'custom'].contains(providerKey)) {
      return const Failure(ValidationFailure(
        userMessage: 'Proveedor no reconocido',
        debugMessage: 'providerKey must be openai|anthropic|custom',
        field: 'providerKey',
      ));
    }
    if (modelName.trim().isEmpty) {
      return const Failure(ValidationFailure(
        userMessage: 'Ingresa el nombre del modelo',
        debugMessage: 'modelName is empty',
        field: 'modelName',
      ));
    }

    try {
      final now = DateTime.now();
      final id = await dao.insertConfiguration(AiConfigurationsCompanion.insert(
        providerKey: providerKey,
        modelName: modelName.trim(),
        isDefault: Value(isDefault),
        createdAt: now,
        updatedAt: now,
      ));
      if (isDefault) {
        await dao.setDefaultConfiguration(id);
      }
      return Success(id);
    } on Exception catch (e) {
      return Failure(DatabaseFailure(
        userMessage: 'Error al guardar la configuracion',
        debugMessage: 'insertConfiguration failed: $e',
        originalError: e,
      ));
    }
  }

  Future<Result<void>> setDefaultProvider(int configId) async {
    try {
      await dao.setDefaultConfiguration(configId);
      return const Success(null);
    } on Exception catch (e) {
      return Failure(DatabaseFailure(
        userMessage: 'Error al cambiar proveedor predeterminado',
        debugMessage: 'setDefaultConfiguration failed: $e',
        originalError: e,
      ));
    }
  }

  Future<Result<void>> deleteConfiguration(int configId) async {
    try {
      await dao.deleteConfiguration(configId);
      return const Success(null);
    } on Exception catch (e) {
      return Failure(DatabaseFailure(
        userMessage: 'Error al eliminar la configuracion',
        debugMessage: 'deleteConfiguration failed: $e',
        originalError: e,
      ));
    }
  }

  // ---------------------------------------------------------------------------
  // Conversations
  // ---------------------------------------------------------------------------

  Future<Result<int>> createConversation({
    required String title,
    int? configId,
  }) async {
    final trimmed = title.trim();
    if (trimmed.isEmpty || trimmed.length > 100) {
      return const Failure(ValidationFailure(
        userMessage: 'El titulo debe tener entre 1 y 100 caracteres',
        debugMessage: 'conversation title out of range',
        field: 'title',
      ));
    }

    try {
      final now = DateTime.now();
      final id = await dao.insertConversation(
        AiConversationsCompanion.insert(
          configId: Value(configId),
          title: trimmed,
          createdAt: now,
          updatedAt: now,
        ),
      );
      _emit(_state.copyWith(activeConversationId: id, messages: []));
      return Success(id);
    } on Exception catch (e) {
      return Failure(DatabaseFailure(
        userMessage: 'Error al crear la conversacion',
        debugMessage: 'insertConversation failed: $e',
        originalError: e,
      ));
    }
  }

  Future<Result<void>> openConversation(int conversationId) async {
    try {
      final messages = await dao.getMessagesForConversation(conversationId);
      _emit(_state.copyWith(
        activeConversationId: conversationId,
        messages: messages,
      ));
      return const Success(null);
    } on Exception catch (e) {
      return Failure(DatabaseFailure(
        userMessage: 'Error al cargar la conversacion',
        debugMessage: 'getMessagesForConversation failed: $e',
        originalError: e,
      ));
    }
  }

  Future<Result<void>> deleteConversation(int conversationId) async {
    try {
      await dao.deleteConversation(conversationId);
      if (_state.activeConversationId == conversationId) {
        // Emit directly to allow clearing nullable activeConversationId to null.
        _emit(AIState(
          configurations: _state.configurations,
          conversations: _state.conversations,
          activeConversationId: null,
          messages: const [],
          isStreaming: _state.isStreaming,
          streamBuffer: _state.streamBuffer,
          isLoading: _state.isLoading,
          errorMessage: _state.errorMessage,
        ));
      }
      return const Success(null);
    } on Exception catch (e) {
      return Failure(DatabaseFailure(
        userMessage: 'Error al eliminar la conversacion',
        debugMessage: 'deleteConversation failed: $e',
        originalError: e,
      ));
    }
  }

  Future<List<AiConversation>> listConversations() =>
      dao.getAllConversations();

  // ---------------------------------------------------------------------------
  // Messaging
  // ---------------------------------------------------------------------------

  /// Sends a user message in [conversationId] and streams the assistant reply.
  ///
  /// The returned [Stream<String>] emits token chunks as they arrive from
  /// the AI provider. The full response is persisted when streaming completes.
  Stream<String> sendMessage(
    int conversationId,
    String userText, {
    ModuleSummary? context,
  }) async* {
    if (userText.trim().isEmpty) return;

    final config = await dao.getDefaultConfiguration();
    if (config == null) {
      yield '[Error: No hay proveedor de IA configurado]';
      return;
    }

    final now = DateTime.now();

    // Persist user message
    await dao.insertMessage(AiMessagesCompanion.insert(
      conversationId: conversationId,
      role: 'user',
      content: userText.trim(),
      tokenCount: const Value(null),
      createdAt: now,
    ));

    // Update conversation updatedAt
    await dao.updateConversationTitle(
      conversationId,
      _state.conversations
              .where((c) => c.id == conversationId)
              .firstOrNull
              ?.title ??
          'Conversacion',
    );

    final systemContext =
        context != null ? buildAIContext(context) : null;

    final provider = providerFactory(config);
    final buffer = StringBuffer();

    _emit(_state.copyWith(isStreaming: true, streamBuffer: ''));

    try {
      await for (final chunk in provider.sendMessage(
        userText.trim(),
        systemContext: systemContext,
      )) {
        buffer.write(chunk);
        _emit(_state.copyWith(streamBuffer: buffer.toString()));
        yield chunk;
      }
    } on Exception catch (e) {
      _logger.error('AIProvider.sendMessage failed: $e');
      yield '[Error al conectar con el proveedor de IA]';
    }

    // Persist assistant message
    final fullResponse = buffer.toString();
    if (fullResponse.isNotEmpty) {
      await dao.insertMessage(AiMessagesCompanion.insert(
        conversationId: conversationId,
        role: 'assistant',
        content: fullResponse,
        tokenCount: const Value(null),
        createdAt: DateTime.now(),
      ));
    }

    // Refresh messages
    final messages = await dao.getMessagesForConversation(conversationId);
    _emit(_state.copyWith(
      messages: messages,
      isStreaming: false,
      streamBuffer: '',
    ));
  }
}
