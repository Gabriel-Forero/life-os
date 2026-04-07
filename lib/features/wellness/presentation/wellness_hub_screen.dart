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
import 'package:life_os/features/sleep/domain/sleep_input.dart';

class WellnessHubScreen extends ConsumerStatefulWidget {
  const WellnessHubScreen({super.key});

  @override
  ConsumerState<WellnessHubScreen> createState() => _WellnessHubScreenState();
}

class _WellnessHubScreenState extends ConsumerState<WellnessHubScreen> {
  // --- Mood state ---
  int _valence = 3;
  int _energy = 3;
  final _moodTags = <String>{};
  bool _moodSaved = false;
  bool _moodSaving = false;

  // --- Gratitude state ---
  final _g1 = TextEditingController();
  final _g2 = TextEditingController();
  final _g3 = TextEditingController();
  bool _gratSaved = false;
  bool _gratSaving = false;

  // --- Energy state ---
  int? _eMorning;
  int? _eAfternoon;
  int? _eEvening;
  bool _energySaved = false;
  bool _energySaving = false;

  static const _tags = ['Feliz', 'Motivado', 'Tranquilo', 'Enfocado', 'Agradecido', 'Cansado', 'Estresado', 'Ansioso', 'Triste', 'Enojado'];

  @override
  void dispose() {
    _g1.dispose();
    _g2.dispose();
    _g3.dispose();
    super.dispose();
  }

  // --- Mood helpers ---
  String get _moodQuadrant {
    if (_valence >= 3 && _energy >= 3) return 'Activo y Positivo';
    if (_valence >= 3 && _energy < 3) return 'Tranquilo y Positivo';
    if (_valence < 3 && _energy >= 3) return 'Activo y Negativo';
    return 'Bajo y Negativo';
  }

  Color get _moodColor {
    final s = ((_valence - 1) / 4.0 * 50 + (_energy - 1) / 4.0 * 50).round();
    if (s >= 75) return AppColors.success;
    if (s >= 50) return AppColors.mental;
    if (s >= 25) return AppColors.warning;
    return AppColors.error;
  }

  Future<void> _saveMood() async {
    setState(() => _moodSaving = true);
    await ref.read(mentalNotifierProvider).logMood(MoodInput(date: DateTime.now(), valence: _valence, energy: _energy, tags: _moodTags.toList()));
    if (mounted) setState(() { _moodSaving = false; _moodSaved = true; });
  }

  Future<void> _saveGratitude() async {
    final t1 = _g1.text.trim(), t2 = _g2.text.trim(), t3 = _g3.text.trim();
    if (t1.isEmpty && t2.isEmpty && t3.isEmpty) return;
    setState(() => _gratSaving = true);
    final lines = <String>[];
    if (t1.isNotEmpty) lines.add('1. $t1');
    if (t2.isNotEmpty) lines.add('2. $t2');
    if (t3.isNotEmpty) lines.add('3. $t3');
    await ref.read(mentalNotifierProvider).logMood(MoodInput(date: DateTime.now(), valence: 4, energy: 3, tags: const ['gratitud'], journalNote: lines.join('\n')));
    if (mounted) setState(() { _gratSaving = false; _gratSaved = true; });
  }

