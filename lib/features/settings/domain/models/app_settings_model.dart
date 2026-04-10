class AppSettingsModel {
  const AppSettingsModel({
    required this.id,
    required this.userName,
    required this.language,
    required this.currency,
    required this.primaryGoal,
    required this.enabledModules,
    required this.themeMode,
    required this.useBiometric,
    required this.onboardingCompleted,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userName;
  final String language;
  final String currency;
  final String primaryGoal;
  final String enabledModules;
  final String themeMode;
  final bool useBiometric;
  final bool onboardingCompleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toMap() => {
        'id': id,
        'userName': userName,
        'language': language,
        'currency': currency,
        'primaryGoal': primaryGoal,
        'enabledModules': enabledModules,
        'themeMode': themeMode,
        'useBiometric': useBiometric,
        'onboardingCompleted': onboardingCompleted,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory AppSettingsModel.fromMap(Map<String, dynamic> map) =>
      AppSettingsModel(
        id: map['id'] as String,
        userName: map['userName'] as String,
        language: map['language'] as String? ?? 'es',
        currency: map['currency'] as String? ?? 'COP',
        primaryGoal: map['primaryGoal'] as String,
        enabledModules: map['enabledModules'] as String? ?? '["finance"]',
        themeMode: map['themeMode'] as String? ?? 'dark',
        useBiometric: map['useBiometric'] as bool? ?? false,
        onboardingCompleted: map['onboardingCompleted'] as bool? ?? false,
        createdAt: DateTime.parse(map['createdAt'] as String),
        updatedAt: DateTime.parse(map['updatedAt'] as String),
      );
}
