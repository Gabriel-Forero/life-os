import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:life_os/core/constants/app_colors.dart';
import 'package:life_os/core/database/app_database.dart';
import 'package:life_os/core/domain/notification_config.dart';
import 'package:life_os/core/providers/providers.dart';
import 'package:life_os/core/router/app_router.dart';
import 'package:life_os/core/services/theme_notifier.dart';

// ---------------------------------------------------------------------------
// Supported currencies
// ---------------------------------------------------------------------------

const _kSupportedCurrencies = [
  'COP',
  'USD',
  'EUR',
  'MXN',
  'ARS',
  'BRL',
  'CLP',
  'PEN',
];

// ---------------------------------------------------------------------------
// Settings screen
// ---------------------------------------------------------------------------

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _habitReminders = false;
  bool _budgetAlerts = false;
  bool _waterReminders = false;

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Future<AppSettingsTableData?> _getSettings() =>
      ref.read(appSettingsDaoProvider).getSettings();

  Future<void> _ensureSettingsRow() async {
    final dao = ref.read(appSettingsDaoProvider);
    final existing = await dao.getSettings();
    if (existing == null) {
      final now = DateTime.now();
      await dao.createSettings(
        AppSettingsTableCompanion.insert(
          userName: 'Usuario',
          primaryGoal: 'balance',
          createdAt: now,
          updatedAt: now,
        ),
      );
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  // ---------------------------------------------------------------------------
  // Theme handling
  // ---------------------------------------------------------------------------

  Future<void> _onThemeChanged(String mode) async {
    await _ensureSettingsRow();
    await ref.read(appSettingsDaoProvider).updateThemeMode(mode);
    ref.read(themeNotifierProvider.notifier).setThemeModeFromString(mode);
  }

  // ---------------------------------------------------------------------------
  // Biometric handling
  // ---------------------------------------------------------------------------

  Future<void> _onBiometricToggled(bool value) async {
    if (value) {
      final available = await ref.read(biometricServiceProvider).isAvailable();
      if (!available) {
        _showSnack('Biometría no disponible en este dispositivo');
        return;
      }
    }
    await _ensureSettingsRow();
    await ref.read(appSettingsDaoProvider).updateBiometric(value);
    setState(() {});
  }

  // ---------------------------------------------------------------------------
  // Notification handling
  // ---------------------------------------------------------------------------

  Future<void> _onHabitRemindersToggled(bool enabled) async {
    final scheduler = ref.read(notificationSchedulerProvider);
    await scheduler.initialize();
    if (enabled) {
      // Schedule daily habit reminder at 9:00 AM
      final now = DateTime.now();
      final scheduled = DateTime(now.year, now.month, now.day, 9);
      final target = scheduled.isBefore(now)
          ? scheduled.add(const Duration(days: 1))
          : scheduled;
      await scheduler.schedule(
        id: scheduler.notificationId(NotificationType.habitReminder),
        title: 'Recordatorio de habitos',
        body: 'Revisa tus habitos del dia',
        scheduledDate: target,
      );
    } else {
      await scheduler.cancel(
        scheduler.notificationId(NotificationType.habitReminder),
      );
    }
    setState(() => _habitReminders = enabled);
  }

  Future<void> _onWaterRemindersToggled(bool enabled) async {
    final scheduler = ref.read(notificationSchedulerProvider);
    await scheduler.initialize();
    if (enabled) {
      // Schedule water reminders every 2 hours between 8 AM and 8 PM
      final now = DateTime.now();
      var offset = 0;
      for (var hour = 8; hour <= 20; hour += 2) {
        final scheduled = DateTime(now.year, now.month, now.day, hour);
        final target = scheduled.isBefore(now)
            ? scheduled.add(const Duration(days: 1))
            : scheduled;
        await scheduler.schedule(
          id: scheduler.notificationId(NotificationType.waterReminder, offset),
          title: 'Recordatorio de agua',
          body: 'Recuerda tomar agua',
          scheduledDate: target,
        );
        offset++;
      }
    } else {
      // Cancel all water reminder IDs (7 slots: hours 8,10,12,14,16,18,20)
      for (var i = 0; i < 7; i++) {
        await scheduler.cancel(
          scheduler.notificationId(NotificationType.waterReminder, i),
        );
      }
    }
    setState(() => _waterReminders = enabled);
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<AppSettingsTableData?>(
        future: _getSettings(),
        builder: (context, snap) {
          final settings = snap.data;
          final themeMode = settings?.themeMode ?? 'dark';
          final language = settings?.language ?? 'es';
          final currency = settings?.currency ?? 'COP';
          final useBiometric = settings?.useBiometric ?? false;

          return ListView(
            key: const ValueKey('settings_list'),
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              // ------------------------------------------------------------------
              // Appearance
              // ------------------------------------------------------------------
              const _SectionHeader(title: 'Apariencia'),
              _SettingsCard(
                children: [
                  Semantics(
                    label: 'Selector de tema',
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tema',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: AppColors.textSecondary(
                                    Theme.of(context).brightness,
                                  ),
                                ),
                          ),
                          const SizedBox(height: 8),
                          SegmentedButton<String>(
                            key: const ValueKey('theme_segmented'),
                            segments: const [
                              ButtonSegment(
                                value: 'dark',
                                label: Text('Oscuro'),
                                icon: Icon(Icons.dark_mode_outlined),
                              ),
                              ButtonSegment(
                                value: 'light',
                                label: Text('Claro'),
                                icon: Icon(Icons.light_mode_outlined),
                              ),
                              ButtonSegment(
                                value: 'system',
                                label: Text('Sistema'),
                                icon: Icon(Icons.settings_brightness_outlined),
                              ),
                            ],
                            selected: {themeMode},
                            onSelectionChanged: (selection) =>
                                _onThemeChanged(selection.first),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  Semantics(
                    label: 'Selector de idioma',
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.language_outlined, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Idioma',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ),
                          SegmentedButton<String>(
                            key: const ValueKey('language_segmented'),
                            segments: const [
                              ButtonSegment(value: 'es', label: Text('ES')),
                              ButtonSegment(value: 'en', label: Text('EN')),
                            ],
                            selected: {language},
                            onSelectionChanged: (selection) async {
                              await _ensureSettingsRow();
                              await ref
                                  .read(appSettingsDaoProvider)
                                  .updateLanguage(selection.first);
                              setState(() {});
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // ------------------------------------------------------------------
              // Security
              // ------------------------------------------------------------------
              const _SectionHeader(title: 'Seguridad'),
              _SettingsCard(
                children: [
                  Semantics(
                    label: 'Bloqueo biometrico',
                    child: SwitchListTile(
                      key: const ValueKey('biometric_switch'),
                      secondary: const Icon(Icons.fingerprint_outlined),
                      title: const Text('Bloqueo biometrico'),
                      subtitle: const Text(
                        'Requiere huella dactilar o Face ID al abrir la app',
                      ),
                      value: useBiometric,
                      onChanged: _onBiometricToggled,
                    ),
                  ),
                ],
              ),

              // ------------------------------------------------------------------
              // Data
              // ------------------------------------------------------------------
              const _SectionHeader(title: 'Datos'),
              _SettingsCard(
                children: [
                  Semantics(
                    label: 'Seleccionar moneda',
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.attach_money_outlined, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Moneda',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ),
                          DropdownButton<String>(
                            key: const ValueKey('currency_dropdown'),
                            value: _kSupportedCurrencies.contains(currency)
                                ? currency
                                : 'COP',
                            underline: const SizedBox.shrink(),
                            items: _kSupportedCurrencies
                                .map(
                                  (c) => DropdownMenuItem(
                                    value: c,
                                    child: Text(c),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) async {
                              if (value == null) return;
                              await _ensureSettingsRow();
                              await ref
                                  .read(appSettingsDaoProvider)
                                  .updateCurrency(value);
                              setState(() {});
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // ------------------------------------------------------------------
              // Notifications
              // ------------------------------------------------------------------
              const _SectionHeader(title: 'Notificaciones'),
              _SettingsCard(
                children: [
                  Semantics(
                    label: 'Recordatorios de habitos',
                    child: SwitchListTile(
                      key: const ValueKey('habit_reminders_switch'),
                      secondary: const Icon(Icons.check_circle_outline),
                      title: const Text('Recordatorios de habitos'),
                      subtitle: const Text('Diario a las 9:00 AM'),
                      value: _habitReminders,
                      onChanged: _onHabitRemindersToggled,
                    ),
                  ),
                  const Divider(height: 1),
                  Semantics(
                    label: 'Alertas de presupuesto',
                    child: SwitchListTile(
                      key: const ValueKey('budget_alerts_switch'),
                      secondary: const Icon(Icons.account_balance_wallet_outlined),
                      title: const Text('Alertas de presupuesto'),
                      subtitle: const Text('Cuando superes el 80% del presupuesto'),
                      value: _budgetAlerts,
                      onChanged: (v) => setState(() => _budgetAlerts = v),
                    ),
                  ),
                  const Divider(height: 1),
                  Semantics(
                    label: 'Recordatorios de agua',
                    child: SwitchListTile(
                      key: const ValueKey('water_reminders_switch'),
                      secondary: const Icon(Icons.water_drop_outlined),
                      title: const Text('Recordatorios de agua'),
                      subtitle: const Text('Cada 2 horas de 8 AM a 8 PM'),
                      value: _waterReminders,
                      onChanged: _onWaterRemindersToggled,
                    ),
                  ),
                ],
              ),

              // ------------------------------------------------------------------
              // Health Integration
              // ------------------------------------------------------------------
              const _SectionHeader(title: 'Salud'),
              _SettingsCard(
                children: [
                  ListTile(
                    key: const ValueKey('health_import_tile'),
                    leading: const Icon(Icons.favorite_outline,
                        color: AppColors.sleep),
                    title: const Text('Importar datos de salud'),
                    subtitle: const Text(
                        'HealthKit / Health Connect (disponible proximamente)'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      showDialog<void>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Importar datos de salud'),
                          content: const Text(
                            'La integracion con plataformas de salud '
                            '(HealthKit / Health Connect) estara disponible proximamente.',
                          ),
                          actions: [
                            FilledButton(
                              onPressed: () => Navigator.of(ctx).pop(),
                              child: const Text('Entendido'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),

              // ------------------------------------------------------------------
              // Backup
              // ------------------------------------------------------------------
              const _SectionHeader(title: 'Respaldo'),
              _SettingsCard(
                children: [
                  ListTile(
                    key: const ValueKey('backup_tile'),
                    leading: const Icon(Icons.backup_outlined),
                    title: const Text('Gestionar respaldo'),
                    subtitle: const Text('Exportar e importar datos de la app'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push(AppRoutes.backup),
                  ),
                ],
              ),

              // ------------------------------------------------------------------
              // AI Configuration
              // ------------------------------------------------------------------
              const _SectionHeader(title: 'Inteligencia Artificial'),
              _SettingsCard(
                children: [
                  ListTile(
                    key: const ValueKey('ai_config_tile'),
                    leading: const Icon(Icons.smart_toy_outlined),
                    title: const Text('Configurar IA'),
                    subtitle: const Text(
                      'OpenAI, Claude, Gemini y modelos personalizados',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push(AppRoutes.aiConfig),
                  ),
                ],
              ),

              // ------------------------------------------------------------------
              // About
              // ------------------------------------------------------------------
              const _SectionHeader(title: 'Acerca de'),
              const _SettingsCard(
                children: [
                  ListTile(
                    key: ValueKey('app_version_tile'),
                    leading: Icon(Icons.shield_outlined,
                        color: AppColors.finance),
                    title: Text('LifeOS'),
                    subtitle: Text('Version 0.1.0'),
                  ),
                  Divider(height: 1),
                  ListTile(
                    key: ValueKey('made_with_love_tile'),
                    leading: Icon(Icons.favorite_outline,
                        color: AppColors.mental),
                    title: Text('Hecho con amor en Colombia'),
                    subtitle: Text('Para una vida mas organizada y plena'),
                  ),
                ],
              ),

              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Helper widgets
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.textSecondary(Theme.of(context).brightness),
              letterSpacing: 1.2,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Card(
        margin: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    );
  }
}
