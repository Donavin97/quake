import 'package:flutter/material.dart';
import '../models/earthquake.dart';
import '../services/usgs_service.dart';

class EarthquakeProvider with ChangeNotifier {
  final UsgsService _usgsService = UsgsService();
  List<Earthquake> _earthquakes = [];
  bool _isLoading = false;
  String? _error;

  List<Earthquake> get earthquakes => _earthquakes;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchEarthquakes() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _earthquakes = await _usgsService.getRecentEarthquakes();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
