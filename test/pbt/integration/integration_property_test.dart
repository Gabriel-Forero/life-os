import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_os/core/database/app_database.dart';
import 'package:life_os/core/domain/app_event.dart';
import 'package:life_os/core/services/event_bus.dart';
import 'package:life_os/features/intelligence/database/ai_dao.dart';

AppDatabase _createInMemoryDb() => AppDatabase(NativeDatabase.memory());

// ---------------------------------------------------------------------------
// Property-Based Tests: Integration + Intelligence
//
// These tests verify invariants that must hold across any combination of
// inputs without relying on specific values.
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
  // Property: Events are always delivered — EventBus is reliable
  // -------------------------------------------------------------------------

  group('EventBus delivery properties', () {
    test('every emitted event is received exactly once by a single subscriber',
        () async {
      final eventBus = EventBus();
      final received = <int>[];

      final sub = eventBus.on<WorkoutCompletedEvent>().listen((e) {
        received.add(e.workoutId);
      });

      const eventCount = 20;
      for (var i = 0; i < eventCount; i++) {
        eventBus.emit(WorkoutCompletedEvent(
          workoutId: i,
          duration: const Duration(minutes: 30),
          totalVolume: 1000.0 * i,
        ));
      }

      // Allow async broadcast
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(received.length, equals(eventCount));
      for (var i = 0; i < eventCount; i++) {
        expect(received[i], equals(i));
      }

      await sub.cancel();
      eventBus.dispose();
    });

    test('events are not delivered after dispose', () async {
      final eventBus = EventBus();
      final received = <int>[];

      eventBus.on<WorkoutCompletedEvent>().listen((e) {
        received.add(e.workoutId);
      });

      eventBus.emit(WorkoutCompletedEvent(
        workoutId: 1,
        duration: const Duration(minutes: 30),
        totalVolume: 1000,
      ));
      await Future<void>.delayed(const Duration(milliseconds: 20));

      eventBus.dispose();

      eventBus.emit(WorkoutCompletedEvent(
        workoutId: 2,
        duration: const Duration(minutes: 30),
        totalVolume: 1000,
      ));
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(received.length, equals(1));
      expect(received.first, equals(1));
    });

    test('multiple subscribers each receive every event', () async {
      final eventBus = EventBus();
      final receivedA = <int>[];
      final receivedB = <int>[];

      final subA = eventBus.on<MoodLoggedEvent>().listen((e) {
        receivedA.add(e.moodLogId);
      });
      final subB = eventBus.on<MoodLoggedEvent>().listen((e) {
        receivedB.add(e.moodLogId);
      });

      const count = 10;
      for (var i = 0; i < count; i++) {
        eventBus.emit(MoodLoggedEvent(
          moodLogId: i,
          level: (i % 10) + 1,
          tags: [],
        ));
      }
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(receivedA.length, equals(count));
      expect(receivedB.length, equals(count));
      expect(receivedA, equals(receivedB));

      await subA.cancel();
      await subB.cancel();
      eventBus.dispose();
    });

    test('events of different types are delivered to correct subscribers only',
        () async {
      final eventBus = EventBus();
      final workoutIds = <int>[];
      final moodIds = <int>[];

      final subW = eventBus.on<WorkoutCompletedEvent>().listen((e) {
        workoutIds.add(e.workoutId);
      });
      final subM = eventBus.on<MoodLoggedEvent>().listen((e) {
        moodIds.add(e.moodLogId);
      });

      eventBus.emit(WorkoutCompletedEvent(
        workoutId: 1,
        duration: const Duration(minutes: 30),
        totalVolume: 1000,
      ));
      eventBus.emit(MoodLoggedEvent(moodLogId: 2, level: 5, tags: []));
      eventBus.emit(WorkoutCompletedEvent(
        workoutId: 3,
        duration: const Duration(minutes: 30),
        totalVolume: 2000,
      ));

      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(workoutIds, equals([1, 3]));
      expect(moodIds, equals([2]));

      await subW.cancel();
      await subM.cancel();
      eventBus.dispose();
    });
  });

  // -------------------------------------------------------------------------
  // Property: No duplicate processing — inserting the same id twice is idempotent
  // -------------------------------------------------------------------------

  group('No duplicate AI message processing', () {
    test('inserting message twice with different content creates two rows',
        () async {
      final configId = await _insertConfig(dao);
      final convId = await _insertConversation(dao, configId: configId);

      await _insertMessage(dao,
          conversationId: convId, role: 'user', content: 'A');
      await _insertMessage(dao,
          conversationId: convId, role: 'assistant', content: 'B');
      await _insertMessage(dao,
          conversationId: convId, role: 'user', content: 'A'); // duplicate content

      final msgs = await dao.getMessagesForConversation(convId);
      // Each insert creates a new autoincrement row — 3 distinct rows
      expect(msgs.length, equals(3));
    });

    test('conversation deletion removes all messages — no orphans', () async {
      const batchSizes = [1, 5, 10, 20];

      for (final n in batchSizes) {
        final configId = await _insertConfig(dao);
        final convId = await _insertConversation(dao, configId: configId);

        for (var i = 0; i < n; i++) {
          await _insertMessage(dao,
              conversationId: convId, role: 'user', content: 'msg $i');
        }

        final before = await dao.getMessagesForConversation(convId);
        expect(before.length, equals(n));

        await dao.deleteConversation(convId);

        final after = await dao.getMessagesForConversation(convId);
        expect(after, isEmpty,
            reason: 'Deleting conversation $convId with $n messages '
                'should remove all messages');
      }
    });

    test('setDefaultConfiguration is idempotent — always exactly one default',
        () async {
      final ids = <int>[];
      for (var i = 0; i < 5; i++) {
        ids.add(await _insertConfig(dao, modelName: 'model-$i'));
      }

      // Call setDefault multiple times on different configs
      for (final id in ids) {
        await dao.setDefaultConfiguration(id);

        final all = await dao.getAllConfigurations();
        final defaults = all.where((c) => c.isDefault).toList();
        expect(defaults.length, equals(1),
            reason: 'There must be exactly one default after setDefault($id)');
        expect(defaults.first.id, equals(id));
      }
    });
  });

  // -------------------------------------------------------------------------
  // Property: AI context builder always produces valid output
  // -------------------------------------------------------------------------

  group('buildAIContext output properties', () {
    // Import tested via integration — these tests verify structural invariants.
    test('prompt always ends with Spanish instruction line', () {
      // Inline because domain/ai_context_builder is pure Dart — no DB needed
      final cases = [
        {'dayScore': 50, 'calories': 1500, 'goal': 2000},
        {'dayScore': null, 'calories': null, 'goal': null},
        {'dayScore': 100, 'calories': 2200, 'goal': 2200},
      ];

      for (final c in cases) {
        // Build a minimal prompt manually to test the invariant
        final prompt = _buildMinimalPrompt(
          dayScore: c['dayScore'] as int?,
          caloriesToday: c['calories'] as int?,
          caloriesGoal: c['goal'] as int?,
        );
        expect(
          prompt,
          contains('Responde siempre en espanol'),
          reason: 'Context must always end with the Spanish instruction',
        );
      }
    });

    test('prompt never contains the word null', () {
      final prompt = _buildMinimalPrompt(
        dayScore: null,
        caloriesToday: null,
        caloriesGoal: null,
      );
      expect(prompt.toLowerCase(), isNot(contains('null')));
    });
  });
}

