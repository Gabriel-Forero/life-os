import 'package:flutter/widgets.dart';

class AccessibilityState {
  const AccessibilityState({
    this.reduceMotion = false,
    this.screenReaderActive = false,
    this.textScaleFactor = 1.0,
    this.highContrast = false,
  });

  final bool reduceMotion;
  final bool screenReaderActive;
  final double textScaleFactor;
  final bool highContrast;
}

class AccessibilityService {
  AccessibilityState readPlatformSettings(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return AccessibilityState(
      reduceMotion: mediaQuery.disableAnimations,
      screenReaderActive: mediaQuery.accessibleNavigation,
      textScaleFactor: mediaQuery.textScaler.scale(1.0),
      highContrast: mediaQuery.highContrast,
    );
  }
}
