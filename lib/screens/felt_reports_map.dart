import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

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
          : FlutterMap(
              options: MapOptions(
                initialCenter: LatLng(widget.earthquake.latitude, widget.earthquake.longitude),
                initialZoom: 5,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                ),
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: LatLng(widget.earthquake.latitude, widget.earthquake.longitude),
                      radius: widget.earthquake.magnitude * 20000,
                      useRadiusInMeter: true,
                      color: Colors.red.withAlpha(77),
                      borderColor: Colors.red,
                      borderStrokeWidth: 2,
                    )
                  ],
                ),
                MarkerLayer(
                  markers: _feltReports.map((report) {
                    return Marker(
                      width: 80.0,
                      height: 80.0,
                      point: LatLng(report.location.latitude, report.location.longitude),
                      child: const Icon(
                        Icons.comment,
                        color: Colors.blue,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
    );
  }
}
