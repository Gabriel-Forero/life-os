import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:life_os/features/finance/data/finance_repository.dart';
import 'package:life_os/features/finance/domain/models/budget_model.dart';
import 'package:life_os/features/finance/domain/models/budget_template_item_model.dart';
import 'package:life_os/features/finance/domain/models/budget_template_model.dart';
import 'package:life_os/features/finance/domain/models/category_group_member_model.dart';
import 'package:life_os/features/finance/domain/models/category_group_model.dart';
import 'package:life_os/features/finance/domain/models/category_model.dart';
import 'package:life_os/features/finance/domain/models/group_budget_model.dart';
import 'package:life_os/features/finance/domain/models/monthly_budget_config_model.dart';
import 'package:life_os/features/finance/domain/models/recurring_transaction_model.dart';
import 'package:life_os/features/finance/domain/models/savings_goal_model.dart';
import 'package:life_os/features/finance/domain/models/transaction_model.dart';

class FirestoreFinanceRepository implements FinanceRepository {
  FirestoreFinanceRepository({required this.userId})
      : _db = FirebaseFirestore.instance;

  final String userId;
  final FirebaseFirestore _db;

  // --- Collection refs ---

  CollectionReference<Map<String, dynamic>> _col(String name) =>
      _db.collection('users').doc(userId).collection(name);

  CollectionReference<Map<String, dynamic>> get _transactions =>
      _col('transactions');
  CollectionReference<Map<String, dynamic>> get _categories =>
      _col('categories');
  CollectionReference<Map<String, dynamic>> get _budgets => _col('budgets');
  CollectionReference<Map<String, dynamic>> get _savingsGoals =>
      _col('savingsGoals');
  CollectionReference<Map<String, dynamic>> get _recurringTransactions =>
      _col('recurringTransactions');
  CollectionReference<Map<String, dynamic>> get _categoryGroups =>
      _col('categoryGroups');
  CollectionReference<Map<String, dynamic>> get _categoryGroupMembers =>
      _col('categoryGroupMembers');
  CollectionReference<Map<String, dynamic>> get _groupBudgets =>
      _col('groupBudgets');
  CollectionReference<Map<String, dynamic>> get _budgetTemplates =>
      _col('budgetTemplates');
  CollectionReference<Map<String, dynamic>> get _budgetTemplateItems =>
      _col('budgetTemplateItems');
  CollectionReference<Map<String, dynamic>> get _monthlyBudgetConfigs =>
      _col('monthlyBudgetConfigs');

  // --- Helpers ---

  Timestamp _ts(DateTime dt) => Timestamp.fromDate(dt);

