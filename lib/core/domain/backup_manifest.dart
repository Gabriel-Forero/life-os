class BackupModuleEntry {
  const BackupModuleEntry({
    required this.name,
    required this.recordCount,
  });

  factory BackupModuleEntry.fromJson(Map<String, dynamic> json) {
    final name = json['name'];
    final recordCount = json['recordCount'];
    if (name is! String || name.isEmpty) {
      throw FormatException('Invalid module name: $name');
    }
    if (recordCount is! int || recordCount < 0) {
      throw FormatException('Invalid record count: $recordCount');
    }
    return BackupModuleEntry(name: name, recordCount: recordCount);
  }

  final String name;
  final int recordCount;

  Map<String, dynamic> toJson() => {
        'name': name,
        'recordCount': recordCount,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BackupModuleEntry &&
          other.name == name &&
          other.recordCount == recordCount;

  @override
  int get hashCode => Object.hash(name, recordCount);
}

class BackupManifest {
  const BackupManifest({
    required this.appVersion,
    required this.exportDate,
    required this.deviceInfo,
    required this.modules,
    required this.driftSchemaVersion,
  });

  factory BackupManifest.fromJson(Map<String, dynamic> json) {
    final appVersion = json['appVersion'];
    if (appVersion is! String || appVersion.isEmpty) {
      throw const FormatException('Missing or invalid appVersion');
    }

    final exportDateStr = json['exportDate'];
    if (exportDateStr is! String) {
      throw const FormatException('Missing or invalid exportDate');
    }
    final exportDate = DateTime.tryParse(exportDateStr);
    if (exportDate == null) {
      throw FormatException('Invalid exportDate format: $exportDateStr');
    }

    final deviceInfo = json['deviceInfo'];
    if (deviceInfo is! String || deviceInfo.isEmpty) {
      throw const FormatException('Missing or invalid deviceInfo');
    }

    final driftSchemaVersion = json['driftSchemaVersion'];
    if (driftSchemaVersion is! int || driftSchemaVersion < 1) {
      throw FormatException(
        'Invalid driftSchemaVersion: $driftSchemaVersion',
      );
    }

    final modulesList = json['modules'];
    if (modulesList is! List || modulesList.isEmpty) {
      throw const FormatException('Missing or empty modules list');
    }
    final modules = modulesList
        .cast<Map<String, dynamic>>()
        .map(BackupModuleEntry.fromJson)
        .toList();

    return BackupManifest(
      appVersion: appVersion,
      exportDate: exportDate,
      deviceInfo: deviceInfo,
      modules: modules,
      driftSchemaVersion: driftSchemaVersion,
    );
  }

  final String appVersion;
  final DateTime exportDate;
  final String deviceInfo;
  final List<BackupModuleEntry> modules;
  final int driftSchemaVersion;

  Map<String, dynamic> toJson() => {
        'appVersion': appVersion,
        'exportDate': exportDate.toUtc().toIso8601String(),
        'deviceInfo': deviceInfo,
        'driftSchemaVersion': driftSchemaVersion,
        'modules': modules.map((m) => m.toJson()).toList(),
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BackupManifest &&
          other.appVersion == appVersion &&
          other.exportDate == exportDate &&
          other.deviceInfo == deviceInfo &&
          other.driftSchemaVersion == driftSchemaVersion &&
          _listEquals(other.modules, modules);

  @override
  int get hashCode => Object.hash(
        appVersion,
        exportDate,
        deviceInfo,
        driftSchemaVersion,
        Object.hashAll(modules),
      );

  static bool _listEquals(
    List<BackupModuleEntry> a,
    List<BackupModuleEntry> b,
  ) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
