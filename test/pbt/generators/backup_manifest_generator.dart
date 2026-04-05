import 'dart:math';

import 'package:life_os/core/domain/backup_manifest.dart';

class BackupManifestGen {
  static final _random = Random(42);

  static BackupManifest generate() {
    const moduleNames = [
      'settings', 'finance', 'gym', 'nutrition',
      'habits', 'sleep', 'mental', 'goals',
    ];

    final moduleCount = _random.nextInt(moduleNames.length) + 1;
    final shuffled = List<String>.from(moduleNames)..shuffle(_random);
    final modules = shuffled
        .take(moduleCount)
        .map(
          (name) => BackupModuleEntry(
            name: name,
            recordCount: _random.nextInt(500),
          ),
        )
        .toList();

    return BackupManifest(
      appVersion: '${_random.nextInt(3)}.${_random.nextInt(10)}.${_random.nextInt(10)}',
      exportDate: DateTime.utc(
        2026,
        _random.nextInt(12) + 1,
        _random.nextInt(28) + 1,
        _random.nextInt(24),
        _random.nextInt(60),
      ),
      deviceInfo: 'Device-${_random.nextInt(100)} - Android ${_random.nextInt(5) + 11}',
      driftSchemaVersion: _random.nextInt(5) + 1,
      modules: modules,
    );
  }

  static List<BackupManifest> generateMany(int count) =>
      List.generate(count, (_) => generate());
}
