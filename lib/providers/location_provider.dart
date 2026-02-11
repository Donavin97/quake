
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../services/location_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocationProvider with ChangeNotifier {
  final LocationService _locationService = LocationService();
  Position? _currentPosition;
  bool _isLoading = false;
  String? _error;
  bool _permissionGranted = false;

  Position? get currentPosition => _currentPosition;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isPermissionGranted => _permissionGranted;

  Future<void> determinePosition() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentPosition = await _locationService.getCurrentPosition();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> requestPermission() async {
    final LocationPermission permission = await Geolocator.requestPermission();
    await _updatePermissionStatus(permission);
  }

  Future<void> checkPermission() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('location_permission_granted') ?? false) {
      _permissionGranted = true;
      notifyListeners();
      return;
    }
    final LocationPermission permission = await Geolocator.checkPermission();
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
}
