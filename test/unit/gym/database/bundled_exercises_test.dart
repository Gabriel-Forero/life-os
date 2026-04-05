import 'dart:convert';
import 'dart:typed_data';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_os/core/database/app_database.dart';
import 'package:life_os/features/gym/database/bundled_exercises.dart';
import 'package:life_os/features/gym/database/gym_dao.dart';

// Minimal exercise library used by tests so we don't depend on the real asset.
const _testExercises = [
  {
    'name': 'Press de banca plano',
    'primaryMuscle': 'Pecho',
    'secondaryMuscles': ['Triceps', 'Hombros'],
    'equipment': 'Barra',
    'instructions': 'Bajar barra al pecho y empujar.',
  },
  {
    'name': 'Sentadilla con barra',
    'primaryMuscle': 'Cuadriceps',
    'secondaryMuscles': ['Gluteos', 'Isquiotibiales'],
    'equipment': 'Barra',
    'instructions': 'Bajar hasta paralelo y subir.',
  },
  {
    'name': 'Peso muerto',
    'primaryMuscle': 'Espalda',
    'secondaryMuscles': [],
    'equipment': 'Barra',
    'instructions': 'Levantar barra desde el suelo manteniendo espalda recta.',
  },
];

AppDatabase _createInMemoryDb() => AppDatabase(NativeDatabase.memory());

/// Registers a fake `assets/exercises.json` asset so [rootBundle] can resolve
/// it during tests without needing the actual Flutter asset bundle.
void _registerFakeExercisesAsset(List<Map<String, Object?>> exercises) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMessageHandler('flutter/assets', (ByteData? message) async {
    final key = utf8.decode(message!.buffer.asUint8List());
    if (key == 'assets/exercises.json') {
      final encoded = utf8.encode(jsonEncode(exercises));
      return encoded.buffer.asByteData();
    }
    return null;
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late GymDao dao;

  setUp(() {
    db = _createInMemoryDb();
    dao = db.gymDao;
    _registerFakeExercisesAsset(_testExercises);
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', null);
    await db.close();
  });

  group('loadBundledExercises', () {
    test('inserts all items from the JSON asset on first call', () async {
      await loadBundledExercises(dao);

      final count = await dao.countExercises();
      expect(count, _testExercises.length);
    });

    test('stores name and primary muscle correctly', () async {
      await loadBundledExercises(dao);

      final results = await dao.watchExercises(muscleGroup: 'Pecho').first;
      expect(results, hasLength(1));
      expect(results.first.name, 'Press de banca plano');
      expect(results.first.equipment, 'Barra');
      expect(results.first.isCustom, isFalse);
      expect(results.first.isDownloaded, isTrue);
    });

    test('encodes non-empty secondary muscles as JSON string', () async {
      await loadBundledExercises(dao);

      final results =
          await dao.watchExercises(query: 'Press de banca').first;
      expect(results, hasLength(1));
      final sm = results.first.secondaryMuscles;
      expect(sm, isNotNull);
      expect(jsonDecode(sm!), containsAll(['Triceps', 'Hombros']));
    });

    test('stores null for empty secondary muscles list', () async {
      await loadBundledExercises(dao);

      final results = await dao.watchExercises(query: 'Peso muerto').first;
      expect(results, hasLength(1));
      // Empty list in JSON -> secondaryMuscles should be null in DB.
      expect(results.first.secondaryMuscles, isNull);
    });

    test('is idempotent — skips insert when data already exists', () async {
      await loadBundledExercises(dao);
      final countAfterFirst = await dao.countExercises();
      expect(countAfterFirst, _testExercises.length);

      await loadBundledExercises(dao);
      final countAfterSecond = await dao.countExercises();
      expect(countAfterSecond, _testExercises.length,
          reason: 'loadBundledExercises should skip insert when count > 0');
    });
  });
}
