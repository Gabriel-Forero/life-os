import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/services.dart';
import 'package:life_os/core/database/app_database.dart';
import 'package:life_os/features/gym/database/gym_dao.dart';

/// Seeds the [GymDao] with the bundled exercise library from
/// `assets/exercises.json` the first time the app launches.
///
/// The function is idempotent — it checks the row count before inserting and
/// returns immediately when data already exists, so calling it on every cold
/// start is safe.
Future<void> loadBundledExercises(GymDao dao) async {
  final count = await dao.countExercises();
  if (count > 0) return;

  final jsonStr = await rootBundle.loadString('assets/exercises.json');
  final list = jsonDecode(jsonStr) as List<dynamic>;

  final companions = list.map((dynamic raw) {
    final item = raw as Map<String, dynamic>;

    // secondaryMuscles may be a List or absent; encode back to JSON string.
    String? secondaryMusclesJson;
    final sm = item['secondaryMuscles'];
    if (sm is List && sm.isNotEmpty) {
      secondaryMusclesJson = jsonEncode(sm);
    }

    return ExercisesCompanion.insert(
      name: item['name'] as String,
      primaryMuscle: item['primaryMuscle'] as String,
      secondaryMuscles: Value(secondaryMusclesJson),
      equipment: Value(item['equipment'] as String?),
      instructions: Value(item['instructions'] as String?),
      isCustom: const Value(false),
      isDownloaded: const Value(true),
      createdAt: DateTime.now(),
    );
  }).toList();

  await dao.bulkInsertExercises(companions);
}
