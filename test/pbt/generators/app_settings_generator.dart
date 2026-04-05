import 'dart:math';

import 'package:life_os/core/domain/validators.dart';

class AppSettingsGen {
  static final _random = Random(42);

  static Map<String, dynamic> generate() {
    final languages = validLanguages.toList();
    final currencies = supportedCurrencies.toList();
    final goals = validPrimaryGoals.toList();
    final allModules = validModuleIds.toList();

    final moduleCount = _random.nextInt(allModules.length) + 1;
    final shuffled = List<String>.from(allModules)..shuffle(_random);
    final modules = shuffled.take(moduleCount).toList();

    return {
      'userName': _randomName(),
      'language': languages[_random.nextInt(languages.length)],
      'currency': currencies[_random.nextInt(currencies.length)],
      'primaryGoal': goals[_random.nextInt(goals.length)],
      'enabledModules': modules,
      'themeMode': ['dark', 'light', 'system'][_random.nextInt(3)],
      'useBiometric': _random.nextBool(),
      'onboardingCompleted': true,
    };
  }

  static String _randomName() {
    const names = [
      'Camila', 'Andres', 'Laura', 'Maria Jose',
      'Santiago', 'Valentina', 'Carlos', 'Isabella',
    ];
    return names[_random.nextInt(names.length)];
  }

  static List<Map<String, dynamic>> generateMany(int count) =>
      List.generate(count, (_) => generate());
}
