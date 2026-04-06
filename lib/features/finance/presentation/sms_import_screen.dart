import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:life_os/core/constants/app_colors.dart';
import 'package:life_os/core/providers/providers.dart';
import 'package:life_os/features/finance/domain/finance_input.dart';
import 'package:life_os/features/finance/services/transaction_parser.dart';

// ---------------------------------------------------------------------------
// State for the SMS/Clipboard import screen
// ---------------------------------------------------------------------------

class _ImportEntry {
  _ImportEntry({required this.parsed, bool selected = true})
      : selected = selected;

  final ParsedTransaction parsed;
  bool selected;
}

// ---------------------------------------------------------------------------
// SMS Import Screen
// ---------------------------------------------------------------------------

/// Pantalla para importar transacciones desde SMS (Android) o portapapeles
/// (iOS/Universal).
///
/// En Android intenta leer SMS recientes de numeros bancarios conocidos.
/// En iOS (y como fallback universal) lee el portapapeles.
class SmsImportScreen extends ConsumerStatefulWidget {
  const SmsImportScreen({super.key});

  @override
  ConsumerState<SmsImportScreen> createState() => _SmsImportScreenState();
}

class _SmsImportScreenState extends ConsumerState<SmsImportScreen> {
  final List<_ImportEntry> _entries = [];
  bool _isLoading = false;
  String? _errorMessage;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    // On iOS always fall back to clipboard; on Android try SMS first.
    if (Platform.isAndroid) {
      _loadFromSmsOrClipboard();
    } else {
      _loadFromClipboard();
    }
  }

  // ---------------------------------------------------------------------------
  // Data loading
  // ---------------------------------------------------------------------------

  /// On Android we try to use the telephony platform channel to read SMS.
  /// Since we don't have the `telephony` package in pubspec.yaml, we use a
  /// MethodChannel to call native SMS reading, gracefully degrading to the
  /// clipboard parser when not available.
  Future<void> _loadFromSmsOrClipboard() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Attempt to read SMS via platform channel.
      const channel = MethodChannel('life_os/sms');
      final List<dynamic>? smsList =
          await channel.invokeMethod<List<dynamic>>('getRecentBankSms');

      if (smsList != null && smsList.isNotEmpty) {
        final parsed = smsList
            .whereType<String>()
            .map(TransactionParser.parse)
            .where((p) => p != null)
            .cast<ParsedTransaction>()
            .toList();

        setState(() {
          _entries.addAll(parsed.map((p) => _ImportEntry(parsed: p)));
        });
      } else {
        // Fall back to clipboard if no SMS results.
        await _loadFromClipboard();
      }
    } on PlatformException {
      // Platform channel not available — fall back to clipboard.
      await _loadFromClipboard();
    } catch (_) {
      await _loadFromClipboard();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadFromClipboard() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      final text = data?.text ?? '';

      if (text.isNotEmpty) {
        final parsed = TransactionParser.parse(text);
        if (parsed != null) {
          setState(() {
            _entries.clear();
            _entries.add(_ImportEntry(parsed: parsed));
          });
        } else {
          setState(() => _errorMessage = 'No se encontro una transaccion en el portapapeles.');
        }
      } else {
        setState(() => _errorMessage = 'El portapapeles esta vacio.');
      }
    } catch (e) {
      setState(() => _errorMessage = 'Error al leer el portapapeles: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Manually parse text entered by the user.
  Future<void> _parseManualText(String text) async {
    final parsed = TransactionParser.parse(text);
    if (parsed == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo detectar una transaccion en el texto.')),
      );
      return;
    }
    setState(() => _entries.insert(0, _ImportEntry(parsed: parsed)));
  }

  // ---------------------------------------------------------------------------
  // Import
  // ---------------------------------------------------------------------------

  Future<void> _importSelected() async {
    final selected = _entries.where((e) => e.selected).toList();
    if (selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona al menos una transaccion.')),
      );
      return;
    }

    final notifier = ref.read(financeNotifierProvider);
    var successCount = 0;
    for (final entry in selected) {
      final result = await notifier.addTransaction(TransactionInput(
        type: 'expense',
        amountCents: entry.parsed.amountCents,
        note: entry.parsed.merchant ?? 'Importado',
        date: entry.parsed.date ?? DateTime.now(),
      ));
      if (result.isSuccess) successCount++;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$successCount transaccion${successCount == 1 ? '' : 'es'} importada${successCount == 1 ? '' : 's'}'),
      ),
    );
    context.pop();
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final selectedCount = _entries.where((e) => e.selected).length;

    return Scaffold(
      key: const ValueKey('sms-import-screen'),
      appBar: AppBar(
        title: Semantics(
          header: true,
          child: const Text('Importar transacciones'),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: AppColors.finance,
        actions: [
          if (_entries.isNotEmpty)
            TextButton(
              key: const ValueKey('sms-import-select-all'),
              onPressed: () {
                final allSelected = _entries.every((e) => e.selected);
                setState(() {
                  for (final e in _entries) {
                    e.selected = !allSelected;
                  }
                });
              },
              child: const Text('Seleccionar todo'),
            ),
        ],
      ),
      body: Column(
        children: [
          // --- Manual text input ---
          _ManualInputBar(
            key: const ValueKey('sms-import-manual-input'),
            onSubmit: _parseManualText,
            onPasteClipboard: _loadFromClipboard,
          ),

          const Divider(height: 1),

          // --- Content area ---
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _entries.isEmpty
                    ? _EmptyState(
                        errorMessage: _errorMessage,
                        onRetry: Platform.isAndroid
                            ? _loadFromSmsOrClipboard
                            : _loadFromClipboard,
                      )
                    : ListView.builder(
                        key: const ValueKey('sms-import-list'),
                        padding: const EdgeInsets.only(bottom: 100),
                        itemCount: _entries.length,
                        itemBuilder: (context, index) {
                          final entry = _entries[index];
                          return _ImportEntryTile(
                            key: ValueKey('sms-import-entry-$index'),
                            entry: entry,
                            onToggle: (value) =>
                                setState(() => entry.selected = value),
                          );
                        },
                      ),
          ),
        ],
      ),
      bottomNavigationBar: _entries.isNotEmpty
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: FilledButton.icon(
                  key: const ValueKey('sms-import-confirm-button'),
                  onPressed: selectedCount > 0 ? _importSelected : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.finance,
                    minimumSize: const Size.fromHeight(52),
                  ),
                  icon: const Icon(Icons.download_done_outlined),
                  label: Text(
                    selectedCount > 0
                        ? 'Importar $selectedCount transaccion${selectedCount == 1 ? '' : 'es'}'
                        : 'Selecciona transacciones',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }
}

