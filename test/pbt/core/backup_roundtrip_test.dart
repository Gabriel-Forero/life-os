import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:life_os/core/domain/backup_manifest.dart';
import 'package:life_os/core/domain/result.dart';
import 'package:life_os/core/services/backup_engine.dart';

import '../generators/backup_manifest_generator.dart';

void main() {
  late BackupEngine engine;

  setUp(() {
    engine = BackupEngine();
  });

  group('RT-01 to RT-05: Backup round-trip properties', () {
    test('RT-02: BackupManifest.fromJson(manifest.toJson()) == manifest for 100 samples', () {
      for (final manifest in BackupManifestGen.generateMany(100)) {
        final json = manifest.toJson();
        final parsed = BackupManifest.fromJson(json);

        expect(parsed.appVersion, manifest.appVersion,
            reason: 'appVersion mismatch');
        expect(parsed.deviceInfo, manifest.deviceInfo,
            reason: 'deviceInfo mismatch');
        expect(parsed.driftSchemaVersion, manifest.driftSchemaVersion,
            reason: 'driftSchemaVersion mismatch');
        expect(parsed.modules.length, manifest.modules.length,
            reason: 'modules count mismatch');
        for (var i = 0; i < manifest.modules.length; i++) {
          expect(parsed.modules[i].name, manifest.modules[i].name);
          expect(
            parsed.modules[i].recordCount,
            manifest.modules[i].recordCount,
          );
        }
      }
    });

    test('RT-01: Export then validateAndParse preserves manifest for 50 samples', () {
      for (final manifest in BackupManifestGen.generateMany(50)) {
        final moduleJsons = <String, String>{};
        for (final m in manifest.modules) {
          moduleJsons[m.name] = jsonEncode(
            List.generate(
              m.recordCount,
              (i) => {'id': i, 'data': 'test_$i'},
            ),
          );
        }

        final zipBytes = engine.createZip(
          manifest: manifest,
          moduleJsons: moduleJsons,
        );

        final result = engine.validateAndParseManifest(zipBytes);
        expect(result, isA<Success<BackupManifest>>(),
            reason: 'Should parse successfully');

        final parsed = result.valueOrNull!;
        expect(parsed.appVersion, manifest.appVersion);
        expect(parsed.driftSchemaVersion, manifest.driftSchemaVersion);
      }
    });

    test('RT-05: JSON encode/decode of enabledModules list is symmetric for 100 samples', () {
      final allModules = [
        'finance', 'gym', 'nutrition', 'habits',
        'sleep', 'mental', 'goals',
      ];

      for (var i = 0; i < 100; i++) {
        final shuffled = List<String>.from(allModules)..shuffle();
        final modules = shuffled.take((i % allModules.length) + 1).toList();

        final encoded = jsonEncode(modules);
        final decoded = (jsonDecode(encoded) as List).cast<String>();

        expect(decoded, modules,
            reason: 'Modules round-trip failed for $modules');
      }
    });
  });
}
