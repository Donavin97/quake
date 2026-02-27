import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:screenshot/screenshot.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:intl/intl.dart';

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
  double _theoreticalFeltRadius = 0.0; // In meters

  final ScreenshotController screenshotController = ScreenshotController();

  @override
  void initState() {
    super.initState();
    _loadFeltReports();

    _theoreticalFeltRadius = widget.earthquake.theoreticalFeltRadius * 1000.0; // Convert km to meters
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
      final double beginRadius = (i / _rippleCount) * _theoreticalFeltRadius;
      final double endRadius = _theoreticalFeltRadius;

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

  Future<void> _captureAndSharePng() async {
    try {
      final image = await screenshotController.capture(
        delay: const Duration(milliseconds: 10), // Give it a slight delay
        pixelRatio: MediaQuery.of(context).devicePixelRatio,
      );

      if (image != null) {
        final directory = await getTemporaryDirectory();
        final imagePath = await File('${directory.path}/felt_map.png').create();
        await imagePath.writeAsBytes(image);

        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(imagePath.path)],
            text: 'Check out this earthquake map!',
          ),
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to capture map image.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sharing map: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Format date and time
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');
    final String formattedDate = dateFormat.format(widget.earthquake.time);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Did You Feel It? Map'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _captureAndSharePng,
            tooltip: 'Share',
          ),
        ],
      ),
      body: Screenshot(
        controller: screenshotController,
        child: Stack(
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
                            radius: _theoreticalFeltRadius, // Use the new calculated felt radius
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
            // Earthquake details overlay
            Positioned(
              top: 10,
              left: 10,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha((255 * 0.7).round()),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Magnitude: ${widget.earthquake.magnitude.toStringAsFixed(1)}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      'Location: ${widget.earthquake.place}',
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    Text(
                      'Time: $formattedDate',
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    Text(
                      'Depth: ${widget.earthquake.depth.toStringAsFixed(1)} km',
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ],
                ),
              ),
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
      ),
    );
  }
}
