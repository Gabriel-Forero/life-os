import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_os/core/constants/app_colors.dart';
import 'package:life_os/core/providers/providers.dart';
import 'package:life_os/features/finance/domain/finance_input.dart';

// ---------------------------------------------------------------------------
// Ticket Scanner Screen — OCR de Tickets (Feature 1)
// ---------------------------------------------------------------------------

/// Allows the user to describe a receipt and have AI extract line items,
/// then create Finance transactions and optionally log food to Nutrition.
class TicketScannerScreen extends ConsumerStatefulWidget {
  const TicketScannerScreen({super.key});

  @override
  ConsumerState<TicketScannerScreen> createState() =>
      _TicketScannerScreenState();
}

class _TicketScannerScreenState extends ConsumerState<TicketScannerScreen> {
  final _descController = TextEditingController();
  bool _isAnalyzing = false;
  _TicketResult? _result;
  String? _error;
  final _confirmedItems = <int>{};
  bool _isSaving = false;
  String? _successMessage;

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  Future<void> _analyze() async {
    final text = _descController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _isAnalyzing = true;
      _error = null;
      _result = null;
      _confirmedItems.clear();
      _successMessage = null;
    });

    try {
      final notifier = ref.read(aiNotifierProvider);
      final config = await notifier.dao.getDefaultConfiguration();
      if (config == null) {
        setState(() {
          _isAnalyzing = false;
          _error =
              'No hay proveedor de IA configurado. Ve a Configuracion > IA.';
        });
        return;
      }

      const systemPrompt =
          'Eres un extractor de datos de tickets de compra. '
          'Responde SOLO con JSON valido, sin texto adicional.';

      final userPrompt =
          'Analiza este ticket de compra. Extrae: tienda, fecha, '
          'items con precio, total. Categoriza cada item como una de: '
          'Alimentacion, Transporte, Entretenimiento, Hogar, Ropa, Salud, '
          'Educacion, Restaurante, Otro. '
          'Responde en JSON con este formato exacto: '
          '{"store":"...","date":"YYYY-MM-DD","items":[{"name":"...","price":0.00,'
          '"category":"...","isFood":false}],"total":0.00}\n\n'
          'Ticket:\n$text';

      final provider = notifier.providerFactory(config);
      final buffer = StringBuffer();
      await for (final chunk in provider.sendMessage(
        userPrompt,
        systemContext: systemPrompt,
      )) {
        buffer.write(chunk);
      }

      final raw = buffer.toString().trim();
      // Extract JSON from response (may have markdown code fences)
      final jsonStr = _extractJson(raw);
      final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
      final ticketResult = _TicketResult.fromJson(decoded);

      setState(() {
        _result = ticketResult;
        _confirmedItems.addAll(
            List.generate(ticketResult.items.length, (i) => i));
        _isAnalyzing = false;
      });
    } on Exception catch (e) {
      setState(() {
        _error = 'Error al analizar el ticket: $e';
        _isAnalyzing = false;
      });
    }
  }

  String _extractJson(String raw) {
    // Remove code fences if present
    var s = raw.replaceAll(RegExp(r'```json\s*'), '');
    s = s.replaceAll(RegExp(r'```\s*'), '');
    // Find first { to last }
    final start = s.indexOf('{');
    final end = s.lastIndexOf('}');
    if (start != -1 && end != -1 && end > start) {
      return s.substring(start, end + 1);
    }
    return s.trim();
  }

  Future<void> _createTransactions() async {
    if (_result == null) return;
    setState(() {
      _isSaving = true;
      _error = null;
      _successMessage = null;
    });

    try {
      final financeNotifier = ref.read(financeNotifierProvider);
      final financeDao = ref.read(financeDaoProvider);
      final items = _result!.items;

      // Get or create a generic expense category
      var categoryId = 1; // fallback
      final categories = await financeDao.getCategoriesByType('expense');
      if (categories.isNotEmpty) {
        categoryId = categories.first.id;
      }

      int savedCount = 0;
      final now = DateTime.now();
      final date = _result!.parsedDate ?? now;

      for (int i = 0; i < items.length; i++) {
        if (!_confirmedItems.contains(i)) continue;
        final item = items[i];
        final amountCents = (item.price * 100).round();

        // Try to find a matching category by name
        int? matchedCategoryId;
        for (final cat in categories) {
          if (_categoryMatches(cat.name, item.category)) {
            matchedCategoryId = cat.id;
            break;
          }
        }

        await financeNotifier.addTransaction(TransactionInput(
          type: 'expense',
          amountCents: amountCents,
          categoryId: matchedCategoryId ?? categoryId,
          note: '${item.name} (${_result!.store})',
          date: date,
        ));
        savedCount++;
      }

      setState(() {
        _isSaving = false;
        _successMessage = '$savedCount transacciones creadas en Finanzas.';
      });
    } on Exception catch (e) {
      setState(() {
        _isSaving = false;
        _error = 'Error al guardar: $e';
      });
    }
  }

  bool _categoryMatches(String catName, String ticketCategory) {
    final lower = catName.toLowerCase();
    final ticket = ticketCategory.toLowerCase();
    if (ticket.contains('aliment') && (lower.contains('super') || lower.contains('aliment') || lower.contains('comida'))) return true;
    if (ticket.contains('restaur') && lower.contains('restaur')) return true;
    if (ticket.contains('transport') && lower.contains('transport')) return true;
    if (ticket.contains('salud') && lower.contains('salud')) return true;
    if (ticket.contains('entrete') && lower.contains('entrete')) return true;
    if (ticket.contains('hogar') && lower.contains('hogar')) return true;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Scaffold(
      key: const ValueKey('ticket_scanner_screen'),
      appBar: AppBar(
        title: const Text('Escanear Ticket'),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Instructions card
            Card(
              elevation: 0,
              color: primaryColor.withAlpha(15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: primaryColor.withAlpha(60)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.receipt_long, color: primaryColor, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Analisis de Ticket con IA',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Escribe o pega el contenido del ticket (tienda, items con precios, total). '
                      'La IA extraera los datos y creara transacciones en Finanzas.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Text input for ticket description
            Semantics(
              label: 'Contenido del ticket',
              child: TextField(
                key: const ValueKey('ticket_description_field'),
                controller: _descController,
                maxLines: 8,
                decoration: InputDecoration(
                  labelText: 'Contenido del ticket',
                  hintText:
                      'Ejemplo:\nSuperMercado XYZ\n2024-01-15\nLeche 1.50\nPan 2.00\nTotal: 3.50',
                  border: const OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
            ),

            const SizedBox(height: 12),

            Semantics(
              label: 'Analizar ticket con IA',
              button: true,
              child: ElevatedButton.icon(
                key: const ValueKey('analyze_ticket_button'),
                onPressed: _isAnalyzing ? null : _analyze,
                icon: _isAnalyzing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_awesome),
                label: Text(_isAnalyzing ? 'Analizando...' : 'Analizar con IA'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
            ),

            // Error
            if (_error != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _error!,
                  style:
                      TextStyle(color: theme.colorScheme.onErrorContainer),
                ),
              ),
            ],

            // Success
            if (_successMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.success.withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.success.withAlpha(80)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: AppColors.success),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _successMessage!,
                        style: const TextStyle(color: AppColors.success),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Results
            if (_result != null) ...[
              const SizedBox(height: 20),
              _TicketResultWidget(
                result: _result!,
                confirmedItems: _confirmedItems,
                onToggleItem: (index) {
                  setState(() {
                    if (_confirmedItems.contains(index)) {
                      _confirmedItems.remove(index);
                    } else {
                      _confirmedItems.add(index);
                    }
                  });
                },
              ),
              const SizedBox(height: 16),

              // Food items notice
              if (_result!.items.any((i) => i.isFood)) ...[
                Card(
                  elevation: 0,
                  color: AppColors.nutrition.withAlpha(15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: AppColors.nutrition.withAlpha(60)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        const Icon(Icons.restaurant, color: AppColors.nutrition, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Se detectaron alimentos. Puedes registrarlos en Nutricion manualmente desde el modulo de Nutricion.',
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              Semantics(
                label: 'Crear transacciones en Finanzas',
                button: true,
                child: ElevatedButton.icon(
                  key: const ValueKey('create_transactions_button'),
                  onPressed: (_isSaving || _confirmedItems.isEmpty)
                      ? null
                      : _createTransactions,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.account_balance_wallet),
                  label: Text(
                    _isSaving
                        ? 'Guardando...'
                        : 'Crear ${_confirmedItems.length} transacciones en Finanzas',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.finance,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Ticket result widget
// ---------------------------------------------------------------------------

class _TicketResultWidget extends StatelessWidget {
  const _TicketResultWidget({
    required this.result,
    required this.confirmedItems,
    required this.onToggleItem,
  });

  final _TicketResult result;
  final Set<int> confirmedItems;
  final ValueChanged<int> onToggleItem;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outline.withAlpha(60)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.receipt_long, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    result.store.isNotEmpty ? result.store : 'Tienda',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                if (result.date.isNotEmpty)
                  Text(
                    result.date,
                    style: theme.textTheme.bodySmall,
                  ),
              ],
            ),
            const Divider(height: 20),
            Text(
              'Items (selecciona los que importar)',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            const SizedBox(height: 8),
            ...result.items.asMap().entries.map((entry) {
              final i = entry.key;
              final item = entry.value;
              final isSelected = confirmedItems.contains(i);
              return CheckboxListTile(
                key: ValueKey('ticket_item_$i'),
                value: isSelected,
                onChanged: (_) => onToggleItem(i),
                title: Text(item.name),
                subtitle: Text(item.category),
                secondary: Text(
                  '\$${item.price.toStringAsFixed(2)}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.finance,
                  ),
                ),
                controlAffinity: ListTileControlAffinity.leading,
                dense: true,
                contentPadding: EdgeInsets.zero,
              );
            }),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total del ticket',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  '\$${result.total.toStringAsFixed(2)}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.finance,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Data models
// ---------------------------------------------------------------------------

class _TicketItem {
  const _TicketItem({
    required this.name,
    required this.price,
    required this.category,
    required this.isFood,
  });

  final String name;
  final double price;
  final String category;
  final bool isFood;

  factory _TicketItem.fromJson(Map<String, dynamic> json) {
    return _TicketItem(
      name: (json['name'] as String?) ?? 'Item',
      price: _toDouble(json['price']),
      category: (json['category'] as String?) ?? 'Otro',
      isFood: (json['isFood'] as bool?) ?? false,
    );
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }
}

class _TicketResult {
  const _TicketResult({
    required this.store,
    required this.date,
    required this.items,
    required this.total,
  });

  final String store;
  final String date;
  final List<_TicketItem> items;
  final double total;

  DateTime? get parsedDate {
    try {
      return DateTime.parse(date);
    } on FormatException {
      return null;
    }
  }

  factory _TicketResult.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final items = <_TicketItem>[];
    if (rawItems is List) {
      for (final item in rawItems) {
        if (item is Map<String, dynamic>) {
          items.add(_TicketItem.fromJson(item));
        }
      }
    }
    return _TicketResult(
      store: (json['store'] as String?) ?? '',
      date: (json['date'] as String?) ?? '',
      items: items,
      total: _TicketItem._toDouble(json['total']),
    );
  }
}
