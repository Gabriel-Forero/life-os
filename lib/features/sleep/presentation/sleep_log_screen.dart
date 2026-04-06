import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:life_os/core/constants/app_colors.dart';
import 'package:life_os/core/providers/providers.dart';
import 'package:life_os/core/router/app_router.dart';
import 'package:life_os/features/sleep/domain/sleep_input.dart';
import 'package:life_os/features/sleep/domain/sleep_validators.dart';

// ---------------------------------------------------------------------------
// Quality labels
// ---------------------------------------------------------------------------

enum _QualityLabel { muyMalo, malo, regular, bueno, excelente }

extension _QualityLabelExt on _QualityLabel {
  String get displayName => switch (this) {
        _QualityLabel.muyMalo => 'Muy malo',
        _QualityLabel.malo => 'Malo',
        _QualityLabel.regular => 'Regular',
        _QualityLabel.bueno => 'Bueno',
        _QualityLabel.excelente => 'Excelente',
      };

  IconData get icon => switch (this) {
        _QualityLabel.muyMalo => Icons.sentiment_very_dissatisfied,
        _QualityLabel.malo => Icons.sentiment_dissatisfied,
        _QualityLabel.regular => Icons.sentiment_neutral,
        _QualityLabel.bueno => Icons.sentiment_satisfied,
        _QualityLabel.excelente => Icons.sentiment_very_satisfied,
      };
}

// ---------------------------------------------------------------------------
// Local interruption model (before the DB log is saved)
// ---------------------------------------------------------------------------

class _LocalInterruption {
  _LocalInterruption({
    required this.time,
    required this.durationMinutes,
    this.reason,
  });

  DateTime time;
  int durationMinutes;
  String? reason;
}

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class SleepLogScreen extends ConsumerStatefulWidget {
  const SleepLogScreen({super.key});

  @override
  ConsumerState<SleepLogScreen> createState() => _SleepLogScreenState();
}

class _SleepLogScreenState extends ConsumerState<SleepLogScreen> {
  // --- State machine ---
  // Phase 0: Not yet started
  // Phase 1: Sleep mode (bedTime recorded, waiting for wake)
  // Phase 2: Morning review (wakeTime recorded, review + confirm)
  // Phase 3: Saved
  int _phase = 0;

  DateTime? _bedTime;
  DateTime? _wakeTime;
  int _minutesToFallAsleep = 15; // slider value
  int _qualityRating = 3;
  String _note = '';
  bool _isSaving = false;
  int? _savedScore;

  final _noteController = TextEditingController();
  final List<_LocalInterruption> _interruptions = [];

  // --- Wake-check dialog shown once ---
  bool _wakeDialogShown = false;

  // --- Alarm ---
  DateTime? _alarmTime;
  TimeOfDay? _savedAlarmTod;

