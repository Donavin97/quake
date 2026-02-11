import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/earthquake.dart';
import '../models/felt_report.dart';
import '../services/felt_report_service.dart';

class FeltReportsMap extends StatefulWidget {
  final Earthquake earthquake;

  const FeltReportsMap({super.key, required this.earthquake});

  @override
  State<FeltReportsMap> createState() => _FeltReportsMapState();
}

class _FeltReportsMapState extends State<FeltReportsMap> {
  final Completer<GoogleMapController> _controller = Completer();
  final FeltReportService _feltReportService = FeltReportService();
  List<FeltReport> _feltReports = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFeltReports();
  }

  Future<void> _loadFeltReports() async {
    try {
      final reports = await _feltReportService.getFeltReports(widget.earthquake.id);
      if (mounted) {
        setState(() {
          _feltReports = reports;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not load reports.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Felt Reports'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : GoogleMap(
              mapType: MapType.normal,
              initialCameraPosition: CameraPosition(
                target: LatLng(widget.earthquake.latitude, widget.earthquake.longitude),
                zoom: 5,
              ),
              onMapCreated: (GoogleMapController controller) {
                _controller.complete(controller);
              },
              markers: _feltReports.map((report) {
                return Marker(
                  markerId: MarkerId(report.userId),
                  position: LatLng(report.location.latitude, report.location.longitude),
                  infoWindow: InfoWindow(
                    title: 'Felt Report',
                    snippet: 'Reported by a user',
                  ),
                );
              }).toSet(),
              circles: {
                Circle(
                  circleId: CircleId(widget.earthquake.id),
                  center: LatLng(widget.earthquake.latitude, widget.earthquake.longitude),
                  radius: widget.earthquake.magnitude * 20000, // Radius in meters
                  fillColor: Colors.red.withOpacity(0.3),
                  strokeColor: Colors.red,
                  strokeWidth: 2,
                )
              },
            ),
    );
  }
}
