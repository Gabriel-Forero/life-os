import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:life_os/core/constants/app_colors.dart';

// ---------------------------------------------------------------------------
// Modelos mock
// ---------------------------------------------------------------------------

class _MockMeasurement {
  const _MockMeasurement({
    required this.date,
    this.weightKg,
    this.bodyFatPercent,
    this.waistCm,
    this.chestCm,
    this.armCm,
  });

  final DateTime date;
  final double? weightKg;
  final double? bodyFatPercent;
  final double? waistCm;
  final double? chestCm;
  final double? armCm;
}

final _mockMeasurements = [
  _MockMeasurement(
    date: DateTime.now(),
    weightKg: 78.4,
    bodyFatPercent: 18.2,
    waistCm: 84.0,
    chestCm: 100.5,
    armCm: 35.0,
  ),
  _MockMeasurement(
    date: DateTime.now().subtract(const Duration(days: 7)),
    weightKg: 79.1,
    bodyFatPercent: 18.8,
    waistCm: 85.0,
    chestCm: 100.0,
    armCm: 34.5,
  ),
  _MockMeasurement(
    date: DateTime.now().subtract(const Duration(days: 14)),
    weightKg: 79.8,
    bodyFatPercent: 19.3,
    waistCm: 86.0,
    chestCm: 99.5,
    armCm: 34.0,
  ),
  _MockMeasurement(
    date: DateTime.now().subtract(const Duration(days: 21)),
    weightKg: 80.2,
    bodyFatPercent: 19.6,
    waistCm: 86.5,
    chestCm: 99.0,
    armCm: 33.8,
  ),
  _MockMeasurement(
    date: DateTime.now().subtract(const Duration(days: 30)),
    weightKg: 81.0,
    bodyFatPercent: 20.1,
    waistCm: 88.0,
    chestCm: 98.5,
    armCm: 33.5,
  ),
];

// Tendencia: positiva = mejora (bajar peso/grasa/cintura, subir pecho/brazo)
enum _Trend { improving, worsening, neutral }

extension _TrendIcon on _Trend {
  IconData get icon => switch (this) {
        _Trend.improving => Icons.trending_down,
        _Trend.worsening => Icons.trending_up,
        _Trend.neutral => Icons.trending_flat,
      };

  Color get color => switch (this) {
        _Trend.improving => AppColors.success,
        _Trend.worsening => AppColors.error,
        _Trend.neutral => Colors.grey,
      };
}

// ---------------------------------------------------------------------------
// Pantalla: medidas corporales
// ---------------------------------------------------------------------------

/// Formulario para registrar medidas corporales y visualizar historial
/// con indicadores de tendencia.
///
/// **Fase 2** — funcionalidad de graficas y analisis avanzado se implementa
/// en la siguiente fase.
///
/// Shell de presentacion — la integracion con Riverpod se realizara en un
/// paso posterior.
///
/// Accesibilidad: A11Y-GYM-05 — todos los campos tienen etiquetas semanticas
/// y el formulario usa teclado numerico.
class BodyMeasurementsScreen extends StatefulWidget {
  const BodyMeasurementsScreen({super.key});

  @override
  State<BodyMeasurementsScreen> createState() =>
      _BodyMeasurementsScreenState();
}

