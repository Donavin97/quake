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
        title: const Text('Did You Feel It? Map'),
      ),
      body: Stack(
        children: [
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : FlutterMap(
                  options: MapOptions(
                    initialCenter: LatLng(widget.earthquake.latitude, widget.earthquake.longitude),
                    initialZoom: 5,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://{s}.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.liebgott.quaketrack',
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
                          width: 40.0,
                          height: 40.0,
                          point: LatLng(report.location.latitude, report.location.longitude),
                          child: Icon(
                            Icons.location_on,
                            color: FeltReport.getIntensityColor(report.intensity),
                            size: 30,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
          Positioned(
            bottom: 20,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor.withAlpha(230),
                borderRadius: BorderRadius.circular(8),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'MMI Scale',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  ...List.generate(10, (index) {
                    final level = index + 1;
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          color: FeltReport.getIntensityColor(level),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$level: ${FeltReport.getIntensityDescription(level)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    );
                  }).reversed,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
