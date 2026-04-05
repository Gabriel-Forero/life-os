import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:life_os/core/router/app_router.dart';
import 'package:life_os/features/onboarding/presentation/first_data_screen.dart';
import 'package:life_os/features/onboarding/presentation/goal_screen.dart';
import 'package:life_os/features/onboarding/presentation/language_screen.dart';
import 'package:life_os/features/onboarding/presentation/modules_screen.dart';
import 'package:life_os/features/onboarding/presentation/profile_screen.dart';
import 'package:life_os/features/onboarding/presentation/welcome_screen.dart';
import 'package:life_os/features/onboarding/providers/onboarding_notifier.dart';

class OnboardingShell extends ConsumerWidget {
  const OnboardingShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingNotifierProvider);

    if (state.currentStep == OnboardingStep.complete) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          GoRouter.of(context).go(AppRoutes.home);
        }
      });
      return const SizedBox.shrink();
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            if (state.currentStep != OnboardingStep.welcome) ...[
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                child: Semantics(
                  label: 'Paso ${state.stepIndex} de ${state.totalSteps}',
                  child: LinearProgressIndicator(
                    key: const ValueKey('onboarding-progress'),
                    value: state.stepIndex / state.totalSteps,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _buildCurrentScreen(state.currentStep),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentScreen(OnboardingStep step) => switch (step) {
    OnboardingStep.welcome => const WelcomeScreen(),
    OnboardingStep.language => const LanguageScreen(),
    OnboardingStep.profile => const ProfileScreen(),
    OnboardingStep.modules => const ModulesScreen(),
    OnboardingStep.goal => const GoalScreen(),
    OnboardingStep.firstData => const FirstDataScreen(),
    OnboardingStep.complete => const SizedBox.shrink(),
  };
}
