import 'dart:io';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:life_os/core/constants/app_colors.dart';
import 'package:life_os/core/database/app_database.dart';
import 'package:life_os/core/providers/providers.dart';
import 'package:life_os/core/widgets/chart_card.dart';
import 'package:life_os/features/gym/domain/gym_input.dart';
import 'package:path_provider/path_provider.dart';

// ---------------------------------------------------------------------------
// BMI helpers
// ---------------------------------------------------------------------------

double? _calculateBMI(double? weightKg, double? heightCm) {
  if (weightKg == null || heightCm == null || heightCm <= 0) return null;
  final h = heightCm / 100;
  return weightKg / (h * h);
}

String _bmiCategory(double bmi) {
  if (bmi < 18.5) return 'Bajo peso';
  if (bmi < 25) return 'Normal';
  if (bmi < 30) return 'Sobrepeso';
  return 'Obesidad';
}

Color _bmiColor(double bmi) {
  if (bmi < 18.5) return AppColors.warning;
  if (bmi < 25) return AppColors.success;
  if (bmi < 30) return AppColors.warning;
  return AppColors.error;
}

// ---------------------------------------------------------------------------
// Trend helpers
// ---------------------------------------------------------------------------

enum _Trend { improving, worsening, neutral }

extension _TrendExt on _Trend {
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

_Trend _trend(double? curr, double? prev, {required bool lowerIsBetter}) {
  if (curr == null || prev == null) return _Trend.neutral;
  if (curr < prev) return lowerIsBetter ? _Trend.improving : _Trend.worsening;
  if (curr > prev) return lowerIsBetter ? _Trend.worsening : _Trend.improving;
  return _Trend.neutral;
}

// ---------------------------------------------------------------------------
// Date formatting helper
// ---------------------------------------------------------------------------

String _formatDate(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));
  final d = DateTime(date.year, date.month, date.day);
  if (d == today) return 'Hoy';
  if (d == yesterday) return 'Ayer';
  const months = [
    'ene', 'feb', 'mar', 'abr', 'may', 'jun',
    'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
  ];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}

// ---------------------------------------------------------------------------
// Main Screen
// ---------------------------------------------------------------------------

/// Pantalla de medidas corporales con historial, tendencias, IMC automatico
/// y fotos de progreso.
///
/// Accesibilidad: A11Y-GYM-05
class BodyMeasurementsScreen extends ConsumerStatefulWidget {
  const BodyMeasurementsScreen({super.key});

  @override
  ConsumerState<BodyMeasurementsScreen> createState() =>
      _BodyMeasurementsScreenState();
}

