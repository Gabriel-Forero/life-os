import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_os/core/database/app_database.dart';
import 'package:life_os/features/intelligence/database/ai_dao.dart';

AppDatabase _createInMemoryDb() => AppDatabase(NativeDatabase.memory());

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Future<int> _insertConfig(
  AiDao dao, {
  String providerKey = 'openai',
  String modelName = 'gpt-4o',
  bool isDefault = false,
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

Future<int> _insertConversation(
  AiDao dao, {
  int? configId,
  String title = 'Test Conversation',
}) {
  final now = DateTime.now();
  return dao.insertConversation(AiConversationsCompanion.insert(
    configId: Value(configId),
    title: title,
    createdAt: now,
    updatedAt: now,
  ));
}

Future<int> _insertMessage(
  AiDao dao, {
  required int conversationId,
  String role = 'user',
  String content = 'Hello',
  int? tokenCount,
}) {
  return dao.insertMessage(AiMessagesCompanion.insert(
    conversationId: conversationId,
    role: role,
    content: content,
    tokenCount: Value(tokenCount),
    createdAt: DateTime.now(),
  ));
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late AppDatabase db;
  late AiDao dao;

  setUp(() {
    db = _createInMemoryDb();
    dao = AiDao(db);
  });

  tearDown(() => db.close());

  // -------------------------------------------------------------------------
  // AiConfigurations
  // -------------------------------------------------------------------------

  group('AiConfigurations CRUD', () {
    test('insert and retrieve configuration', () async {
      final id = await _insertConfig(
        dao,
        providerKey: 'openai',
        modelName: 'gpt-4o',
        isDefault: true,
      );

      final config = await dao.getConfigurationById(id);
      expect(config, isNotNull);
      expect(config!.providerKey, equals('openai'));
      expect(config.modelName, equals('gpt-4o'));
      expect(config.isDefault, isTrue);
    });

    test('getDefaultConfiguration returns single default', () async {
      await _insertConfig(dao, modelName: 'gpt-4', isDefault: false);
      final id2 = await _insertConfig(
        dao,
        modelName: 'gpt-4o',
        isDefault: true,
      );

      final def = await dao.getDefaultConfiguration();
      expect(def, isNotNull);
      expect(def!.id, equals(id2));
    });

    test('setDefaultConfiguration clears previous default', () async {
      final id1 = await _insertConfig(dao, modelName: 'gpt-4', isDefault: true);
      final id2 = await _insertConfig(
        dao,
        modelName: 'gpt-4o',
        isDefault: false,
      );

      await dao.setDefaultConfiguration(id2);

      final c1 = await dao.getConfigurationById(id1);
      final c2 = await dao.getConfigurationById(id2);
      expect(c1!.isDefault, isFalse);
      expect(c2!.isDefault, isTrue);
    });

    test('deleteConfiguration removes it', () async {
      final id = await _insertConfig(dao);
      await dao.deleteConfiguration(id);
      final config = await dao.getConfigurationById(id);
      expect(config, isNull);
    });

    test('getAllConfigurations returns list ordered default first', () async {
      await _insertConfig(dao, modelName: 'model-a', isDefault: false);
      await _insertConfig(dao, modelName: 'model-b', isDefault: true);

      final all = await dao.getAllConfigurations();
      expect(all.length, equals(2));
      // Default first
      expect(all.first.isDefault, isTrue);
    });

    test('updateConfiguration persists changes', () async {
      final id = await _insertConfig(
        dao,
        modelName: 'gpt-4',
        isDefault: false,
      );
      final config = await dao.getConfigurationById(id);
      expect(config, isNotNull);
      await dao.updateConfiguration(
        config!.copyWith(modelName: 'gpt-4o', isDefault: false),
      );
      final updated = await dao.getConfigurationById(id);
      expect(updated!.modelName, equals('gpt-4o'));
    });
  });

  // -------------------------------------------------------------------------
  // AiConversations
  // -------------------------------------------------------------------------

  group('AiConversations CRUD', () {
    test('insert and retrieve conversation', () async {
      final configId = await _insertConfig(dao);
      final convId = await _insertConversation(
        dao,
        configId: configId,
        title: 'Mi primera conversacion',
      );

      final conv = await dao.getConversationById(convId);
      expect(conv, isNotNull);
      expect(conv!.title, equals('Mi primera conversacion'));
      expect(conv.configId, equals(configId));
    });

    test('deleteConversation also removes its messages', () async {
      final configId = await _insertConfig(dao);
      final convId = await _insertConversation(dao, configId: configId);
      await _insertMessage(dao, conversationId: convId, role: 'user');
      await _insertMessage(dao, conversationId: convId, role: 'assistant');

      await dao.deleteConversation(convId);

      final conv = await dao.getConversationById(convId);
      expect(conv, isNull);

      final msgs = await dao.getMessagesForConversation(convId);
      expect(msgs, isEmpty);
    });

    test('watchAllConversations streams updates', () async {
      final convId = await _insertConversation(dao, title: 'Convs A');

      final future = dao.watchAllConversations().first;
      final list = await future;
      expect(list.any((c) => c.id == convId), isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // AiMessages
  // -------------------------------------------------------------------------

  group('AiMessages CRUD', () {
    late int convId;

    setUp(() async {
      final configId = await _insertConfig(dao);
      convId = await _insertConversation(dao, configId: configId);
    });

    test('insert user and assistant messages', () async {
      await _insertMessage(
        dao,
        conversationId: convId,
        role: 'user',
        content: 'Hola!',
      );
      await _insertMessage(
        dao,
        conversationId: convId,
        role: 'assistant',
        content: 'Hola! Como puedo ayudarte?',
      );

      final msgs = await dao.getMessagesForConversation(convId);
      expect(msgs.length, equals(2));
      expect(msgs.first.role, equals('user'));
      expect(msgs.last.role, equals('assistant'));
    });

    test('getMessagesForConversation ordered by createdAt ASC', () async {
      final now = DateTime.now();
      await dao.insertMessage(AiMessagesCompanion.insert(
        conversationId: convId,
        role: 'user',
        content: 'First',
        tokenCount: const Value(null),
        createdAt: now,
      ));
      await dao.insertMessage(AiMessagesCompanion.insert(
        conversationId: convId,
        role: 'assistant',
        content: 'Second',
        tokenCount: const Value(null),
        createdAt: now.add(const Duration(seconds: 1)),
      ));

      final msgs = await dao.getMessagesForConversation(convId);
      expect(msgs.first.content, equals('First'));
      expect(msgs.last.content, equals('Second'));
    });

    test('updateMessageTokenCount persists value', () async {
      final msgId = await _insertMessage(
        dao,
        conversationId: convId,
        role: 'assistant',
        content: 'Response',
      );
      await dao.updateMessageTokenCount(msgId, 42);

      final msgs = await dao.getMessagesForConversation(convId);
      final msg = msgs.firstWhere((m) => m.id == msgId);
      expect(msg.tokenCount, equals(42));
    });

    test('tokenCount is nullable', () async {
      final msgId = await _insertMessage(
        dao,
        conversationId: convId,
        role: 'user',
        content: 'Pending',
        tokenCount: null,
      );
      final msgs = await dao.getMessagesForConversation(convId);
      final msg = msgs.firstWhere((m) => m.id == msgId);
      expect(msg.tokenCount, isNull);
    });
  });

  // -------------------------------------------------------------------------
  // Export helpers
  // -------------------------------------------------------------------------

  group('Export helpers', () {
    test('getAllConfigsForExport returns all rows', () async {
      await _insertConfig(dao, modelName: 'model-1');
      await _insertConfig(dao, modelName: 'model-2');

      final configs = await dao.getAllConfigsForExport();
      expect(configs.length, equals(2));
    });

    test('getAllConversationsForExport returns all rows', () async {
      final configId = await _insertConfig(dao);
      await _insertConversation(dao, configId: configId, title: 'A');
      await _insertConversation(dao, configId: configId, title: 'B');

      final convs = await dao.getAllConversationsForExport();
      expect(convs.length, equals(2));
    });

    test('getAllMessagesForExport returns all rows', () async {
      final configId = await _insertConfig(dao);
      final convId = await _insertConversation(dao, configId: configId);
      await _insertMessage(dao, conversationId: convId, role: 'user');
      await _insertMessage(dao, conversationId: convId, role: 'assistant');

      final msgs = await dao.getAllMessagesForExport();
      expect(msgs.length, equals(2));
    });
  });
}