  DateTime _fromTs(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is String) return DateTime.parse(v);
    return DateTime.now();
  }

  DateTime? _fromTsNullable(dynamic v) {
    if (v == null) return null;
    if (v is Timestamp) return v.toDate();
    if (v is String) return DateTime.parse(v);
    return null;
  }

  // =====================================================================
  // Transactions
  // =====================================================================

  @override
  Future<String> insertTransaction({
    required String type,
    required int amountCents,
    required String categoryId,
    String? note,
    required DateTime date,
    String? recurringId,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) async {
    final ref = await _transactions.add({
      'type': type,
      'amountCents': amountCents,
      'categoryId': categoryId,
      'note': note,
      'date': _ts(date),
      'recurringId': recurringId,
      'createdAt': _ts(createdAt),
      'updatedAt': _ts(updatedAt),
    });
    return ref.id;
  }

  @override
  Future<void> updateTransaction({
    required String id,
    required String type,
    required int amountCents,
    required String categoryId,
    String? note,
    required DateTime date,
    required DateTime updatedAt,
  }) =>
      _transactions.doc(id).update({
        'type': type,
        'amountCents': amountCents,
        'categoryId': categoryId,
        'note': note,
        'date': _ts(date),
        'updatedAt': _ts(updatedAt),
      });

  @override
  Future<void> deleteTransaction(String id) => _transactions.doc(id).delete();

  TransactionModel _txFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return TransactionModel(
      id: doc.id,
      type: d['type'] as String,
      amountCents: d['amountCents'] as int,
      categoryId: d['categoryId'] as String,
      note: d['note'] as String?,
      date: _fromTs(d['date']),
      recurringId: d['recurringId']?.toString(),
      createdAt: _fromTs(d['createdAt']),
      updatedAt: _fromTs(d['updatedAt']),
    );
  }

  @override
  Stream<List<TransactionModel>> watchTransactions(
    DateTime from,
    DateTime to,
  ) {
    return _transactions
        .where('date', isGreaterThanOrEqualTo: _ts(from))
        .where('date', isLessThanOrEqualTo: _ts(to))
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(_txFromDoc).toList());
  }

  @override
  Future<List<TransactionModel>> getTransactionsByCategory(
    String categoryId,
    DateTime from,
    DateTime to,
  ) async {
    final snap = await _transactions
        .where('categoryId', isEqualTo: categoryId)
        .where('date', isGreaterThanOrEqualTo: _ts(from))
        .where('date', isLessThanOrEqualTo: _ts(to))
        .get();
    return snap.docs.map(_txFromDoc).toList();
  }

  @override
  Future<int> sumByType(String type, DateTime from, DateTime to) async {
    final snap = await _transactions
        .where('type', isEqualTo: type)
        .where('date', isGreaterThanOrEqualTo: _ts(from))
        .where('date', isLessThanOrEqualTo: _ts(to))
        .get();
    int total = 0;
    for (final doc in snap.docs) {
      total += (doc.data()['amountCents'] as int?) ?? 0;
    }
    return total;
  }

  // =====================================================================
  // Categories
  // =====================================================================

  @override
  Future<String> insertCategory({
    required String name,
    String icon = 'category',
    int color = 0xFF9CA3AF,
    String type = 'expense',
    bool isPredefined = false,
    int sortOrder = 0,
    required DateTime createdAt,
  }) async {
    // Check if already exists by name
    final existing = await _categories
        .where('name', isEqualTo: name)
        .limit(1)
        .get();
    if (existing.docs.isNotEmpty) return existing.docs.first.id;

    final ref = await _categories.add({
      'name': name,
      'icon': icon,
      'color': color,
      'type': type,
      'isPredefined': isPredefined,
      'sortOrder': sortOrder,
      'createdAt': _ts(createdAt),
    });
    return ref.id;
  }

  @override
  Future<void> updateCategory({
    required String id,
    String? icon,
    int? color,
  }) {
    final data = <String, dynamic>{};
    if (icon != null) data['icon'] = icon;
    if (color != null) data['color'] = color;
    return _categories.doc(id).update(data);
  }

  @override
  Future<void> deleteCategory(String id) => _categories.doc(id).delete();

  CategoryModel _catFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return CategoryModel(
      id: doc.id,
      name: d['name'] as String,
      icon: d['icon'] as String? ?? 'category',
      color: d['color'] as int? ?? 0xFF9CA3AF,
      type: d['type'] as String? ?? 'expense',
      isPredefined: d['isPredefined'] as bool? ?? false,
      sortOrder: d['sortOrder'] as int? ?? 0,
      createdAt: _fromTs(d['createdAt']),
    );
  }

  @override
  Stream<List<CategoryModel>> watchCategories() {
    return _categories
        .orderBy('sortOrder')
        .snapshots()
        .map((snap) => snap.docs.map(_catFromDoc).toList());
  }

  @override
  Future<List<CategoryModel>> getCategoriesByType(String type) async {
    final snap = await _categories
        .where('type', whereIn: [type, 'both'])
        .orderBy('sortOrder')
        .get();
    return snap.docs.map(_catFromDoc).toList();
  }

  @override
  Future<CategoryModel?> getCategoryByName(String name) async {
    final snap =
        await _categories.where('name', isEqualTo: name).limit(1).get();
    if (snap.docs.isEmpty) return null;
    return _catFromDoc(snap.docs.first);
  }

  @override
  Future<int> countTransactionsInCategory(String categoryId) async {
    final snap = await _transactions
        .where('categoryId', isEqualTo: categoryId)
        .count()
        .get();
    return snap.count ?? 0;
  }

  @override
  Future<void> reassignTransactions(
      String fromCategoryId, String toCategoryId) async {
    final snap = await _transactions
        .where('categoryId', isEqualTo: fromCategoryId)
        .get();
    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'categoryId': toCategoryId});
    }
    await batch.commit();
  }

  // =====================================================================
  // Budgets
  // =====================================================================

  String _budgetYearMonth(int month, int year) =>
      '$year-${month.toString().padLeft(2, '0')}';

  @override
  Future<String> insertBudget({
    required String categoryId,
    required int amountCents,
    required int month,
    required int year,
    bool autoRepeat = true,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) async {
    final ref = await _budgets.add({
      'categoryId': categoryId,
      'amountCents': amountCents,
      'month': month,
      'year': year,
      'yearMonth': _budgetYearMonth(month, year),
      'autoRepeat': autoRepeat,
      'createdAt': _ts(createdAt),
      'updatedAt': _ts(updatedAt),
    });
    return ref.id;
  }

  @override
  Future<void> updateBudget({
    required String id,
    required int amountCents,
    required DateTime updatedAt,
  }) =>
      _budgets.doc(id).update({
        'amountCents': amountCents,
        'updatedAt': _ts(updatedAt),
      });

  BudgetModel _budgetFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return BudgetModel(
      id: doc.id,
      categoryId: d['categoryId'] as String,
      amountCents: d['amountCents'] as int,
      month: d['month'] as int,
      year: d['year'] as int,
      autoRepeat: d['autoRepeat'] as bool? ?? true,
      createdAt: _fromTs(d['createdAt']),
      updatedAt: _fromTs(d['updatedAt']),
    );
  }

  @override
  Stream<List<BudgetModel>> watchBudgets(int month, int year) {
    return _budgets
        .where('yearMonth', isEqualTo: _budgetYearMonth(month, year))
        .snapshots()
        .map((snap) => snap.docs.map(_budgetFromDoc).toList());
  }

  @override
  Future<BudgetModel?> getBudget(
      String categoryId, int month, int year) async {
    final snap = await _budgets
        .where('categoryId', isEqualTo: categoryId)
        .where('yearMonth', isEqualTo: _budgetYearMonth(month, year))
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return _budgetFromDoc(snap.docs.first);
  }

  @override
  Future<int> spentInBudget(String categoryId, int month, int year) async {
    final from = DateTime(year, month);
    final to = DateTime(year, month + 1, 0, 23, 59, 59);
    final snap = await _transactions
        .where('categoryId', isEqualTo: categoryId)
        .where('type', isEqualTo: 'expense')
        .where('date', isGreaterThanOrEqualTo: _ts(from))
        .where('date', isLessThanOrEqualTo: _ts(to))
        .get();
    int total = 0;
    for (final doc in snap.docs) {
      total += (doc.data()['amountCents'] as int?) ?? 0;
    }
    return total;
  }

  @override
  Future<void> deleteBudgetsForCategory(String categoryId) async {
    final snap =
        await _budgets.where('categoryId', isEqualTo: categoryId).get();
    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  @override
  Future<List<BudgetModel>> getBudgetsForMonth(int month, int year) async {
    final snap = await _budgets
        .where('yearMonth', isEqualTo: _budgetYearMonth(month, year))
        .get();
    return snap.docs.map(_budgetFromDoc).toList();
  }

  @override
  Future<void> copyBudgetsToMonth({
    required int fromMonth,
    required int fromYear,
    required int toMonth,
    required int toYear,
  }) async {
    final source = await getBudgetsForMonth(fromMonth, fromYear);
    final now = DateTime.now();
    for (final b in source) {
      final existing = await getBudget(b.categoryId, toMonth, toYear);
      if (existing != null) continue;
      await insertBudget(
        categoryId: b.categoryId,
        amountCents: b.amountCents,
        month: toMonth,
        year: toYear,
        autoRepeat: b.autoRepeat,
        createdAt: now,
        updatedAt: now,
      );
    }
  }

  // =====================================================================
  // Budget Templates
  // =====================================================================

  @override
  Future<String> insertTemplate({
    required String name,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) async {
    final ref = await _budgetTemplates.add({
      'name': name,
      'createdAt': _ts(createdAt),
      'updatedAt': _ts(updatedAt),
    });
    return ref.id;
  }

  @override
  Stream<List<BudgetTemplateModel>> watchTemplates() {
    return _budgetTemplates.orderBy('name').snapshots().map(
          (snap) => snap.docs
              .map((doc) => BudgetTemplateModel(
                    id: doc.id,
                    name: doc.data()['name'] as String,
                    createdAt: _fromTs(doc.data()['createdAt']),
                    updatedAt: _fromTs(doc.data()['updatedAt']),
                  ))
              .toList(),
        );
  }

  @override
  Future<void> deleteTemplate(String id) async {
    final items = await _budgetTemplateItems
        .where('templateId', isEqualTo: id)
        .get();
    final batch = _db.batch();
    for (final doc in items.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_budgetTemplates.doc(id));
    await batch.commit();
  }

  @override
  Future<String> insertTemplateItem({
    required String templateId,
    required String categoryId,
    required int amountCents,
  }) async {
    final ref = await _budgetTemplateItems.add({
      'templateId': templateId,
      'categoryId': categoryId,
      'amountCents': amountCents,
    });
    return ref.id;
  }

  @override
  Future<List<BudgetTemplateItemModel>> getTemplateItems(
      String templateId) async {
    final snap = await _budgetTemplateItems
        .where('templateId', isEqualTo: templateId)
        .get();
    return snap.docs
        .map((doc) => BudgetTemplateItemModel(
              id: doc.id,
              templateId: doc.data()['templateId'] as String,
              categoryId: doc.data()['categoryId'] as String,
              amountCents: doc.data()['amountCents'] as int,
            ))
        .toList();
  }

  @override
  Future<String> saveCurrentBudgetsAsTemplate({
    required String name,
    required int month,
    required int year,
  }) async {
    final now = DateTime.now();
    final templateId =
        await insertTemplate(name: name, createdAt: now, updatedAt: now);
    final budgets = await getBudgetsForMonth(month, year);
    for (final b in budgets) {
      await insertTemplateItem(
        templateId: templateId,
        categoryId: b.categoryId,
        amountCents: b.amountCents,
      );
    }
    return templateId;
  }

  @override
  Future<void> applyTemplate({
    required String templateId,
    required int month,
    required int year,
  }) async {
    final items = await getTemplateItems(templateId);
    final now = DateTime.now();
    for (final item in items) {
      final existing = await getBudget(item.categoryId, month, year);
      if (existing != null) {
        await updateBudget(
            id: existing.id, amountCents: item.amountCents, updatedAt: now);
      } else {
        await insertBudget(
          categoryId: item.categoryId,
          amountCents: item.amountCents,
          month: month,
          year: year,
          createdAt: now,
          updatedAt: now,
        );
      }
    }
  }

  // =====================================================================
  // Monthly Budget Config
  // =====================================================================

  String _configDocId(int month, int year) =>
      '$year-${month.toString().padLeft(2, '0')}';

  @override
  Future<MonthlyBudgetConfigModel?> getMonthlyConfig(
      int month, int year) async {
    final doc = await _monthlyBudgetConfigs.doc(_configDocId(month, year)).get();
    if (!doc.exists) return null;
    final d = doc.data()!;
    return MonthlyBudgetConfigModel(
      id: doc.id,
      globalBudgetCents: d['globalBudgetCents'] as int?,
      month: d['month'] as int,
      year: d['year'] as int,
      createdAt: _fromTs(d['createdAt']),
      updatedAt: _fromTs(d['updatedAt']),
    );
  }

  @override
  Future<void> setGlobalBudget({
    required int amountCents,
    required int month,
    required int year,
  }) {
    final now = DateTime.now();
    return _monthlyBudgetConfigs.doc(_configDocId(month, year)).set({
      'globalBudgetCents': amountCents,
      'month': month,
      'year': year,
      'createdAt': _ts(now),
      'updatedAt': _ts(now),
    }, SetOptions(merge: true));
  }

  @override
  Future<void> copyMonthlyConfig({
    required int fromMonth,
    required int fromYear,
    required int toMonth,
    required int toYear,
  }) async {
    final source = await getMonthlyConfig(fromMonth, fromYear);
    if (source == null || source.globalBudgetCents == null) return;
    await setGlobalBudget(
      amountCents: source.globalBudgetCents!,
      month: toMonth,
      year: toYear,
    );
  }

  @override
  Future<Map<String, int>> getMonthlySpentByCategory(
      int month, int year) async {
    final from = DateTime(year, month);
    final to = DateTime(year, month + 1, 0, 23, 59, 59);
    final snap = await _transactions
        .where('type', isEqualTo: 'expense')
        .where('date', isGreaterThanOrEqualTo: _ts(from))
        .where('date', isLessThanOrEqualTo: _ts(to))
        .get();
    final result = <String, int>{};
    for (final doc in snap.docs) {
      final catId = doc.data()['categoryId'] as String;
      final cents = (doc.data()['amountCents'] as int?) ?? 0;
      result[catId] = (result[catId] ?? 0) + cents;
    }
    return result;
  }

  @override
  Future<List<({DateTime date, int cents})>> getDailyExpenses(
      int month, int year) async {
    final from = DateTime(year, month);
    final to = DateTime(year, month + 1, 0, 23, 59, 59);
    final snap = await _transactions
        .where('type', isEqualTo: 'expense')
        .where('date', isGreaterThanOrEqualTo: _ts(from))
        .where('date', isLessThanOrEqualTo: _ts(to))
        .get();
    final daily = <DateTime, int>{};
    for (final doc in snap.docs) {
      final dt = _fromTs(doc.data()['date']);
      final day = DateTime(dt.year, dt.month, dt.day);
      final cents = (doc.data()['amountCents'] as int?) ?? 0;
      daily[day] = (daily[day] ?? 0) + cents;
    }
    final entries = daily.entries
        .map((e) => (date: e.key, cents: e.value))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    return entries;
  }

  // =====================================================================
  // Category Groups
  // =====================================================================

  @override
  Future<String> insertGroup({
    required String name,
    int color = 0xFF9CA3AF,
    required DateTime createdAt,
  }) async {
    final ref = await _categoryGroups.add({
      'name': name,
      'color': color,
      'sortOrder': 0,
      'createdAt': _ts(createdAt),
    });
    return ref.id;
  }

  @override
  Stream<List<CategoryGroupModel>> watchGroups() {
    return _categoryGroups.orderBy('sortOrder').snapshots().map(
          (snap) => snap.docs
              .map((doc) => CategoryGroupModel(
                    id: doc.id,
                    name: doc.data()['name'] as String,
                    color: doc.data()['color'] as int? ?? 0xFF9CA3AF,
                    sortOrder: doc.data()['sortOrder'] as int? ?? 0,
                    createdAt: _fromTs(doc.data()['createdAt']),
                  ))
              .toList(),
        );
  }

  @override
  Future<void> deleteGroup(String id) async {
    final members = await _categoryGroupMembers
        .where('groupId', isEqualTo: id)
        .get();
    final batch = _db.batch();
    for (final doc in members.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_categoryGroups.doc(id));
    await batch.commit();
  }

  @override
  Future<void> addCategoryToGroup(String groupId, String categoryId) async {
    await _categoryGroupMembers.add({
      'groupId': groupId,
      'categoryId': categoryId,
    });
  }

  @override
  Future<void> removeCategoryFromGroup(
      String groupId, String categoryId) async {
    final snap = await _categoryGroupMembers
        .where('groupId', isEqualTo: groupId)
        .where('categoryId', isEqualTo: categoryId)
        .get();
    for (final doc in snap.docs) {
      await doc.reference.delete();
    }
  }

  @override
  Future<List<CategoryGroupMemberModel>> getGroupMembers(
      String groupId) async {
    final snap = await _categoryGroupMembers
        .where('groupId', isEqualTo: groupId)
        .get();
    return snap.docs
        .map((doc) => CategoryGroupMemberModel(
              id: doc.id,
              groupId: doc.data()['groupId'] as String,
              categoryId: doc.data()['categoryId'] as String,
            ))
        .toList();
  }

  @override
  Future<String?> getCategoryGroupId(String categoryId) async {
    final snap = await _categoryGroupMembers
        .where('categoryId', isEqualTo: categoryId)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return snap.docs.first.data()['groupId'] as String;
  }

  // =====================================================================
  // Group Budgets
  // =====================================================================

  @override
  Future<GroupBudgetModel?> getGroupBudget(
      String groupId, int month, int year) async {
    final snap = await _groupBudgets
        .where('groupId', isEqualTo: groupId)
        .where('yearMonth', isEqualTo: _budgetYearMonth(month, year))
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    final doc = snap.docs.first;
    final d = doc.data();
    return GroupBudgetModel(
      id: doc.id,
      groupId: d['groupId'] as String,
      amountCents: d['amountCents'] as int,
      month: d['month'] as int,
      year: d['year'] as int,
      createdAt: _fromTs(d['createdAt']),
      updatedAt: _fromTs(d['updatedAt']),
    );
  }

  @override
  Stream<List<GroupBudgetModel>> watchGroupBudgets(int month, int year) {
    return _groupBudgets
        .where('yearMonth', isEqualTo: _budgetYearMonth(month, year))
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) {
              final d = doc.data();
              return GroupBudgetModel(
                id: doc.id,
                groupId: d['groupId'] as String,
                amountCents: d['amountCents'] as int,
                month: d['month'] as int,
                year: d['year'] as int,
                createdAt: _fromTs(d['createdAt']),
                updatedAt: _fromTs(d['updatedAt']),
              );
            })
            .toList());
  }

  @override
  Future<void> setGroupBudget({
    required String groupId,
    required int amountCents,
    required int month,
    required int year,
  }) async {
    final existing = await getGroupBudget(groupId, month, year);
    final now = DateTime.now();
    if (existing != null) {
      await _groupBudgets.doc(existing.id).update({
        'amountCents': amountCents,
        'updatedAt': _ts(now),
      });
    } else {
      await _groupBudgets.add({
        'groupId': groupId,
        'amountCents': amountCents,
        'month': month,
        'year': year,
        'yearMonth': _budgetYearMonth(month, year),
        'createdAt': _ts(now),
        'updatedAt': _ts(now),
      });
    }
  }

  @override
  Future<int> spentInGroup(String groupId, int month, int year) async {
    final members = await getGroupMembers(groupId);
    int total = 0;
    for (final member in members) {
      total += await spentInBudget(member.categoryId, month, year);
    }
    return total;
  }

  @override
  Future<void> copyGroupBudgetsToMonth({
    required int fromMonth,
    required int fromYear,
    required int toMonth,
    required int toYear,
  }) async {
    final snap = await _groupBudgets
        .where('yearMonth', isEqualTo: _budgetYearMonth(fromMonth, fromYear))
        .get();
    for (final doc in snap.docs) {
      final d = doc.data();
      final existing = await getGroupBudget(
          d['groupId'] as String, toMonth, toYear);
      if (existing != null) continue;
      await setGroupBudget(
        groupId: d['groupId'] as String,
        amountCents: d['amountCents'] as int,
        month: toMonth,
        year: toYear,
      );
    }
  }

  // =====================================================================
  // Savings Goals
  // =====================================================================

  @override
  Future<String> insertSavingsGoal({
    required String name,
    required int targetCents,
    int currentCents = 0,
    DateTime? deadline,
    bool isCompleted = false,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) async {
    final ref = await _savingsGoals.add({
      'name': name,
      'targetCents': targetCents,
      'currentCents': currentCents,
      'deadline': deadline != null ? _ts(deadline) : null,
      'isCompleted': isCompleted,
      'createdAt': _ts(createdAt),
      'updatedAt': _ts(updatedAt),
    });
    return ref.id;
  }

  @override
  Future<void> updateSavingsGoal({
    required String id,
    required int currentCents,
    required bool isCompleted,
    required DateTime updatedAt,
  }) =>
      _savingsGoals.doc(id).update({
        'currentCents': currentCents,
        'isCompleted': isCompleted,
        'updatedAt': _ts(updatedAt),
      });

  @override
  Future<void> deleteSavingsGoal(String id) =>
      _savingsGoals.doc(id).delete();

  @override
  Stream<List<SavingsGoalModel>> watchSavingsGoals() {
    return _savingsGoals.snapshots().map((snap) => snap.docs
        .map((doc) {
          final d = doc.data();
          return SavingsGoalModel(
            id: doc.id,
            name: d['name'] as String,
            targetCents: d['targetCents'] as int,
            currentCents: d['currentCents'] as int? ?? 0,
            deadline: _fromTsNullable(d['deadline']),
            isCompleted: d['isCompleted'] as bool? ?? false,
            createdAt: _fromTs(d['createdAt']),
            updatedAt: _fromTs(d['updatedAt']),
          );
        })
        .toList());
  }

  // =====================================================================
  // Recurring Transactions
  // =====================================================================

  @override
  Future<String> insertRecurring({
    required String type,
    required int amountCents,
    required String categoryId,
    String? note,
    String frequency = 'monthly',
    required DateTime nextOccurrence,
    bool isActive = true,
    required DateTime createdAt,
  }) async {
    final ref = await _recurringTransactions.add({
      'type': type,
      'amountCents': amountCents,
      'categoryId': categoryId,
      'note': note,
      'frequency': frequency,
      'nextOccurrence': _ts(nextOccurrence),
      'isActive': isActive,
      'createdAt': _ts(createdAt),
    });
    return ref.id;
  }

  @override
  Future<List<RecurringTransactionModel>> getDueRecurrings(
      DateTime now) async {
    final snap = await _recurringTransactions
        .where('isActive', isEqualTo: true)
        .where('nextOccurrence', isLessThanOrEqualTo: _ts(now))
        .get();
    return snap.docs
        .map((doc) {
          final d = doc.data();
          return RecurringTransactionModel(
            id: doc.id,
            type: d['type'] as String,
            amountCents: d['amountCents'] as int,
            categoryId: d['categoryId'] as String,
            note: d['note'] as String?,
            frequency: d['frequency'] as String? ?? 'monthly',
            nextOccurrence: _fromTs(d['nextOccurrence']),
            isActive: d['isActive'] as bool? ?? true,
            createdAt: _fromTs(d['createdAt']),
          );
        })
        .toList();
  }

  @override
  Future<void> updateNextOccurrence(String id, DateTime next) =>
      _recurringTransactions.doc(id).update({
        'nextOccurrence': _ts(next),
      });
}
