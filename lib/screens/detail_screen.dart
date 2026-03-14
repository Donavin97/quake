import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../generated/app_localizations.dart';

import '../models/earthquake.dart';
import '../models/felt_report.dart';
import '../providers/service_providers.dart';
import '../services/felt_report_service.dart';
import '../services/haptic_service.dart';
import '../config/app_config.dart';
import 'felt_reports_map.dart';
import 'seismograph_screen.dart';
import '../widgets/skeleton_item.dart';

class DetailScreen extends ConsumerStatefulWidget {
  final Earthquake? earthquake;
  final String? earthquakeId;

  const DetailScreen({super.key, this.earthquake, this.earthquakeId});

  @override
  ConsumerState<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends ConsumerState<DetailScreen> with WidgetsBindingObserver {
  Earthquake? _earthquake;
  double? distance;
  double? _theoreticalFeltRadius;
  bool _isReporting = false;
  final FeltReportService _feltReportService = FeltReportService();
  bool _isLoading = false;
  
  InterstitialAd? _interstitialAd;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadInterstitialAd();
    if (widget.earthquake != null) {
      _earthquake = widget.earthquake;
      _calculateDistance();
      _calculateTheoreticalFeltRadius();
      HapticService.vibrateForEarthquake(_earthquake!);
    } else if (widget.earthquakeId != null) {
      _loadEarthquakeFromRepo();
    }
  }

  void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: AppConfig.detailInterstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          setState(() {
            _interstitialAd = ad;
          });
        },
        onAdFailedToLoad: (err) {
          debugPrint('Failed to load interstitial ad: ${err.message}');
        },
      ),
    );
  }

  void _showInterstitialAdAndNavigate() {
    if (_earthquake == null) return;
    
    if (_interstitialAd != null) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SeismographScreen(earthquake: _earthquake!),
            ),
          );
          _loadInterstitialAd();
        },
        onAdFailedToShowFullScreenContent: (ad, err) {
          debugPrint('Failed to show interstitial ad: ${err.message}');
          ad.dispose();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SeismographScreen(earthquake: _earthquake!),
            ),
          );
          _loadInterstitialAd();
        },
      );
      _interstitialAd!.show();
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SeismographScreen(earthquake: _earthquake!),
        ),
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _interstitialAd?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadInterstitialAd();
    }
  }

  void _calculateTheoreticalFeltRadius() {
    if (_earthquake == null) return;
    setState(() {
      _theoreticalFeltRadius = _earthquake!.theoreticalFeltRadius;
    });
  }

  Future<void> _loadEarthquakeFromRepo() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final repository = ref.read(earthquakeRepositoryProvider);
      
      // Try to find in current list
      try {
        final earthquake = repository.allEarthquakes.firstWhere((e) => e.id == widget.earthquakeId);
        setState(() {
          _earthquake = earthquake;
        });
        await _calculateDistance();
        _calculateTheoreticalFeltRadius();
        HapticService.vibrateForEarthquake(earthquake);
      } catch (_) {
        // Not found in local list. 
        // We could try to fetch it from API if we had a method for that in repository.
        // For now, we accept it's not found.
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
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 10),
        ),
      );
      if (!mounted) return;
      final earthquake = _earthquake;
      if (earthquake == null) return;

      final calculatedDistance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        earthquake.latitude,
        earthquake.longitude,
      );
      if (mounted) {
        setState(() {
          distance = calculatedDistance / 1000;
        });
      }
    } catch (e) {
      debugPrint('Could not get location: $e');
    }
  }

  Future<void> _reportFelt() async {
    final earthquake = _earthquake;
    if (_isReporting || earthquake == null) return;

    final authService = ref.read(authServiceProvider);
    final user = authService.currentUser;

    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You must be logged in to report.')),
        );
      }
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
                    label: currentLevel.toString(),
                    onChanged: (double value) {
                      setState(() {
                        currentLevel = value.round();
                      });
                    },
                    semanticFormatterCallback: (double value) {
                      return 'Intensity level ${value.round()}: ${FeltReport.getIntensityDescription(value.round())}';
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

    if (selectedIntensity == null || !mounted) return;

    setState(() {
      _isReporting = true;
    });

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 10),
        ),
      );
      if (!mounted) return;

      final report = FeltReport(
        earthquakeId: earthquake.id,
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

  void _navigateToSeismograph() {
    _showInterstitialAdAndNavigate();
  }

  void _shareEarthquake() {
    if (_earthquake == null) return;

    final String timeStr = DateFormat.yMMMd().add_jms().format(_earthquake!.time.toLocal());
    final String mapUrl = 'https://www.google.com/maps/search/?api=1&query=${_earthquake!.latitude},${_earthquake!.longitude}';
    
    final String shareText = 'Earthquake Alert!\n\n'
        'Magnitude: ${_earthquake!.magnitude.toStringAsFixed(_earthquake!.source == EarthquakeSource.sec ? 2 : 1)}\n'
        'Location: ${_earthquake!.place}\n'
        'Time: $timeStr\n'
        'Source: ${_earthquake!.source.name.toUpperCase()}\n\n'
        'Epicenter: $mapUrl\n\n'
        'Shared via QuakeTrack';

    SharePlus.instance.share(
      ShareParams(
        text: shareText,
        subject: 'Earthquake in ${_earthquake!.place}',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Loading Details...')),
        body: const EarthquakeDetailSkeleton(),
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
        title: Text(l10n.appTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareEarthquake,
            tooltip: l10n.share,
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
            Text('${l10n.magnitude}: ${_earthquake!.magnitude.toStringAsFixed(_earthquake!.source == EarthquakeSource.sec ? 2 : 1)}'),
            const SizedBox(height: 8),
            Text('${l10n.time}: ${DateFormat.yMMMd().add_jms().format(_earthquake!.time.toLocal())}'),
            const SizedBox(height: 8),
            Text(
              'Coordinates: (${_earthquake!.latitude.toStringAsFixed(2)}, ${_earthquake!.longitude.toStringAsFixed(2)})',
            ),
            const SizedBox(height: 8),
            Text('${l10n.depth}: ${_earthquake!.depth.toStringAsFixed(2)} km'),
            const SizedBox(height: 8),
            Text('${l10n.source}: ${_earthquake!.source.name.toUpperCase()}'),
            if (distance != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text('${l10n.distance}: ${distance!.toStringAsFixed(2)} km'),
              ),
            if (_theoreticalFeltRadius != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text('${l10n.theoreticalFeltRadius}: ${_theoreticalFeltRadius!.toStringAsFixed(0)} km'),
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
                    child: Text(l10n.didYouFeelIt),
                  ),
                  ElevatedButton(
                    onPressed: _navigateToFeltReportsMap,
                    child: Text(l10n.viewFeltReports),
                  ),
                  ElevatedButton.icon(
                    onPressed: _navigateToSeismograph,
                    icon: const Icon(Icons.show_chart),
                    label: Text(l10n.seismograph),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
