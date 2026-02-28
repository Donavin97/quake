import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/earthquake.dart';
import '../services/waveform_service.dart';

class SeismographScreen extends StatefulWidget {
  final Earthquake earthquake;

  const SeismographScreen({super.key, required this.earthquake});

  @override
  State<SeismographScreen> createState() => _SeismographScreenState();
}

class _SeismographScreenState extends State<SeismographScreen> {
  final WaveformService _waveformService = WaveformService();
  List<WaveformSample>? _waveformData;
  StationInfo? _stationInfo;
  bool _isMockData = false;
  bool _isLoading = true;
  String? _error;

  // Zoom and pan state
  double _minX = 0;
  double _maxX = 60;
  double _minY = -10;
  double _maxY = 10;

  // For pinch zoom
  double _baseScale = 1.0;
  double _currentScale = 1.0;
  Offset _baseFocalPoint = Offset.zero;

  @override
  void initState() {
    super.initState();
    _loadWaveformData();
  }

  Future<void> _loadWaveformData() async {
    try {
      final result = await _waveformService.getWaveformData(widget.earthquake);
      if (mounted) {
        setState(() {
          _waveformData = result.samples;
          _stationInfo = result.station;
          _isMockData = result.isMockData;
          _error = result.errorMessage;
          _isLoading = false;
          // Auto-scale Y axis based on data
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
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _resetZoom() {
    setState(() {
      _minX = 0;
      _maxX = 60;
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading waveform data...'),
        ],
      ),
    );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadWaveformData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildInfoCard(),
        Expanded(
          child: _buildChart(),
        ),
        _buildLegend(),
      ],
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
              'M${widget.earthquake.magnitude.toStringAsFixed(1)} • ${DateFormat.yMMMd().add_jms().format(widget.earthquake.time)}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            if (_stationInfo != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.cell_tower, size: 14, color: Colors.green[700]),
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
                    SizedBox(width: 18),
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
                    SizedBox(width: 18),
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
                        'Channel: ${_stationInfo!.channel}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.green[700],
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
            if (_isMockData) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.info_outline, size: 14, color: Colors.orange[700]),
                  const SizedBox(width: 4),
                  Text(
                    'Simulated waveform data',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.orange[700],
                        ),
                  ),
                ],
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
            _minX = (center - range / 2).clamp(0, 60 - range);
            _maxX = (_minX + range).clamp(range, 60);
          }
          
          // Handle pan
          final dx = details.focalPoint.dx - _baseFocalPoint.dx;
          final range = _maxX - _minX;
          final panAmount = -dx * range / 300; // Adjust sensitivity
          _minX = (_minX + panAmount).clamp(0, 60 - range);
          _maxX = (_minX + range).clamp(range, 60);
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
              rightTitles: AxisTitles(
                sideTitles: SideTitles(),
              ),
              topTitles: AxisTitles(
                sideTitles: SideTitles(),
              ),
            ),
            gridData: FlGridData(
              horizontalInterval: (_maxY - _minY) / 5,
              verticalInterval: (_maxX - _minX) / 6,
              getDrawingHorizontalLine: (value) {
                if (value == 0) {
                  return const FlLine(
                    color: Colors.black54,
                    strokeWidth: 2,
                  );
                }
                return FlLine(
                  color: Colors.grey.withValues(alpha: 0.3),
                );
              },
              getDrawingVerticalLine: (value) {
                return FlLine(
                  color: Colors.grey.withValues(alpha: 0.3),
                );
              },
            ),
            borderData: FlBorderData(
              border: Border.all(color: Colors.grey),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                color: Colors.blue,
                dotData: const FlDotData(),
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

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.grey[100],
      child: const Row(
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