  Future<void> _saveEnergy() async {
    if (_eMorning == null && _eAfternoon == null && _eEvening == null) return;
    setState(() => _energySaving = true);
    final notifier = ref.read(sleepNotifierProvider);
    final now = DateTime.now();
    final date = DateTime(now.year, now.month, now.day);
    if (_eMorning != null) await notifier.logEnergy(EnergyInput(date: date, timeOfDay: 'morning', level: _eMorning!));
    if (_eAfternoon != null) await notifier.logEnergy(EnergyInput(date: date, timeOfDay: 'afternoon', level: _eAfternoon!));
    if (_eEvening != null) await notifier.logEnergy(EnergyInput(date: date, timeOfDay: 'evening', level: _eEvening!));
    if (mounted) setState(() { _energySaving = false; _energySaved = true; });
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
            return _desktopLayout(context, theme, sleepDao, mentalDao, todayStart);
          }
          return _phoneLayout(context, theme, sleepDao, mentalDao, todayStart);
        },
      ),
    );
  }

  // ===========================================================================
  // DESKTOP — inline cards stacked vertically in two columns
  // ===========================================================================

  Widget _desktopLayout(BuildContext ctx, ThemeData theme, SleepDao sleepDao, MentalDao mentalDao, DateTime todayStart) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // LEFT: inline cards
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _moodCard(theme),
                const SizedBox(height: 16),
                _gratitudeCard(theme),
                const SizedBox(height: 16),
                _energyCard(theme),
                const SizedBox(height: 20),
                Text('Necesitan pantalla completa', style: theme.textTheme.labelMedium?.copyWith(color: AppColors.lightTextSecondary)),
                const SizedBox(height: 8),
                Wrap(spacing: 10, runSpacing: 10, children: [
                  _NavChip(icon: Icons.self_improvement, label: 'Respiracion', color: AppColors.mental, onTap: () => GoRouter.of(ctx).push(AppRoutes.breathing)),
                  _NavChip(icon: Icons.bedtime, label: 'Registrar sueno', color: AppColors.sleep, onTap: () => GoRouter.of(ctx).push(AppRoutes.sleep)),
                ]),
              ],
            ),
          ),
          const SizedBox(width: 20),
          // RIGHT: summary + history
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Resumen de hoy', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _sleepSummary(ctx, sleepDao, todayStart),
                const SizedBox(height: 8),
                _moodSummary(ctx, mentalDao, todayStart),
                const SizedBox(height: 24),
                Text('Historiales', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _histTile(Icons.nights_stay, AppColors.sleep, 'Historial de sueno', () => GoRouter.of(ctx).go(AppRoutes.sleepHistory)),
                _histTile(Icons.show_chart, AppColors.sleep, 'Ritmo circadiano', () => GoRouter.of(ctx).go(AppRoutes.circadian)),
                _histTile(Icons.calendar_month, AppColors.mental, 'Calendario emocional', () => GoRouter.of(ctx).go(AppRoutes.mentalHistory)),
                _histTile(Icons.psychology, AppColors.goals, 'Patrones IA', () => GoRouter.of(ctx).go(AppRoutes.mentalInsights)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // INLINE CARDS
  // ===========================================================================

  Widget _cardShell({required Widget child, required Color accent}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        border: Border.all(color: accent.withAlpha(50)),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: child,
    );
  }

  Widget _savedBanner(String text, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: color.withAlpha(15), border: Border.all(color: color.withAlpha(60))),
      child: Row(children: [
        Icon(Icons.check_circle, color: color, size: 28),
        const SizedBox(width: 10),
        Text(text, style: TextStyle(fontWeight: FontWeight.w700, color: color)),
      ]),
    );
  }

  // --- MOOD ---
  Widget _moodCard(ThemeData theme) {
    if (_moodSaved) return _savedBanner('Mood registrado — $_moodQuadrant', _moodColor);
    return _cardShell(
      accent: AppColors.mental,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.mood, color: AppColors.mental, size: 22),
          const SizedBox(width: 8),
          Text('Como te sientes?', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const Spacer(),
          _badge(_moodQuadrant, _moodColor),
        ]),
        const SizedBox(height: 14),
        _emojiRow('Animo', ['😫', '😔', '😐', '😊', '🔥'], _valence, (v) => setState(() => _valence = v), theme),
        const SizedBox(height: 8),
        _emojiRow('Energia', ['🔋', '🔋', '🔋', '🔋', '🔋'], _energy, (v) => setState(() => _energy = v), theme, useOpacity: true),
        const SizedBox(height: 12),
        _tagChips(),
        const SizedBox(height: 14),
        _saveBtn('Registrar mood', AppColors.mental, _moodSaving, _saveMood),
      ]),
    );
  }

  // --- GRATITUDE ---
  Widget _gratitudeCard(ThemeData theme) {
    if (_gratSaved) return _savedBanner('Gratitud registrada', AppColors.mental);
    return _cardShell(
      accent: AppColors.mental,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.favorite, color: AppColors.mental, size: 22),
          const SizedBox(width: 8),
          Text('Gratitud', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const Spacer(),
          Text('3 cosas buenas de hoy', style: theme.textTheme.bodySmall?.copyWith(color: AppColors.lightTextSecondary)),
        ]),
        const SizedBox(height: 14),
        _gratField(_g1, '1. Estoy agradecido por...'),
        const SizedBox(height: 8),
        _gratField(_g2, '2. Estoy agradecido por...'),
        const SizedBox(height: 8),
        _gratField(_g3, '3. Estoy agradecido por...'),
        const SizedBox(height: 14),
        _saveBtn('Guardar gratitud', AppColors.mental, _gratSaving, _saveGratitude),
      ]),
    );
  }

  Widget _gratField(TextEditingController ctrl, String hint) {
    return TextField(
      controller: ctrl,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: AppColors.lightTextSecondary.withAlpha(120), fontSize: 13),
        filled: true,
        fillColor: AppColors.lightSurfaceVariant,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        isDense: true,
      ),
      style: const TextStyle(fontSize: 13),
    );
  }

  // --- ENERGY ---
  Widget _energyCard(ThemeData theme) {
    if (_energySaved) return _savedBanner('Energia registrada', AppColors.gym);
    return _cardShell(
      accent: AppColors.gym,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.bolt, color: AppColors.gym, size: 22),
          const SizedBox(width: 8),
          Text('Energia del dia', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 14),
        _energySlot('☀️ Manana', _eMorning, (v) => setState(() => _eMorning = v), theme),
        const SizedBox(height: 8),
        _energySlot('🌤️ Tarde', _eAfternoon, (v) => setState(() => _eAfternoon = v), theme),
        const SizedBox(height: 8),
        _energySlot('🌙 Noche', _eEvening, (v) => setState(() => _eEvening = v), theme),
        const SizedBox(height: 14),
        _saveBtn('Guardar energia', AppColors.gym, _energySaving, _saveEnergy),
      ]),
    );
  }

  Widget _energySlot(String label, int? value, ValueChanged<int> onChanged, ThemeData theme) {
    return Row(children: [
      SizedBox(width: 80, child: Text(label, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600))),
      ...List.generate(5, (i) {
        final level = (i + 1) * 2; // 2,4,6,8,10
        final selected = value == level;
        return Padding(
          padding: const EdgeInsets.only(right: 6),
          child: GestureDetector(
            onTap: () => onChanged(level),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: selected ? AppColors.gym.withAlpha(25) : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: selected ? AppColors.gym : AppColors.lightBorder, width: selected ? 2 : 1),
              ),
              alignment: Alignment.center,
              child: Text('${i + 1}', style: TextStyle(fontSize: 14, fontWeight: selected ? FontWeight.w700 : FontWeight.w400, color: selected ? AppColors.gym : AppColors.lightTextSecondary)),
            ),
          ),
        );
      }),
    ]);
  }

  // ===========================================================================
  // Shared inline helpers
  // ===========================================================================

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withAlpha(20), borderRadius: BorderRadius.circular(8)),
      child: Text(text, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    );
  }

  Widget _emojiRow(String label, List<String> emojis, int value, ValueChanged<int> onChanged, ThemeData theme, {bool useOpacity = false}) {
    return Row(children: [
      SizedBox(width: 60, child: Text(label, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600))),
      ...List.generate(5, (i) {
        final v = i + 1;
        final selected = value == v;
        return Padding(
          padding: const EdgeInsets.only(right: 6),
          child: GestureDetector(
            onTap: () => onChanged(v),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: selected ? _moodColor.withAlpha(25) : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: selected ? _moodColor : AppColors.lightBorder, width: selected ? 2 : 1),
              ),
              alignment: Alignment.center,
              child: useOpacity
                  ? Opacity(opacity: selected ? 1.0 : 0.3 + (i * 0.15), child: Text(emojis[i], style: TextStyle(fontSize: selected ? 18 : 14)))
                  : Text(emojis[i], style: TextStyle(fontSize: selected ? 20 : 16)),
            ),
          ),
        );
      }),
    ]);
  }

  Widget _tagChips() {
    return Wrap(spacing: 6, runSpacing: 6, children: _tags.map((t) {
      final sel = _moodTags.contains(t);
      return FilterChip(
        label: Text(t, style: TextStyle(fontSize: 12, color: sel ? Colors.white : null)),
        selected: sel,
        onSelected: (_) => setState(() { if (sel) { _moodTags.remove(t); } else if (_moodTags.length < 5) { _moodTags.add(t); } }),
        selectedColor: AppColors.mental,
        checkmarkColor: Colors.white,
        side: BorderSide(color: sel ? AppColors.mental : AppColors.lightBorder),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        visualDensity: VisualDensity.compact,
      );
    }).toList());
  }

  Widget _saveBtn(String label, Color color, bool loading, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        icon: loading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.check, size: 18),
        label: Text(loading ? 'Guardando...' : label),
        style: FilledButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        onPressed: loading ? null : onPressed,
      ),
    );
  }

  // ===========================================================================
  // PHONE layout (unchanged — cards navigate to full screens)
  // ===========================================================================

  Widget _phoneLayout(BuildContext ctx, ThemeData theme, SleepDao sleepDao, MentalDao mentalDao, DateTime todayStart) {
    return ListView(padding: const EdgeInsets.all(16), children: [
      Text('Acciones rapidas', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
      const SizedBox(height: 12),
      GridView.count(crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.4, children: [
        _PhoneCard(icon: Icons.mood, label: 'Estado de animo', sub: 'Registrar mood', color: AppColors.mental, onTap: () => GoRouter.of(ctx).push(AppRoutes.mood)),
        _PhoneCard(icon: Icons.self_improvement, label: 'Respiracion', sub: 'Ejercicio guiado', color: AppColors.mental, onTap: () => GoRouter.of(ctx).push(AppRoutes.breathing)),
        _PhoneCard(icon: Icons.favorite, label: 'Gratitud', sub: '3 cosas buenas', color: AppColors.mental, onTap: () => GoRouter.of(ctx).push(AppRoutes.gratitude)),
        _PhoneCard(icon: Icons.bedtime, label: 'Sueno', sub: 'Registrar noche', color: AppColors.sleep, onTap: () => GoRouter.of(ctx).push(AppRoutes.sleep)),
        _PhoneCard(icon: Icons.bolt, label: 'Energia', sub: 'Check-in rapido', color: AppColors.gym, onTap: () => GoRouter.of(ctx).push(AppRoutes.energy)),
        _PhoneCard(icon: Icons.psychology, label: 'Patrones IA', sub: 'Analisis cruzado', color: AppColors.goals, onTap: () => GoRouter.of(ctx).go(AppRoutes.mentalInsights)),
      ]),
      const SizedBox(height: 24),
      Text('Resumen de hoy', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
      const SizedBox(height: 12),
      _sleepSummary(ctx, sleepDao, todayStart),
      const SizedBox(height: 8),
      _moodSummary(ctx, mentalDao, todayStart),
      const SizedBox(height: 24),
      Text('Historiales', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
      const SizedBox(height: 12),
      _histTile(Icons.nights_stay, AppColors.sleep, 'Historial de sueno', () => GoRouter.of(ctx).go(AppRoutes.sleepHistory)),
      _histTile(Icons.show_chart, AppColors.sleep, 'Ritmo circadiano', () => GoRouter.of(ctx).go(AppRoutes.circadian)),
      _histTile(Icons.calendar_month, AppColors.mental, 'Calendario emocional', () => GoRouter.of(ctx).go(AppRoutes.mentalHistory)),
    ]);
  }

  // ===========================================================================
  // Summary widgets (shared)
  // ===========================================================================

  Widget _sleepSummary(BuildContext ctx, SleepDao dao, DateTime todayStart) {
    return StreamBuilder<List<SleepLog>>(
      stream: dao.watchSleepLogs(todayStart.subtract(const Duration(days: 1)), todayStart),
      builder: (ctx2, snap) {
        final logs = snap.data ?? [];
        if (logs.isEmpty) return _summaryCard(Icons.bedtime, AppColors.sleep, 'Sueno', 'Sin registro', 'Toca para registrar', () => GoRouter.of(ctx).push(AppRoutes.sleep));
        final l = logs.first;
        final h = l.wakeTime.difference(l.bedTime).inMinutes / 60;
        return _summaryCard(Icons.bedtime, AppColors.sleep, 'Sueno anoche', '${h.toStringAsFixed(1)}h — Score ${l.sleepScore}/100', 'Calidad: ${'⭐' * l.qualityRating}', () => GoRouter.of(ctx).go(AppRoutes.sleepHistory));
      },
    );
  }

  Widget _moodSummary(BuildContext ctx, MentalDao dao, DateTime todayStart) {
    return StreamBuilder<List<MoodLog>>(
      stream: dao.watchMoodLogs(todayStart, todayStart.add(const Duration(days: 1))),
      builder: (ctx2, snap) {
        final logs = snap.data ?? [];
        if (logs.isEmpty) return _summaryCard(Icons.mood, AppColors.mental, 'Estado de animo', 'Sin registro hoy', 'Usa el formulario de arriba', null);
        final l = logs.first;
        final e = ['', '😫', '😔', '😐', '😊', '🔥'][l.valence.clamp(1, 5)];
        return _summaryCard(Icons.mood, AppColors.mental, 'Mood hoy', '$e Valence ${l.valence}/5, Energia ${l.energy}/5', l.tags.isNotEmpty ? 'Tags: ${l.tags}' : null, () => GoRouter.of(ctx).go(AppRoutes.mentalHistory));
      },
    );
  }

  Widget _summaryCard(IconData icon, Color color, String title, String value, String? sub, VoidCallback? onTap) {
    final theme = Theme.of(context);
    return Card(child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(12), child: Padding(padding: const EdgeInsets.all(14), child: Row(children: [
      CircleAvatar(backgroundColor: color.withAlpha(25), child: Icon(icon, color: color, size: 20)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: theme.textTheme.bodySmall),
        Text(value, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
        if (sub != null) Text(sub, style: theme.textTheme.bodySmall),
      ])),
      if (onTap != null) Icon(Icons.chevron_right, color: theme.textTheme.bodySmall?.color),
    ]))));
  }

  Widget _histTile(IconData icon, Color color, String title, VoidCallback onTap) {
    return ListTile(leading: Icon(icon, color: color), title: Text(title), trailing: const Icon(Icons.chevron_right), onTap: onTap);
  }
}

// ===========================================================================
// Small private widgets
// ===========================================================================

class _NavChip extends StatelessWidget {
  const _NavChip({required this.icon, required this.label, required this.color, required this.onTap});
  final IconData icon; final String label; final Color color; final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => ActionChip(avatar: Icon(icon, color: color, size: 18), label: Text(label), onPressed: onTap, side: BorderSide(color: color.withAlpha(60)), backgroundColor: color.withAlpha(10));
}

class _PhoneCard extends StatelessWidget {
  const _PhoneCard({required this.icon, required this.label, required this.sub, required this.color, required this.onTap});
  final IconData icon; final String label; final String sub; final Color color; final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(16), child: Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withAlpha(60)), gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [color.withAlpha(30), color.withAlpha(8)])),
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, color: color, size: 28), const Spacer(),
        Text(label, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
        Text(sub, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withAlpha(160))),
      ]),
    ));
  }
}
