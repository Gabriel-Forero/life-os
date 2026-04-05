import 'package:flutter/services.dart';

class HapticService {
  bool _reduceMotion = false;

  void updateReduceMotion(bool value) {
    _reduceMotion = value;
  }

  Future<void> light() async {
    if (_reduceMotion) return;
    await HapticFeedback.lightImpact();
  }

  Future<void> medium() async {
    if (_reduceMotion) return;
    await HapticFeedback.mediumImpact();
  }

  Future<void> heavy() async {
    if (_reduceMotion) return;
    await HapticFeedback.heavyImpact();
  }

  Future<void> selection() async {
    if (_reduceMotion) return;
    await HapticFeedback.selectionClick();
  }
}