class _BodyMeasurementsScreenState extends State<BodyMeasurementsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _weightController = TextEditingController();
  final _bodyFatController = TextEditingController();
  final _waistController = TextEditingController();
  final _chestController = TextEditingController();
  final _armController = TextEditingController();

  bool _formExpanded = false;

  @override
  void dispose() {
    _weightController.dispose();
    _bodyFatController.dispose();
    _waistController.dispose();
    _chestController.dispose();
    _armController.dispose();
    super.dispose();
  }

  void _handleSave() {
    if (!_formKey.currentState!.validate()) return;
    // Validar que al menos un campo tenga valor
    final hasAnyValue = [
      _weightController.text,
      _bodyFatController.text,
      _waistController.text,
      _chestController.text,
      _armController.text,
    ].any((v) => v.trim().isNotEmpty);

    if (!hasAnyValue) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingresa al menos una medida para guardar'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // TODO: llamar a GymNotifier.saveMeasurement cuando se conecte
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Medidas guardadas correctamente'),
        backgroundColor: AppColors.gym,
      ),
    );
    setState(() => _formExpanded = false);
    _weightController.clear();
    _bodyFatController.clear();
    _waistController.clear();
    _chestController.clear();
    _armController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final latest = _mockMeasurements.isNotEmpty ? _mockMeasurements.first : null;
    final previous = _mockMeasurements.length > 1 ? _mockMeasurements[1] : null;

    return Scaffold(
      key: const ValueKey('body-measurements-screen'),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Semantics(
          header: true,
          child: const Text('Medidas corporales'),
        ),
        actions: [
          // Etiqueta Fase 2
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Semantics(
              label: 'Funcionalidad de Fase 2',
              child: Container(
                key: const ValueKey('body-measurements-phase2-badge'),
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.gym.withAlpha(20),
                  border: Border.all(color: AppColors.gym.withAlpha(80)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Fase 2',
                  style: TextStyle(
                    color: AppColors.gym,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          // --- Resumen actual ---
          if (latest != null) ...[
            Semantics(
              header: true,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'Ultima medicion',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            _CurrentMeasurementCard(
              key: const ValueKey('body-measurements-current-card'),
              latest: latest,
              previous: previous,
            ),
            const SizedBox(height: 16),
          ],

          // --- Formulario para nueva medicion ---
          _NewMeasurementForm(
            key: const ValueKey('body-measurements-form-section'),
            formKey: _formKey,
            weightController: _weightController,
            bodyFatController: _bodyFatController,
            waistController: _waistController,
            chestController: _chestController,
            armController: _armController,
            isExpanded: _formExpanded,
            onToggleExpand: () =>
                setState(() => _formExpanded = !_formExpanded),
            onSave: _handleSave,
          ),
          const SizedBox(height: 16),

          // --- Historial ---
          Semantics(
            header: true,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'Historial',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          if (_mockMeasurements.isEmpty)
            _EmptyMeasurementsHistory(
              key: const ValueKey('body-measurements-empty-history'),
            )
          else
            ..._mockMeasurements.asMap().entries.map(
              (entry) => _MeasurementHistoryRow(
                key: ValueKey('measurement-history-${entry.key}'),
                measurement: entry.value,
                previous: entry.key < _mockMeasurements.length - 1
                    ? _mockMeasurements[entry.key + 1]
                    : null,
                isLatest: entry.key == 0,
              ),
            ),

          // Nota de Fase 2
          const SizedBox(height: 16),
          Semantics(
            label: 'Nota: los graficos de tendencia estaran disponibles en Fase 2',
            child: Container(
              key: const ValueKey('body-measurements-phase2-note'),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.gym.withAlpha(10),
                border: Border.all(color: AppColors.gym.withAlpha(40)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: AppColors.gym,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Los graficos de tendencia y analisis avanzado estaran disponibles en Fase 2.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.gym,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Widget: tarjeta con medicion actual
// TODO: Extract to separate widget file
// ---------------------------------------------------------------------------

class _CurrentMeasurementCard extends StatelessWidget {
  const _CurrentMeasurementCard({
    super.key,
    required this.latest,
    required this.previous,
  });

  final _MockMeasurement latest;
  final _MockMeasurement? previous;

  _Trend _weightTrend() {
    if (previous?.weightKg == null || latest.weightKg == null) {
      return _Trend.neutral;
    }
    return latest.weightKg! < previous!.weightKg!
        ? _Trend.improving
        : latest.weightKg! > previous!.weightKg!
            ? _Trend.worsening
            : _Trend.neutral;
  }

  _Trend _bodyFatTrend() {
    if (previous?.bodyFatPercent == null || latest.bodyFatPercent == null) {
      return _Trend.neutral;
    }
    return latest.bodyFatPercent! < previous!.bodyFatPercent!
        ? _Trend.improving
        : latest.bodyFatPercent! > previous!.bodyFatPercent!
            ? _Trend.worsening
            : _Trend.neutral;
  }

  _Trend _waistTrend() {
    if (previous?.waistCm == null || latest.waistCm == null) {
      return _Trend.neutral;
    }
    return latest.waistCm! < previous!.waistCm!
        ? _Trend.improving
        : latest.waistCm! > previous!.waistCm!
            ? _Trend.worsening
            : _Trend.neutral;
  }

  _Trend _chestTrend() {
    if (previous?.chestCm == null || latest.chestCm == null) {
      return _Trend.neutral;
    }
    return latest.chestCm! > previous!.chestCm!
        ? _Trend.improving
        : latest.chestCm! < previous!.chestCm!
            ? _Trend.worsening
            : _Trend.neutral;
  }

  _Trend _armTrend() {
    if (previous?.armCm == null || latest.armCm == null) {
      return _Trend.neutral;
    }
    return latest.armCm! > previous!.armCm!
        ? _Trend.improving
        : latest.armCm! < previous!.armCm!
            ? _Trend.worsening
            : _Trend.neutral;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Fila superior: peso y grasa corporal
            Row(
              children: [
                if (latest.weightKg != null)
                  Expanded(
                    child: _MeasurementTile(
                      key: const ValueKey('current-weight-tile'),
                      label: 'Peso',
                      value: '${latest.weightKg} kg',
                      trend: _weightTrend(),
                    ),
                  ),
                if (latest.bodyFatPercent != null)
                  Expanded(
                    child: _MeasurementTile(
                      key: const ValueKey('current-body-fat-tile'),
                      label: 'Grasa corporal',
                      value: '${latest.bodyFatPercent}%',
                      trend: _bodyFatTrend(),
                    ),
                  ),
              ],
            ),
            if (latest.waistCm != null ||
                latest.chestCm != null ||
                latest.armCm != null) ...[
              const Divider(),
              Row(
                children: [
                  if (latest.waistCm != null)
                    Expanded(
                      child: _MeasurementTile(
                        key: const ValueKey('current-waist-tile'),
                        label: 'Cintura',
                        value: '${latest.waistCm} cm',
                        trend: _waistTrend(),
                      ),
                    ),
                  if (latest.chestCm != null)
                    Expanded(
                      child: _MeasurementTile(
                        key: const ValueKey('current-chest-tile'),
                        label: 'Pecho',
                        value: '${latest.chestCm} cm',
                        trend: _chestTrend(),
                      ),
                    ),
                  if (latest.armCm != null)
                    Expanded(
                      child: _MeasurementTile(
                        key: const ValueKey('current-arm-tile'),
                        label: 'Brazo',
                        value: '${latest.armCm} cm',
                        trend: _armTrend(),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Widget: tile de medicion con tendencia
// ---------------------------------------------------------------------------

class _MeasurementTile extends StatelessWidget {
  const _MeasurementTile({
    super.key,
    required this.label,
    required this.value,
    required this.trend,
  });

  final String label;
  final String value;
  final _Trend trend;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      label: '$label: $value, tendencia: ${trend.name}',
      child: Column(
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.textTheme.bodySmall?.color,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                value,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.gym,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                trend.icon,
                size: 16,
                color: trend.color,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Widget: formulario de nueva medicion (expandible)
// TODO: Extract to separate widget file
// ---------------------------------------------------------------------------

class _NewMeasurementForm extends StatelessWidget {
  const _NewMeasurementForm({
    super.key,
    required this.formKey,
    required this.weightController,
    required this.bodyFatController,
    required this.waistController,
    required this.chestController,
    required this.armController,
    required this.isExpanded,
    required this.onToggleExpand,
    required this.onSave,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController weightController;
  final TextEditingController bodyFatController;
  final TextEditingController waistController;
  final TextEditingController chestController;
  final TextEditingController armController;
  final bool isExpanded;
  final VoidCallback onToggleExpand;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      key: const ValueKey('new-measurement-form-card'),
      child: Column(
        children: [
          // Cabecera expandible
          Semantics(
            label: isExpanded
                ? 'Cerrar formulario de nueva medicion'
                : 'Registrar nueva medicion',
            button: true,
            child: InkWell(
              key: const ValueKey('new-measurement-form-toggle'),
              onTap: onToggleExpand,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.gym.withAlpha(20),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.add_chart,
                        color: AppColors.gym,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Registrar nueva medicion',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: AppColors.gym,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Campos del formulario (expandibles)
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Divider(),
                    const SizedBox(height: 8),

                    // Peso
                    _MeasurementField(
                      key: const ValueKey('new-measurement-weight-field'),
                      controller: weightController,
                      label: 'Peso (kg)',
                      hint: 'Ej. 78.5',
                      icon: Icons.monitor_weight_outlined,
                      allowDecimal: true,
                      max: 500,
                    ),
                    const SizedBox(height: 12),

                    // Grasa corporal
                    _MeasurementField(
                      key: const ValueKey('new-measurement-body-fat-field'),
                      controller: bodyFatController,
                      label: 'Grasa corporal (%)',
                      hint: 'Ej. 18.5',
                      icon: Icons.percent,
                      allowDecimal: true,
                      max: 100,
                    ),
                    const SizedBox(height: 12),

                    // Cintura
                    _MeasurementField(
                      key: const ValueKey('new-measurement-waist-field'),
                      controller: waistController,
                      label: 'Cintura (cm)',
                      hint: 'Ej. 84',
                      icon: Icons.straighten,
                      allowDecimal: true,
                      max: 300,
                    ),
                    const SizedBox(height: 12),

                    // Pecho
                    _MeasurementField(
                      key: const ValueKey('new-measurement-chest-field'),
                      controller: chestController,
                      label: 'Pecho (cm)',
                      hint: 'Ej. 100',
                      icon: Icons.straighten,
                      allowDecimal: true,
                      max: 300,
                    ),
                    const SizedBox(height: 12),

                    // Brazo
                    _MeasurementField(
                      key: const ValueKey('new-measurement-arm-field'),
                      controller: armController,
                      label: 'Brazo (cm)',
                      hint: 'Ej. 35',
                      icon: Icons.straighten,
                      allowDecimal: true,
                      max: 100,
                    ),
                    const SizedBox(height: 20),

                    // Boton guardar
                    Semantics(
                      label: 'Guardar medidas corporales',
                      button: true,
                      child: FilledButton.icon(
                        key: const ValueKey('new-measurement-save-button'),
                        onPressed: onSave,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.gym,
                          minimumSize: const Size.fromHeight(48),
                        ),
                        icon: const Icon(Icons.check),
                        label: const Text(
                          'Guardar medidas',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Widget: campo de medicion numerico
// ---------------------------------------------------------------------------

class _MeasurementField extends StatelessWidget {
  const _MeasurementField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.allowDecimal,
    required this.max,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool allowDecimal;
  final double max;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      textField: true,
      child: TextFormField(
        controller: controller,
        keyboardType: TextInputType.numberWithOptions(
          decimal: allowDecimal,
          signed: false,
        ),
        inputFormatters: allowDecimal
            ? [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))]
            : [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon),
          border: const OutlineInputBorder(),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: AppColors.gym, width: 2),
          ),
          isDense: true,
        ),
        validator: (v) {
          if (v == null || v.isEmpty) return null; // Opcional
          final parsed = double.tryParse(v);
          if (parsed == null || parsed <= 0) {
            return 'Ingresa un valor valido mayor a 0';
          }
          if (parsed > max) {
            return 'El valor maximo es $max';
          }
          return null;
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Widget: fila de historial de medicion
// ---------------------------------------------------------------------------

class _MeasurementHistoryRow extends StatelessWidget {
  const _MeasurementHistoryRow({
    super.key,
    required this.measurement,
    required this.previous,
    required this.isLatest,
  });

  final _MockMeasurement measurement;
  final _MockMeasurement? previous;
  final bool isLatest;

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final d = DateTime(date.year, date.month, date.day);

    if (d == today) return 'Hoy';
    if (d == yesterday) return 'Ayer';

    final months = [
      'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Widget _trendIcon(_Trend trend) {
    return Icon(trend.icon, size: 14, color: trend.color);
  }

  _Trend _weightTrend() {
    if (previous?.weightKg == null || measurement.weightKg == null) {
      return _Trend.neutral;
    }
    return measurement.weightKg! < previous!.weightKg!
        ? _Trend.improving
        : measurement.weightKg! > previous!.weightKg!
            ? _Trend.worsening
            : _Trend.neutral;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      label: '${_formatDate(measurement.date)}: '
          '${measurement.weightKg != null ? 'Peso ${measurement.weightKg} kg' : ''}'
          '${measurement.bodyFatPercent != null ? ', Grasa ${measurement.bodyFatPercent}%' : ''}'
          '${measurement.waistCm != null ? ', Cintura ${measurement.waistCm} cm' : ''}',
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        color: isLatest
            ? AppColors.gym.withAlpha(8)
            : null,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Fecha
              Row(
                children: [
                  Text(
                    _formatDate(measurement.date),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isLatest ? AppColors.gym : null,
                      fontWeight:
                          isLatest ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                  if (isLatest) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.gym.withAlpha(20),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Actual',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.gym,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),

              // Valores
              Wrap(
                spacing: 16,
                runSpacing: 6,
                children: [
                  if (measurement.weightKg != null)
                    _HistoryValue(
                      label: 'Peso',
                      value: '${measurement.weightKg} kg',
                      trendWidget: _trendIcon(_weightTrend()),
                    ),
                  if (measurement.bodyFatPercent != null)
                    _HistoryValue(
                      label: 'Grasa',
                      value: '${measurement.bodyFatPercent}%',
                    ),
                  if (measurement.waistCm != null)
                    _HistoryValue(
                      label: 'Cintura',
                      value: '${measurement.waistCm} cm',
                    ),
                  if (measurement.chestCm != null)
                    _HistoryValue(
                      label: 'Pecho',
                      value: '${measurement.chestCm} cm',
                    ),
                  if (measurement.armCm != null)
                    _HistoryValue(
                      label: 'Brazo',
                      value: '${measurement.armCm} cm',
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Widget: valor de historial
// ---------------------------------------------------------------------------

class _HistoryValue extends StatelessWidget {
  const _HistoryValue({
    required this.label,
    required this.value,
    this.trendWidget,
  });

  final String label;
  final String value;
  final Widget? trendWidget;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label: ',
          style: theme.textTheme.bodySmall,
        ),
        Text(
          value,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        if (trendWidget != null) ...[
          const SizedBox(width: 2),
          trendWidget!,
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Widget: estado vacio del historial
// ---------------------------------------------------------------------------

class _EmptyMeasurementsHistory extends StatelessWidget {
  const _EmptyMeasurementsHistory({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.monitor_weight_outlined,
              size: 48,
              color: theme.disabledColor,
            ),
            const SizedBox(height: 12),
            Text(
              'Sin mediciones previas',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Registra tu primera medicion para empezar el seguimiento.',
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
