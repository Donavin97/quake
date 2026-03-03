import 'dart:io';
import 'dart:typed_data';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';
import 'package:intl/intl.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

import '../models/earthquake.dart';
import '../services/waveform_service.dart';

class SeismographScreen extends StatefulWidget {
  final Earthquake earthquake;

  const SeismographScreen({super.key, required this.earthquake});

  @override
  State<SeismographScreen> createState() => _SeismographScreenState();
}

class _SeismographScreenState extends State<SeismographScreen> with SingleTickerProviderStateMixin {
  // Helper method to trigger haptic feedback safely using Vibration class
  Future<void> _triggerHaptic(String type) async {
    try {
      // Check if device has vibration capability
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator != true) return;

      switch (type) {
        case 'light':
          await Vibration.vibrate(duration: 10);
        case 'medium':
          await Vibration.vibrate(duration: 25);
        case 'heavy':
          await Vibration.vibrate(duration: 50);
      }
    } catch (_) {
      // Ignore haptic feedback errors (e.g., on desktop/simulator)
    }
  }

  final WaveformService _waveformService = WaveformService();
  Uint8List? _imageData; // PNG image from Python backend
  Uint8List? _audioData; // Audio data from Python backend
  List<WaveformSample>? _waveformData; // Fallback samples from IRIS
  StationInfo? _stationInfo;
  bool _isMockData = false;
  bool _isLoading = true;
  String? _error;
  bool _isUsingImage = true; // Track if we're showing image (Python) or chart (IRIS fallback)

  // Animation controller for fade-in effect
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  // Audio player state
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isAudioLoading = false;
  bool _isAudioReady = false;
  String? _tempAudioPath;
  
  // Current loading status for user feedback
  String _loadingStatus = 'Initializing...';
  List<String> _loadingSteps = [];

  // Unused variables kept for API compatibility but not displayed
  // ignore: unused_field,prefer_final_fields
  final String _currentStation = '';
  // ignore: unused_field,prefer_final_fields
  final List<String> _stationAttempts = [];

  // Zoom and pan state (only used for chart fallback)
  double _minX = 0;
  double _maxX = 360;
  double _minY = -10;
  double _maxY = 10;

  // For pinch zoom (only used for chart fallback)
  double _baseScale = 1.0;
  double _currentScale = 1.0;
  Offset _baseFocalPoint = Offset.zero;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _initAudioPlayer();
    _loadWaveformData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _deleteTempAudioFile();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _deleteTempAudioFile() async {
    if (_tempAudioPath != null) {
      try {
        final file = File(_tempAudioPath!);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {
        // Ignore cleanup errors
      }
      _tempAudioPath = null;
    }
  }

  Future<void> _initAudioPlayer() async {
    // Listen to player state changes
    _audioPlayer.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isAudioLoading = state.processingState == ProcessingState.loading ||
              state.processingState == ProcessingState.buffering;
        });
      }
    });
  }

  Future<void> _loadAudio() async {
    if (_audioData == null || _audioData!.isEmpty) return;
    
    setState(() {
      _isAudioLoading = true;
    });
    
    try {
      // Delete previous temp file if exists
      await _deleteTempAudioFile();
      
      // Write audio data to a temporary file
      final tempDir = await getTemporaryDirectory();
      final audioFile = File('${tempDir.path}/waveform_audio_${DateTime.now().millisecondsSinceEpoch}.wav');
      await audioFile.writeAsBytes(_audioData!);
      _tempAudioPath = audioFile.path;
      
      // Load into audio player
      await _audioPlayer.setFilePath(audioFile.path);
      
      if (mounted) {
        setState(() {
          _isAudioReady = true;
          _isAudioLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isAudioReady = false;
          _isAudioLoading = false;
        });
      }
    }
  }

  Future<void> _loadWaveformData() async {
    // Reset state
    // Stop any playing audio and cleanup
    _audioPlayer.stop();
    _deleteTempAudioFile();
    
    // Reset animation for fresh load
    _animationController.reset();
    
    setState(() {
      _isLoading = true;
      _error = null;
      _imageData = null;
      _audioData = null;
      _waveformData = null;
      _stationInfo = null;
      _isMockData = false;
      _isUsingImage = true;
      _isAudioReady = false;
      _isAudioLoading = false;
      _loadingStatus = 'Searching for nearby seismic stations...';
      _loadingSteps = [];
    });

    // Progress callback - kept for waveform service but not displayed
    void handleProgressUpdate(String message) {
      // Progress is tracked internally but not shown in UI
    }

    try {
      // Update status to show we're searching for stations
      setState(() {
        _loadingStatus = 'Finding nearby seismic stations...';
      });

      final result = await _waveformService.getWaveformData(
        widget.earthquake,
        onProgressUpdate: handleProgressUpdate,
      );
      
      if (!mounted) return;

      // Determine status message based on result
      String statusMessage;
      List<String> steps;
      
      // Check if we got an image from Python or samples from IRIS fallback
      final hasImage = result.hasImage;
      final hasSamples = result.samples.isNotEmpty;
      
      if (result.isMockData) {
        if (result.station == null) {
          statusMessage = 'No nearby stations found';
          steps = [
            'Searched IRIS station database',
            'No stations within range of earthquake location',
            'Displaying simulated waveform data',
          ];
        } else if (result.errorMessage != null && result.errorMessage!.contains('No waveform data')) {
          statusMessage = 'Station found but no waveform data available';
          steps = [
            'Found station: ${result.station?.displayName ?? "Unknown"}',
            'Station is ${result.station?.distanceKm.toStringAsFixed(1) ?? "?"} km away',
            'No seismic data recorded for this event time',
            'Displaying simulated waveform data',
          ];
        } else if (result.errorMessage != null) {
          statusMessage = 'Unable to fetch live data';
          steps = [
            'Found station: ${result.station?.displayName ?? "Unknown"}',
            'Network error: ${result.errorMessage}',
            'Displaying simulated waveform data',
          ];
        } else {
          statusMessage = 'Using simulated waveform data';
          steps = [
            'Station query completed',
            'Waveform data not available',
          ];
        }
      } else if (hasImage) {
        statusMessage = 'Live waveform plot loaded';
        steps = [
          'Found station: ${result.station?.displayName ?? "Unknown"}',
          'Station is ${result.station?.distanceKm.toStringAsFixed(1) ?? "?"} km away',
          'Channel: ${result.station?.channel ?? "N/A"}',
          'Generated waveform plot with Matplotlib',
        ];
      } else if (hasSamples) {
        statusMessage = 'Live waveform data loaded (IRIS)';
        steps = [
          'Found station: ${result.station?.displayName ?? "Unknown"}',
          'Station is ${result.station?.distanceKm.toStringAsFixed(1) ?? "?"} km away',
          'Channel: ${result.station?.channel ?? "N/A"}',
          'Successfully retrieved ${result.samples.length} samples',
        ];
      } else {
        statusMessage = 'Using simulated waveform data';
        steps = ['No waveform data available, using simulation'];
      }

  // Vibrate once on successful data retrieval
      await _triggerHaptic('medium');
      
      setState(() {
        _imageData = result.imageData;
        _audioData = result.audioData;
        _waveformData = result.samples;
        _stationInfo = result.station;
        _isMockData = result.isMockData;
        _error = result.errorMessage;
        _loadingStatus = statusMessage;
        _loadingSteps = steps;
        _isLoading = false;
        _isUsingImage = hasImage;
        _animationController.forward();
        
        // Load audio if available
        if (result.hasAudio) {
          _loadAudio();
        }
        
        // Auto-scale Y axis based on data (for chart fallback)
        if (result.samples.isNotEmpty) {
          double maxAmp = 0;
          for (final sample in result.samples) {
            if (sample.amplitude.abs() > maxAmp) {
              maxAmp = sample.amplitude.abs();
            }
          }
          _minY = -maxAmp * 1.2;
          _maxY = maxAmp * 1.2;
        }
      });
    } catch (e) {
      if (!mounted) return;
      // Vibrate twice on failure
      await _triggerHaptic('heavy');
      await Future.delayed(const Duration(milliseconds: 150));
      await _triggerHaptic('heavy');
      
      setState(() {
        _error = e.toString();
        _loadingStatus = 'Error loading waveform data';
        _loadingSteps = [
          'An unexpected error occurred',
          _error ?? 'Unknown error',
        ];
        _isLoading = false;
      });
    }
  }

  void _resetZoom() {
    setState(() {
      _minX = 0;
      _maxX = 360;
      if (_waveformData != null && _waveformData!.isNotEmpty) {
        double maxAmp = 0;
        for (final sample in _waveformData!) {
          if (sample.amplitude.abs() > maxAmp) {
            maxAmp = sample.amplitude.abs();
          }
        }
        _minY = -maxAmp * 1.2;
        _maxY = maxAmp * 1.2;
      }
    });
  }

  FlLine _getHorizontalLine(double value) {
    if (value == 0) {
      return const FlLine(
        color: Colors.black54,
      );
    }
    return FlLine(
      color: Colors.grey.withAlpha(77),
    );
  }

  FlLine _getVerticalLine(double value) {
    return FlLine(
      color: Colors.grey.withAlpha(77),
    );
  }

  String _getTimeRangeText() {
    // Calculate the time range used for waveform data
    final eqTime = widget.earthquake.time;
    final startTime = eqTime.subtract(const Duration(seconds: 60));
    final endTime = eqTime.add(const Duration(seconds: 300));
    
    final startStr = DateFormat.Hms().format(startTime.toLocal());
    final endStr = DateFormat.Hms().format(endTime.toLocal());
    
    return '$startStr - $endStr (${endTime.difference(startTime).inMinutes} min)';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seismograph'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadWaveformData,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.zoom_out_map),
            onPressed: _resetZoom,
            tooltip: 'Reset Zoom',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 24),
              Text(
                _loadingStatus,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'This may take a few seconds...',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red[400]),
              const SizedBox(height: 16),
              Text(
                _loadingStatus,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'What happened:',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: Colors.red[700],
                          ),
                    ),
                    const SizedBox(height: 8),
                    ..._loadingSteps.asMap().entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              entry.key < _loadingSteps.length - 1 
                                  ? Icons.check_circle 
                                  : Icons.info_outline,
                              size: 16,
                              color: entry.key < _loadingSteps.length - 1 
                                  ? Colors.green[600] 
                                  : Colors.orange[600],
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                entry.value,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      const Divider(),
                      const SizedBox(height: 8),
                      Text(
                        'Details: $_error',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.red[700],
                              fontStyle: FontStyle.italic,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: _loadWaveformData,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                  const SizedBox(width: 16),
                  OutlinedButton.icon(
                    onPressed: () async {
                      setState(() {
                        _isMockData = true;
                        _loadingStatus = 'Generating simulated waveform...';
                        _loadingSteps = ['Creating waveform simulation based on earthquake parameters'];
                      });
                      
                      // Generate mock data directly
                      final result = await WaveformService().getWaveformData(
                        widget.earthquake,
                        onProgressUpdate: (msg) {
                          if (mounted) {
                            setState(() {
                              _loadingSteps = [..._loadingSteps, msg];
                            });
                          }
                        },
                      );
                      if (mounted) {
                        // Vibrate twice on mock/simulated data
                        await _triggerHaptic('heavy');
                        await Future.delayed(const Duration(milliseconds: 150));
                        await _triggerHaptic('heavy');
                        
                        setState(() {
                          _imageData = result.imageData;
                          _audioData = result.audioData;
                          _waveformData = result.samples;
                          _stationInfo = result.station;
                          _error = null;
                          _isUsingImage = result.hasImage;
                          
                          // Load audio if available
                          if (result.hasAudio) {
                            _loadAudio();
                          }
                          if (result.hasImage) {
                            _loadingStatus = 'Simulated waveform plot ready';
                            _loadingSteps = ['Simulation complete', 'Displaying waveform plot'];
                          } else {
                            _loadingStatus = 'Simulated waveform ready';
                            _loadingSteps = ['Simulation complete', 'Displaying ${result.samples.length} samples'];
                          }
                          if (result.samples.isNotEmpty) {
                            double maxAmp = 0;
                            for (final sample in result.samples) {
                              if (sample.amplitude.abs() > maxAmp) {
                                maxAmp = sample.amplitude.abs();
                              }
                            }
                            _minY = -maxAmp * 1.2;
                            _maxY = maxAmp * 1.2;
                          }
                        });
                      }
                    },
                    icon: const Icon(Icons.science),
                    label: const Text('Use Simulation'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            _buildInfoCard(),
            SizedBox(
              height: 400,
              child: _isUsingImage && _imageData != null 
                  ? _buildImageView() 
                  : _buildChart(),
            ),
            if (_audioData != null && _audioData!.isNotEmpty) _buildAudioPlayer(),
            _buildLegend(),
          ],
        ),
      ),
    );
  }

  /// Build the image view for PNG from Python/Matplotlib
  Widget _buildImageView() {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: Image.memory(
            _imageData!,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.broken_image, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 8),
                    Text(
                      'Failed to load waveform image',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    if (_waveformData != null && _waveformData!.isNotEmpty)
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _isUsingImage = false;
                          });
                        },
                        child: const Text('Show chart view instead'),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.earthquake.place,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'M${widget.earthquake.magnitude.toStringAsFixed(1)} • ${DateFormat.yMMMd().add_jms().format(widget.earthquake.time.toLocal())}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            if (_stationInfo != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.cell_tower, size: 14, color: Colors.green),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${_stationInfo!.displayName} • ${_stationInfo!.distanceKm.toStringAsFixed(1)} km away',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.green[700],
                          ),
                    ),
                  ),
                ],
              ),
              if (_stationInfo!.locationString.isNotEmpty) ...[
                const SizedBox(height: 2),
                Row(
                  children: [
                    const SizedBox(width: 18),
                    Expanded(
                      child: Text(
                        _stationInfo!.locationString,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                              fontSize: 11,
                            ),
                      ),
                    ),
                  ],
                ),
              ],
              if (_stationInfo!.channel != null) ...[
                const SizedBox(height: 2),
                Row(
                  children: [
                    const SizedBox(width: 18),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green[700]?.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: Colors.green[700]?.withValues(alpha: 0.3) ?? Colors.green,
                        ),
                      ),
                      child: Text(
                        'Channel: ${_stationInfo!.fullChannelId}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.green[700],
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ),
                    if (_stationInfo!.sampleRate != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue[700]?.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: Colors.blue[700]?.withValues(alpha: 0.3) ?? Colors.blue,
                          ),
                        ),
                        child: Text(
                          '${_stationInfo!.sampleRate} SPS',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.blue[700],
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
              // Show time range
              const SizedBox(height: 2),
              Row(
                children: [
                  const SizedBox(width: 18),
                  Icon(Icons.schedule, size: 12, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    _getTimeRangeText(),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                          fontSize: 11,
                        ),
                  ),
                ],
              ),
            ],
            if (_isMockData) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.info_outline, size: 14, color: Colors.orange),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        _error ?? 'Simulated waveform data',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.orange[700],
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                _buildWaveTypeChip('P-wave', Colors.blue),
                const SizedBox(width: 8),
                _buildWaveTypeChip('S-wave', Colors.orange),
                const SizedBox(width: 8),
                _buildWaveTypeChip('Surface', Colors.purple),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWaveTypeChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildChart() {
    final spots = _waveformData!
        .map((sample) => FlSpot(sample.time, sample.amplitude))
        .toList();

    return GestureDetector(
      onScaleStart: (details) {
        _baseScale = _currentScale;
        _baseFocalPoint = details.focalPoint;
      },
      onScaleUpdate: (details) {
        setState(() {
          // Handle pinch zoom
          if (details.scale != 1.0) {
            _currentScale = (_baseScale * details.scale).clamp(0.5, 10.0);
            final range = (_maxX - _minX) / _currentScale;
            final center = (_minX + _maxX) / 2;
            _minX = (center - range / 2).clamp(0, 360 - range);
            _maxX = (_minX + range).clamp(range, 360);
          }
          
          // Handle pan
          final dx = details.focalPoint.dx - _baseFocalPoint.dx;
          final range = _maxX - _minX;
          final panAmount = -dx * range / 300; // Adjust sensitivity
          _minX = (_minX + panAmount).clamp(0, 360 - range);
          _maxX = (_minX + range).clamp(range, 360);
          _baseFocalPoint = details.focalPoint;
        });
      },
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LineChart(
          LineChartData(
            minX: _minX,
            maxX: _maxX,
            minY: _minY,
            maxY: _maxY,
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  reservedSize: 50,
                  getTitlesWidget: (value, meta) {
                    return SideTitleWidget(
                      axisSide: meta.axisSide,
                      child: Text(
                        value.toStringAsFixed(1),
                        style: const TextStyle(fontSize: 10),
                      ),
                    );
                  },
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  reservedSize: 30,
                  interval: 10,
                  getTitlesWidget: (value, meta) {
                    return SideTitleWidget(
                      axisSide: meta.axisSide,
                      child: Text(
                        '${value.toInt()}s',
                        style: const TextStyle(fontSize: 10),
                      ),
                    );
                  },
                ),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(
                  reservedSize: 1,
                ),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(
                  reservedSize: 1,
                ),
              ),
            ),
            gridData: FlGridData(
              horizontalInterval: (_maxY - _minY) / 5,
              verticalInterval: (_maxX - _minX) / 6,
              getDrawingHorizontalLine: _getHorizontalLine,
              getDrawingVerticalLine: _getVerticalLine,
            ),
            borderData: FlBorderData(
              border: Border.all(color: Colors.grey),
            ),
            // Add a vertical line to mark earthquake event time (at 60 seconds)
            extraLinesData: ExtraLinesData(
              verticalLines: [
                VerticalLine(
                  x: 60,
                  color: Colors.red.withValues(alpha: 0.7),
                  dashArray: [5, 5],
                  label: VerticalLineLabel(
                    alignment: Alignment.topRight,
                    style: TextStyle(
                      color: Colors.red[700],
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    labelResolver: (line) => 'Quake',
                  ),
                ),
              ],
            ),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                belowBarData: BarAreaData(
                  color: Colors.blue.withValues(alpha: 0.1),
                ),
              ),
            ],
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (touchedSpot) => Colors.blueGrey.shade800,
                getTooltipItems: (touchedSpots) {
                  return touchedSpots.map((spot) {
                    return LineTooltipItem(
                      't: ${spot.x.toStringAsFixed(2)}s\namp: ${spot.y.toStringAsFixed(3)}',
                      const TextStyle(color: Colors.white, fontSize: 12),
                    );
                  }).toList();
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAudioPlayer() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.deepPurple[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.deepPurple[200]!),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.music_note, color: Colors.deepPurple[700], size: 20),
              const SizedBox(width: 8),
              Text(
                'Seismic Audio Sonification',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple[700],
                ),
              ),
              const Spacer(),
              if (_isMockData)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange[100],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Simulated',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.orange[700],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          // Audio player controls
          StreamBuilder<PlayerState>(
            stream: _audioPlayer.playerStateStream,
            builder: (context, snapshot) {
              final playerState = snapshot.data;
              final playing = playerState?.playing;
              
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Play/Pause button
                  IconButton(
                    iconSize: 40,
                    tooltip: playing == true ? 'Pause' : 'Play',
                    onPressed: _isAudioReady
                        ? () {
                            if (playing == true) {
                              _audioPlayer.pause();
                            } else {
                              _audioPlayer.play();
                            }
                          }
                        : null,
                    icon: Icon(
                      _isAudioLoading
                          ? Icons.hourglass_empty
                          : (playing == true ? Icons.pause_circle_filled : Icons.play_circle_filled),
                      color: _isAudioReady ? Colors.deepPurple[700] : Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Progress bar
                  Expanded(
                    child: _isAudioLoading
                        ? const LinearProgressIndicator()
                        : StreamBuilder<Duration>(
                            stream: _audioPlayer.positionStream,
                            builder: (context, snapshot) {
                              final position = snapshot.data ?? Duration.zero;
                              return StreamBuilder<Duration?>(
                                stream: _audioPlayer.durationStream,
                                builder: (context, durationSnapshot) {
                                  final duration = durationSnapshot.data ?? Duration.zero;
                                  final positionSeconds = position.inSeconds.toDouble();
                                  final durationSeconds = duration.inSeconds.toDouble();
                                  
                                  return Tooltip(
                                    message: 'Seek to position',
                                    child: Column(
                                      children: [
                                        SliderTheme(
                                          data: SliderTheme.of(context).copyWith(
                                            trackHeight: 4,
                                            thumbShape: const RoundSliderThumbShape(
                                              enabledThumbRadius: 6,
                                            ),
                                          ),
                                          child: Slider(
                                            value: durationSeconds > 0 
                                                ? positionSeconds.clamp(0, durationSeconds) 
                                                : 0,
                                            max: durationSeconds > 0 ? durationSeconds : 1,
                                            onChanged: (value) {
                                              _audioPlayer.seek(Duration(seconds: value.toInt()));
                                            },
                                            activeColor: Colors.deepPurple[700],
                                            inactiveColor: Colors.deepPurple[200],
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 16),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                _formatDuration(position),
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                              Text(
                                                _formatDuration(duration),
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                  ),
                  // Stop button
                  IconButton(
                    tooltip: 'Stop and reset',
                    onPressed: _isAudioReady
                        ? () {
                            _audioPlayer.stop();
                            _audioPlayer.seek(Duration.zero);
                          }
                        : null,
                    icon: Icon(
                      Icons.stop_circle,
                      color: _isAudioReady ? Colors.deepPurple[700] : Colors.grey,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 8),
          Text(
            'Listen to the seismic waves converted to audio',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.grey[100],        child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.touch_app, size: 16),
          SizedBox(width: 8),
          Text(
            'Pinch to zoom • Drag to pan',
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}
