import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_os/core/database/app_database.dart';
import 'package:life_os/features/finance/database/finance_dao.dart';

AppDatabase _createInMemoryDb() => AppDatabase(NativeDatabase.memory());

void main() {
  late AppDatabase db;
  late FinanceDao dao;

  setUp(() async {
    db = _createInMemoryDb();
    dao = db.financeDao;
  });

  tearDown(() async {
    await db.close();
  });

  group('FinanceDao — Transactions', () {
    Future<int> insertExpenseCategory() async {
      return dao.insertCategory(CategoriesCompanion.insert(
        name: 'Alimentacion',
        icon: const Value('restaurant'),
        color: const Value(0xFF10B981),
        type: const Value('expense'),
        isPredefined: const Value(true),
        sortOrder: const Value(0),
        createdAt: DateTime.now(),
      ));
    }

    test('insertTransaction returns id', () async {
      final catId = await insertExpenseCategory();
      final id = await dao.insertTransaction(TransactionsCompanion.insert(
        type: 'expense',
        amountCents: 25000,
        categoryId: catId,
        date: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
      expect(id, greaterThan(0));
    });

    test('watchTransactions returns inserted transactions', () async {
      final catId = await insertExpenseCategory();
      final now = DateTime.now();

      await dao.insertTransaction(TransactionsCompanion.insert(
        type: 'expense',
        amountCents: 50000,
        categoryId: catId,
        date: now,
        createdAt: now,
        updatedAt: now,
      ));

      final from = DateTime(now.year, now.month, 1);
      final to = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
      final txs = await dao.watchTransactions(from, to).first;

      expect(txs, hasLength(1));
      expect(txs.first.amountCents, 50000);
      expect(txs.first.type, 'expense');
    });

    test('deleteTransaction removes the row', () async {
      final catId = await insertExpenseCategory();
      final id = await dao.insertTransaction(TransactionsCompanion.insert(
        type: 'expense',
        amountCents: 10000,
        categoryId: catId,
        date: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      await dao.deleteTransaction(id);
      final now = DateTime.now();
      final from = DateTime(now.year, now.month, 1);
      final to = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
      final txs = await dao.watchTransactions(from, to).first;
      expect(txs, isEmpty);
    });

    test('sumByType returns correct sum for expenses', () async {
      final catId = await insertExpenseCategory();
      final now = DateTime.now();

      for (final amount in [10000, 20000, 30000]) {
        await dao.insertTransaction(TransactionsCompanion.insert(
          type: 'expense',
          amountCents: amount,
          categoryId: catId,
          date: now,
          createdAt: now,
          updatedAt: now,
        ));
      }

      final from = DateTime(now.year, now.month, 1);
      final to = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
      final sum = await dao.sumByType('expense', from, to);
      expect(sum, 60000);
    });

    test('sumByType returns 0 when no transactions exist', () async {
      final now = DateTime.now();
      final from = DateTime(now.year, now.month, 1);
      final to = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
      final sum = await dao.sumByType('income', from, to);
      expect(sum, 0);
    });
  });

  group('FinanceDao — Categories', () {
    test('insertCategory returns id', () async {
      final id = await dao.insertCategory(CategoriesCompanion.insert(
        name: 'Mascota',
        icon: const Value('pets'),
        color: const Value(0xFF10B981),
        type: const Value('expense'),
        isPredefined: const Value(false),
        sortOrder: const Value(20),
        createdAt: DateTime.now(),
      ));
      expect(id, greaterThan(0));
    });

    test('watchCategories returns all categories', () async {
      await dao.insertCategory(CategoriesCompanion.insert(
        name: 'Cat1',
        icon: const Value('star'),
        color: const Value(0xFF000000),
        type: const Value('expense'),
        isPredefined: const Value(false),
        sortOrder: const Value(0),
        createdAt: DateTime.now(),
      ));
      await dao.insertCategory(CategoriesCompanion.insert(
        name: 'Cat2',
        icon: const Value('star'),
        color: const Value(0xFF000000),
        type: const Value('income'),
        isPredefined: const Value(false),
        sortOrder: const Value(1),
        createdAt: DateTime.now(),
      ));

      final cats = await dao.watchCategories().first;
      expect(cats, hasLength(2));
    });

    test('getCategoriesByType filters correctly', () async {
      await dao.insertCategory(CategoriesCompanion.insert(
        name: 'Expense Cat',
        icon: const Value('star'),
        color: const Value(0xFF000000),
        type: const Value('expense'),
        isPredefined: const Value(false),
        sortOrder: const Value(0),
        createdAt: DateTime.now(),
      ));
      await dao.insertCategory(CategoriesCompanion.insert(
        name: 'Income Cat',
        icon: const Value('star'),
        color: const Value(0xFF000000),
        type: const Value('income'),
        isPredefined: const Value(false),
        sortOrder: const Value(1),
        createdAt: DateTime.now(),
      ));

      final expenses = await dao.getCategoriesByType('expense');
      expect(expenses, hasLength(1));
      expect(expenses.first.name, 'Expense Cat');
    });
  });

  group('FinanceDao — Budgets', () {
    test('insertBudget and spentInBudget calculates correctly', () async {
      final catId = await dao.insertCategory(CategoriesCompanion.insert(
        name: 'Food',
        icon: const Value('restaurant'),
        color: const Value(0xFF10B981),
        type: const Value('expense'),
        isPredefined: const Value(false),
        sortOrder: const Value(0),
        createdAt: DateTime.now(),
      ));

      final now = DateTime.now();
      await dao.insertBudget(BudgetsCompanion.insert(
        categoryId: catId,
        amountCents: 500000,
        month: now.month,
        year: now.year,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      // Add expenses
      await dao.insertTransaction(TransactionsCompanion.insert(
        type: 'expense',
        amountCents: 100000,
        categoryId: catId,
        date: now,
        createdAt: now,
        updatedAt: now,
      ));
      await dao.insertTransaction(TransactionsCompanion.insert(
        type: 'expense',
        amountCents: 150000,
        categoryId: catId,
        date: now,
        createdAt: now,
        updatedAt: now,
      ));

      final spent = await dao.spentInBudget(catId, now.month, now.year);
      expect(spent, 250000);
    });

    test('watchBudgets returns budgets for given month', () async {
      final catId = await dao.insertCategory(CategoriesCompanion.insert(
        name: 'Transport',
        icon: const Value('car'),
        color: const Value(0xFF3B82F6),
        type: const Value('expense'),
        isPredefined: const Value(false),
        sortOrder: const Value(0),
        createdAt: DateTime.now(),
      ));

      final now = DateTime.now();
      await dao.insertBudget(BudgetsCompanion.insert(
        categoryId: catId,
        amountCents: 300000,
        month: now.month,
        year: now.year,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      final budgets = await dao.watchBudgets(now.month, now.year).first;
      expect(budgets, hasLength(1));
      expect(budgets.first.amountCents, 300000);
    });

    test('insertBudget defaults autoRepeat to true', () async {
      final catId = await dao.insertCategory(CategoriesCompanion.insert(
        name: 'Food',
        icon: const Value('restaurant'),
        color: const Value(0xFF10B981),
        type: const Value('expense'),
        isPredefined: const Value(false),
        sortOrder: const Value(0),
        createdAt: DateTime.now(),
      ));

      await dao.insertBudget(BudgetsCompanion.insert(
        categoryId: catId,
        amountCents: 500000,
        month: 3,
        year: 2026,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      final budget = await dao.getBudget(catId, 3, 2026);
      expect(budget, isNotNull);
      expect(budget!.autoRepeat, isTrue);
    });

    test('getBudgetsForMonth returns all budgets with autoRepeat flag',
        () async {
      final catId = await dao.insertCategory(CategoriesCompanion.insert(
        name: 'Food',
        icon: const Value('restaurant'),
        color: const Value(0xFF10B981),
        type: const Value('expense'),
        isPredefined: const Value(false),
        sortOrder: const Value(0),
        createdAt: DateTime.now(),
      ));

      final now = DateTime.now();
      await dao.insertBudget(BudgetsCompanion.insert(
        categoryId: catId,
        amountCents: 500000,
        month: now.month,
        year: now.year,
        autoRepeat: const Value(false),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      final budgets = await dao.getBudgetsForMonth(now.month, now.year);
      expect(budgets, hasLength(1));
      expect(budgets.first.autoRepeat, isFalse);
    });

    test('copyBudgetsToMonth copies only autoRepeat budgets', () async {
      final catId1 = await dao.insertCategory(CategoriesCompanion.insert(
        name: 'Food',
        icon: const Value('restaurant'),
        color: const Value(0xFF10B981),
        type: const Value('expense'),
        isPredefined: const Value(false),
        sortOrder: const Value(0),
        createdAt: DateTime.now(),
      ));
      final catId2 = await dao.insertCategory(CategoriesCompanion.insert(
        name: 'Transport',
        icon: const Value('car'),
        color: const Value(0xFF3B82F6),
        type: const Value('expense'),
        isPredefined: const Value(false),
        sortOrder: const Value(1),
        createdAt: DateTime.now(),
      ));

      // Budget with autoRepeat = true
      await dao.insertBudget(BudgetsCompanion.insert(
        categoryId: catId1,
        amountCents: 500000,
        month: 3,
        year: 2026,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
      // Budget with autoRepeat = false
      await dao.insertBudget(BudgetsCompanion.insert(
        categoryId: catId2,
        amountCents: 200000,
        month: 3,
        year: 2026,
        autoRepeat: const Value(false),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      await dao.copyBudgetsToMonth(
        fromMonth: 3,
        fromYear: 2026,
        toMonth: 4,
        toYear: 2026,
      );

      final copied = await dao.getBudgetsForMonth(4, 2026);
      expect(copied, hasLength(1));
      expect(copied.first.categoryId, catId1);
      expect(copied.first.amountCents, 500000);
      expect(copied.first.autoRepeat, isTrue);
    });
  });

  group('FinanceDao — Budget Templates', () {
    test('insertTemplate returns id', () async {
      final id = await dao.insertTemplate(BudgetTemplatesCompanion.insert(
        name: 'Mes normal',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
      expect(id, greaterThan(0));
    });

    test('watchTemplates returns all templates', () async {
      await dao.insertTemplate(BudgetTemplatesCompanion.insert(
        name: 'Mes normal',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
      await dao.insertTemplate(BudgetTemplatesCompanion.insert(
        name: 'Vacaciones',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      final templates = await dao.watchTemplates().first;
      expect(templates, hasLength(2));
    });

    test('deleteTemplate removes template and its items', () async {
      final catId = await dao.insertCategory(CategoriesCompanion.insert(
        name: 'Food',
        icon: const Value('restaurant'),
        color: const Value(0xFF10B981),
        type: const Value('expense'),
        isPredefined: const Value(false),
        sortOrder: const Value(0),
        createdAt: DateTime.now(),
      ));

      final templateId =
          await dao.insertTemplate(BudgetTemplatesCompanion.insert(
        name: 'Test',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      await dao.insertTemplateItem(BudgetTemplateItemsCompanion.insert(
        templateId: templateId,
        categoryId: catId,
        amountCents: 500000,
      ));

      await dao.deleteTemplate(templateId);

      final templates = await dao.watchTemplates().first;
      expect(templates, isEmpty);

      final items = await dao.getTemplateItems(templateId);
      expect(items, isEmpty);
    });

    test('getTemplateItems returns items for given template', () async {
      final catId1 = await dao.insertCategory(CategoriesCompanion.insert(
        name: 'Food',
        icon: const Value('restaurant'),
        color: const Value(0xFF10B981),
        type: const Value('expense'),
        isPredefined: const Value(false),
        sortOrder: const Value(0),
        createdAt: DateTime.now(),
      ));
      final catId2 = await dao.insertCategory(CategoriesCompanion.insert(
        name: 'Transport',
        icon: const Value('car'),
        color: const Value(0xFF3B82F6),
        type: const Value('expense'),
        isPredefined: const Value(false),
        sortOrder: const Value(1),
        createdAt: DateTime.now(),
      ));

      final templateId =
          await dao.insertTemplate(BudgetTemplatesCompanion.insert(
        name: 'Normal',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      await dao.insertTemplateItem(BudgetTemplateItemsCompanion.insert(
        templateId: templateId,
        categoryId: catId1,
        amountCents: 500000,
      ));
      await dao.insertTemplateItem(BudgetTemplateItemsCompanion.insert(
        templateId: templateId,
        categoryId: catId2,
        amountCents: 200000,
      ));

      final items = await dao.getTemplateItems(templateId);
      expect(items, hasLength(2));
    });

    test('saveCurrentBudgetsAsTemplate captures all budgets', () async {
      final catId1 = await dao.insertCategory(CategoriesCompanion.insert(
        name: 'Food',
        icon: const Value('restaurant'),
        color: const Value(0xFF10B981),
        type: const Value('expense'),
        isPredefined: const Value(false),
        sortOrder: const Value(0),
        createdAt: DateTime.now(),
      ));
      final catId2 = await dao.insertCategory(CategoriesCompanion.insert(
        name: 'Transport',
        icon: const Value('car'),
        color: const Value(0xFF3B82F6),
        type: const Value('expense'),
        isPredefined: const Value(false),
        sortOrder: const Value(1),
        createdAt: DateTime.now(),
      ));

      await dao.insertBudget(BudgetsCompanion.insert(
        categoryId: catId1,
        amountCents: 500000,
        month: 4,
        year: 2026,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
      await dao.insertBudget(BudgetsCompanion.insert(
        categoryId: catId2,
        amountCents: 200000,
        month: 4,
        year: 2026,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      final templateId = await dao.saveCurrentBudgetsAsTemplate(
        name: 'Abril',
        month: 4,
        year: 2026,
      );

      final items = await dao.getTemplateItems(templateId);
      expect(items, hasLength(2));
      final amounts = items.map((i) => i.amountCents).toSet();
      expect(amounts, containsAll([500000, 200000]));
    });

    test('applyTemplate overwrites budgets for target month', () async {
      final catId = await dao.insertCategory(CategoriesCompanion.insert(
        name: 'Food',
        icon: const Value('restaurant'),
        color: const Value(0xFF10B981),
        type: const Value('expense'),
        isPredefined: const Value(false),
        sortOrder: const Value(0),
        createdAt: DateTime.now(),
      ));

      // Create existing budget for target month
      await dao.insertBudget(BudgetsCompanion.insert(
        categoryId: catId,
        amountCents: 300000,
        month: 5,
        year: 2026,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      // Create template with different amount
      final templateId =
          await dao.insertTemplate(BudgetTemplatesCompanion.insert(
        name: 'Test',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
      await dao.insertTemplateItem(BudgetTemplateItemsCompanion.insert(
        templateId: templateId,
        categoryId: catId,
        amountCents: 700000,
      ));

      await dao.applyTemplate(
        templateId: templateId,
        month: 5,
        year: 2026,
      );

      final budgets = await dao.getBudgetsForMonth(5, 2026);
      expect(budgets, hasLength(1));
      expect(budgets.first.amountCents, 700000);
    });
  });

  group('FinanceDao — Monthly Budget Config', () {
    test('setGlobalBudget creates config for month', () async {
      await dao.setGlobalBudget(
        amountCents: 3000000,
        month: 4,
        year: 2026,
      );

      final config = await dao.getMonthlyConfig(4, 2026);
      expect(config, isNotNull);
      expect(config!.globalBudgetCents, 3000000);
    });

    test('setGlobalBudget updates existing config', () async {
      await dao.setGlobalBudget(
        amountCents: 3000000,
        month: 4,
        year: 2026,
      );
      await dao.setGlobalBudget(
        amountCents: 3500000,
        month: 4,
        year: 2026,
      );

      final config = await dao.getMonthlyConfig(4, 2026);
      expect(config!.globalBudgetCents, 3500000);
    });

    test('copyMonthlyConfig copies global budget to new month', () async {
      await dao.setGlobalBudget(
        amountCents: 3000000,
        month: 3,
        year: 2026,
      );

      await dao.copyMonthlyConfig(
        fromMonth: 3,
        fromYear: 2026,
        toMonth: 4,
        toYear: 2026,
      );

      final config = await dao.getMonthlyConfig(4, 2026);
      expect(config, isNotNull);
      expect(config!.globalBudgetCents, 3000000);
    });

    test('getMonthlyConfig returns null when no config exists', () async {
      final config = await dao.getMonthlyConfig(12, 2025);
      expect(config, isNull);
    });
  });

  group('FinanceDao — Category Groups', () {
    Future<int> _insertCat(String name, {int sort = 0}) {
      return dao.insertCategory(CategoriesCompanion.insert(
        name: name,
        icon: const Value('star'),
        color: const Value(0xFF000000),
        type: const Value('expense'),
        isPredefined: const Value(false),
        sortOrder: Value(sort),
        createdAt: DateTime.now(),
      ));
    }

    test('insertGroup returns id', () async {
      final id = await dao.insertGroup(CategoryGroupsCompanion.insert(
        name: 'Necesidades',
        color: const Value(0xFF10B981),
        sortOrder: const Value(0),
        createdAt: DateTime.now(),
      ));
      expect(id, greaterThan(0));
    });

    test('watchGroups returns all groups ordered by sortOrder', () async {
      await dao.insertGroup(CategoryGroupsCompanion.insert(
        name: 'Ocio',
        sortOrder: const Value(2),
        createdAt: DateTime.now(),
      ));
      await dao.insertGroup(CategoryGroupsCompanion.insert(
        name: 'Necesidades',
        sortOrder: const Value(1),
        createdAt: DateTime.now(),
      ));

      final groups = await dao.watchGroups().first;
      expect(groups, hasLength(2));
      expect(groups.first.name, 'Necesidades');
      expect(groups.last.name, 'Ocio');
    });

    test('deleteGroup removes group and its members', () async {
      final catId = await _insertCat('Food');
      final groupId = await dao.insertGroup(CategoryGroupsCompanion.insert(
        name: 'Test',
        createdAt: DateTime.now(),
      ));
      await dao.addCategoryToGroup(groupId, catId);

      await dao.deleteGroup(groupId);

      final groups = await dao.watchGroups().first;
      expect(groups, isEmpty);
      final members = await dao.getGroupMembers(groupId);
      expect(members, isEmpty);
    });

    test('addCategoryToGroup creates membership', () async {
      final catId = await _insertCat('Food');
      final groupId = await dao.insertGroup(CategoryGroupsCompanion.insert(
        name: 'Necesidades',
        createdAt: DateTime.now(),
      ));

      await dao.addCategoryToGroup(groupId, catId);

      final members = await dao.getGroupMembers(groupId);
      expect(members, hasLength(1));
      expect(members.first.categoryId, catId);
    });

    test('removeCategoryFromGroup removes membership', () async {
      final catId = await _insertCat('Food');
      final groupId = await dao.insertGroup(CategoryGroupsCompanion.insert(
        name: 'Necesidades',
        createdAt: DateTime.now(),
      ));

      await dao.addCategoryToGroup(groupId, catId);
      await dao.removeCategoryFromGroup(groupId, catId);

      final members = await dao.getGroupMembers(groupId);
      expect(members, isEmpty);
    });

    test('getCategoryGroupId returns group for a category', () async {
      final catId = await _insertCat('Food');
      final groupId = await dao.insertGroup(CategoryGroupsCompanion.insert(
        name: 'Necesidades',
        createdAt: DateTime.now(),
      ));
      await dao.addCategoryToGroup(groupId, catId);

      final result = await dao.getCategoryGroupId(catId);
      expect(result, groupId);
    });

    test('getCategoryGroupId returns null for ungrouped category', () async {
      final catId = await _insertCat('Food');
      final result = await dao.getCategoryGroupId(catId);
      expect(result, isNull);
    });
  });

  group('FinanceDao — Group Budgets', () {
    test('setGroupBudget creates new group budget', () async {
      final groupId = await dao.insertGroup(CategoryGroupsCompanion.insert(
        name: 'Necesidades',
        createdAt: DateTime.now(),
      ));

      await dao.setGroupBudget(
        groupId: groupId,
        amountCents: 1000000,
        month: 4,
        year: 2026,
      );

      final gb = await dao.getGroupBudget(groupId, 4, 2026);
      expect(gb, isNotNull);
      expect(gb!.amountCents, 1000000);
    });

    test('setGroupBudget updates existing', () async {
      final groupId = await dao.insertGroup(CategoryGroupsCompanion.insert(
        name: 'Necesidades',
        createdAt: DateTime.now(),
      ));

      await dao.setGroupBudget(
        groupId: groupId,
        amountCents: 1000000,
        month: 4,
        year: 2026,
      );
      await dao.setGroupBudget(
        groupId: groupId,
        amountCents: 1500000,
        month: 4,
        year: 2026,
      );

      final gb = await dao.getGroupBudget(groupId, 4, 2026);
      expect(gb!.amountCents, 1500000);
    });

    test('watchGroupBudgets returns budgets for month', () async {
      final g1 = await dao.insertGroup(CategoryGroupsCompanion.insert(
        name: 'Necesidades',
        createdAt: DateTime.now(),
      ));
      final g2 = await dao.insertGroup(CategoryGroupsCompanion.insert(
        name: 'Ocio',
        createdAt: DateTime.now(),
      ));

      await dao.setGroupBudget(
          groupId: g1, amountCents: 1000000, month: 4, year: 2026);
      await dao.setGroupBudget(
          groupId: g2, amountCents: 500000, month: 4, year: 2026);

      final gbs = await dao.watchGroupBudgets(4, 2026).first;
      expect(gbs, hasLength(2));
    });

    test('spentInGroup sums expenses of group member categories', () async {
      final catId1 = await dao.insertCategory(CategoriesCompanion.insert(
        name: 'Food',
        icon: const Value('restaurant'),
        color: const Value(0xFF10B981),
        type: const Value('expense'),
        isPredefined: const Value(false),
        sortOrder: const Value(0),
        createdAt: DateTime.now(),
      ));
      final catId2 = await dao.insertCategory(CategoriesCompanion.insert(
        name: 'Home',
        icon: const Value('home'),
        color: const Value(0xFFF59E0B),
        type: const Value('expense'),
        isPredefined: const Value(false),
        sortOrder: const Value(1),
        createdAt: DateTime.now(),
      ));

      final groupId = await dao.insertGroup(CategoryGroupsCompanion.insert(
        name: 'Necesidades',
        createdAt: DateTime.now(),
      ));
      await dao.addCategoryToGroup(groupId, catId1);
      await dao.addCategoryToGroup(groupId, catId2);

      final now = DateTime.now();
      await dao.insertTransaction(TransactionsCompanion.insert(
        type: 'expense',
        amountCents: 100000,
        categoryId: catId1,
        date: now,
        createdAt: now,
        updatedAt: now,
      ));
      await dao.insertTransaction(TransactionsCompanion.insert(
        type: 'expense',
        amountCents: 50000,
        categoryId: catId2,
        date: now,
        createdAt: now,
        updatedAt: now,
      ));

      final spent = await dao.spentInGroup(groupId, now.month, now.year);
      expect(spent, 150000);
    });

    test('copyGroupBudgetsToMonth copies group budgets', () async {
      final groupId = await dao.insertGroup(CategoryGroupsCompanion.insert(
        name: 'Necesidades',
        createdAt: DateTime.now(),
      ));

      await dao.setGroupBudget(
        groupId: groupId,
        amountCents: 1000000,
        month: 3,
        year: 2026,
      );

      await dao.copyGroupBudgetsToMonth(
        fromMonth: 3,
        fromYear: 2026,
        toMonth: 4,
        toYear: 2026,
      );

      final gb = await dao.getGroupBudget(groupId, 4, 2026);
      expect(gb, isNotNull);
      expect(gb!.amountCents, 1000000);
    });
  });
}
