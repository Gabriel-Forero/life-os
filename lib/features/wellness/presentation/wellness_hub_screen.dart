import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:life_os/core/constants/app_breakpoints.dart';
import 'package:life_os/core/constants/app_colors.dart';
import 'package:life_os/core/database/app_database.dart';
import 'package:life_os/core/providers/providers.dart';
import 'package:life_os/core/router/app_router.dart';
import 'package:life_os/features/mental/database/mental_dao.dart';
import 'package:life_os/features/mental/domain/mental_input.dart';
import 'package:life_os/features/sleep/database/sleep_dao.dart';

/// Wellness hub — desktop uses a rich two-column layout with inline mood
/// logging. Phone uses the classic single-column with navigation cards.
class WellnessHubScreen extends ConsumerStatefulWidget {
  const WellnessHubScreen({super.key});

  @override
  ConsumerState<WellnessHubScreen> createState() => _WellnessHubScreenState();
}

class _WellnessHubScreenState extends ConsumerState<WellnessHubScreen> {
  // Inline mood state
  int _valence = 3;
  int _energy = 3;
  final _selectedTags = <String>{};
  bool _moodSaved = false;
  bool _isSaving = false;

  static const _tags = [
    'Feliz', 'Motivado', 'Tranquilo', 'Enfocado', 'Agradecido',
    'Cansado', 'Estresado', 'Ansioso', 'Triste', 'Enojado',
  ];

  String get _moodQuadrant {
    if (_valence >= 3 && _energy >= 3) return 'Activo y Positivo';
    if (_valence >= 3 && _energy < 3) return 'Tranquilo y Positivo';
    if (_valence < 3 && _energy >= 3) return 'Activo y Negativo';
    return 'Bajo y Negativo';
  }

  Color get _moodColor {
    final score = ((_valence - 1) / 4.0 * 50 + (_energy - 1) / 4.0 * 50).round();
    if (score >= 75) return AppColors.success;
    if (score >= 50) return AppColors.mental;
    if (score >= 25) return AppColors.warning;
    return AppColors.error;
  }

  Future<void> _saveMood() async {
    setState(() => _isSaving = true);
    final notifier = ref.read(mentalNotifierProvider);
    await notifier.logMood(MoodInput(
      date: DateTime.now(),
      valence: _valence,
      energy: _energy,
      tags: _selectedTags.toList(),
    ));
    if (mounted) setState(() { _isSaving = false; _moodSaved = true; });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sleepDao = ref.watch(sleepDaoProvider);
    final mentalDao = ref.watch(mentalDaoProvider);
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= AppBreakpoints.compact) {
            return _buildDesktopLayout(context, theme, sleepDao, mentalDao, todayStart);
          }
          return _buildPhoneLayout(context, theme, sleepDao, mentalDao, todayStart);
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Desktop: mood inline + actions + summary side-by-side
  // ---------------------------------------------------------------------------

