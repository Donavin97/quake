
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:myapp/services/location_service.dart';

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
    LocationPermission permission = await Geolocator.requestPermission();
    _updatePermissionStatus(permission);
  }

  Future<void> checkPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    _updatePermissionStatus(permission);
  }

  void _updatePermissionStatus(LocationPermission permission) {
    final granted = permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
    if (_permissionGranted != granted) {
      _permissionGranted = granted;
      notifyListeners();
    }
  }
}