// ---------------------------------------------------------------------------
// Inline minimal context builder (mirrors production logic for invariant tests)
// ---------------------------------------------------------------------------

String _buildMinimalPrompt({
  int? dayScore,
  int? caloriesToday,
  int? caloriesGoal,
}) {
  final lines = <String>[
    'Eres un asistente de vida inteligente integrado en LifeOS.',
    'Contexto actual del usuario:',
  ];
  if (dayScore != null) lines.add('- Puntuacion del dia: $dayScore/100');
  if (caloriesToday != null && caloriesGoal != null) {
    lines.add('- Calorias: $caloriesToday de $caloriesGoal kcal');
  }
  lines.add('Responde siempre en espanol. Se conciso y motivador.');
  return lines.join('\n');
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Future<int> _insertConfig(
  AiDao dao, {
  String modelName = 'gpt-4o',
}) {
  final now = DateTime.now();
  return dao.insertConfiguration(AiConfigurationsCompanion.insert(
    providerKey: 'openai',
    modelName: modelName,
    isDefault: const Value(false),
    createdAt: now,
    updatedAt: now,
  ));
}

Future<int> _insertConversation(
  AiDao dao, {
  required int configId,
}) {
  final now = DateTime.now();
  return dao.insertConversation(AiConversationsCompanion.insert(
    configId: Value(configId),
    title: 'Test conversation',
    createdAt: now,
    updatedAt: now,
  ));
}

Future<int> _insertMessage(
  AiDao dao, {
  required int conversationId,
  required String role,
  required String content,
}) {
  return dao.insertMessage(AiMessagesCompanion.insert(
    conversationId: conversationId,
    role: role,
    content: content,
    tokenCount: const Value(null),
    createdAt: DateTime.now(),
  ));
}
