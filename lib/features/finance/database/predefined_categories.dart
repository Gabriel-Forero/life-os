import 'package:drift/drift.dart';
import 'package:life_os/core/database/app_database.dart';
import 'package:life_os/features/finance/database/finance_dao.dart';

final _predefined = <CategoriesCompanion>[
  // Expense categories
  CategoriesCompanion.insert(
    name: 'Alimentacion', icon: const Value('restaurant'),
    color: const Value(0xFF10B981), type: const Value('expense'),
    isPredefined: const Value(true), sortOrder: const Value(0),
    createdAt: DateTime(2026),
  ),
  CategoriesCompanion.insert(
    name: 'Transporte', icon: const Value('directions_car'),
    color: const Value(0xFF3B82F6), type: const Value('expense'),
    isPredefined: const Value(true), sortOrder: const Value(1),
    createdAt: DateTime(2026),
  ),
  CategoriesCompanion.insert(
    name: 'Entretenimiento', icon: const Value('movie'),
    color: const Value(0xFF8B5CF6), type: const Value('expense'),
    isPredefined: const Value(true), sortOrder: const Value(2),
    createdAt: DateTime(2026),
  ),
  CategoriesCompanion.insert(
    name: 'Salud', icon: const Value('local_hospital'),
    color: const Value(0xFFEF4444), type: const Value('expense'),
    isPredefined: const Value(true), sortOrder: const Value(3),
    createdAt: DateTime(2026),
  ),
  CategoriesCompanion.insert(
    name: 'Hogar', icon: const Value('home'),
    color: const Value(0xFFF59E0B), type: const Value('expense'),
    isPredefined: const Value(true), sortOrder: const Value(4),
    createdAt: DateTime(2026),
  ),
  CategoriesCompanion.insert(
    name: 'Educacion', icon: const Value('school'),
    color: const Value(0xFF06B6D4), type: const Value('expense'),
    isPredefined: const Value(true), sortOrder: const Value(5),
    createdAt: DateTime(2026),
  ),
  CategoriesCompanion.insert(
    name: 'Ropa', icon: const Value('checkroom'),
    color: const Value(0xFFEC4899), type: const Value('expense'),
    isPredefined: const Value(true), sortOrder: const Value(6),
    createdAt: DateTime(2026),
  ),
  CategoriesCompanion.insert(
    name: 'Servicios', icon: const Value('receipt_long'),
    color: const Value(0xFF6366F1), type: const Value('expense'),
    isPredefined: const Value(true), sortOrder: const Value(7),
    createdAt: DateTime(2026),
  ),
  // Both (default expense category)
  CategoriesCompanion.insert(
    name: 'Otros', icon: const Value('more_horiz'),
    color: const Value(0xFF9CA3AF), type: const Value('both'),
    isPredefined: const Value(true), sortOrder: const Value(8),
    createdAt: DateTime(2026),
  ),
  // Income categories
  CategoriesCompanion.insert(
    name: 'General', icon: const Value('account_balance'),
    color: const Value(0xFF6366F1), type: const Value('income'),
    isPredefined: const Value(true), sortOrder: const Value(9),
    createdAt: DateTime(2026),
  ),
  CategoriesCompanion.insert(
    name: 'Salario', icon: const Value('payments'),
    color: const Value(0xFF10B981), type: const Value('income'),
    isPredefined: const Value(true), sortOrder: const Value(10),
    createdAt: DateTime(2026),
  ),
  CategoriesCompanion.insert(
    name: 'Freelance', icon: const Value('work'),
    color: const Value(0xFF3B82F6), type: const Value('income'),
    isPredefined: const Value(true), sortOrder: const Value(11),
    createdAt: DateTime(2026),
  ),
];

Future<void> seedPredefinedCategories(FinanceDao dao) async {
  final existing = await dao.watchCategories().first;
  if (existing.isNotEmpty) return;

  for (final cat in _predefined) {
    await dao.insertCategory(cat);
  }
}
