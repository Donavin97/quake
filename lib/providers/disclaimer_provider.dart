import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DisclaimerNotifier extends Notifier<bool> {
  @override
  bool build() {
    _loadDisclaimerState();
    return false;
  }

  Future<void> _loadDisclaimerState() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool('disclaimer_accepted') ?? false;
  }

  Future<void> acceptDisclaimer() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('disclaimer_accepted', true);
    state = true;
  }
}

final disclaimerProvider = NotifierProvider<DisclaimerNotifier, bool>(() {
  return DisclaimerNotifier();
});