  @override
  void initState() {
    super.initState();
    _loadAlarm();
    // Feature 3: if returning to app while in sleep mode (phase 1), prompt
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_phase == 1 && !_wakeDialogShown) {
        _checkAutoWake();
        _showWakeCheckDialog();
      }
    });
  }

  Future<void> _loadAlarm() async {
    final alarmService = ref.read(alarmServiceProvider);
    final alarm = await alarmService.getNextAlarm();
    final saved = await alarmService.getSavedAlarmTime();
    if (mounted) {
      setState(() {
        _alarmTime = alarm;
        _savedAlarmTod = saved != null
            ? TimeOfDay(hour: saved.hour, minute: saved.minute)
            : null;
      });
    }
  }

  /// If we're in sleep mode and the alarm time has passed, auto-set wake time.
  void _checkAutoWake() {
    if (_phase == 1 && _alarmTime != null && _wakeTime == null) {
      final now = DateTime.now();
      if (now.isAfter(_alarmTime!)) {
        setState(() {
          _wakeTime = _alarmTime;
          _phase = 2;
        });
      }
    }
  }

  Future<void> _pickAlarmTime() async {
    final alarmService = ref.read(alarmServiceProvider);
    final initial = _savedAlarmTod ?? const TimeOfDay(hour: 7, minute: 0);
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      helpText: 'Hora de tu alarma',
      cancelText: 'Cancelar',
      confirmText: 'Guardar',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context)
              .colorScheme
              .copyWith(primary: AppColors.sleep),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      await alarmService.saveAlarmTime(picked.hour, picked.minute);
      if (mounted) {
        setState(() => _savedAlarmTod = picked);
        await _loadAlarm();
      }
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Feature 3: Auto-detection dialog
  // ---------------------------------------------------------------------------

  Future<void> _showWakeCheckDialog() async {
    if (!mounted) return;
    _wakeDialogShown = true;
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Seguimiento de sueno'),
        content: const Text('¿Te despertaste durante la noche?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('No, solo revise el telefono'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Si, registrar interrupcion'),
          ),
        ],
      ),
    );
    if (result == true && mounted) {
      _addInterruptionDialog();
    }
  }

  // ---------------------------------------------------------------------------
  // Feature 1: Bed time — "Me voy a dormir"
  // ---------------------------------------------------------------------------

  void _goToSleep() {
    setState(() {
      _bedTime = DateTime.now();
      _phase = 1;
      _wakeDialogShown = false;
    });
  }

  // ---------------------------------------------------------------------------
  // Feature 1: Wake time — "Ya desperte"
  // ---------------------------------------------------------------------------

  void _wakeUp() {
    setState(() {
      _wakeTime = DateTime.now();
      _phase = 2;
    });
  }

  // ---------------------------------------------------------------------------
  // Feature 2 & 4: Add interruption dialog
  // ---------------------------------------------------------------------------

  Future<void> _addInterruptionDialog({_LocalInterruption? editing}) async {
    final now = DateTime.now();
    DateTime pickedTime = editing?.time ?? now;
    int durationMinutes = editing?.durationMinutes ?? 15;
    String reason = editing?.reason ?? '';

    final List<int> durationOptions = [5, 10, 15, 20, 30, 45, 60];
    if (!durationOptions.contains(durationMinutes)) durationMinutes = 15;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDlgState) {
            return AlertDialog(
              title: Text(editing == null
                  ? 'Registrar interrupcion'
                  : 'Editar interrupcion'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Time picker button
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.access_time),
                      title: Text(
                        'Hora: ${_fmtTime(pickedTime)}',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      onTap: () async {
                        final t = await showTimePicker(
                          context: ctx,
                          initialTime: TimeOfDay.fromDateTime(pickedTime),
                          helpText: 'Hora de interrupcion',
                        );
                        if (t != null) {
                          setDlgState(() {
                            pickedTime = DateTime(
                              now.year,
                              now.month,
                              now.day,
                              t.hour,
                              t.minute,
                            );
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    // Duration selector
                    Text('Duracion (minutos)',
                        style: Theme.of(ctx).textTheme.labelMedium),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      children: durationOptions.map((d) {
                        return ChoiceChip(
                          label: Text('$d'),
                          selected: durationMinutes == d,
                          onSelected: (_) =>
                              setDlgState(() => durationMinutes = d),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    // Reason
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Motivo (opcional)',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      controller: TextEditingController(text: reason),
                      onChanged: (v) => reason = v,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed == true) {
      setState(() {
        if (editing != null) {
          editing.time = pickedTime;
          editing.durationMinutes = durationMinutes;
          editing.reason = reason.isEmpty ? null : reason;
        } else {
          _interruptions.add(_LocalInterruption(
            time: pickedTime,
            durationMinutes: durationMinutes,
            reason: reason.isEmpty ? null : reason,
          ));
        }
      });
    }
  }

  // ---------------------------------------------------------------------------
  // Feature 4: Confirm and save
  // ---------------------------------------------------------------------------

  Future<void> _confirmAndSave() async {
    if (_bedTime == null || _wakeTime == null) return;
    setState(() => _isSaving = true);

    final notifier = ref.read(sleepNotifierProvider);
    final hoursSlept =
        _wakeTime!.difference(_bedTime!).inMinutes / 60.0;
    final score = calculateSleepScore(
      hoursSlept: hoursSlept,
      qualityRating: _qualityRating,
      interruptionCount: _interruptions.length,
    );

    final result = await notifier.logSleep(SleepInput(
      date: DateTime.now(),
      bedTime: _bedTime!,
      wakeTime: _wakeTime!,
      qualityRating: _qualityRating,
      note: _note.isEmpty ? null : _note,
    ));

    if (result.isFailure) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.failureOrNull?.userMessage ?? 'Error al guardar'),
        ),
      );
      return;
    }

    final logId = result.valueOrNull!;

    // Persist interruptions
    for (final intr in _interruptions) {
      await notifier.addInterruption(SleepInterruptionInput(
        sleepLogId: logId,
        time: intr.time,
        durationMinutes: intr.durationMinutes,
        reason: intr.reason,
      ));
    }

    if (!mounted) return;
    setState(() {
      _savedScore = score;
      _phase = 3;
      _isSaving = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Noche confirmada y guardada!')),
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  String _fmtTime(DateTime? dt) {
    if (dt == null) return '--:--';
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  double? get _hoursSlept {
    if (_bedTime == null || _wakeTime == null) return null;
    return _wakeTime!.difference(_bedTime!).inMinutes / 60.0;
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const sleepColor = AppColors.sleep;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Registro de Sueno'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: sleepColor,
        actions: [
          // Navigation: Energy tracker
          IconButton(
            icon: const Icon(Icons.bolt_outlined),
            tooltip: 'Energia',
            onPressed: () => context.push(AppRoutes.energy),
          ),
          // Navigation: Circadian
          IconButton(
            icon: const Icon(Icons.query_stats),
            tooltip: 'Ritmo Circadiano',
            onPressed: () => context.push(AppRoutes.circadian),
          ),
          // Navigation: HealthKit (coming soon)
          IconButton(
            icon: const Icon(Icons.favorite_outline),
            tooltip: 'Importar datos de salud',
            onPressed: () => _showHealthImportDialog(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Phase 0: "Me voy a dormir"
            if (_phase == 0) _buildPhase0(theme, sleepColor),

            // Phase 1: Sleep mode active
            if (_phase == 1) _buildPhase1(theme, sleepColor),

            // Phase 2: Morning review
            if (_phase == 2) _buildPhase2(theme, sleepColor),

            // Phase 3: Saved — show score
            if (_phase == 3) _buildPhase3(theme, sleepColor),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Phase 0 — Start
  // ---------------------------------------------------------------------------

  Widget _buildPhase0(ThemeData theme, Color sleepColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          color: sleepColor.withAlpha(20),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Icon(Icons.bedtime_outlined, color: sleepColor, size: 64),
                const SizedBox(height: 12),
                Text(
                  'Buenas noches',
                  style: theme.textTheme.headlineMedium
                      ?.copyWith(color: sleepColor, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Toca el boton cuando vayas a dormir para iniciar el seguimiento.',
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // "Me voy a dormir" button
        FilledButton.icon(
          key: const ValueKey('go-to-sleep-button'),
          onPressed: _goToSleep,
          style: FilledButton.styleFrom(
            backgroundColor: sleepColor,
            minimumSize: const Size.fromHeight(56),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          icon: const Icon(Icons.bedtime),
          label: const Text('Me voy a dormir',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ),
        const SizedBox(height: 12),

        // "Tiempo en dormirme" slider
        Card(
          key: const ValueKey('fall-asleep-card'),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tiempo en dormirme',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  '(Cuanto tardas en quedarte dormido habitualmente)',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Slider(
                        key: const ValueKey('fall-asleep-slider'),
                        value: _minutesToFallAsleep.toDouble(),
                        min: 5,
                        max: 30,
                        divisions: 5,
                        label: '$_minutesToFallAsleep min',
                        activeColor: sleepColor,
                        onChanged: (v) =>
                            setState(() => _minutesToFallAsleep = v.round()),
                      ),
                    ),
                    Text('$_minutesToFallAsleep min',
                        style: TextStyle(color: sleepColor, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Alarm configuration card
        Card(
          key: const ValueKey('alarm-config-card'),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: InkWell(
            onTap: _pickAlarmTime,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.alarm, color: sleepColor, size: 28),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mi alarma',
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _savedAlarmTod != null
                              ? 'Configurada a las ${_savedAlarmTod!.hour.toString().padLeft(2, '0')}:${_savedAlarmTod!.minute.toString().padLeft(2, '0')}'
                              : 'Toca para configurar tu hora de despertar',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: _savedAlarmTod != null
                                ? sleepColor
                                : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_savedAlarmTod != null)
                    Text(
                      '${_savedAlarmTod!.hour.toString().padLeft(2, '0')}:${_savedAlarmTod!.minute.toString().padLeft(2, '0')}',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: sleepColor,
                        fontWeight: FontWeight.w800,
                      ),
                    )
                  else
                    Icon(Icons.chevron_right, color: AppColors.lightTextSecondary),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Phase 1 — Sleep mode
  // ---------------------------------------------------------------------------

  Widget _buildPhase1(ThemeData theme, Color sleepColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          key: const ValueKey('sleep-mode-card'),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: sleepColor, width: 1.5),
          ),
          color: sleepColor.withAlpha(15),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Icon(Icons.nightlight_round, color: sleepColor, size: 56),
                const SizedBox(height: 12),
                Text(
                  'Modo sueno activo',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: sleepColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Dormiste a las ${_fmtTime(_bedTime)}',
                  style: theme.textTheme.bodyMedium,
                ),
                if (_alarmTime != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.alarm, color: sleepColor, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'Alarma: ${_fmtTime(_alarmTime)}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: sleepColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Interruptions recorded so far
        if (_interruptions.isNotEmpty) ...[
          Card(
            key: const ValueKey('interruptions-preview-card'),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Interrupciones registradas',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ..._interruptions.map((intr) => _InterruptionTile(
                        interruption: intr,
                        sleepColor: sleepColor,
                        onEdit: () => _addInterruptionDialog(editing: intr),
                      )),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Register interruption
        OutlinedButton.icon(
          key: const ValueKey('register-interruption-button'),
          onPressed: () => _addInterruptionDialog(),
          style: OutlinedButton.styleFrom(
            foregroundColor: sleepColor,
            side: BorderSide(color: sleepColor),
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          icon: const Icon(Icons.add_circle_outline),
          label: const Text('Registrar interrupcion'),
        ),
        const SizedBox(height: 12),

        // Ya desperte button
        FilledButton.icon(
          key: const ValueKey('wake-up-button'),
          onPressed: _wakeUp,
          style: FilledButton.styleFrom(
            backgroundColor: sleepColor,
            minimumSize: const Size.fromHeight(56),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          icon: const Icon(Icons.wb_sunny),
          label: const Text('Ya desperte',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Phase 2 — Morning review
  // ---------------------------------------------------------------------------

  Widget _buildPhase2(ThemeData theme, Color sleepColor) {
    final hours = _hoursSlept;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Timeline summary
        Card(
          key: const ValueKey('morning-timeline-card'),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Resumen de la noche',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _TimeChip(
                      icon: Icons.bedtime_outlined,
                      label: 'Dormi',
                      time: _fmtTime(_bedTime),
                      color: sleepColor,
                    ),
                    const Expanded(
                      child: Divider(endIndent: 0, indent: 0),
                    ),
                    _TimeChip(
                      icon: Icons.wb_sunny_outlined,
                      label: 'Desperte',
                      time: _fmtTime(_wakeTime),
                      color: AppColors.gym,
                    ),
                  ],
                ),
                if (hours != null) ...[
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      '${hours.toStringAsFixed(1)} horas dormidas',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: sleepColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Interruptions list (editable)
        Card(
          key: const ValueKey('interruptions-review-card'),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Interrupciones (${_interruptions.length})',
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      key: const ValueKey('add-interruption-review-button'),
                      onPressed: () => _addInterruptionDialog(),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Agregar'),
                      style: TextButton.styleFrom(foregroundColor: sleepColor),
                    ),
                  ],
                ),
                if (_interruptions.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Sin interrupciones registradas',
                      style: theme.textTheme.bodySmall,
                    ),
                  )
                else
                  ..._interruptions.map((intr) => _InterruptionTile(
                        interruption: intr,
                        sleepColor: sleepColor,
                        onEdit: () => _addInterruptionDialog(editing: intr),
                        onDelete: () =>
                            setState(() => _interruptions.remove(intr)),
                      )),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Quality rating
        Card(
          key: const ValueKey('quality-rating-card'),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Calidad del sueno',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Semantics(
                  label:
                      'Calidad: ${_QualityLabel.values[_qualityRating - 1].displayName}',
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(5, (index) {
                      final rating = index + 1;
                      final label = _QualityLabel.values[index];
                      final isSelected = _qualityRating == rating;
                      return Semantics(
                        button: true,
                        label: label.displayName,
                        selected: isSelected,
                        child: GestureDetector(
                          key: ValueKey('quality-$rating'),
                          onTap: () =>
                              setState(() => _qualityRating = rating),
                          child: Column(
                            children: [
                              Icon(
                                label.icon,
                                size: 36,
                                color:
                                    isSelected ? sleepColor : Colors.grey,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$rating',
                                style: TextStyle(
                                  color:
                                      isSelected ? sleepColor : Colors.grey,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Note
        Card(
          key: const ValueKey('sleep-note-card'),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nota (opcional)',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextField(
                  key: const ValueKey('sleep-note-field'),
                  controller: _noteController,
                  maxLength: 200,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Como fue tu sueno...',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) => _note = v,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Sleep score preview
        if (_hoursSlept != null) ...[
          _ScorePreview(
            hours: _hoursSlept!,
            qualityRating: _qualityRating,
            interruptionCount: _interruptions.length,
            sleepColor: sleepColor,
            theme: theme,
          ),
          const SizedBox(height: 16),
        ],

        // Confirm button
        FilledButton.icon(
          key: const ValueKey('confirm-night-button'),
          onPressed: _isSaving ? null : _confirmAndSave,
          style: FilledButton.styleFrom(
            backgroundColor: sleepColor,
            minimumSize: const Size.fromHeight(56),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          icon: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.check_circle_outline),
          label: Text(
            _isSaving ? 'Guardando...' : 'Confirmar noche',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Phase 3 — Saved
  // ---------------------------------------------------------------------------

  Widget _buildPhase3(ThemeData theme, Color sleepColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          label: 'Puntuacion de sueno: $_savedScore',
          child: Card(
            key: const ValueKey('sleep-score-card'),
            color: sleepColor.withAlpha(30),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: sleepColor, width: 1.5),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(
                    '${_savedScore ?? '--'}',
                    style: theme.textTheme.displayLarge?.copyWith(
                      color: sleepColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Puntuacion de Sueno',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(color: sleepColor),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_hoursSlept?.toStringAsFixed(1) ?? '--'} horas dormidas',
                    style: theme.textTheme.bodyMedium,
                  ),
                  if (_interruptions.isNotEmpty)
                    Text(
                      '${_interruptions.length} interrupcion(es) registrada(s)',
                      style: theme.textTheme.bodySmall,
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: () => context.push(AppRoutes.sleepHistory),
          style: FilledButton.styleFrom(
            backgroundColor: sleepColor,
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          icon: const Icon(Icons.bar_chart),
          label: const Text('Ver historial'),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // HealthKit coming-soon dialog
  // ---------------------------------------------------------------------------

  void _showHealthImportDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Importar datos de salud'),
        content: const Text(
          'La integracion con plataformas de salud (HealthKit / Health Connect) '
          'estara disponible proximamente.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: FilledButton.styleFrom(backgroundColor: AppColors.sleep),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Helper widgets
// ---------------------------------------------------------------------------

class _TimeChip extends StatelessWidget {
  const _TimeChip({
    required this.icon,
    required this.label,
    required this.time,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String time;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: color, fontSize: 11)),
        Text(
          time,
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _InterruptionTile extends StatelessWidget {
  const _InterruptionTile({
    required this.interruption,
    required this.sleepColor,
    required this.onEdit,
    this.onDelete,
  });

  final _LocalInterruption interruption;
  final Color sleepColor;
  final VoidCallback onEdit;
  final VoidCallback? onDelete;

  String _fmtTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(Icons.alarm, color: sleepColor, size: 20),
      title: Text(
        '${_fmtTime(interruption.time)} — ${interruption.durationMinutes} min',
        style: const TextStyle(fontSize: 14),
      ),
      subtitle: interruption.reason != null
          ? Text(interruption.reason!, style: const TextStyle(fontSize: 12))
          : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 18),
            onPressed: onEdit,
            tooltip: 'Editar',
          ),
          if (onDelete != null)
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
              onPressed: onDelete,
              tooltip: 'Eliminar',
            ),
        ],
      ),
    );
  }
}

class _ScorePreview extends StatelessWidget {
  const _ScorePreview({
    required this.hours,
    required this.qualityRating,
    required this.interruptionCount,
    required this.sleepColor,
    required this.theme,
  });

  final double hours;
  final int qualityRating;
  final int interruptionCount;
  final Color sleepColor;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final score = calculateSleepScore(
      hoursSlept: hours,
      qualityRating: qualityRating,
      interruptionCount: interruptionCount,
    );
    return Card(
      key: const ValueKey('score-preview-card'),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: sleepColor.withAlpha(15),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          children: [
            Icon(Icons.star_outline, color: sleepColor),
            const SizedBox(width: 12),
            Text(
              'Puntuacion estimada: ',
              style: theme.textTheme.bodyMedium,
            ),
            Text(
              '$score / 100',
              style: TextStyle(
                color: sleepColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
