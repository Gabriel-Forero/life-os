import 'package:flutter/material.dart';
import 'package:life_os/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_os/core/domain/validators.dart';
import 'package:life_os/features/onboarding/providers/onboarding_notifier.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    final state = ref.read(onboardingNotifierProvider);
    _nameController = TextEditingController(text: state.userName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingNotifierProvider);
    final notifier = ref.read(onboardingNotifierProvider.notifier);
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          Text(l10n.profileTitle, style: theme.textTheme.headlineMedium),
          const SizedBox(height: 32),
          TextField(
            key: const ValueKey('profile-name-input'),
            controller: _nameController,
            decoration: InputDecoration(
              labelText: l10n.profileNameLabel,
              hintText: l10n.profileNameHint,
              border: const OutlineInputBorder(),
              errorText: state.error,
            ),
            maxLength: 50,
            onChanged: notifier.setName,
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 24),
          Text(l10n.profileCurrencyLabel,
              style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          _CurrencyDropdown(
            key: const ValueKey('profile-currency-dropdown'),
            selectedCurrency: state.currency,
            onChanged: notifier.setCurrency,
          ),
          const Spacer(),
          Row(
            children: [
              TextButton(
                key: const ValueKey('profile-skip-button'),
                onPressed: () => notifier.skip(),
                child: Text(l10n.onboardingSkipSetup),
              ),
              const Spacer(),
              FilledButton(
                key: const ValueKey('profile-continue-button'),
                onPressed: () {
                  final result = notifier.validateName();
                  if (result.isSuccess) {
                    notifier.nextStep();
                  }
                },
                child: Text(l10n.onboardingContinue),
              ),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _CurrencyDropdown extends StatelessWidget {
  const _CurrencyDropdown({
    super.key,
    required this.selectedCurrency,
    required this.onChanged,
  });

  final String selectedCurrency;
  final void Function(String) onChanged;

  @override
  Widget build(BuildContext context) {
    final currencies = supportedCurrencies.toList()..sort();

    return DropdownButtonFormField<String>(
      initialValue: selectedCurrency,
      decoration: const InputDecoration(border: OutlineInputBorder()),
      items: currencies
          .map(
            (c) => DropdownMenuItem(value: c, child: Text(c)),
          )
          .toList(),
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
    );
  }
}
