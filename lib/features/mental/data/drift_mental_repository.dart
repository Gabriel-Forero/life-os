import 'package:drift/drift.dart';
import 'package:life_os/core/database/app_database.dart';
import 'package:life_os/features/mental/data/mental_repository.dart';
import 'package:life_os/features/mental/database/mental_dao.dart';
import 'package:life_os/features/mental/domain/models/breathing_session_model.dart';
import 'package:life_os/features/mental/domain/models/mood_log_model.dart';

class DriftMentalRepository implements MentalRepository {
  DriftMentalRepository({required this.dao});

  final MentalDao dao;

  // --- Mapping helpers ---

  static MoodLogModel _toMoodLogModel(MoodLog row) => MoodLogModel(
        id: row.id.toString(),
        date: row.date,
        valence: row.valence,
        energy: row.energy,
        tags: row.tags,
        journalNote: row.journalNote,
        createdAt: row.createdAt,
      );

  static BreathingSessionModel _toBreathingSessionModel(
    BreathingSession row,
  ) =>
      BreathingSessionModel(
        id: row.id.toString(),
        techniqueName: row.techniqueName,
        durationSeconds: row.durationSeconds,
        isCompleted: row.isCompleted,
        createdAt: row.createdAt,
      );

  // --- MoodLogs ---

  @override
  Future<String> insertMoodLog({
    required DateTime date,
    required int valence,
    required int energy,
    required String tags,
    String? journalNote,
    required DateTime createdAt,
  }) async {
    final id = await dao.insertMoodLog(MoodLogsCompanion.insert(
      date: date,
      valence: valence,
      energy: energy,
      tags: Value(tags),
      journalNote: Value(journalNote),
      createdAt: createdAt,
    ));
    return id.toString();
  }

  @override
  Future<List<MoodLogModel>> getMoodLogs(DateTime from, DateTime to) async {
    final rows = await dao.getMoodLogs(from, to);
    return rows.map(_toMoodLogModel).toList();
  }

  @override
  Stream<List<MoodLogModel>> watchMoodLogs(DateTime from, DateTime to) {
    return dao
        .watchMoodLogs(from, to)
        .map((rows) => rows.map(_toMoodLogModel).toList());
  }

  @override
  Future<MoodLogModel?> getMoodLogById(String id) async {
    final intId = int.tryParse(id);
    if (intId == null) return null;
    final row = await dao.getMoodLogById(intId);
    return row != null ? _toMoodLogModel(row) : null;
  }

  @override
  Future<void> deleteMoodLog(String id) async {
    final intId = int.tryParse(id);
    if (intId == null) return;
    await dao.deleteMoodLog(intId);
  }

  // --- BreathingSessions ---

  @override
  Future<String> insertBreathingSession({
    required String techniqueName,
    required int durationSeconds,
    required bool isCompleted,
    required DateTime createdAt,
  }) async {
    final id = await dao.insertBreathingSession(
      BreathingSessionsCompanion.insert(
        techniqueName: techniqueName,
        durationSeconds: durationSeconds,
        isCompleted: Value(isCompleted),
        createdAt: createdAt,
      ),
    );
    return id.toString();
  }

  @override
  Stream<List<BreathingSessionModel>> watchBreathingSessions(
    DateTime from,
    DateTime to,
  ) {
    return dao
        .watchBreathingSessions(from, to)
        .map((rows) => rows.map(_toBreathingSessionModel).toList());
  }

  @override
  Future<List<BreathingSessionModel>> getBreathingSessions(
    DateTime from,
    DateTime to,
  ) async {
    final rows = await dao.getBreathingSessions(from, to);
    return rows.map(_toBreathingSessionModel).toList();
  }

  @override
  Future<int> countCompletedSessions() => dao.countCompletedSessions();
}
