import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_os/core/database/app_database.dart';
import 'package:life_os/features/intelligence/database/ai_dao.dart';
import 'package:life_os/features/intelligence/domain/ai_provider.dart';
import 'package:life_os/features/intelligence/providers/ai_notifier.dart';

AppDatabase _createInMemoryDb() => AppDatabase(NativeDatabase.memory());

// ---------------------------------------------------------------------------
// Fake AI provider for testing
// ---------------------------------------------------------------------------

class _FakeAIProvider implements AIProvider {
  _FakeAIProvider({this.responseChunks = const ['Hello ', 'world!']});

  final List<String> responseChunks;
  int callCount = 0;

  @override
  String get providerKey => 'openai';

  @override
  Stream<String> sendMessage(String prompt, {String? systemContext}) async* {
    callCount++;
    for (final chunk in responseChunks) {
      yield chunk;
    }
  }

  @override
  Future<List<String>> listModels() async => ['gpt-4o', 'gpt-4'];
}

class _ErrorAIProvider implements AIProvider {
  @override
  String get providerKey => 'openai';

  @override
  Stream<String> sendMessage(String prompt, {String? systemContext}) async* {
    throw Exception('Network error');
  }

  @override
  Future<List<String>> listModels() async => [];
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Future<int> _insertConfig(
  AiDao dao, {
  String providerKey = 'openai',
  String modelName = 'gpt-4o',
  bool isDefault = true,
}) {
  final now = DateTime.now();
  return dao.insertConfiguration(AiConfigurationsCompanion.insert(
    providerKey: providerKey,
    modelName: modelName,
    isDefault: Value(isDefault),
    createdAt: now,
    updatedAt: now,
  ));
}

AINotifier _buildNotifier(
  AiDao dao,
  AIProvider provider,
) =>
    AINotifier(
      dao: dao,
      providerFactory: (_) => provider,
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late AppDatabase db;
  late AiDao dao;
  late _FakeAIProvider fakeProvider;

  setUp(() {
    db = _createInMemoryDb();
    dao = AiDao(db);
    fakeProvider = _FakeAIProvider();
  });

  tearDown(() => db.close());

  // -------------------------------------------------------------------------
  // Initialization
  // -------------------------------------------------------------------------

  group('initialize', () {
    test('loads configurations and conversations on init', () async {
      await _insertConfig(dao, modelName: 'gpt-4o');
      final notifier = _buildNotifier(dao, fakeProvider);
      await notifier.initialize();

      expect(notifier.state.configurations.length, equals(1));
      expect(notifier.state.conversations, isEmpty);
      notifier.dispose();
    });

    test('initial state has isLoading=false after init', () async {
      final notifier = _buildNotifier(dao, fakeProvider);
      await notifier.initialize();
      expect(notifier.state.isLoading, isFalse);
      notifier.dispose();
    });
  });

  // -------------------------------------------------------------------------
  // Configuration management
  // -------------------------------------------------------------------------

  group('addConfiguration', () {
    test('adds valid configuration', () async {
      final notifier = _buildNotifier(dao, fakeProvider);

      final result = await notifier.addConfiguration(
        providerKey: 'openai',
        modelName: 'gpt-4o',
        isDefault: true,
      );

      expect(result.isSuccess, isTrue);
      final configs = await dao.getAllConfigurations();
      expect(configs.length, equals(1));
      notifier.dispose();
    });

    test('rejects empty providerKey', () async {
      final notifier = _buildNotifier(dao, fakeProvider);
      final result = await notifier.addConfiguration(
        providerKey: '',
        modelName: 'gpt-4o',
      );
      expect(result.isFailure, isTrue);
      notifier.dispose();
    });

    test('rejects unknown providerKey', () async {
      final notifier = _buildNotifier(dao, fakeProvider);
      final result = await notifier.addConfiguration(
        providerKey: 'google',
        modelName: 'gemini',
      );
      expect(result.isFailure, isTrue);
      notifier.dispose();
    });

    test('rejects empty modelName', () async {
      final notifier = _buildNotifier(dao, fakeProvider);
      final result = await notifier.addConfiguration(
        providerKey: 'openai',
        modelName: '   ',
      );
      expect(result.isFailure, isTrue);
      notifier.dispose();
    });
  });

  group('setDefaultProvider', () {
    test('sets default and clears others', () async {
      final notifier = _buildNotifier(dao, fakeProvider);
      final r1 = await notifier.addConfiguration(
        providerKey: 'openai',
        modelName: 'gpt-4',
        isDefault: true,
      );
      final r2 = await notifier.addConfiguration(
        providerKey: 'anthropic',
        modelName: 'claude-3',
        isDefault: false,
      );

      await notifier.setDefaultProvider(r2.valueOrNull!);

      final def = await dao.getDefaultConfiguration();
      expect(def?.id, equals(r2.valueOrNull));
      expect(r1.isSuccess, isTrue);
      notifier.dispose();
    });
  });

  group('deleteConfiguration', () {
    test('removes configuration', () async {
      final notifier = _buildNotifier(dao, fakeProvider);
      final id = await _insertConfig(dao);
      final result = await notifier.deleteConfiguration(id);
      expect(result.isSuccess, isTrue);
      final config = await dao.getConfigurationById(id);
      expect(config, isNull);
      notifier.dispose();
    });
  });

  // -------------------------------------------------------------------------
  // Conversations
  // -------------------------------------------------------------------------

  group('createConversation', () {
    test('creates conversation with valid title', () async {
      final notifier = _buildNotifier(dao, fakeProvider);
      final result = await notifier.createConversation(title: 'Mi chat');
      expect(result.isSuccess, isTrue);
      expect(notifier.state.activeConversationId, equals(result.valueOrNull));
      notifier.dispose();
    });

    test('rejects empty title', () async {
      final notifier = _buildNotifier(dao, fakeProvider);
      final result = await notifier.createConversation(title: '');
      expect(result.isFailure, isTrue);
      notifier.dispose();
    });

    test('rejects title exceeding 100 chars', () async {
      final notifier = _buildNotifier(dao, fakeProvider);
      final result = await notifier.createConversation(title: 'A' * 101);
      expect(result.isFailure, isTrue);
      notifier.dispose();
    });
  });

  group('openConversation', () {
    test('loads messages for conversation', () async {
      final configId = await _insertConfig(dao);
      final notifier = _buildNotifier(dao, fakeProvider);

      final convResult = await notifier.createConversation(
        title: 'Prueba',
        configId: configId,
      );
      final convId = convResult.valueOrNull!;

      await dao.insertMessage(AiMessagesCompanion.insert(
        conversationId: convId,
        role: 'user',
        content: 'Hola',
        tokenCount: const Value(null),
        createdAt: DateTime.now(),
      ));

      await notifier.openConversation(convId);
      expect(notifier.state.messages.length, equals(1));
      notifier.dispose();
    });
  });

  group('deleteConversation', () {
    test('deletes and clears activeConversationId', () async {
      final notifier = _buildNotifier(dao, fakeProvider);
      final result = await notifier.createConversation(title: 'A borrar');
      final convId = result.valueOrNull!;

      await notifier.deleteConversation(convId);
      expect(notifier.state.activeConversationId, isNull);

      final conv = await dao.getConversationById(convId);
      expect(conv, isNull);
      notifier.dispose();
    });
  });

  group('listConversations', () {
    test('returns all conversations from DAO', () async {
      final configId = await _insertConfig(dao);
      final now = DateTime.now();
      await dao.insertConversation(AiConversationsCompanion.insert(
        configId: Value(configId),
        title: 'Conv 1',
        createdAt: now,
        updatedAt: now,
      ));
      await dao.insertConversation(AiConversationsCompanion.insert(
        configId: Value(configId),
        title: 'Conv 2',
        createdAt: now,
        updatedAt: now,
      ));
      final notifier = _buildNotifier(dao, fakeProvider);
      final list = await notifier.listConversations();
      expect(list.length, equals(2));
      notifier.dispose();
    });
  });

  // -------------------------------------------------------------------------
  // sendMessage
  // -------------------------------------------------------------------------

  group('sendMessage', () {
    test('persists user and assistant messages', () async {
      await _insertConfig(dao, isDefault: true);
      final notifier = _buildNotifier(dao, fakeProvider);
      final convResult = await notifier.createConversation(title: 'Chat');
      final convId = convResult.valueOrNull!;

      final chunks = <String>[];
      await for (final chunk in notifier.sendMessage(convId, 'Hola')) {
        chunks.add(chunk);
      }

      final msgs = await dao.getMessagesForConversation(convId);
      expect(msgs.length, equals(2));
      expect(msgs.first.role, equals('user'));
      expect(msgs.last.role, equals('assistant'));
      expect(msgs.first.content, equals('Hola'));
    });

    test('streams token chunks', () async {
      await _insertConfig(dao, isDefault: true);
      fakeProvider = _FakeAIProvider(
        responseChunks: ['Chunk1 ', 'Chunk2 ', 'Chunk3'],
      );
      final notifier = _buildNotifier(dao, fakeProvider);
      final convResult = await notifier.createConversation(title: 'Chat');
      final convId = convResult.valueOrNull!;

      final chunks = <String>[];
      await for (final chunk in notifier.sendMessage(convId, 'Mensaje')) {
        chunks.add(chunk);
      }

      expect(chunks, equals(['Chunk1 ', 'Chunk2 ', 'Chunk3']));
      notifier.dispose();
    });

    test('skips empty user messages', () async {
      await _insertConfig(dao, isDefault: true);
      final notifier = _buildNotifier(dao, fakeProvider);
      final convResult = await notifier.createConversation(title: 'Chat');
      final convId = convResult.valueOrNull!;

      final chunks = <String>[];
      await for (final chunk in notifier.sendMessage(convId, '   ')) {
        chunks.add(chunk);
      }

      expect(chunks, isEmpty);
      final msgs = await dao.getMessagesForConversation(convId);
      expect(msgs, isEmpty);
      notifier.dispose();
    });

    test('yields error chunk when no provider configured', () async {
      // No configuration inserted
      final notifier = _buildNotifier(dao, fakeProvider);
      final convResult = await notifier.createConversation(title: 'Chat');
      final convId = convResult.valueOrNull!;

      final chunks = <String>[];
      await for (final chunk in notifier.sendMessage(convId, 'Hola')) {
        chunks.add(chunk);
      }

      expect(chunks.any((c) => c.contains('Error')), isTrue);
      notifier.dispose();
    });

    test('provider call count increments per message', () async {
      await _insertConfig(dao, isDefault: true);
      final notifier = _buildNotifier(dao, fakeProvider);
      final convResult = await notifier.createConversation(title: 'Chat');
      final convId = convResult.valueOrNull!;

      await for (final _ in notifier.sendMessage(convId, 'Mensaje 1')) {}
      await for (final _ in notifier.sendMessage(convId, 'Mensaje 2')) {}

      expect(fakeProvider.callCount, equals(2));
      notifier.dispose();
    });
  });
}
