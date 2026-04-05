// HealthKit / Health Connect stub implementation.
// A real implementation would use the `health` package to read platform data.

/// Raw sleep data imported from a health platform.
class SleepImportData {
  const SleepImportData({
    required this.bedTime,
    required this.wakeTime,
    this.interruptions = const [],
  });

  final DateTime bedTime;
  final DateTime wakeTime;
  final List<SleepInterruptionData> interruptions;
}

/// A single interruption record as reported by the health platform.
class SleepInterruptionData {
  const SleepInterruptionData({
    required this.startTime,
    required this.durationMinutes,
  });

  final DateTime startTime;
  final int durationMinutes;
}

/// Contract for platform health integrations.
abstract class HealthService {
  Future<bool> isAvailable();
  Future<bool> requestPermissions();
  Future<List<SleepImportData>> fetchSleepData(DateTime from, DateTime to);
}

/// Stub that always reports unavailable — replace with a real implementation
/// when the `health` package is added to pubspec.yaml.
class HealthServiceStub implements HealthService {
  const HealthServiceStub();

  @override
  Future<bool> isAvailable() async => false;

  @override
  Future<bool> requestPermissions() async => false;

  @override
  Future<List<SleepImportData>> fetchSleepData(
    DateTime from,
    DateTime to,
  ) async =>
      const [];
}
