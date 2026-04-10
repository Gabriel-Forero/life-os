import 'package:life_os/features/mental/domain/models/breathing_session_model.dart';
import 'package:life_os/features/mental/domain/models/mood_log_model.dart';

abstract class MentalRepository {
  // --- MoodLogs ---

  Future<String> insertMoodLog({
    required DateTime date,
    required int valence,
    required int energy,
    required String tags,
    String? journalNote,
    required DateTime createdAt,
  });

  Future<List<MoodLogModel>> getMoodLogs(DateTime from, DateTime to);

  Stream<List<MoodLogModel>> watchMoodLogs(DateTime from, DateTime to);

  Future<MoodLogModel?> getMoodLogById(String id);

  Future<void> deleteMoodLog(String id);

  // --- BreathingSessions ---

  Future<String> insertBreathingSession({
    required String techniqueName,
    required int durationSeconds,
    required bool isCompleted,
    required DateTime createdAt,
  });

  Stream<List<BreathingSessionModel>> watchBreathingSessions(
    DateTime from,
    DateTime to,
  );

  Future<List<BreathingSessionModel>> getBreathingSessions(
    DateTime from,
    DateTime to,
  );

  Future<int> countCompletedSessions();
}
