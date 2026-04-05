import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_os/core/constants/app_colors.dart';
import 'package:life_os/core/providers/providers.dart';
import 'package:life_os/features/mental/domain/mental_input.dart';

// ---------------------------------------------------------------------------
// Breathing technique data
// ---------------------------------------------------------------------------

class _Technique {
  const _Technique({
    required this.key,
    required this.name,
    required this.description,
    required this.inhale,
    required this.hold1,
    required this.exhale,
    required this.hold2,
  });

  final String key;
  final String name;
  final String description;
  final int inhale;
  final int hold1;
  final int exhale;
  final int hold2;

  int get totalCycle => inhale + hold1 + exhale + hold2;
}

const _techniques = [
  _Technique(
    key: 'box',
    name: 'Respiracion Cuadrada',
    description: 'Inhala 4s, Pausa 4s, Exhala 4s, Pausa 4s',
    inhale: 4,
    hold1: 4,
    exhale: 4,
    hold2: 4,
  ),
  _Technique(
    key: '4_7_8',
    name: 'Tecnica 4-7-8',
    description: 'Inhala 4s, Pausa 7s, Exhala 8s',
    inhale: 4,
    hold1: 7,
    exhale: 8,
    hold2: 0,
  ),
  _Technique(
    key: 'coherent',
    name: 'Respiracion Coherente',
    description: 'Inhala 5s, Exhala 5s (ritmo cardiaco)',
    inhale: 5,
    hold1: 0,
    exhale: 5,
    hold2: 0,
  ),
  _Technique(
    key: 'diaphragmatic',
    name: 'Respiracion Diafragmatica',
    description: 'Inhala 4s por nariz, Exhala 6s por boca',
    inhale: 4,
    hold1: 0,
    exhale: 6,
    hold2: 0,
  ),
];

enum _Phase { inhale, hold1, exhale, hold2, idle }

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class BreathingScreen extends ConsumerStatefulWidget {
  const BreathingScreen({super.key});

  @override
  ConsumerState<BreathingScreen> createState() => _BreathingScreenState();
}