// ---------------------------------------------------------------------------
// Private widgets
// ---------------------------------------------------------------------------

class _ManualInputBar extends StatefulWidget {
  const _ManualInputBar({
    super.key,
    required this.onSubmit,
    required this.onPasteClipboard,
  });

  final Future<void> Function(String) onSubmit;
  final VoidCallback onPasteClipboard;

  @override
  State<_ManualInputBar> createState() => _ManualInputBarState();
}

class _ManualInputBarState extends State<_ManualInputBar> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              label: 'Pegar o escribir texto de transaccion',
              textField: true,
              child: TextField(
                key: const ValueKey('sms-import-text-field'),
                controller: _controller,
                maxLines: 2,
                minLines: 1,
                decoration: InputDecoration(
                  hintText: 'Pega el SMS o texto del banco aqui...',
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  suffixIcon: IconButton(
                    tooltip: 'Pegar portapapeles',
                    icon: const Icon(Icons.content_paste_rounded),
                    onPressed: widget.onPasteClipboard,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Semantics(
            label: 'Analizar texto',
            button: true,
            child: IconButton.filled(
              key: const ValueKey('sms-import-analyze-button'),
              onPressed: () {
                final text = _controller.text.trim();
                if (text.isNotEmpty) {
                  widget.onSubmit(text);
                  _controller.clear();
                }
              },
              style: IconButton.styleFrom(
                backgroundColor: AppColors.finance,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.search),
              tooltip: 'Analizar',
            ),
          ),
        ],
      ),
    );
  }
}

