import 'package:flutter_test/flutter_test.dart';
import 'package:life_os/features/intelligence/domain/ai_context_builder.dart';

void main() {
  // -------------------------------------------------------------------------
  // buildAIContext
  // -------------------------------------------------------------------------

  group('buildAIContext', () {
    test('contains base system prompt lines', () {
      final prompt = buildAIContext(const ModuleSummary());

      expect(prompt, contains('Eres un asistente de vida inteligente'));
      expect(prompt, contains('Responde siempre en espanol'));
    });

    test('includes dayScore when present', () {
      final prompt = buildAIContext(const ModuleSummary(dayScore: 78));
      expect(prompt, contains('78/100'));
    });

    test('omits dayScore when null', () {
      final prompt = buildAIContext(const ModuleSummary());
      expect(prompt, isNot(contains('Puntuacion del dia')));
    });

    test('includes calories with goal when both present', () {
      final prompt = buildAIContext(const ModuleSummary(
        caloriesToday: 1850,
        caloriesGoal: 2200,
      ));
      expect(prompt, contains('1850'));
      expect(prompt, contains('2200'));
    });

    test('includes calories without goal when goal is null', () {
      final prompt = buildAIContext(
        const ModuleSummary(caloriesToday: 1500),
      );
      expect(prompt, contains('1500'));
      expect(prompt, isNot(contains('de 2200')));
    });

    test('omits calories when both are null', () {
      final prompt = buildAIContext(const ModuleSummary());
      expect(prompt, isNot(contains('Calorias')));
    });

    test('includes budget percentage when present', () {
      final prompt = buildAIContext(const ModuleSummary(budgetUsedPercent: 0.65));
      expect(prompt, contains('65%'));
    });

    test('omits budget when null', () {
      final prompt = buildAIContext(const ModuleSummary());
      expect(prompt, isNot(contains('Presupuesto')));
    });

    test('includes active streaks', () {
      final prompt = buildAIContext(ModuleSummary(
        activeStreaks: [
          (name: 'Ejercicio', days: 12),
          (name: 'Meditacion', days: 5),
        ],
      ));
      expect(prompt, contains('Ejercicio (12 dias)'));
      expect(prompt, contains('Meditacion (5 dias)'));
    });

    test('omits streaks line when list is empty', () {
      final prompt = buildAIContext(const ModuleSummary(activeStreaks: []));
      expect(prompt, isNot(contains('Rachas activas')));
    });

    test('includes sleep score when present', () {
      final prompt = buildAIContext(const ModuleSummary(lastSleepScore: 82));
      expect(prompt, contains('82/100'));
    });

    test('omits sleep score when null', () {
      final prompt = buildAIContext(const ModuleSummary());
      expect(prompt, isNot(contains('sueno')));
    });

    test('includes mood level when present', () {
      final prompt = buildAIContext(const ModuleSummary(lastMoodLevel: 7));
      expect(prompt, contains('7/10'));
    });

    test('omits mood level when null', () {
      final prompt = buildAIContext(const ModuleSummary());
      expect(prompt, isNot(contains('animo')));
    });

    test('full context with all fields produces valid prompt', () {
      final prompt = buildAIContext(ModuleSummary(
        dayScore: 85,
        caloriesToday: 1900,
        caloriesGoal: 2200,
        budgetUsedPercent: 0.72,
        activeStreaks: [(name: 'Yoga', days: 30)],
        lastSleepScore: 90,
        lastMoodLevel: 8,
      ));

      // All expected fragments
      expect(prompt, contains('85/100'));
      expect(prompt, contains('1900'));
      expect(prompt, contains('2200'));
      expect(prompt, contains('72%'));
      expect(prompt, contains('Yoga (30 dias)'));
      expect(prompt, contains('90/100'));
      expect(prompt, contains('8/10'));
    });

    test('empty ModuleSummary produces minimal but valid prompt', () {
      final prompt = buildAIContext(const ModuleSummary());
      final lines = prompt.split('\n');
      // At minimum: header + context label + footer
      expect(lines.length, greaterThanOrEqualTo(3));
    });

    test('budget rounds to integer percentage', () {
      final prompt = buildAIContext(
        const ModuleSummary(budgetUsedPercent: 0.3333),
      );
      expect(prompt, contains('33%'));
    });
  });
}