class _BodyMeasurementsScreenState
    extends ConsumerState<BodyMeasurementsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openNewMeasurementSheet(
    BuildContext context,
    List<BodyMeasurement> measurements,
  ) {
    final lastHeight =
        measurements.isNotEmpty ? measurements.first.heightCm : null;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => _NewMeasurementSheet(
        prefillHeightCm: lastHeight,
        onSave: (input) async {
          final notifier = ref.read(gymNotifierProvider);
          final result = await notifier.logMeasurement(input);
          if (!context.mounted) return;
          Navigator.of(ctx).pop();
          result.when(
            success: (_) => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Medidas guardadas correctamente'),
                backgroundColor: AppColors.gym,
              ),
            ),
            failure: (f) => ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(f.userMessage),
                backgroundColor: AppColors.error,
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dao = ref.watch(gymDaoProvider);

    return Scaffold(
      key: const ValueKey('body-measurements-screen'),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: AppColors.gym,
        title: Semantics(
          header: true,
          child: const Text('Medidas Corporales'),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.gym,
          labelColor: AppColors.gym,
          tabs: const [
            Tab(key: ValueKey('tab-overview'), text: 'Resumen'),
            Tab(key: ValueKey('tab-history'), text: 'Historial'),
            Tab(key: ValueKey('tab-trends'), text: 'Tendencias'),
          ],
        ),
      ),
      body: StreamBuilder<List<BodyMeasurement>>(
        stream: dao.watchMeasurements(),
        builder: (context, snapshot) {
          final measurements = snapshot.data ?? [];
          final latest = measurements.isNotEmpty ? measurements.first : null;
          final previous = measurements.length > 1 ? measurements[1] : null;

          return TabBarView(
            controller: _tabController,
            children: [
              // Overview tab
              _OverviewTab(
                key: const ValueKey('overview-tab-content'),
                latest: latest,
                previous: previous,
              ),
              // History tab
              _HistoryTab(
                key: const ValueKey('history-tab-content'),
                measurements: measurements,
              ),
              // Trends tab
              _MeasurementTrendsTab(
                key: const ValueKey('trends-tab-content'),
                measurements: measurements,
              ),
            ],
          );
        },
      ),
      floatingActionButton: StreamBuilder<List<BodyMeasurement>>(
        stream: dao.watchMeasurements(limit: 1),
        builder: (context, snapshot) {
          final measurements = snapshot.data ?? [];
          return Semantics(
            label: 'Registrar nueva medicion',
            button: true,
            child: FloatingActionButton.extended(
              key: const ValueKey('measurements-fab'),
              onPressed: () =>
                  _openNewMeasurementSheet(context, measurements),
              backgroundColor: AppColors.gym,
              icon: const Icon(Icons.add),
              label: const Text('Nueva Medicion'),
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Overview Tab
// ---------------------------------------------------------------------------

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({
    super.key,
    required this.latest,
    required this.previous,
  });

  final BodyMeasurement? latest;
  final BodyMeasurement? previous;

  @override
  Widget build(BuildContext context) {
    if (latest == null) {
      return const _EmptyState(key: ValueKey('measurements-empty-state'));
    }

    final bmi = _calculateBMI(latest!.weightKg, latest!.heightCm);

    return ListView(
      key: const ValueKey('overview-list'),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        // Composicion corporal
        _SectionHeader(
          key: const ValueKey('section-body-composition'),
          title: 'Composicion Corporal',
          icon: Icons.monitor_weight_outlined,
        ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    if (latest!.weightKg != null)
                      Expanded(
                        child: _MeasurementTile(
                          key: const ValueKey('tile-weight'),
                          label: 'Peso',
                          value: '${latest!.weightKg!.toStringAsFixed(1)} kg',
                          trend: _trend(
                            latest!.weightKg,
                            previous?.weightKg,
                            lowerIsBetter: true,
                          ),
                        ),
                      ),
                    if (bmi != null)
                      Expanded(
                        child: _BmiTile(
                          key: const ValueKey('tile-bmi'),
                          bmi: bmi,
                        ),
                      ),
                  ],
                ),
                if (latest!.bodyFatPercent != null ||
                    latest!.muscleMassKg != null ||
                    latest!.bodyWaterPercent != null) ...[
                  const Divider(),
                  Row(
                    children: [
                      if (latest!.bodyFatPercent != null)
                        Expanded(
                          child: _MeasurementTile(
                            key: const ValueKey('tile-body-fat'),
                            label: 'Grasa',
                            value:
                                '${latest!.bodyFatPercent!.toStringAsFixed(1)}%',
                            trend: _trend(
                              latest!.bodyFatPercent,
                              previous?.bodyFatPercent,
                              lowerIsBetter: true,
                            ),
                          ),
                        ),
                      if (latest!.muscleMassKg != null)
                        Expanded(
                          child: _MeasurementTile(
                            key: const ValueKey('tile-muscle-mass'),
                            label: 'Muscular',
                            value:
                                '${latest!.muscleMassKg!.toStringAsFixed(1)} kg',
                            trend: _trend(
                              latest!.muscleMassKg,
                              previous?.muscleMassKg,
                              lowerIsBetter: false,
                            ),
                          ),
                        ),
                      if (latest!.bodyWaterPercent != null)
                        Expanded(
                          child: _MeasurementTile(
                            key: const ValueKey('tile-body-water'),
                            label: 'Agua',
                            value:
                                '${latest!.bodyWaterPercent!.toStringAsFixed(1)}%',
                            trend: _trend(
                              latest!.bodyWaterPercent,
                              previous?.bodyWaterPercent,
                              lowerIsBetter: false,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),

        // Circunferencias
        if (_hasAnyCircumference(latest!)) ...[
          const SizedBox(height: 16),
          _SectionHeader(
            key: const ValueKey('section-circumferences'),
            title: 'Circunferencias',
            icon: Icons.straighten,
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                spacing: 0,
                children: [
                  if (latest!.neckCm != null)
                    _CircumferenceTile(
                      key: const ValueKey('tile-neck'),
                      label: 'Cuello',
                      value: latest!.neckCm!,
                      previous: previous?.neckCm,
                      lowerIsBetter: true,
                    ),
                  if (latest!.shouldersCm != null)
                    _CircumferenceTile(
                      key: const ValueKey('tile-shoulders'),
                      label: 'Hombros',
                      value: latest!.shouldersCm!,
                      previous: previous?.shouldersCm,
                      lowerIsBetter: false,
                    ),
                  if (latest!.chestCm != null)
                    _CircumferenceTile(
                      key: const ValueKey('tile-chest'),
                      label: 'Pecho',
                      value: latest!.chestCm!,
                      previous: previous?.chestCm,
                      lowerIsBetter: false,
                    ),
                  if (latest!.armCm != null)
                    _CircumferenceTile(
                      key: const ValueKey('tile-arm'),
                      label: 'Brazo',
                      value: latest!.armCm!,
                      previous: previous?.armCm,
                      lowerIsBetter: false,
                    ),
                  if (latest!.forearmCm != null)
                    _CircumferenceTile(
                      key: const ValueKey('tile-forearm'),
                      label: 'Antebrazo',
                      value: latest!.forearmCm!,
                      previous: previous?.forearmCm,
                      lowerIsBetter: false,
                    ),
                  if (latest!.waistCm != null)
                    _CircumferenceTile(
                      key: const ValueKey('tile-waist'),
                      label: 'Cintura',
                      value: latest!.waistCm!,
                      previous: previous?.waistCm,
                      lowerIsBetter: true,
                    ),
                  if (latest!.hipCm != null)
                    _CircumferenceTile(
                      key: const ValueKey('tile-hip'),
                      label: 'Cadera',
                      value: latest!.hipCm!,
                      previous: previous?.hipCm,
                      lowerIsBetter: true,
                    ),
                  if (latest!.thighCm != null)
                    _CircumferenceTile(
                      key: const ValueKey('tile-thigh'),
                      label: 'Muslo',
                      value: latest!.thighCm!,
                      previous: previous?.thighCm,
                      lowerIsBetter: false,
                    ),
                  if (latest!.calfCm != null)
                    _CircumferenceTile(
                      key: const ValueKey('tile-calf'),
                      label: 'Pantorrilla',
                      value: latest!.calfCm!,
                      previous: previous?.calfCm,
                      lowerIsBetter: false,
                    ),
                ],
              ),
            ),
          ),
        ],

        // Fotos de progreso
        if (_hasAnyPhoto(latest!)) ...[
          const SizedBox(height: 16),
          _SectionHeader(
            key: const ValueKey('section-photos'),
            title: 'Fotos de Progreso',
            icon: Icons.photo_camera_outlined,
          ),
          const SizedBox(height: 8),
          _PhotosCard(
            key: const ValueKey('photos-card'),
            measurement: latest!,
          ),
        ],

        // Nota
        if (latest!.note != null && latest!.note!.isNotEmpty) ...[
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.notes_outlined,
                      color: AppColors.gym, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(latest!.note!,
                        style: Theme.of(context).textTheme.bodySmall),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  bool _hasAnyCircumference(BodyMeasurement m) =>
      m.neckCm != null ||
      m.shouldersCm != null ||
      m.chestCm != null ||
      m.armCm != null ||
      m.forearmCm != null ||
      m.waistCm != null ||
      m.hipCm != null ||
      m.thighCm != null ||
      m.calfCm != null;

  bool _hasAnyPhoto(BodyMeasurement m) =>
      m.photoFrontPath != null ||
      m.photoSidePath != null ||
      m.photoBackPath != null;
}

// ---------------------------------------------------------------------------
// History Tab
// ---------------------------------------------------------------------------

class _HistoryTab extends StatelessWidget {
  const _HistoryTab({
    super.key,
    required this.measurements,
  });

  final List<BodyMeasurement> measurements;

  @override
  Widget build(BuildContext context) {
    if (measurements.isEmpty) {
      return const _EmptyState(key: ValueKey('history-empty-state'));
    }

    return ListView.separated(
      key: const ValueKey('history-list'),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: measurements.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final m = measurements[index];
        final prev =
            index + 1 < measurements.length ? measurements[index + 1] : null;
        return _HistoryCard(
          key: ValueKey('history-card-${m.id}'),
          measurement: m,
          previous: prev,
          isLatest: index == 0,
          onTap: () => _showDetail(context, m),
        );
      },
    );
  }

  void _showDetail(BuildContext context, BodyMeasurement m) {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (ctx) => _MeasurementDetailScreen(measurement: m),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section Header
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    super.key,
    required this.title,
    required this.icon,
  });

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Row(
        children: [
          Icon(icon, color: AppColors.gym, size: 16),
          const SizedBox(width: 6),
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Measurement Tile (composicion corporal)
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
          Text(label, style: theme.textTheme.labelSmall),
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
              Icon(trend.icon, size: 14, color: trend.color),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// BMI Tile
// ---------------------------------------------------------------------------

class _BmiTile extends StatelessWidget {
  const _BmiTile({super.key, required this.bmi});

  final double bmi;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final category = _bmiCategory(bmi);
    final color = _bmiColor(bmi);
    return Semantics(
      label: 'IMC: ${bmi.toStringAsFixed(1)}, $category',
      child: Column(
        children: [
          Text('IMC', style: theme.textTheme.labelSmall),
          const SizedBox(height: 4),
          Text(
            bmi.toStringAsFixed(1),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            category,
            style: theme.textTheme.labelSmall?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Circumference Tile (in grid)
// ---------------------------------------------------------------------------

class _CircumferenceTile extends StatelessWidget {
  const _CircumferenceTile({
    super.key,
    required this.label,
    required this.value,
    required this.previous,
    required this.lowerIsBetter,
  });

  final String label;
  final double value;
  final double? previous;
  final bool lowerIsBetter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = _trend(value, previous, lowerIsBetter: lowerIsBetter);
    return SizedBox(
      width: (MediaQuery.of(context).size.width - 64) / 3,
      child: Semantics(
        label: '$label: ${value.toStringAsFixed(1)} cm, tendencia ${t.name}',
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            children: [
              Text(label,
                  style: theme.textTheme.labelSmall,
                  textAlign: TextAlign.center),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${value.toStringAsFixed(1)}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(t.icon, size: 12, color: t.color),
                ],
              ),
              Text(
                'cm',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.textTheme.bodySmall?.color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Photos Card
// ---------------------------------------------------------------------------

class _PhotosCard extends StatelessWidget {
  const _PhotosCard({super.key, required this.measurement});

  final BodyMeasurement measurement;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            if (measurement.photoFrontPath != null)
              Expanded(
                child: _PhotoThumb(
                  key: const ValueKey('photo-front-thumb'),
                  path: measurement.photoFrontPath!,
                  label: 'Frente',
                ),
              ),
            if (measurement.photoSidePath != null)
              Expanded(
                child: _PhotoThumb(
                  key: const ValueKey('photo-side-thumb'),
                  path: measurement.photoSidePath!,
                  label: 'Lado',
                ),
              ),
            if (measurement.photoBackPath != null)
              Expanded(
                child: _PhotoThumb(
                  key: const ValueKey('photo-back-thumb'),
                  path: measurement.photoBackPath!,
                  label: 'Espalda',
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PhotoThumb extends StatelessWidget {
  const _PhotoThumb({super.key, required this.path, required this.label});

  final String path;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Foto de progreso: $label',
      button: true,
      child: GestureDetector(
        onTap: () => _viewFullScreen(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: File(path).existsSync()
                    ? Image.file(
                        File(path),
                        height: 100,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholder(),
                      )
                    : _placeholder(),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: AppColors.gym.withAlpha(20),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: Icon(Icons.image_not_supported_outlined, color: AppColors.gym),
      ),
    );
  }

  void _viewFullScreen(BuildContext context) {
    if (!File(path).existsSync()) return;
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            centerTitle: true,
            foregroundColor: AppColors.gym,
            leading: IconButton(
              key: const ValueKey('photo-fullscreen-back'),
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(label,
                style: const TextStyle(color: Colors.white)),
          ),
          body: Center(
            child: InteractiveViewer(
              child: Image.file(File(path)),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// History Card
// ---------------------------------------------------------------------------

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({
    super.key,
    required this.measurement,
    required this.previous,
    required this.isLatest,
    required this.onTap,
  });

  final BodyMeasurement measurement;
  final BodyMeasurement? previous;
  final bool isLatest;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bmi =
        _calculateBMI(measurement.weightKg, measurement.heightCm);
    final dateStr = _formatDate(measurement.date);

    return Semantics(
      label: '$dateStr: ${measurement.weightKg != null ? 'Peso ${measurement.weightKg} kg' : ''}'
          '${bmi != null ? ', IMC ${bmi.toStringAsFixed(1)}' : ''}'
          '${measurement.bodyFatPercent != null ? ', Grasa ${measurement.bodyFatPercent}%' : ''}',
      button: true,
      child: Card(
        color: isLatest ? AppColors.gym.withAlpha(8) : null,
        child: InkWell(
          key: ValueKey('history-card-tap-${measurement.id}'),
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      dateStr,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isLatest ? AppColors.gym : null,
                        fontWeight:
                            isLatest ? FontWeight.w700 : FontWeight.w400,
                      ),
                    ),
                    if (isLatest) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.gym.withAlpha(20),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Actual',
                          style: TextStyle(
                              fontSize: 10,
                              color: AppColors.gym,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                    const Spacer(),
                    const Icon(Icons.chevron_right_outlined,
                        size: 16, color: Colors.grey),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 16,
                  runSpacing: 4,
                  children: [
                    if (measurement.weightKg != null)
                      _HistoryChip(
                        label: 'Peso',
                        value:
                            '${measurement.weightKg!.toStringAsFixed(1)} kg',
                        trend: _trend(
                          measurement.weightKg,
                          previous?.weightKg,
                          lowerIsBetter: true,
                        ),
                      ),
                    if (bmi != null)
                      _HistoryChip(
                        label: 'IMC',
                        value: bmi.toStringAsFixed(1),
                        trend: _Trend.neutral,
                      ),
                    if (measurement.bodyFatPercent != null)
                      _HistoryChip(
                        label: 'Grasa',
                        value:
                            '${measurement.bodyFatPercent!.toStringAsFixed(1)}%',
                        trend: _trend(
                          measurement.bodyFatPercent,
                          previous?.bodyFatPercent,
                          lowerIsBetter: true,
                        ),
                      ),
                    if (measurement.waistCm != null)
                      _HistoryChip(
                        label: 'Cintura',
                        value:
                            '${measurement.waistCm!.toStringAsFixed(1)} cm',
                        trend: _trend(
                          measurement.waistCm,
                          previous?.waistCm,
                          lowerIsBetter: true,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HistoryChip extends StatelessWidget {
  const _HistoryChip({
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$label: ', style: theme.textTheme.bodySmall),
        Text(value,
            style: theme.textTheme.bodySmall
                ?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(width: 2),
        Icon(trend.icon, size: 12, color: trend.color),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Measurement Detail Screen
// ---------------------------------------------------------------------------

class _MeasurementDetailScreen extends StatelessWidget {
  const _MeasurementDetailScreen({required this.measurement});

  final BodyMeasurement measurement;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bmi =
        _calculateBMI(measurement.weightKg, measurement.heightCm);

    return Scaffold(
      key: const ValueKey('measurement-detail-screen'),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: AppColors.gym,
        title: Semantics(
          header: true,
          child: Text(_formatDate(measurement.date)),
        ),
        leading: Semantics(
          label: 'Volver al historial',
          button: true,
          child: IconButton(
            key: const ValueKey('detail-back-button'),
            icon: const Icon(Icons.arrow_back_outlined),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Volver',
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: [
          // Composicion corporal
          if (measurement.weightKg != null ||
              bmi != null ||
              measurement.bodyFatPercent != null ||
              measurement.muscleMassKg != null ||
              measurement.bodyWaterPercent != null) ...[
            _SectionHeader(
              title: 'Composicion Corporal',
              icon: Icons.monitor_weight_outlined,
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    if (measurement.weightKg != null)
                      _DetailRow(
                          label: 'Peso',
                          value:
                              '${measurement.weightKg!.toStringAsFixed(1)} kg'),
                    if (measurement.heightCm != null)
                      _DetailRow(
                          label: 'Estatura',
                          value:
                              '${measurement.heightCm!.toStringAsFixed(1)} cm'),
                    if (bmi != null)
                      _DetailRow(
                        label: 'IMC',
                        value:
                            '${bmi.toStringAsFixed(1)} — ${_bmiCategory(bmi)}',
                        valueColor: _bmiColor(bmi),
                      ),
                    if (measurement.bodyFatPercent != null)
                      _DetailRow(
                          label: 'Grasa corporal',
                          value:
                              '${measurement.bodyFatPercent!.toStringAsFixed(1)}%'),
                    if (measurement.muscleMassKg != null)
                      _DetailRow(
                          label: 'Masa muscular',
                          value:
                              '${measurement.muscleMassKg!.toStringAsFixed(1)} kg'),
                    if (measurement.bodyWaterPercent != null)
                      _DetailRow(
                          label: 'Agua corporal',
                          value:
                              '${measurement.bodyWaterPercent!.toStringAsFixed(1)}%'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Circunferencias
          if (_hasAnyCircumference()) ...[
            _SectionHeader(
              title: 'Circunferencias',
              icon: Icons.straighten,
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    if (measurement.neckCm != null)
                      _DetailRow(
                          label: 'Cuello',
                          value:
                              '${measurement.neckCm!.toStringAsFixed(1)} cm'),
                    if (measurement.shouldersCm != null)
                      _DetailRow(
                          label: 'Hombros',
                          value:
                              '${measurement.shouldersCm!.toStringAsFixed(1)} cm'),
                    if (measurement.chestCm != null)
                      _DetailRow(
                          label: 'Pecho',
                          value:
                              '${measurement.chestCm!.toStringAsFixed(1)} cm'),
                    if (measurement.armCm != null)
                      _DetailRow(
                          label: 'Brazo (biceps)',
                          value:
                              '${measurement.armCm!.toStringAsFixed(1)} cm'),
                    if (measurement.forearmCm != null)
                      _DetailRow(
                          label: 'Antebrazo',
                          value:
                              '${measurement.forearmCm!.toStringAsFixed(1)} cm'),
                    if (measurement.waistCm != null)
                      _DetailRow(
                          label: 'Cintura',
                          value:
                              '${measurement.waistCm!.toStringAsFixed(1)} cm'),
                    if (measurement.hipCm != null)
                      _DetailRow(
                          label: 'Cadera',
                          value:
                              '${measurement.hipCm!.toStringAsFixed(1)} cm'),
                    if (measurement.thighCm != null)
                      _DetailRow(
                          label: 'Muslo',
                          value:
                              '${measurement.thighCm!.toStringAsFixed(1)} cm'),
                    if (measurement.calfCm != null)
                      _DetailRow(
                          label: 'Pantorrilla',
                          value:
                              '${measurement.calfCm!.toStringAsFixed(1)} cm'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Fotos
          if (_hasAnyPhoto()) ...[
            _SectionHeader(
              title: 'Fotos de Progreso',
              icon: Icons.photo_camera_outlined,
            ),
            const SizedBox(height: 8),
            _PhotosCard(measurement: measurement),
            const SizedBox(height: 16),
          ],

          // Notas
          if (measurement.note != null && measurement.note!.isNotEmpty) ...[
            _SectionHeader(title: 'Notas', icon: Icons.notes_outlined),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(measurement.note!,
                    style: theme.textTheme.bodyMedium),
              ),
            ),
          ],
        ],
      ),
    );
  }

  bool _hasAnyCircumference() =>
      measurement.neckCm != null ||
      measurement.shouldersCm != null ||
      measurement.chestCm != null ||
      measurement.armCm != null ||
      measurement.forearmCm != null ||
      measurement.waistCm != null ||
      measurement.hipCm != null ||
      measurement.thighCm != null ||
      measurement.calfCm != null;

  bool _hasAnyPhoto() =>
      measurement.photoFrontPath != null ||
      measurement.photoSidePath != null ||
      measurement.photoBackPath != null;
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodyMedium),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// New Measurement Bottom Sheet
// ---------------------------------------------------------------------------

class _NewMeasurementSheet extends ConsumerStatefulWidget {
  const _NewMeasurementSheet({
    required this.onSave,
    this.prefillHeightCm,
  });

  final Future<void> Function(MeasurementInput) onSave;
  final double? prefillHeightCm;

  @override
  ConsumerState<_NewMeasurementSheet> createState() =>
      _NewMeasurementSheetState();
}

class _NewMeasurementSheetState extends ConsumerState<_NewMeasurementSheet> {
  final _formKey = GlobalKey<FormState>();

  // Body composition
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _bodyFatController = TextEditingController();
  final _muscleMassController = TextEditingController();
  final _bodyWaterController = TextEditingController();

  // Circumferences
  final _neckController = TextEditingController();
  final _shouldersController = TextEditingController();
  final _chestController = TextEditingController();
  final _armController = TextEditingController();
  final _forearmController = TextEditingController();
  final _waistController = TextEditingController();
  final _hipController = TextEditingController();
  final _thighController = TextEditingController();
  final _calfController = TextEditingController();

  // Notes
  final _noteController = TextEditingController();

  // Photos
  String? _photoFrontPath;
  String? _photoSidePath;
  String? _photoBackPath;

  // Calculated BMI (reactive)
  double? _bmi;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.prefillHeightCm != null) {
      _heightController.text =
          widget.prefillHeightCm!.toStringAsFixed(1);
    }
    _weightController.addListener(_recalcBmi);
    _heightController.addListener(_recalcBmi);
  }

  void _recalcBmi() {
    final weight = double.tryParse(_weightController.text);
    final height = double.tryParse(_heightController.text);
    setState(() {
      _bmi = _calculateBMI(weight, height);
    });
  }

  @override
  void dispose() {
    _weightController
      ..removeListener(_recalcBmi)
      ..dispose();
    _heightController
      ..removeListener(_recalcBmi)
      ..dispose();
    _bodyFatController.dispose();
    _muscleMassController.dispose();
    _bodyWaterController.dispose();
    _neckController.dispose();
    _shouldersController.dispose();
    _chestController.dispose();
    _armController.dispose();
    _forearmController.dispose();
    _waistController.dispose();
    _hipController.dispose();
    _thighController.dispose();
    _calfController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(String position) async {
    final picker = ImagePicker();
    final source = await _showPhotoSourceDialog();
    if (source == null) return;

    final picked = await picker.pickImage(source: source, imageQuality: 85);
    if (picked == null) return;

    // Save to app documents directory
    final dir = await getApplicationDocumentsDirectory();
    final measurementsDir =
        Directory('${dir.path}${Platform.pathSeparator}measurements');
    if (!measurementsDir.existsSync()) {
      measurementsDir.createSync(recursive: true);
    }
    final now = DateTime.now();
    final filename =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_$position.jpg';
    final destPath =
        '${measurementsDir.path}${Platform.pathSeparator}$filename';
    await File(picked.path).copy(destPath);

    setState(() {
      switch (position) {
        case 'front':
          _photoFrontPath = destPath;
        case 'side':
          _photoSidePath = destPath;
        case 'back':
          _photoBackPath = destPath;
      }
    });
  }

  Future<ImageSource?> _showPhotoSourceDialog() async {
    return showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              key: const ValueKey('photo-source-camera'),
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Camara'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              key: const ValueKey('photo-source-gallery'),
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Galeria'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final input = MeasurementInput(
      weightKg: double.tryParse(_weightController.text),
      heightCm: double.tryParse(_heightController.text),
      bodyFatPercent: double.tryParse(_bodyFatController.text),
      muscleMassKg: double.tryParse(_muscleMassController.text),
      bodyWaterPercent: double.tryParse(_bodyWaterController.text),
      neckCm: double.tryParse(_neckController.text),
      shouldersCm: double.tryParse(_shouldersController.text),
      chestCm: double.tryParse(_chestController.text),
      armCm: double.tryParse(_armController.text),
      forearmCm: double.tryParse(_forearmController.text),
      waistCm: double.tryParse(_waistController.text),
      hipCm: double.tryParse(_hipController.text),
      thighCm: double.tryParse(_thighController.text),
      calfCm: double.tryParse(_calfController.text),
      photoFrontPath: _photoFrontPath,
      photoSidePath: _photoSidePath,
      photoBackPath: _photoBackPath,
      note:
          _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
    );

    if (!input.hasAnyValue) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingresa al menos una medida para guardar'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await widget.onSave(input);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      key: const ValueKey('new-measurement-sheet-scaffold'),
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: AppColors.gym,
        title: Semantics(
          header: true,
          child: const Text('Nueva Medicion'),
        ),
        leading: Semantics(
          label: 'Cerrar formulario',
          button: true,
          child: IconButton(
            key: const ValueKey('new-measurement-close-button'),
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        actions: [
          _isSaving
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : Semantics(
                  label: 'Guardar medidas',
                  button: true,
                  child: TextButton(
                    key: const ValueKey('new-measurement-save-action'),
                    onPressed: _handleSave,
                    child: const Text(
                      'Guardar',
                      style: TextStyle(
                          color: AppColors.gym, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
          children: [
            // ------- Composicion Corporal -------
            _FormSectionHeader(
              key: const ValueKey('form-section-body-comp'),
              title: 'Composicion Corporal',
              icon: Icons.monitor_weight_outlined,
            ),
            const SizedBox(height: 8),
            _NumericField(
              key: const ValueKey('field-weight'),
              controller: _weightController,
              label: 'Peso (kg)',
              hint: 'Ej. 78.5',
              icon: Icons.monitor_weight_outlined,
              max: 500,
            ),
            const SizedBox(height: 10),
            _NumericField(
              key: const ValueKey('field-height'),
              controller: _heightController,
              label: 'Estatura (cm)',
              hint: 'Ej. 175',
              icon: Icons.height_outlined,
              max: 300,
            ),
            const SizedBox(height: 10),
            _NumericField(
              key: const ValueKey('field-body-fat'),
              controller: _bodyFatController,
              label: 'Grasa corporal (%)',
              hint: 'Ej. 18.5',
              icon: Icons.percent,
              max: 100,
            ),
            const SizedBox(height: 10),
            _NumericField(
              key: const ValueKey('field-muscle-mass'),
              controller: _muscleMassController,
              label: 'Masa muscular (kg)',
              hint: 'Ej. 62',
              icon: Icons.fitness_center_outlined,
              max: 300,
            ),
            const SizedBox(height: 10),
            _NumericField(
              key: const ValueKey('field-body-water'),
              controller: _bodyWaterController,
              label: 'Agua corporal (%)',
              hint: 'Ej. 55',
              icon: Icons.water_drop_outlined,
              max: 100,
            ),
            const SizedBox(height: 12),

            // IMC calculado automaticamente
            if (_bmi != null) ...[
              _BmiReadonlyCard(
                key: const ValueKey('bmi-readonly-card'),
                bmi: _bmi!,
              ),
              const SizedBox(height: 12),
            ],

            // ------- Circunferencias -------
            _FormSectionHeader(
              key: const ValueKey('form-section-circumferences'),
              title: 'Circunferencias (cm)',
              icon: Icons.straighten,
            ),
            const SizedBox(height: 8),
            _NumericField(
              key: const ValueKey('field-neck'),
              controller: _neckController,
              label: 'Cuello',
              hint: 'Ej. 38',
              icon: Icons.straighten,
              max: 100,
            ),
            const SizedBox(height: 10),
            _NumericField(
              key: const ValueKey('field-shoulders'),
              controller: _shouldersController,
              label: 'Hombros',
              hint: 'Ej. 112',
              icon: Icons.straighten,
              max: 200,
            ),
            const SizedBox(height: 10),
            _NumericField(
              key: const ValueKey('field-chest'),
              controller: _chestController,
              label: 'Pecho',
              hint: 'Ej. 100',
              icon: Icons.straighten,
              max: 200,
            ),
            const SizedBox(height: 10),
            _NumericField(
              key: const ValueKey('field-arm'),
              controller: _armController,
              label: 'Brazo (biceps)',
              hint: 'Ej. 36',
              icon: Icons.straighten,
              max: 100,
            ),
            const SizedBox(height: 10),
            _NumericField(
              key: const ValueKey('field-forearm'),
              controller: _forearmController,
              label: 'Antebrazo',
              hint: 'Ej. 30',
              icon: Icons.straighten,
              max: 100,
            ),
            const SizedBox(height: 10),
            _NumericField(
              key: const ValueKey('field-waist'),
              controller: _waistController,
              label: 'Cintura',
              hint: 'Ej. 82',
              icon: Icons.straighten,
              max: 200,
            ),
            const SizedBox(height: 10),
            _NumericField(
              key: const ValueKey('field-hip'),
              controller: _hipController,
              label: 'Cadera',
              hint: 'Ej. 95',
              icon: Icons.straighten,
              max: 200,
            ),
            const SizedBox(height: 10),
            _NumericField(
              key: const ValueKey('field-thigh'),
              controller: _thighController,
              label: 'Muslo',
              hint: 'Ej. 58',
              icon: Icons.straighten,
              max: 150,
            ),
            const SizedBox(height: 10),
            _NumericField(
              key: const ValueKey('field-calf'),
              controller: _calfController,
              label: 'Pantorrilla',
              hint: 'Ej. 38',
              icon: Icons.straighten,
              max: 100,
            ),
            const SizedBox(height: 20),

            // ------- Fotos de Progreso -------
            _FormSectionHeader(
              key: const ValueKey('form-section-photos'),
              title: 'Fotos de Progreso',
              icon: Icons.photo_camera_outlined,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _PhotoPickerButton(
                    key: const ValueKey('photo-picker-front'),
                    label: 'Frente',
                    path: _photoFrontPath,
                    onTap: () => _pickPhoto('front'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _PhotoPickerButton(
                    key: const ValueKey('photo-picker-side'),
                    label: 'Lado',
                    path: _photoSidePath,
                    onTap: () => _pickPhoto('side'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _PhotoPickerButton(
                    key: const ValueKey('photo-picker-back'),
                    label: 'Espalda',
                    path: _photoBackPath,
                    onTap: () => _pickPhoto('back'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ------- Notas -------
            _FormSectionHeader(
              key: const ValueKey('form-section-notes'),
              title: 'Notas',
              icon: Icons.notes_outlined,
            ),
            const SizedBox(height: 8),
            Semantics(
              label: 'Notas opcionales',
              textField: true,
              child: TextFormField(
                key: const ValueKey('field-note'),
                controller: _noteController,
                maxLines: 3,
                maxLength: 200,
                decoration: InputDecoration(
                  hintText: 'Observaciones opcionales...',
                  border: const OutlineInputBorder(),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.gym, width: 2),
                  ),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ------- Save button -------
            Semantics(
              label: 'Guardar medidas corporales',
              button: true,
              child: FilledButton.icon(
                key: const ValueKey('new-measurement-save-button'),
                onPressed: _isSaving ? null : _handleSave,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.gym,
                  minimumSize: const Size.fromHeight(48),
                ),
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check),
                label: const Text(
                  'Guardar medidas',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// BMI Read-Only Card (shown while filling form)
// ---------------------------------------------------------------------------

class _BmiReadonlyCard extends StatelessWidget {
  const _BmiReadonlyCard({super.key, required this.bmi});

  final double bmi;

  @override
  Widget build(BuildContext context) {
    final category = _bmiCategory(bmi);
    final color = _bmiColor(bmi);
    return Semantics(
      label: 'IMC calculado: ${bmi.toStringAsFixed(1)}, $category',
      child: Container(
        key: const ValueKey('bmi-readonly-container'),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          border: Border.all(color: color.withAlpha(80)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(Icons.calculate_outlined, color: color, size: 18),
            const SizedBox(width: 8),
            Text(
              'IMC: ',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Text(
              '${bmi.toStringAsFixed(1)} ',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
            ),
            Text(
              '($category)',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: color,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Form Section Header
// ---------------------------------------------------------------------------

class _FormSectionHeader extends StatelessWidget {
  const _FormSectionHeader({
    super.key,
    required this.title,
    required this.icon,
  });

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Row(
          children: [
            Icon(icon, color: AppColors.gym, size: 16),
            const SizedBox(width: 6),
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.gym,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Numeric Field
// ---------------------------------------------------------------------------

class _NumericField extends StatelessWidget {
  const _NumericField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.max,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final double max;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      textField: true,
      child: TextFormField(
        controller: controller,
        keyboardType:
            const TextInputType.numberWithOptions(decimal: true, signed: false),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
        ],
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, size: 18),
          border: const OutlineInputBorder(),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: AppColors.gym, width: 2),
          ),
          isDense: true,
        ),
        validator: (v) {
          if (v == null || v.isEmpty) return null;
          final parsed = double.tryParse(v);
          if (parsed == null || parsed <= 0) {
            return 'Valor mayor a 0';
          }
          if (parsed > max) {
            return 'Max $max';
          }
          return null;
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Photo Picker Button
// ---------------------------------------------------------------------------

class _PhotoPickerButton extends StatelessWidget {
  const _PhotoPickerButton({
    super.key,
    required this.label,
    required this.path,
    required this.onTap,
  });

  final String label;
  final String? path;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasPhoto = path != null && File(path!).existsSync();

    return Semantics(
      label: hasPhoto ? 'Foto $label seleccionada. Toca para cambiar' : 'Agregar foto $label',
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: AspectRatio(
          aspectRatio: 3 / 4,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.gym.withAlpha(12),
              border: Border.all(
                color:
                    hasPhoto ? AppColors.gym : AppColors.gym.withAlpha(60),
                width: hasPhoto ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: hasPhoto
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(9),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.file(File(path!), fit: BoxFit.cover),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            color: Colors.black54,
                            padding:
                                const EdgeInsets.symmetric(vertical: 4),
                            child: Text(
                              label,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add_a_photo_outlined,
                          color: AppColors.gym, size: 28),
                      const SizedBox(height: 6),
                      Text(
                        label,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppColors.gym,
                              fontWeight: FontWeight.w600,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty State
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  const _EmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.monitor_weight_outlined,
                size: 64, color: theme.disabledColor),
            const SizedBox(height: 16),
            Text('Sin mediciones', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Toca el boton + para registrar tu primera medicion.',
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Trends Tab — fl_chart LineCharts para tendencias reales
// ---------------------------------------------------------------------------

enum _CircumferenceField {
  waist,
  chest,
  arm,
  neck,
  shoulders,
  forearm,
  thigh,
  calf,
  hip,
}

extension _CircumferenceFieldLabel on _CircumferenceField {
  String get label => switch (this) {
        _CircumferenceField.waist => 'Cintura',
        _CircumferenceField.chest => 'Pecho',
        _CircumferenceField.arm => 'Brazo',
        _CircumferenceField.neck => 'Cuello',
        _CircumferenceField.shoulders => 'Hombros',
        _CircumferenceField.forearm => 'Antebrazo',
        _CircumferenceField.thigh => 'Muslo',
        _CircumferenceField.calf => 'Pantorrilla',
        _CircumferenceField.hip => 'Cadera',
      };

  double? valueFrom(BodyMeasurement m) => switch (this) {
        _CircumferenceField.waist => m.waistCm,
        _CircumferenceField.chest => m.chestCm,
        _CircumferenceField.arm => m.armCm,
        _CircumferenceField.neck => m.neckCm,
        _CircumferenceField.shoulders => m.shouldersCm,
        _CircumferenceField.forearm => m.forearmCm,
        _CircumferenceField.thigh => m.thighCm,
        _CircumferenceField.calf => m.calfCm,
        _CircumferenceField.hip => m.hipCm,
      };
}

class _MeasurementTrendsTab extends StatefulWidget {
  const _MeasurementTrendsTab({
    super.key,
    required this.measurements,
  });

  final List<BodyMeasurement> measurements;

  @override
  State<_MeasurementTrendsTab> createState() => _MeasurementTrendsTabState();
}

class _MeasurementTrendsTabState extends State<_MeasurementTrendsTab> {
  _CircumferenceField _selectedCircumference = _CircumferenceField.waist;

  // measurements come in descending order — reverse for charts (oldest → newest)
  List<BodyMeasurement> get _sorted =>
      widget.measurements.reversed.take(30).toList();

  @override
  Widget build(BuildContext context) {
    final data = _sorted;

    return ListView(
      key: const ValueKey('trends-list'),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        // Weight trend
        _buildLineChart(
          key: 'weight-trend-chart',
          title: 'Peso (kg)',
          data: data,
          getValue: (m) => m.weightKg,
          color: AppColors.gym,
        ),
        const SizedBox(height: 16),

        // Body fat trend
        _buildLineChart(
          key: 'bodyfat-trend-chart',
          title: 'Grasa corporal (%)',
          data: data,
          getValue: (m) => m.bodyFatPercent,
          color: AppColors.warning,
        ),
        const SizedBox(height: 16),

        // BMI trend (computed)
        _buildLineChart(
          key: 'bmi-trend-chart',
          title: 'IMC',
          data: data,
          getValue: (m) => _calculateBMI(m.weightKg, m.heightCm),
          color: AppColors.info,
        ),
        const SizedBox(height: 16),

        // Circumference selector + chart
        ChartCard(
          key: const ValueKey('circumference-trend-chart'),
          title: 'Circunferencia',
          child: Column(
            children: [
              // Dropdown to pick field
              DropdownButton<_CircumferenceField>(
                value: _selectedCircumference,
                isExpanded: true,
                onChanged: (v) {
                  if (v != null) setState(() => _selectedCircumference = v);
                },
                items: _CircumferenceField.values
                    .map(
                      (f) => DropdownMenuItem(
                        value: f,
                        child: Text(f.label),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 8),
              _buildInlineChart(
                data: data,
                getValue: (m) => _selectedCircumference.valueFrom(m),
                color: AppColors.gym,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLineChart({
    required String key,
    required String title,
    required List<BodyMeasurement> data,
    required double? Function(BodyMeasurement) getValue,
    required Color color,
  }) {
    final filtered = data
        .where((m) => getValue(m) != null)
        .toList();

    return ChartCard(
      key: ValueKey(key),
      title: title,
      child: filtered.length < 2
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('Sin datos suficientes'),
              ),
            )
          : _buildInlineChart(data: filtered, getValue: getValue, color: color),
    );
  }

  Widget _buildInlineChart({
    required List<BodyMeasurement> data,
    required double? Function(BodyMeasurement) getValue,
    required Color color,
  }) {
    final filtered = data.where((m) => getValue(m) != null).toList();

    if (filtered.length < 2) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('Sin datos suficientes'),
        ),
      );
    }

    final spots = filtered.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), getValue(e.value)!);
    }).toList();

    return SizedBox(
      height: 180,
      child: LineChart(
        LineChartData(
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (spots) => spots.map((s) {
                final idx = s.x.toInt();
                final d = idx < filtered.length ? filtered[idx].date : null;
                final label = d != null ? '${d.day}/${d.month}' : '';
                return LineTooltipItem(
                  '$label\n${s.y.toStringAsFixed(1)}',
                  const TextStyle(fontSize: 11),
                );
              }).toList(),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => const FlLine(
              color: Color(0x1A9E9E9E),
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                interval: (filtered.length / 5).ceilToDouble(),
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= filtered.length) {
                    return const SizedBox.shrink();
                  }
                  final d = filtered[idx].date;
                  return Text(
                    '${d.day}/${d.month}',
                    style: const TextStyle(fontSize: 9),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: color,
              barWidth: 2.5,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: color.withAlpha(40),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