class _ImportEntryTile extends StatelessWidget {
  const _ImportEntryTile({
    super.key,
    required this.entry,
    required this.onToggle,
  });

  final _ImportEntry entry;
  final ValueChanged<bool> onToggle;

  String _formatAmount(int cents) {
    final formatter = NumberFormat('#,##0', 'es_CO');
    return '\$${formatter.format(cents)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final parsed = entry.parsed;
    final maxPreview = parsed.rawText.length > 80
        ? '${parsed.rawText.substring(0, 80)}...'
        : parsed.rawText;

    return Semantics(
      label:
          '${entry.selected ? 'Seleccionada' : 'No seleccionada'}: ${_formatAmount(parsed.amountCents)}${parsed.merchant != null ? ' en ${parsed.merchant}' : ''}',
      child: CheckboxListTile(
        key: key,
        value: entry.selected,
        onChanged: (v) => onToggle(v ?? false),
        activeColor: AppColors.finance,
        title: Text(
          _formatAmount(parsed.amountCents),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.finance,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (parsed.merchant != null)
              Text(
                parsed.merchant!,
                style: theme.textTheme.bodyMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            Text(
              maxPreview,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withAlpha(100),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        controlAffinity: ListTileControlAffinity.leading,
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({this.errorMessage, this.onRetry});

  final String? errorMessage;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.sms_outlined,
              size: 56,
              color: AppColors.finance.withAlpha(120),
            ),
            const SizedBox(height: 16),
            Text(
              errorMessage ?? 'No se encontraron transacciones',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Pega el texto de tu banco en el campo de arriba o toca "Pegar portapapeles".',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              OutlinedButton.icon(
                key: const ValueKey('sms-import-retry-button'),
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Clipboard sniff banner (used from other screens to offer pre-fill)
// ---------------------------------------------------------------------------

/// Shows a dismissible banner at the top of the Finance screen when the
/// clipboard contains what looks like a bank transaction.
class ClipboardTransactionBanner extends ConsumerStatefulWidget {
  const ClipboardTransactionBanner({super.key});

  @override
  ConsumerState<ClipboardTransactionBanner> createState() =>
      _ClipboardTransactionBannerState();
}

class _ClipboardTransactionBannerState
    extends ConsumerState<ClipboardTransactionBanner> {
  ParsedTransaction? _detected;
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();
    _sniffClipboard();
  }

  Future<void> _sniffClipboard() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      final text = data?.text ?? '';
      if (text.isEmpty) return;
      final parsed = TransactionParser.parse(text);
      if (parsed != null && mounted) {
        setState(() => _detected = parsed);
      }
    } catch (_) {
      // Ignore clipboard errors.
    }
  }

  String _formatAmount(int cents) {
    final formatter = NumberFormat('#,##0', 'es_CO');
    return '\$${formatter.format(cents)}';
  }

  @override
  Widget build(BuildContext context) {
    if (_dismissed || _detected == null) return const SizedBox.shrink();
    final parsed = _detected!;

    return Material(
      color: AppColors.finance.withAlpha(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            const Icon(Icons.content_paste_rounded,
                color: AppColors.finance, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Transaccion detectada: ${_formatAmount(parsed.amountCents)}. ¿Registrar?',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.finance,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            TextButton(
              key: const ValueKey('clipboard-banner-register'),
              onPressed: () {
                setState(() => _dismissed = true);
                GoRouter.of(context).push(
                  '/finance/sms-import',
                );
              },
              style: TextButton.styleFrom(foregroundColor: AppColors.finance),
              child: const Text('Ver'),
            ),
            IconButton(
              key: const ValueKey('clipboard-banner-dismiss'),
              onPressed: () => setState(() => _dismissed = true),
              icon: const Icon(Icons.close, size: 18),
              tooltip: 'Cerrar',
            ),
          ],
        ),
      ),
    );
  }
}