class _BreathingScreenState extends ConsumerState<BreathingScreen>
    with TickerProviderStateMixin {
  int _selectedIndex = 0;
  bool _isRunning = false;
  bool _isCompleted = false;
  int _totalSeconds = 0;
  int _phaseCountdown = 0;
  _Phase _phase = _Phase.idle;
  Timer? _timer;
  late AnimationController _circleAnim;
  late Animation<double> _circleScale;
  int _weeklySessionCount = 0;

  _Technique get _technique => _techniques[_selectedIndex];

  @override
  void initState() {
    super.initState();
    _circleAnim = AnimationController(
      vsync: this,
      duration: Duration(seconds: _technique.inhale),
    );
    _circleScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _circleAnim, curve: Curves.easeInOut),
    );
    _loadWeeklyCount();
  }

  Future<void> _loadWeeklyCount() async {
    final dao = ref.read(mentalDaoProvider);
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final from = DateTime(weekStart.year, weekStart.month, weekStart.day);
    final sessions = await dao.getBreathingSessions(from, now);
    if (mounted) {
      setState(() => _weeklySessionCount = sessions.length);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _circleAnim.dispose();
    super.dispose();
  }

  void _selectTechnique(int index) {
    _stopSession();
    setState(() {
      _selectedIndex = index;
      _phase = _Phase.idle;
    });
    _circleAnim.duration = Duration(seconds: _techniques[index].inhale);
  }

  void _startSession() {
    setState(() {
      _isRunning = true;
      _isCompleted = false;
      _totalSeconds = 0;
    });
    _runPhase(_Phase.inhale);
  }

  void _stopSession() {
    _timer?.cancel();
    _circleAnim.stop();
    setState(() {
      _isRunning = false;
      _phase = _Phase.idle;
    });
  }

  void _runPhase(_Phase phase) {
    setState(() => _phase = phase);
    // Haptic feedback at each phase transition
    final haptic = ref.read(hapticServiceProvider);
    if (phase == _Phase.inhale) {
      haptic.medium();
    } else if (phase == _Phase.exhale) {
      haptic.light();
    } else if (phase == _Phase.hold1 || phase == _Phase.hold2) {
      haptic.selection();
    }
    final duration = _phaseDuration(phase);
    if (duration == 0) {
      _nextPhase(phase);
      return;
    }

    setState(() => _phaseCountdown = duration);

    if (phase == _Phase.inhale) {
      _circleAnim.duration = Duration(seconds: duration);
      _circleAnim.forward(from: 0);
    } else if (phase == _Phase.exhale) {
      _circleAnim.duration = Duration(seconds: duration);
      _circleAnim.reverse(from: 1);
    }

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        _totalSeconds++;
        _phaseCountdown--;
      });
      if (_phaseCountdown <= 0) {
        t.cancel();
        _nextPhase(phase);
      }
    });
  }

  int _phaseDuration(_Phase phase) => switch (phase) {
        _Phase.inhale => _technique.inhale,
        _Phase.hold1 => _technique.hold1,
        _Phase.exhale => _technique.exhale,
        _Phase.hold2 => _technique.hold2,
        _Phase.idle => 0,
      };

  void _nextPhase(_Phase current) {
    if (!_isRunning) return;
    switch (current) {
      case _Phase.inhale:
        _runPhase(_Phase.hold1);
      case _Phase.hold1:
        _runPhase(_Phase.exhale);
      case _Phase.exhale:
        _runPhase(_Phase.hold2);
      case _Phase.hold2:
        _runPhase(_Phase.inhale); // loop
      case _Phase.idle:
        break;
    }
  }

  String get _phaseLabel => switch (_phase) {
        _Phase.inhale => 'Inhala',
        _Phase.hold1 => 'Pausa',
        _Phase.exhale => 'Exhala',
        _Phase.hold2 => 'Pausa',
        _Phase.idle => 'Preparado',
      };

  String get _formattedTotal {
    final m = _totalSeconds ~/ 60;
    final s = _totalSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Future<void> _finishSession() async {
    _stopSession();
    setState(() => _isCompleted = true);

    final notifier = ref.read(mentalNotifierProvider);
    await notifier.startBreathingSession(
      BreathingSessionInput(
        techniqueName: _technique.key,
        durationSeconds: _totalSeconds,
        isCompleted: true,
      ),
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Guardado! Sesion completada: $_formattedTotal'),
        backgroundColor: AppColors.mental,
      ),
    );
    await _loadWeeklyCount();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mentalColor = AppColors.mental;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Respiracion'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: mentalColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Weekly streak banner
            Card(
              key: const ValueKey('weekly-streak-card'),
              color: mentalColor.withAlpha(20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                child: Row(
                  children: [
                    Icon(Icons.local_fire_department, color: mentalColor),
                    const SizedBox(width: 8),
                    Text(
                      'Has hecho $_weeklySessionCount sesiones esta semana',
                      style: TextStyle(color: mentalColor, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Technique picker
            Semantics(
              label: 'Selecciona tecnica de respiracion',
              child: Card(
                key: const ValueKey('technique-picker-card'),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: List.generate(_techniques.length, (i) {
                      final t = _techniques[i];
                      final isSelected = i == _selectedIndex;
                      return Semantics(
                        button: true,
                        selected: isSelected,
                        label: t.name,
                        child: RadioListTile<int>(
                          key: ValueKey('technique-${t.key}'),
                          value: i,
                          groupValue: _selectedIndex,
                          onChanged: _isRunning ? null : (v) => _selectTechnique(v!),
                          title: Text(
                            t.name,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: isSelected ? mentalColor : null,
                            ),
                          ),
                          subtitle: Text(t.description, style: const TextStyle(fontSize: 12)),
                          activeColor: mentalColor,
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Animated breathing circle
            Center(
              child: Semantics(
                label: _isRunning ? '$_phaseLabel: $_phaseCountdown segundos' : 'Circulo de respiracion',
                child: AnimatedBuilder(
                  animation: _circleScale,
                  builder: (context, child) {
                    final scale = _isRunning ? _circleScale.value : 0.7;
                    return GestureDetector(
                      key: const ValueKey('breathing-circle'),
                      onTap: _isRunning ? null : _startSession,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: mentalColor.withAlpha(20),
                          border: Border.all(color: mentalColor, width: 2),
                          boxShadow: _isRunning
                              ? [
                                  BoxShadow(
                                    color: mentalColor.withAlpha(80),
                                    blurRadius: 30 * scale,
                                    spreadRadius: 10 * scale,
                                  )
                                ]
                              : null,
                        ),
                        child: Transform.scale(
                          scale: scale,
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: mentalColor.withAlpha(60),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (_isRunning) ...[
                                    Text(
                                      _phaseLabel,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                    Text(
                                      '$_phaseCountdown',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 36,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ] else
                                    Column(
                                      children: [
                                        Icon(
                                          Icons.air,
                                          color: mentalColor,
                                          size: 40,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Toca para\nempezar',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(color: mentalColor),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Timer display
            if (_isRunning || _totalSeconds > 0) ...[
              Semantics(
                label: 'Tiempo transcurrido: $_formattedTotal',
                child: Center(
                  child: Text(
                    _formattedTotal,
                    key: const ValueKey('session-timer'),
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: mentalColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Controls
            if (_isRunning) ...[
              Row(
                children: [
                  Expanded(
                    child: Semantics(
                      button: true,
                      label: 'Detener sesion',
                      child: OutlinedButton.icon(
                        key: const ValueKey('stop-breathing-button'),
                        onPressed: _stopSession,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: AppColors.error),
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.stop_outlined),
                        label: const Text('Detener'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Semantics(
                      button: true,
                      label: 'Finalizar sesion de respiracion',
                      child: FilledButton.icon(
                        key: const ValueKey('finish-breathing-button'),
                        onPressed: _finishSession,
                        style: FilledButton.styleFrom(
                          backgroundColor: mentalColor,
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.check),
                        label: const Text('Finalizar'),
                      ),
                    ),
                  ),
                ],
              ),
            ] else if (!_isRunning && _totalSeconds == 0) ...[
              Semantics(
                button: true,
                label: 'Iniciar sesion de ${_technique.name}',
                child: FilledButton.icon(
                  key: const ValueKey('start-breathing-button'),
                  onPressed: _startSession,
                  style: FilledButton.styleFrom(
                    backgroundColor: mentalColor,
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.play_arrow),
                  label: Text('Iniciar ${_technique.name}'),
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Phase guide
            Card(
              key: const ValueKey('phase-guide-card'),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Guia de fases',
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    _PhaseRow(
                      phase: 'Inhala',
                      seconds: _technique.inhale,
                      color: AppColors.success,
                      icon: Icons.arrow_upward,
                    ),
                    if (_technique.hold1 > 0)
                      _PhaseRow(
                        phase: 'Pausa',
                        seconds: _technique.hold1,
                        color: AppColors.warning,
                        icon: Icons.pause,
                      ),
                    _PhaseRow(
                      phase: 'Exhala',
                      seconds: _technique.exhale,
                      color: AppColors.mental,
                      icon: Icons.arrow_downward,
                    ),
                    if (_technique.hold2 > 0)
                      _PhaseRow(
                        phase: 'Pausa',
                        seconds: _technique.hold2,
                        color: AppColors.warning,
                        icon: Icons.pause,
                      ),
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Ciclo total: ${_technique.totalCycle} segundos',
                        style: theme.textTheme.labelSmall,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhaseRow extends StatelessWidget {
  const _PhaseRow({
    required this.phase,
    required this.seconds,
    required this.color,
    required this.icon,
  });

  final String phase;
  final int seconds;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$phase: $seconds segundos',
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 8),
            Text(phase, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
            const Spacer(),
            Text('${seconds}s', style: TextStyle(color: color)),
          ],
        ),
      ),
    );
  }
}
