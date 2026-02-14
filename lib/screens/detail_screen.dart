import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/earthquake.dart';
import '../models/felt_report.dart';
import '../services/auth_service.dart';
import '../services/felt_report_service.dart';
import 'felt_reports_map.dart';

class DetailScreen extends StatefulWidget {
  final Earthquake earthquake;

  const DetailScreen({super.key, required this.earthquake});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  double? distance;
  bool _isReporting = false;
  final FeltReportService _feltReportService = FeltReportService();

  @override
  void initState() {
    super.initState();
    _calculateDistance();
  }

  Future<void> _calculateDistance() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      if (!mounted) return;
      final calculatedDistance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        widget.earthquake.latitude,
        widget.earthquake.longitude,
      );
      setState(() {
        distance = calculatedDistance / 1000; // Convert to km
      });
    } catch (e) {
      debugPrint('Could not get location: $e');
    }
  }

  Future<void> _reportFelt() async {
    if (_isReporting) return;

    setState(() {
      _isReporting = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = authService.currentUser;

      if (user == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You must be logged in to report.')),
        );
        return;
      }

      final position = await Geolocator.getCurrentPosition();
      if (!mounted) return;

      final report = FeltReport(
        earthquakeId: widget.earthquake.id,
        userId: user.uid,
        timestamp: Timestamp.now(),
        location: GeoPoint(position.latitude, position.longitude),
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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FeltReportsMap(earthquake: widget.earthquake),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Earthquake Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.earthquake.place,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text('Magnitude: ${widget.earthquake.magnitude.toStringAsFixed(2)}'),
            const SizedBox(height: 8),
            Text('Time: ${DateFormat.yMMMd().add_jms().format(widget.earthquake.time)}'),
            const SizedBox(height: 8),
            Text(
              'Coordinates: (${widget.earthquake.latitude.toStringAsFixed(2)}, ${widget.earthquake.longitude.toStringAsFixed(2)})',
            ),
            const SizedBox(height: 8),
            Text('Depth: ${widget.earthquake.depth.toStringAsFixed(2)} km'),
            if (distance != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text('Distance: ${distance!.toStringAsFixed(2)} km from your location'),
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
