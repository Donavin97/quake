import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DisclaimerProvider with ChangeNotifier {
  bool _disclaimerAccepted = false;

  bool get disclaimerAccepted => _disclaimerAccepted;

  DisclaimerProvider() {
    _loadDisclaimerState();
  }

  Future<void> _loadDisclaimerState() async {
    final prefs = await SharedPreferences.getInstance();
    _disclaimerAccepted = prefs.getBool('disclaimer_accepted') ?? false;
    notifyListeners();
  }

  Future<void> acceptDisclaimer() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('disclaimer_accepted', true);
    _disclaimerAccepted = true;
    notifyListeners();
  }
}
