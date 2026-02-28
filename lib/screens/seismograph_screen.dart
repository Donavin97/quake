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
      final data = await _waveformService.getWaveformData(widget.earthquake);
      if (mounted) {
        setState(() {
          _waveformData = data;
          _isLoading = false;
          // Auto-scale Y axis based on data
          if (data.isNotEmpty) {
            double maxAmp = 0;
            for (final sample in data) {
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
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
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
        color: color.withOpacity(0.2),
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
            clipData: const FlClipData.all(),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
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
                  showTitles: true,
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
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: true,
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
                  color: Colors.grey.withOpacity(0.3),
                  strokeWidth: 1,
                );
              },
              getDrawingVerticalLine: (value) {
                return FlLine(
                  color: Colors.grey.withOpacity(0.3),
                  strokeWidth: 1,
                );
              },
            ),
            borderData: FlBorderData(
              show: true,
              border: Border.all(color: Colors.grey),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: false,
                color: Colors.blue,
                barWidth: 1,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  color: Colors.blue.withOpacity(0.1),
                ),
              ),
            ],
            lineTouchData: LineTouchData(
              enabled: true,
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
          duration: Duration.zero,
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.grey[100],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.touch_app, size: 16),
          const SizedBox(width: 8),
          const Text(
            'Pinch to zoom • Drag to pan',
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}
