
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:quaketrack/services/location_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocationProvider with ChangeNotifier {
  final LocationService _locationService = LocationService();
  Position? _currentPosition;
  bool _isLoading = false;
  String? _error;
  bool _permissionGranted = false;
  final StreamController<Position> _locationStreamController = StreamController<Position>.broadcast();

  Position? get currentPosition => _currentPosition;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isPermissionGranted => _permissionGranted;
  Stream<Position> get locationStream => _locationStreamController.stream;

  LocationProvider();

  Future<void> determinePosition() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentPosition = await _locationService.getCurrentPosition();
      if (_currentPosition != null) {
        _locationStreamController.add(_currentPosition!);
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> requestPermission() async {
    final LocationPermission permission = await _locationService.requestPermission();
    await _updatePermissionStatus(permission);
  }

  Future<void> checkPermission() async {
    final LocationPermission permission = await _locationService.checkPermission();
    await _updatePermissionStatus(permission);
  }

  Future<void> _updatePermissionStatus(LocationPermission permission) async {
    final granted = permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
    if (_permissionGranted != granted) {
      _permissionGranted = granted;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('location_permission_granted', granted);
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _locationStreamController.close();
    super.dispose();
  }
}
