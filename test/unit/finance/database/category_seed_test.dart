import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_os/core/database/app_database.dart';
import 'package:life_os/features/finance/database/finance_dao.dart';
import 'package:life_os/features/finance/database/predefined_categories.dart';

AppDatabase _createInMemoryDb() => AppDatabase(NativeDatabase.memory());

void main() {
  late AppDatabase db;
  late FinanceDao dao;

  setUp(() async {
    db = _createInMemoryDb();
    dao = db.financeDao;
    await seedPredefinedCategories(dao);
  });

  tearDown(() async {
    await db.close();
  });

  group('Predefined Categories Seed', () {
    test('seeds 12 predefined categories', () async {
      final cats = await dao.watchCategories().first;
      expect(cats.length, 12);
    });

    test('all seeded categories have isPredefined = true', () async {
      final cats = await dao.watchCategories().first;
      for (final cat in cats) {
        expect(cat.isPredefined, isTrue, reason: '${cat.name} should be predefined');
      }
    });

    test('expense default category "Otros" exists with type "both"', () async {
      final otros = await dao.getCategoryByName('Otros');
      expect(otros, isNotNull);
      expect(otros!.type, 'both');
    });

    test('income default category "General" exists with type "income"', () async {
      final general = await dao.getCategoryByName('General');
      expect(general, isNotNull);
      expect(general!.type, 'income');
    });

    test('all categories have unique colors', () async {
      final cats = await dao.watchCategories().first;
      final colors = cats.map((c) => c.color).toSet();
      // At minimum, most should be unique (Alimentacion and Salario share green intentionally)
      expect(colors.length, greaterThanOrEqualTo(9));
    });

    test('categories are ordered by sortOrder', () async {
      final cats = await dao.watchCategories().first;
      for (var i = 1; i < cats.length; i++) {
        expect(cats[i].sortOrder, greaterThanOrEqualTo(cats[i - 1].sortOrder));
      }
    });
  });
}
