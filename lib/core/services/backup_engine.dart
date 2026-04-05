import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:life_os/core/domain/app_failure.dart';
import 'package:life_os/core/domain/backup_manifest.dart';
import 'package:life_os/core/domain/result.dart';
import 'package:life_os/core/services/app_logger.dart';

class BackupExportResult {
  const BackupExportResult({required this.zipBytes, required this.manifest});

  final Uint8List zipBytes;
  final BackupManifest manifest;
}

class BackupImportModuleResult {
  const BackupImportModuleResult({
    required this.moduleName,
    required this.inserted,
    required this.skipped,
    required this.failed,
  });

  final String moduleName;
  final int inserted;
  final int skipped;
  final int failed;
}

class BackupEngine {
  BackupEngine({AppLogger? logger})
      : _logger = logger ?? AppLogger(tag: 'BackupEngine');

  final AppLogger _logger;

  Uint8List createZip({
    required BackupManifest manifest,
    required Map<String, String> moduleJsons,
  }) {
    final archive = Archive();

    final manifestJson = jsonEncode(manifest.toJson());
    archive.addFile(
      ArchiveFile.bytes('manifest.json', utf8.encode(manifestJson)),
    );

    for (final entry in moduleJsons.entries) {
      archive.addFile(
        ArchiveFile.bytes('${entry.key}.json', utf8.encode(entry.value)),
      );
    }

    final encoded = ZipEncoder().encode(archive);

    _logger.security('Backup exported: ${manifest.modules.length} modules');
    return Uint8List.fromList(encoded);
  }

  Result<BackupManifest> validateAndParseManifest(Uint8List zipBytes) {
    try {
      final archive = ZipDecoder().decodeBytes(zipBytes);
      final manifestFile = archive.findFile('manifest.json');

      if (manifestFile == null) {
        return const Failure(
          BackupFailure(
            userMessage: 'Archivo de respaldo invalido: manifiesto no encontrado',
            debugMessage: 'manifest.json not found in ZIP archive',
            phase: 'validate',
          ),
        );
      }

      final manifestJson =
          jsonDecode(utf8.decode(manifestFile.readBytes()!))
              as Map<String, dynamic>;
      final manifest = BackupManifest.fromJson(manifestJson);
      return Success(manifest);
    } on FormatException catch (e) {
      return Failure(
        BackupFailure(
          userMessage: 'Archivo de respaldo corrupto',
          debugMessage: 'Manifest parse error: $e',
          phase: 'validate',
        ),
      );
    } on Exception catch (e) {
      return Failure(
        BackupFailure(
          userMessage: 'No se pudo leer el archivo de respaldo',
          debugMessage: 'ZIP read error: $e',
          phase: 'validate',
        ),
      );
    }
  }

  Result<Map<String, List<Map<String, dynamic>>>> extractModuleData(
    Uint8List zipBytes,
    List<String> selectedModules,
  ) {
    try {
      final archive = ZipDecoder().decodeBytes(zipBytes);
      final result = <String, List<Map<String, dynamic>>>{};

      for (final moduleName in selectedModules) {
        final file = archive.findFile('$moduleName.json');
        if (file == null) {
          _logger.warning('Module file $moduleName.json not found in ZIP');
          continue;
        }

        final jsonStr = utf8.decode(file.readBytes()!);
        final records = (jsonDecode(jsonStr) as List)
            .cast<Map<String, dynamic>>();
        result[moduleName] = records;
      }

      return Success(result);
    } on Exception catch (e) {
      return Failure(
        BackupFailure(
          userMessage: 'Error al leer datos del respaldo',
          debugMessage: 'Module extraction error: $e',
          phase: 'import',
        ),
      );
    }
  }
}
