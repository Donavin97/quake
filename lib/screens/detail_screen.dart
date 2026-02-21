import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/earthquake.dart';
import '../models/felt_report.dart';
import '../services/auth_service.dart';
import '../services/felt_report_service.dart';
import 'felt_reports_map.dart';

class DetailScreen extends StatefulWidget {
  final Earthquake? earthquake;
  final String? earthquakeId;

  const DetailScreen({super.key, this.earthquake, this.earthquakeId});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  Earthquake? _earthquake;
  double? distance;
  bool _isReporting = false;
  final FeltReportService _feltReportService = FeltReportService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.earthquake != null) {
      _earthquake = widget.earthquake;
      _calculateDistance();
    } else if (widget.earthquakeId != null) {
      _loadEarthquakeFromHive();
    }
  }

  Future<void> _loadEarthquakeFromHive() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final box = await Hive.openBox<Earthquake>('earthquakes');
      final earthquake = box.get(widget.earthquakeId);
      if (earthquake != null) {
        setState(() {
          _earthquake = earthquake;
        });
        await _calculateDistance();
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _calculateDistance() async {
    if (_earthquake == null) return;
    try {
      final position = await Geolocator.getCurrentPosition();
      if (!mounted) return;
      final calculatedDistance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        _earthquake!.latitude,
        _earthquake!.longitude,
      );
      setState(() {
        distance = calculatedDistance / 1000; // Convert to km
      });
    } catch (e) {
      debugPrint('Could not get location: $e');
    }
  }

  Future<void> _reportFelt() async {
    if (_isReporting || _earthquake == null) return;

    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to report.')),
      );
      return;
    }

    final int? selectedIntensity = await showDialog<int>(
      context: context,
      builder: (context) {
        int currentLevel = 3;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('How strongly did you feel it?'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Level $currentLevel: ${FeltReport.getIntensityDescription(currentLevel)}',
                    style: TextStyle(
                      color: FeltReport.getIntensityColor(currentLevel),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Slider(
                    value: currentLevel.toDouble(),
                    min: 1,
                    max: 10,
                    divisions: 9,
                    onChanged: (value) {
                      setState(() {
                        currentLevel = value.toInt();
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, currentLevel),
                  child: const Text('Submit'),
                ),
              ],
            );
          },
        );
      },
    );

    if (selectedIntensity == null) return;

    setState(() {
      _isReporting = true;
    });

    try {
      final position = await Geolocator.getCurrentPosition();
      if (!mounted) return;

      final report = FeltReport(
        earthquakeId: _earthquake!.id,
        userId: user.uid,
        timestamp: Timestamp.now(),
        location: GeoPoint(position.latitude, position.longitude),
        intensity: selectedIntensity,
      );

      await _feltReportService.addFeltReport(report);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thank you for your report!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Could not submit report. Please try again.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isReporting = false;
        });
      }
    }
  }

  void _navigateToFeltReportsMap() {
    if (_earthquake == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FeltReportsMap(earthquake: _earthquake!),
      ),
    );
  }

  void _shareEarthquake() {
    if (_earthquake == null) return;

    final String timeStr = DateFormat.yMMMd().add_jms().format(_earthquake!.time);
    final String mapUrl = 'https://www.google.com/maps/search/?api=1&query=${_earthquake!.latitude},${_earthquake!.longitude}';
    
    final String shareText = 'Earthquake Alert!\n\n'
        'Magnitude: ${_earthquake!.magnitude.toStringAsFixed(_earthquake!.source == EarthquakeSource.sec ? 2 : 1)}\n'
        'Location: ${_earthquake!.place}\n'
        'Time: $timeStr\n'
        'Source: ${_earthquake!.source.name.toUpperCase()}\n\n'
        'Epicenter: $mapUrl\n\n'
        'Shared via QuakeTrack';

    Share.share(
      shareText,
      subject: 'Earthquake in ${_earthquake!.place}',
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_earthquake == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(
          child: Text('Earthquake details not found.'),
        ),
      );
    }

    final String displayPlace = _earthquake!.place.contains(' km ') 
        ? 'Near ${_earthquake!.place}' 
        : _earthquake!.place;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Earthquake Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareEarthquake,
            tooltip: 'Share',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              displayPlace,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text('Magnitude: ${_earthquake!.magnitude.toStringAsFixed(_earthquake!.source == EarthquakeSource.sec ? 2 : 1)}'),
            const SizedBox(height: 8),
            Text('Time: ${DateFormat.yMMMd().add_jms().format(_earthquake!.time)}'),
            const SizedBox(height: 8),
            Text(
              'Coordinates: (${_earthquake!.latitude.toStringAsFixed(2)}, ${_earthquake!.longitude.toStringAsFixed(2)})',
            ),
            const SizedBox(height: 8),
            Text('Depth: ${_earthquake!.depth.toStringAsFixed(2)} km'),
            const SizedBox(height: 8),
            Text('Source: ${_earthquake!.source.name.toUpperCase()}'),
            if (distance != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text('Distance: ${distance!.toStringAsFixed(2)} km from your current location'),
              ),
            const SizedBox(height: 20),
            if (_isReporting)
              const Center(child: CircularProgressIndicator())
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: _reportFelt,
                    child: const Text('Did you feel it?'),
                  ),
                  ElevatedButton(
                    onPressed: _navigateToFeltReportsMap,
                    child: const Text('View Felt Reports'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
