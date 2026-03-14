import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../generated/app_localizations.dart';

import '../models/earthquake.dart';
import '../providers/earthquake_provider.dart';
import '../providers/location_provider.dart';
import '../providers/settings_provider.dart';
import '../services/haptic_service.dart';
import '../config/app_config.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> with WidgetsBindingObserver {
  final MapController _mapController = MapController();
  List<Marker> _markers = [];

  bool _platesLoading = true;
  bool _faultsLoading = true;
  String? _platesError;
  String? _faultsError;

  String? _selectedMagnitudeCategory;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _validateWmsService();
    Future.microtask(() => _refreshMarkers());
  }

  Future<void> _validateWmsService() async {
    setState(() {
      _platesLoading = true;
      _faultsLoading = true;
      _platesError = null;
      _faultsError = null;
    });
    
    const platesUrl = AppConfig.usgsPlatesWmsUrl;

    HttpClient? client;
    try {
      client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 10);
      
      final uri = Uri.parse('$platesUrl?SERVICE=WMS&REQUEST=GetCapabilities&VERSION=1.3.0');
      final request = await client.getUrl(uri);
      final response = await request.close();
      
      if (!mounted) return;
      
      if (response.statusCode == 200) {
        setState(() {
          _platesLoading = false;
          _faultsLoading = false;
        });
      } else {
        setState(() {
          _platesLoading = false;
          _faultsLoading = false;
          _platesError = 'Failed (${response.statusCode})';
          _faultsError = 'Failed (${response.statusCode})';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _platesLoading = false;
        _faultsLoading = false;
        _platesError = 'Connection failed';
        _faultsError = 'Connection failed';
      });
    } finally {
      client?.close();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _mapController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshMarkers();
    }
  }

  void _updateMapCenter() {
    final position = ref.read(locationProvider.select((s) => s.position));
    if (position != null && _mapController.camera.center.latitude == 0) {
      _mapController.move(
        LatLng(position.latitude, position.longitude),
        _mapController.camera.zoom,
      );
    }
  }

  void _zoomInToUserLocation() {
    final position = ref.read(locationProvider.select((s) => s.position));
    if (position != null) {
      _mapController.move(
        LatLng(position.latitude, position.longitude),
        7.0,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User location not available.')),
      );
    }
  }

  void _centerOnUserLocation() {
    final position = ref.read(locationProvider.select((s) => s.position));
    if (position != null) {
      _mapController.move(
        LatLng(position.latitude, position.longitude),
        _mapController.camera.zoom,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Centered on your location'),
          duration: Duration(seconds: 1),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User location not available.')),
      );
    }
  }

  void _zoomOutToGlobalView() {
    _mapController.move(
      const LatLng(0.0, 0.0),
      2.0,
    );
  }

  void _refreshMarkers() {
    final earthquakes = ref.read(earthquakeNotifierProvider.select((s) => s.allEarthquakes));
    final smallMarkerScale = ref.read(settingsProvider.select((s) => s.smallMarkerScale));
    
    if (!mounted) return;

    final filteredEarthquakes = earthquakes.where((eq) {
      if (_selectedMagnitudeCategory == null) return true;
      
      final magnitude = eq.magnitude;
      if (_selectedMagnitudeCategory == '7.0+') return magnitude >= 7.0;
      if (_selectedMagnitudeCategory == '5.0 - 6.9') return magnitude >= 5.0 && magnitude < 7.0;
      if (_selectedMagnitudeCategory == '3.0 - 4.9') return magnitude >= 3.0 && magnitude < 5.0;
      if (_selectedMagnitudeCategory == '< 3.0') return magnitude < 3.0;
      
      return true;
    }).toList();

    setState(() {
      _markers = filteredEarthquakes.map((earthquake) {
        final magnitude = earthquake.magnitude;
        double size = _getMarkerSize(magnitude);
        if (magnitude < 3.0) {
          size *= smallMarkerScale;
        }

        return Marker(
          width: size * 1.5,
          height: size * 1.5,
          point: LatLng(earthquake.latitude, earthquake.longitude),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              HapticService.vibrateForEarthquake(earthquake);
              context.go('/details/${earthquake.id}', extra: earthquake);
            },
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      color: _getMarkerColorForMagnitude(magnitude),
                      shape: BoxShape.circle,
                    ),
                  ),
                  if (size > 15)
                    Text(
                      magnitude.toStringAsFixed(1),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: size / 3,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      }).toList();
    });
  }

  double _getMarkerSize(double magnitude) {
    if (magnitude < 3.0) return 12;
    if (magnitude < 5.0) return 20;
    if (magnitude < 7.0) return 28;
    return 36;
  }

  Color _getMarkerColorForMagnitude(double magnitude) {
    if (magnitude < 3.0) return Colors.green.withAlpha(180);
    if (magnitude < 5.0) return Colors.yellow.withAlpha(180);
    if (magnitude < 7.0) return Colors.orange.withAlpha(180);
    return Colors.red.withAlpha(180);
  }

  Widget _buildMap(LatLng userLocation, bool showPlates, bool showFaults, bool showFeltRadius, List<Earthquake> earthquakes, double mapButtonScale) {
    return SafeArea(
      child: Stack(
        children: [
          RepaintBoundary(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: userLocation,
                initialZoom: 4,
                minZoom: 2.0,
                maxZoom: 18.0,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                  rotationThreshold: 200,
                  rotationWinGestures: MultiFingerGesture.none,
                  enableMultiFingerGestureRace: true,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: AppConfig.osmHotTileUrl,
                  userAgentPackageName: 'com.liebgott.quaketrack',
                ),
                if (showPlates)
                  TileLayer(
                    wmsOptions: WMSTileLayerOptions(
                      baseUrl: AppConfig.usgsPlatesWmsUrl,
                      layers: const ['1'],
                    ),
                    userAgentPackageName: 'com.liebgott.quaketrack',
                  ),
                if (showFaults)
                  TileLayer(
                    wmsOptions: WMSTileLayerOptions(
                      baseUrl: AppConfig.usgsPlatesWmsUrl,
                      layers: const ['0'],
                    ),
                    userAgentPackageName: 'com.liebgott.quaketrack',
                  ),
                if (showFeltRadius)
                  CircleLayer(
                    circles: earthquakes
                        .where((eq) => eq.magnitude >= 3.0) 
                        .map((eq) {
                      final color = _getMarkerColorForMagnitude(eq.magnitude);
                      return CircleMarker(
                        point: LatLng(eq.latitude, eq.longitude),
                        radius: eq.theoreticalFeltRadius * 1000, 
                        useRadiusInMeter: true,
                        color: color.withAlpha(40),
                        borderColor: color.withAlpha(100),
                        borderStrokeWidth: 1,
                      );
                    }).toList(),
                  ),
                MarkerClusterLayerWidget(
                  options: MarkerClusterLayerOptions(
                    maxClusterRadius: 45,
                    size: const Size(40, 40),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.all(50),
                    maxZoom: 15,
                    markers: _markers,
                    builder: (context, markers) {
                      return Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: Theme.of(context).primaryColor.withAlpha(230),
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            markers.length.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: userLocation,
                      width: 32,
                      height: 32,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                RichAttributionWidget(
                  attributions: [
                    TextSourceAttribution(
                      'OpenStreetMap contributors',
                      onTap: () => launchUrl(Uri.parse('https://openstreetmap.org/copyright')),
                    ),
                    TextSourceAttribution(
                      'USGS Tectonic Plate Boundaries',
                      onTap: () => launchUrl(Uri.parse('https://earthquake.usgs.gov/arcgis/rest/services/eq/map_plateboundaries/MapServer')),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            top: 10,
            right: 10,
            child: Transform.scale(
              scale: mapButtonScale,
              alignment: Alignment.topRight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  FloatingActionButton.extended(
                    heroTag: 'zoomInButton',
                    onPressed: _zoomInToUserLocation,
                    backgroundColor: Theme.of(context).primaryColor,
                    icon: const Icon(Icons.zoom_in),
                    label: const Text('Zoom In'),
                  ),
                  const SizedBox(height: 8),
                  FloatingActionButton.extended(
                    heroTag: 'zoomOutButton',
                    onPressed: _zoomOutToGlobalView,
                    backgroundColor: Theme.of(context).primaryColor,
                    icon: const Icon(Icons.zoom_out),
                    label: const Text('Zoom Out'),
                  ),
                  const SizedBox(height: 8),
                  FloatingActionButton.extended(
                    heroTag: 'centerLocationButton',
                    onPressed: _centerOnUserLocation,
                    backgroundColor: Theme.of(context).primaryColor,
                    icon: const Icon(Icons.my_location),
                    label: const Text('My Location'),
                  ),
                  const SizedBox(height: 8),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => ref.read(settingsProvider.notifier).setShowPlates(!showPlates),
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: _platesLoading 
                              ? Colors.blue.withAlpha(200)
                              : _platesError != null 
                                  ? Colors.red.withAlpha(200) 
                                  : Colors.green.withAlpha(200),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_platesLoading)
                              const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            else if (_platesError != null)
                              const Icon(Icons.error, color: Colors.white, size: 16)
                            else
                              const Icon(Icons.check, color: Colors.white, size: 16),
                            const SizedBox(width: 6),
                            Icon(Icons.public, color: showPlates ? Colors.white : Colors.red, size: 18),
                            const SizedBox(width: 4),
                            Text(
                              'Plates',
                              style: TextStyle(
                                color: showPlates ? Colors.white : Colors.red,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => ref.read(settingsProvider.notifier).setShowFaults(!showFaults),
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: _faultsLoading 
                              ? Colors.blue.withAlpha(200)
                              : _faultsError != null 
                                  ? Colors.red.withAlpha(200) 
                                  : Colors.green.withAlpha(200),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_faultsLoading)
                              const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            else if (_faultsError != null)
                              const Icon(Icons.error, color: Colors.white, size: 16)
                            else
                              const Icon(Icons.check, color: Colors.white, size: 16),
                            const SizedBox(width: 6),
                            Icon(Icons.reorder, color: showFaults ? Colors.white : Colors.orange, size: 18),
                            const SizedBox(width: 4),
                            Text(
                              'Microplates',
                              style: TextStyle(
                                color: showFaults ? Colors.white : Colors.orange,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_platesError != null || _faultsError != null)
            Positioned(
              top: 10,
              left: 10,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 200),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_platesError != null)
                      Row(
                        children: [
                          const Icon(Icons.warning, color: Colors.red, size: 14),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Plates: $_platesError',
                              style: const TextStyle(color: Colors.red, fontSize: 10),
                            ),
                          ),
                        ],
                      ),
                    if (_faultsError != null)
                      Row(
                        children: [
                          const Icon(Icons.warning, color: Colors.red, size: 14),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Faults: $_faultsError',
                              style: const TextStyle(color: Colors.red, fontSize: 10),
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton.icon(
                        onPressed: _validateWmsService,
                        icon: const Icon(Icons.refresh, size: 14),
                        label: const Text('Retry'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red.shade700,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          minimumSize: const Size(0, 28),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          _buildLegend(showFeltRadius, showPlates, showFaults, mapButtonScale),
        ],
      ),
    );
  }

  Widget _buildLegend(bool showFeltRadius, bool showPlates, bool showFaults, double mapButtonScale) {
    final l10n = AppLocalizations.of(context)!;
    return Positioned(
      bottom: 20,
      right: 10,
      child: Transform.scale(
        scale: mapButtonScale,
        alignment: Alignment.bottomRight,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor.withAlpha(220),
            borderRadius: BorderRadius.circular(10),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.magnitude,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                  ),
                  if (_selectedMagnitudeCategory != null)
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedMagnitudeCategory = null;
                          _refreshMarkers();
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Icon(Icons.close, size: 14, color: Theme.of(context).hintColor),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              _buildInteractiveLegendItem(Colors.red, '7.0+'),
              _buildInteractiveLegendItem(Colors.orange, '5.0 - 6.9'),
              _buildInteractiveLegendItem(Colors.yellow, '3.0 - 4.9'),
              _buildInteractiveLegendItem(Colors.green, '< 3.0'),
              const Divider(height: 16),
              _buildOverlayToggle(
                l10n.showFeltRadius,
                showFeltRadius,
                (val) => ref.read(settingsProvider.notifier).setShowFeltRadius(val),
              ),
              const SizedBox(height: 4),
              _buildOverlayToggle(
                l10n.plateBoundaries,
                showPlates,
                (val) => ref.read(settingsProvider.notifier).setShowPlates(val),
              ),
              const SizedBox(height: 4),
              _buildOverlayToggle(
                l10n.faultLines,
                showFaults,
                (val) => ref.read(settingsProvider.notifier).setShowFaults(val),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverlayToggle(String label, bool value, Function(bool) onChanged) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onChanged(!value),
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 4.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                value ? Icons.check_box : Icons.check_box_outline_blank,
                size: 14,
                color: value ? Theme.of(context).primaryColor : Theme.of(context).hintColor,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInteractiveLegendItem(Color color, String label) {
    final bool isSelected = _selectedMagnitudeCategory == label;
    final bool isAnySelected = _selectedMagnitudeCategory != null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            if (_selectedMagnitudeCategory == label) {
              _selectedMagnitudeCategory = null;
            } else {
              _selectedMagnitudeCategory = label;
            }
            _refreshMarkers();
          });
        },
        borderRadius: BorderRadius.circular(4),
        child: Opacity(
          opacity: !isAnySelected || isSelected ? 1.0 : 0.4,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 4.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: isSelected ? Border.all(width: 1.5) : null,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingScreen(String message, {String? subtitle}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(message),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final position = ref.watch(locationProvider.select((s) => s.position));
    final isSettingsLoaded = ref.watch(settingsProvider.select((s) => s.isLoaded));
    
    final showPlates = ref.watch(settingsProvider.select((s) => s.showPlates));
    final showFaults = ref.watch(settingsProvider.select((s) => s.showFaults));
    final showFeltRadius = ref.watch(settingsProvider.select((s) => s.showFeltRadius));
    final mapButtonScale = ref.watch(settingsProvider.select((s) => s.mapButtonScale));
    
    final earthquakes = ref.watch(earthquakeNotifierProvider.select((s) => s.allEarthquakes));
    
    ref.listen(earthquakeNotifierProvider.select((s) => s.allEarthquakes), (previous, next) {
      if (previous != next) {
        _refreshMarkers();
      }
    });

    ref.listen(settingsProvider.select((s) => s.smallMarkerScale), (previous, next) {
      if (previous != next) {
        _refreshMarkers();
      }
    });

    ref.listen(locationProvider.select((s) => s.position), (previous, next) {
      if (previous != next) {
        _updateMapCenter();
      }
    });

    if (!isSettingsLoaded) {
      return _buildLoadingScreen('Loading settings...');
    }
    
    final LatLng center = position != null 
        ? LatLng(position.latitude, position.longitude)
        : const LatLng(0.0, 0.0);
    
    return _buildMap(center, showPlates, showFaults, showFeltRadius, earthquakes, mapButtonScale);
  }
}
