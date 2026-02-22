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

class _FeltReportsMapState extends State<FeltReportsMap> with SingleTickerProviderStateMixin {
  final FeltReportService _feltReportService = FeltReportService();
  List<FeltReport> _feltReports = [];
  bool _isLoading = true;

  late AnimationController _rippleController;
  final List<Animation<double>> _rippleRadii = [];
  final List<Animation<Color?>> _rippleColors = [];

  final int _rippleCount = 3; // Number of concentric ripples
  final double _maxBaseRadius = 100000; // Base max radius in meters for a 1.0 magnitude quake

  @override
  void initState() {
    super.initState();
    _loadFeltReports();

    final double magnitude = widget.earthquake.magnitude;
    final Duration animationDuration = Duration(milliseconds: (2000 + magnitude * 500).toInt()); // Scales with magnitude

    _rippleController = AnimationController(
      vsync: this,
      duration: animationDuration,
    )..addListener(() {
        setState(() {}); // Rebuilds the widget to update ripple size/color
      })..addStatusListener((status) {
          if (status == AnimationStatus.completed) {
            _rippleController.repeat(); // Loop the animation
          }
      });

    for (int i = 0; i < _rippleCount; i++) {
      final double beginRadius = (i / _rippleCount) * (_maxBaseRadius * magnitude);
      final double endRadius = _maxBaseRadius * magnitude;

      _rippleRadii.add(
        Tween<double>(begin: beginRadius, end: endRadius).animate(
          CurvedAnimation(
            parent: _rippleController,
            curve: Interval(
              i / _rippleCount, // Stagger start times
              1.0,
              curve: Curves.easeOutCubic,
            ),
          ),
        ),
      );

      _rippleColors.add(
        ColorTween(begin: Colors.red.withAlpha(100), end: Colors.red.withAlpha(0)).animate(
          CurvedAnimation(
            parent: _rippleController,
            curve: Interval(
              i / _rippleCount, // Stagger start times
              1.0,
              curve: Curves.easeOutQuad,
            ),
          ),
        ),
      );
    }
        _rippleController.forward(); // Start the animation
      }
    
      @override
      void dispose() {
        _rippleController.dispose();
        super.dispose();
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
                        // Static circle for the epicenter
                        CircleMarker(
                          point: LatLng(widget.earthquake.latitude, widget.earthquake.longitude),
                          radius: 5000, // Small static circle for epicenter
                          useRadiusInMeter: true,
                          color: Colors.red.withAlpha(200),
                          borderColor: Colors.red,
                          borderStrokeWidth: 2,
                        ),
                        // Theoretical maximum shaking distance
                        CircleMarker(
                          point: LatLng(widget.earthquake.latitude, widget.earthquake.longitude),
                          radius: widget.earthquake.magnitude * _maxBaseRadius, // Scales with magnitude
                          useRadiusInMeter: true,
                          color: Colors.blue.withAlpha(30), // Light blue, semi-transparent
                          borderColor: Colors.blue,
                          borderStrokeWidth: 1,
                        ),
                        // Animated ripples
                        ...List.generate(_rippleCount, (index) {
                          return CircleMarker(
                            point: LatLng(widget.earthquake.latitude, widget.earthquake.longitude),
                            radius: _rippleRadii[index].value,
                            useRadiusInMeter: true,
                            color: _rippleColors[index].value ?? Colors.transparent,
                            borderColor: Colors.red,
                            borderStrokeWidth: 1,
                          );
                        }),
                      ],
                    ),
                    MarkerLayer(
                      markers: [
                        // Earthquake epicenter magnitude marker
                        Marker(
                          width: 60.0, // Larger width for magnitude text
                          height: 60.0, // Larger height for magnitude text
                          point: LatLng(widget.earthquake.latitude, widget.earthquake.longitude),
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.red.withAlpha(150), // Semi-transparent red background
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: Text(
                              widget.earthquake.magnitude.toStringAsFixed(1),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16, // Fixed font size for clarity
                              ),
                            ),
                          ),
                        ),
                        // Felt report markers
                        ..._feltReports.map((report) {
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
                        }),
                      ],
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
          Positioned(
            bottom: 20,
            left: 16,
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
              child: Text(
                'Theoretical Shaking Radius: ${(widget.earthquake.magnitude * _maxBaseRadius / 1000).toStringAsFixed(0)} km',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
