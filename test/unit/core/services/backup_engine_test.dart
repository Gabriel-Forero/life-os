import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:life_os/core/domain/backup_manifest.dart';
import 'package:life_os/core/domain/result.dart';
import 'package:life_os/core/services/backup_engine.dart';

void main() {
  late BackupEngine engine;

  setUp(() {
    engine = BackupEngine();
  });

  BackupManifest _sampleManifest() => BackupManifest(
        appVersion: '0.1.0',
        exportDate: DateTime.utc(2026, 4, 4, 12, 0),
        deviceInfo: 'Test Device - Android 15',
        driftSchemaVersion: 1,
        modules: const [
          BackupModuleEntry(name: 'settings', recordCount: 1),
          BackupModuleEntry(name: 'finance', recordCount: 10),
        ],
      );

  group('BackupEngine', () {
    test('createZip produces valid ZIP bytes', () {
      final manifest = _sampleManifest();
      final moduleJsons = {
        'settings': jsonEncode([{'id': 1, 'userName': 'Test'}]),
        'finance': jsonEncode(
          List.generate(
            10,
            (i) => {'id': i, 'amount': 100.0 * i},
          ),
        ),
      };

      final zipBytes = engine.createZip(
        manifest: manifest,
        moduleJsons: moduleJsons,
      );

      expect(zipBytes, isNotEmpty);
    });

    test('validateAndParseManifest round-trips with createZip', () {
      final manifest = _sampleManifest();
      final moduleJsons = {
        'settings': jsonEncode([{'id': 1}]),
        'finance': jsonEncode([{'id': 1}]),
      };

      final zipBytes = engine.createZip(
        manifest: manifest,
        moduleJsons: moduleJsons,
      );

      final result = engine.validateAndParseManifest(zipBytes);
      expect(result, isA<Success<BackupManifest>>());

      final parsed = result.valueOrNull!;
      expect(parsed.appVersion, manifest.appVersion);
      expect(parsed.driftSchemaVersion, manifest.driftSchemaVersion);
      expect(parsed.modules.length, manifest.modules.length);
    });

    test('extractModuleData retrieves correct data', () {
      final manifest = _sampleManifest();
      final records = [
        {'id': 1, 'amount': 50.0},
        {'id': 2, 'amount': 100.0},
      ];
      final moduleJsons = {
        'settings': jsonEncode([{'id': 1}]),
        'finance': jsonEncode(records),
      };

      final zipBytes = engine.createZip(
        manifest: manifest,
        moduleJsons: moduleJsons,
      );

      final result = engine.extractModuleData(zipBytes, ['finance']);
      expect(result, isA<Success<Map<String, List<Map<String, dynamic>>>>>());

      final data = result.valueOrNull!;
      expect(data['finance'], hasLength(2));
      expect(data['finance']![0]['amount'], 50.0);
    });
  });

  group('BackupManifest', () {
    test('toJson and fromJson are symmetric', () {
      final manifest = _sampleManifest();
      final json = manifest.toJson();
      final parsed = BackupManifest.fromJson(json);

      expect(parsed.appVersion, manifest.appVersion);
      expect(parsed.deviceInfo, manifest.deviceInfo);
      expect(parsed.driftSchemaVersion, manifest.driftSchemaVersion);
      expect(parsed.modules.length, manifest.modules.length);
    });

    test('fromJson throws on missing fields', () {
      expect(
        () => BackupManifest.fromJson({}),
        throwsA(isA<FormatException>()),
      );
    });

    test('fromJson throws on invalid schema version', () {
      expect(
        () => BackupManifest.fromJson({
          'appVersion': '1.0.0',
          'exportDate': '2026-04-04T00:00:00Z',
          'deviceInfo': 'Test',
          'driftSchemaVersion': -1,
          'modules': [
            {'name': 'settings', 'recordCount': 1},
          ],
        }),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
