import 'package:life_os/features/finance/data/finance_repository.dart';

const _predefined = <Map<String, dynamic>>[
  {'name': 'Alimentacion', 'icon': 'restaurant', 'color': 0xFF10B981, 'type': 'expense', 'sortOrder': 0},
  {'name': 'Transporte', 'icon': 'directions_car', 'color': 0xFF3B82F6, 'type': 'expense', 'sortOrder': 1},
  {'name': 'Entretenimiento', 'icon': 'movie', 'color': 0xFF8B5CF6, 'type': 'expense', 'sortOrder': 2},
  {'name': 'Salud', 'icon': 'local_hospital', 'color': 0xFFEF4444, 'type': 'expense', 'sortOrder': 3},
  {'name': 'Hogar', 'icon': 'home', 'color': 0xFFF59E0B, 'type': 'expense', 'sortOrder': 4},
  {'name': 'Educacion', 'icon': 'school', 'color': 0xFF06B6D4, 'type': 'expense', 'sortOrder': 5},
  {'name': 'Ropa', 'icon': 'checkroom', 'color': 0xFFEC4899, 'type': 'expense', 'sortOrder': 6},
  {'name': 'Servicios', 'icon': 'receipt_long', 'color': 0xFF6366F1, 'type': 'expense', 'sortOrder': 7},
  {'name': 'Otros', 'icon': 'more_horiz', 'color': 0xFF9CA3AF, 'type': 'both', 'sortOrder': 8},
  {'name': 'General', 'icon': 'account_balance', 'color': 0xFF6366F1, 'type': 'income', 'sortOrder': 9},
  {'name': 'Salario', 'icon': 'payments', 'color': 0xFF10B981, 'type': 'income', 'sortOrder': 10},
  {'name': 'Freelance', 'icon': 'work', 'color': 0xFF3B82F6, 'type': 'income', 'sortOrder': 11},
];

Future<void> seedPredefinedCategoriesFromRepo(FinanceRepository repo) async {
  final existing = await repo.watchCategories().first;
  if (existing.isNotEmpty) return;

  final now = DateTime(2026);
  for (final cat in _predefined) {
    await repo.insertCategory(
      name: cat['name'] as String,
      icon: cat['icon'] as String,
      color: cat['color'] as int,
      type: cat['type'] as String,
      isPredefined: true,
      sortOrder: cat['sortOrder'] as int,
      createdAt: now,
    );
  }
}
