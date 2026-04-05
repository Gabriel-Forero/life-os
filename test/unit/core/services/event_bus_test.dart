import 'package:flutter_test/flutter_test.dart';
import 'package:life_os/core/domain/app_event.dart';
import 'package:life_os/core/services/event_bus.dart';

void main() {
  late EventBus eventBus;

  setUp(() {
    eventBus = EventBus();
  });

  tearDown(() {
    eventBus.dispose();
  });

  group('EventBus', () {
    test('emit delivers event to typed subscriber', () async {
      final events = <WorkoutCompletedEvent>[];
      eventBus.on<WorkoutCompletedEvent>().listen(events.add);

      final event = WorkoutCompletedEvent(
        workoutId: 1,
        duration: const Duration(minutes: 45),
        totalVolume: 5000,
      );
      eventBus.emit(event);

      await Future<void>.delayed(Duration.zero);
      expect(events, hasLength(1));
      expect(events.first.workoutId, 1);
    });

    test('emit does not deliver to unrelated type subscriber', () async {
      final events = <ExpenseAddedEvent>[];
      eventBus.on<ExpenseAddedEvent>().listen(events.add);

      eventBus.emit(WorkoutCompletedEvent(
        workoutId: 1,
        duration: const Duration(minutes: 30),
        totalVolume: 3000,
      ));

      await Future<void>.delayed(Duration.zero);
      expect(events, isEmpty);
    });

    test('multiple subscribers receive the same event', () async {
      final list1 = <WorkoutCompletedEvent>[];
      final list2 = <WorkoutCompletedEvent>[];
      eventBus.on<WorkoutCompletedEvent>().listen(list1.add);
      eventBus.on<WorkoutCompletedEvent>().listen(list2.add);

      eventBus.emit(WorkoutCompletedEvent(
        workoutId: 1,
        duration: const Duration(minutes: 20),
        totalVolume: 2000,
      ));

      await Future<void>.delayed(Duration.zero);
      expect(list1, hasLength(1));
      expect(list2, hasLength(1));
    });

    test('emit after dispose is a no-op', () {
      eventBus.dispose();

      expect(
        () => eventBus.emit(SettingsChangedEvent()),
        returnsNormally,
      );
    });

    test('on after dispose returns empty stream', () {
      eventBus.dispose();
      final stream = eventBus.on<SettingsChangedEvent>();
      expect(stream, emitsDone);
    });

    test('AppEvent timestamp is auto-assigned', () {
      final before = DateTime.now();
      final event = SettingsChangedEvent();
      final after = DateTime.now();

      expect(event.timestamp.isAfter(before) || event.timestamp == before, isTrue);
      expect(event.timestamp.isBefore(after) || event.timestamp == after, isTrue);
    });
  });
}