  Widget _buildDesktopLayout(
    BuildContext context, ThemeData theme,
    SleepDao sleepDao, MentalDao mentalDao, DateTime todayStart,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left column: inline mood + quick actions
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Inline mood logging ---
                _buildInlineMood(theme),
                const SizedBox(height: 24),
                // --- Other quick actions ---
                Text('Mas acciones', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _ActionChip(icon: Icons.self_improvement, label: 'Respiracion', color: AppColors.mental, onTap: () => GoRouter.of(context).push(AppRoutes.breathing)),
                    _ActionChip(icon: Icons.favorite, label: 'Gratitud', color: AppColors.mental, onTap: () => GoRouter.of(context).push(AppRoutes.gratitude)),
                    _ActionChip(icon: Icons.bedtime, label: 'Registrar sueno', color: AppColors.sleep, onTap: () => GoRouter.of(context).push(AppRoutes.sleep)),
                    _ActionChip(icon: Icons.bolt, label: 'Energia', color: AppColors.gym, onTap: () => GoRouter.of(context).push(AppRoutes.energy)),
                    _ActionChip(icon: Icons.psychology, label: 'Patrones IA', color: AppColors.goals, onTap: () => GoRouter.of(context).go(AppRoutes.mentalInsights)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          // Right column: today's summary + history
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Resumen de hoy', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _buildSleepSummary(context, sleepDao, todayStart),
                const SizedBox(height: 8),
                _buildMoodSummary(context, mentalDao, todayStart),
                const SizedBox(height: 24),
                Text('Historiales', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _HistoryTile(icon: Icons.nights_stay, color: AppColors.sleep, title: 'Historial de sueno', onTap: () => GoRouter.of(context).go(AppRoutes.sleepHistory)),
                _HistoryTile(icon: Icons.show_chart, color: AppColors.sleep, title: 'Ritmo circadiano', onTap: () => GoRouter.of(context).go(AppRoutes.circadian)),
                _HistoryTile(icon: Icons.calendar_month, color: AppColors.mental, title: 'Calendario emocional', onTap: () => GoRouter.of(context).go(AppRoutes.mentalHistory)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Inline mood widget
  // ---------------------------------------------------------------------------

  Widget _buildInlineMood(ThemeData theme) {
    if (_moodSaved) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: _moodColor.withAlpha(15),
          border: Border.all(color: _moodColor.withAlpha(60)),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle, color: _moodColor, size: 32),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Mood registrado', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: _moodColor)),
                Text(_moodQuadrant, style: theme.textTheme.bodySmall),
              ],
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        border: Border.all(color: AppColors.lightBorder),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.mood, color: AppColors.mental, size: 24),
              const SizedBox(width: 8),
              Text('Como te sientes?', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _moodColor.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_moodQuadrant, style: theme.textTheme.labelSmall?.copyWith(color: _moodColor, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Valence row
          Row(
            children: [
              SizedBox(width: 60, child: Text('Animo', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600))),
              ...List.generate(5, (i) {
                final v = i + 1;
                final emojis = ['😫', '😔', '😐', '😊', '🔥'];
                final selected = _valence == v;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: GestureDetector(
                    onTap: () => setState(() => _valence = v),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: selected ? _moodColor.withAlpha(25) : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: selected ? _moodColor : AppColors.lightBorder, width: selected ? 2 : 1),
                      ),
                      alignment: Alignment.center,
                      child: Text(emojis[i], style: TextStyle(fontSize: selected ? 20 : 16)),
                    ),
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: 10),
          // Energy row
          Row(
            children: [
              SizedBox(width: 60, child: Text('Energia', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600))),
              ...List.generate(5, (i) {
                final e = i + 1;
                final labels = ['⚡', '⚡', '⚡', '⚡', '⚡'];
                final selected = _energy == e;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: GestureDetector(
                    onTap: () => setState(() => _energy = e),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: selected ? _moodColor.withAlpha(25) : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: selected ? _moodColor : AppColors.lightBorder, width: selected ? 2 : 1),
                      ),
                      alignment: Alignment.center,
                      child: Opacity(opacity: selected ? 1.0 : 0.3 + (i * 0.15), child: Text(labels[i], style: TextStyle(fontSize: selected ? 18 : 14))),
                    ),
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: 14),
          // Tags
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _tags.map((tag) {
              final selected = _selectedTags.contains(tag);
              return FilterChip(
                label: Text(tag, style: TextStyle(fontSize: 12, color: selected ? Colors.white : null)),
                selected: selected,
                onSelected: (_) {
                  setState(() {
                    if (selected) { _selectedTags.remove(tag); } else if (_selectedTags.length < 5) { _selectedTags.add(tag); }
                  });
                },
                selectedColor: AppColors.mental,
                checkmarkColor: Colors.white,
                side: BorderSide(color: selected ? AppColors.mental : AppColors.lightBorder),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                visualDensity: VisualDensity.compact,
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              icon: _isSaving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.check, size: 18),
              label: Text(_isSaving ? 'Guardando...' : 'Registrar mood'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.mental,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _isSaving ? null : _saveMood,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Phone layout (unchanged from original)
  // ---------------------------------------------------------------------------

  Widget _buildPhoneLayout(
    BuildContext context, ThemeData theme,
    SleepDao sleepDao, MentalDao mentalDao, DateTime todayStart,
  ) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Acciones rapidas', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.4,
          children: [
            _QuickAction(icon: Icons.mood, label: 'Estado de animo', subtitle: 'Registrar mood', color: AppColors.mental, onTap: () => GoRouter.of(context).push(AppRoutes.mood)),
            _QuickAction(icon: Icons.self_improvement, label: 'Respiracion', subtitle: 'Ejercicio guiado', color: AppColors.mental, onTap: () => GoRouter.of(context).push(AppRoutes.breathing)),
            _QuickAction(icon: Icons.favorite, label: 'Gratitud', subtitle: '3 cosas buenas', color: AppColors.mental, onTap: () => GoRouter.of(context).push(AppRoutes.gratitude)),
            _QuickAction(icon: Icons.bedtime, label: 'Sueno', subtitle: 'Registrar noche', color: AppColors.sleep, onTap: () => GoRouter.of(context).push(AppRoutes.sleep)),
            _QuickAction(icon: Icons.bolt, label: 'Energia', subtitle: 'Check-in rapido', color: AppColors.gym, onTap: () => GoRouter.of(context).push(AppRoutes.energy)),
            _QuickAction(icon: Icons.psychology, label: 'Patrones IA', subtitle: 'Analisis cruzado', color: AppColors.goals, onTap: () => GoRouter.of(context).go(AppRoutes.mentalInsights)),
          ],
        ),
        const SizedBox(height: 24),
        Text('Resumen de hoy', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        _buildSleepSummary(context, sleepDao, todayStart),
        const SizedBox(height: 8),
        _buildMoodSummary(context, mentalDao, todayStart),
        const SizedBox(height: 24),
        Text('Historiales', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        _HistoryTile(icon: Icons.nights_stay, color: AppColors.sleep, title: 'Historial de sueno', onTap: () => GoRouter.of(context).go(AppRoutes.sleepHistory)),
        _HistoryTile(icon: Icons.show_chart, color: AppColors.sleep, title: 'Ritmo circadiano', onTap: () => GoRouter.of(context).go(AppRoutes.circadian)),
        _HistoryTile(icon: Icons.calendar_month, color: AppColors.mental, title: 'Calendario emocional', onTap: () => GoRouter.of(context).go(AppRoutes.mentalHistory)),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Summary widgets
  // ---------------------------------------------------------------------------

  Widget _buildSleepSummary(BuildContext context, SleepDao sleepDao, DateTime todayStart) {
    return StreamBuilder<List<SleepLog>>(
      stream: sleepDao.watchSleepLogs(todayStart.subtract(const Duration(days: 1)), todayStart),
      builder: (context, snapshot) {
        final logs = snapshot.data ?? [];
        if (logs.isEmpty) {
          return _SummaryCard(icon: Icons.bedtime, color: AppColors.sleep, title: 'Sueno', value: 'Sin registro', subtitle: 'Toca para registrar', onTap: () => GoRouter.of(context).push(AppRoutes.sleep));
        }
        final log = logs.first;
        final hours = log.wakeTime.difference(log.bedTime).inMinutes / 60;
        return _SummaryCard(icon: Icons.bedtime, color: AppColors.sleep, title: 'Sueno anoche', value: '${hours.toStringAsFixed(1)}h — Score ${log.sleepScore}/100', subtitle: 'Calidad: ${'⭐' * log.qualityRating}', onTap: () => GoRouter.of(context).go(AppRoutes.sleepHistory));
      },
    );
  }

  Widget _buildMoodSummary(BuildContext context, MentalDao mentalDao, DateTime todayStart) {
    return StreamBuilder<List<MoodLog>>(
      stream: mentalDao.watchMoodLogs(todayStart, todayStart.add(const Duration(days: 1))),
      builder: (context, snapshot) {
        final logs = snapshot.data ?? [];
        if (logs.isEmpty) {
          return _SummaryCard(icon: Icons.mood, color: AppColors.mental, title: 'Estado de animo', value: 'Sin registro hoy', subtitle: 'Toca para hacer check-in', onTap: () => GoRouter.of(context).push(AppRoutes.mood));
        }
        final log = logs.first;
        final emoji = ['', '😫', '😔', '😐', '😊', '🔥'][log.valence.clamp(1, 5)];
        return _SummaryCard(icon: Icons.mood, color: AppColors.mental, title: 'Mood hoy', value: '$emoji Valence ${log.valence}/5, Energia ${log.energy}/5', subtitle: log.tags.isNotEmpty ? 'Tags: ${log.tags}' : null, onTap: () => GoRouter.of(context).go(AppRoutes.mentalHistory));
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Private widgets
// ---------------------------------------------------------------------------

class _ActionChip extends StatelessWidget {
  const _ActionChip({required this.icon, required this.label, required this.color, required this.onTap});
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, color: color, size: 18),
      label: Text(label),
      onPressed: onTap,
      side: BorderSide(color: color.withAlpha(60)),
      backgroundColor: color.withAlpha(10),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({required this.icon, required this.label, required this.subtitle, required this.color, required this.onTap});
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withAlpha(60)),
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [color.withAlpha(30), color.withAlpha(8)]),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const Spacer(),
            Text(label, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
            Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withAlpha(160))),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.icon, required this.color, required this.title, required this.value, this.subtitle, this.onTap});
  final IconData icon;
  final Color color;
  final String title;
  final String value;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(backgroundColor: color.withAlpha(25), child: Icon(icon, color: color, size: 20)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: theme.textTheme.bodySmall),
                Text(value, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                if (subtitle != null) Text(subtitle!, style: theme.textTheme.bodySmall),
              ])),
              Icon(Icons.chevron_right, color: theme.textTheme.bodySmall?.color),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.icon, required this.color, required this.title, required this.onTap});
  final IconData icon;
  final Color color;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(leading: Icon(icon, color: color), title: Text(title), trailing: const Icon(Icons.chevron_right), onTap: onTap);
  }
}
