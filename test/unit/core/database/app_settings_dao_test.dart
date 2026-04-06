import 'dart:convert';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_os/core/database/app_database.dart';
import 'package:life_os/core/database/daos/app_settings_dao.dart';

AppDatabase _createInMemoryDb() =>
    AppDatabase(NativeDatabase.memory());

void main() {
  late AppDatabase db;
  late AppSettingsDao dao;

  setUp(() {
    db = _createInMemoryDb();
    dao = db.appSettingsDao;
  });

  tearDown(() async {
    await db.close();
  });

  group('AppSettingsDao', () {
    AppSettingsTableCompanion validSettings() =>
        AppSettingsTableCompanion.insert(
          userName: 'Camila',
          language: const Value('es'),
          currency: const Value('COP'),
          primaryGoal: 'balance',
          enabledModules: const Value('["finance","gym"]'),
          themeMode: const Value('dark'),
          useBiometric: const Value(false),
          onboardingCompleted: const Value(false),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

    test('createSettings inserts and returns row id', () async {
      final id = await dao.createSettings(validSettings());
      expect(id, 1);
    });

    test('getSettings returns null when no row exists', () async {
      final result = await dao.getSettings();
      expect(result, isNull);
    });

    test('getSettings returns row after creation', () async {
      await dao.createSettings(validSettings());
      final result = await dao.getSettings();
      expect(result, isNotNull);
      expect(result!.userName, 'Camila');
      expect(result.language, 'es');
      expect(result.currency, 'COP');
      expect(result.primaryGoal, 'balance');
    });

    test('updateLanguage changes language', () async {
      await dao.createSettings(validSettings());
      await dao.updateLanguage('en');
      final result = await dao.getSettings();
      expect(result!.language, 'en');
    });

    test('updateCurrency changes currency', () async {
      await dao.createSettings(validSettings());
      await dao.updateCurrency('USD');
      final result = await dao.getSettings();
      expect(result!.currency, 'USD');
    });

    test('updateUserName changes userName', () async {
      await dao.createSettings(validSettings());
      await dao.updateUserName('Andres');
      final result = await dao.getSettings();
      expect(result!.userName, 'Andres');
    });

    test('updateThemeMode changes themeMode', () async {
      await dao.createSettings(validSettings());
      await dao.updateThemeMode('light');
      final result = await dao.getSettings();
      expect(result!.themeMode, 'light');
    });

    test('updateBiometric toggles useBiometric', () async {
      await dao.createSettings(validSettings());
      await dao.updateBiometric(true);
      final result = await dao.getSettings();
      expect(result!.useBiometric, true);
    });

    test('updatePrimaryGoal changes primaryGoal', () async {
      await dao.createSettings(validSettings());
      await dao.updatePrimaryGoal('get_fit');
      final result = await dao.getSettings();
      expect(result!.primaryGoal, 'get_fit');
    });

    test('updateEnabledModules persists JSON list', () async {
      await dao.createSettings(validSettings());
      await dao.updateEnabledModules(['finance', 'habits', 'sleep']);
      final result = await dao.getSettings();
      final modules =
          (jsonDecode(result!.enabledModules) as List).cast<String>();
      expect(modules, ['finance', 'habits', 'sleep']);
    });

    test('markOnboardingCompleted sets flag to true', () async {
      await dao.createSettings(validSettings());
      await dao.markOnboardingCompleted();
      final result = await dao.getSettings();
      expect(result!.onboardingCompleted, true);
    });

    test('updateSettings updates updatedAt timestamp', () async {
      await dao.createSettings(validSettings());
      final before = await dao.getSettings();
      await Future<void>.delayed(const Duration(milliseconds: 10));
      await dao.updateUserName('Laura');
      final after = await dao.getSettings();
      expect(
        after!.updatedAt.millisecondsSinceEpoch,
        greaterThanOrEqualTo(before!.updatedAt.millisecondsSinceEpoch),
      );
    });

    test('watchSettings emits on changes', () async {
      await dao.createSettings(validSettings());

      final stream = dao.watchSettings();
      final expectation = expectLater(
        stream.map((s) => s?.userName),
        emitsInOrder(['Camila', 'Laura']),
      );

      await dao.updateUserName('Laura');
      await expectation;
    });

    test('userName length constraint rejects empty string', () async {
      final settings = AppSettingsTableCompanion.insert(
        userName: '',
        primaryGoal: 'balance',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(
        () => dao.createSettings(settings),
        throwsA(isA<InvalidDataException>()),
      );
    });
  });
}
