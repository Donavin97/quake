import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../generated/app_localizations.dart';

import '../models/earthquake.dart';
import '../providers/earthquake_provider.dart';

class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final earthquakes = ref.watch(earthquakeNotifierProvider.select((s) => s.allEarthquakes));
    
    if (earthquakes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.analytics_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              l10n.noData,
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.loading,
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    final stats = _calculateStatistics(earthquakes);

    return RefreshIndicator(
      onRefresh: () async => ref.read(earthquakeNotifierProvider.notifier).refresh(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSummaryGrid(context, stats),
          const SizedBox(height: 20),
          _buildMagnitudeDistributionCard(context, stats),
          const SizedBox(height: 20),
          _buildRecentActivityTrend(context, earthquakes),
          const SizedBox(height: 20),
          _buildDepthAnalysisCard(context, stats),
          const SizedBox(height: 20),
          _buildTopRegionsCard(context, earthquakes),
          const SizedBox(height: 100), // Spacing for ad or bottom nav
        ],
      ),
    );
  }

  Widget _buildSummaryGrid(BuildContext context, _EarthquakeStats stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'Seismic Summary',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.5,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          children: [
            _buildSummaryItem(
              context,
              'Total Events',
              stats.totalCount.toString(),
              Icons.sensors,
              Colors.blue,
            ),
            _buildSummaryItem(
              context,
              'Avg Magnitude',
              stats.averageMagnitude.toStringAsFixed(1),
              Icons.waves,
              Colors.orange,
            ),
            _buildSummaryItem(
              context,
              'Max Magnitude',
              stats.maxMagnitude.toStringAsFixed(1),
              Icons.warning_amber,
              Colors.red,
            ),
            _buildSummaryItem(
              context,
              'Deepest Quake',
              '${stats.averageDepth.toStringAsFixed(0)} km',
              Icons.vertical_align_bottom,
              Colors.purple,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryItem(BuildContext context, String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Theme.of(context).hintColor),
          ),
        ],
      ),
    );
  }

  Widget _buildMagnitudeDistributionCard(BuildContext context, _EarthquakeStats stats) {
    final dist = stats.magnitudeDistribution;
    final data = [
      _BarData(Colors.green, dist.micro.toDouble(), '< 2.0'),
      _BarData(Colors.lightGreen, dist.minor.toDouble(), '2-4'),
      _BarData(Colors.yellow, dist.light.toDouble(), '4-5'),
      _BarData(Colors.orange, dist.moderate.toDouble(), '5-6'),
      _BarData(Colors.deepOrange, dist.strong.toDouble(), '6-7'),
      _BarData(Colors.red, dist.major.toDouble(), '7+'),
    ];

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Theme.of(context).dividerColor.withAlpha(50)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Magnitude Frequency', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            AspectRatio(
              aspectRatio: 1.7,
              child: RepaintBoundary(
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: data.map((e) => e.value).reduce((a, b) => a > b ? a : b) * 1.2,
                    barTouchData: BarTouchData(),
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            if (value.toInt() >= 0 && value.toInt() < data.length) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(data[value.toInt()].label, style: const TextStyle(fontSize: 10)),
                              );
                            }
                            return const Text('');
                          },
                        ),
                      ),
                      leftTitles: const AxisTitles(),
                      topTitles: const AxisTitles(),
                      rightTitles: const AxisTitles(),
                    ),
                    gridData: const FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    barGroups: List.generate(data.length, (i) {
                      return BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: data[i].value,
                            color: data[i].color,
                            width: 18,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                          ),
                        ],
                      );
                    }),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivityTrend(BuildContext context, List<Earthquake> earthquakes) {
    // Group quakes by day for the last 7 days
    final now = DateTime.now();
    final Map<int, int> dayCounts = {};
    for (int i = 0; i < 7; i++) {
      dayCounts[i] = 0;
    }

    for (final eq in earthquakes) {
      final diff = now.difference(eq.time).inDays;
      if (diff >= 0 && diff < 7) {
        dayCounts[diff] = (dayCounts[diff] ?? 0) + 1;
      }
    }

    final spots = List.generate(7, (i) {
      return FlSpot(i.toDouble(), dayCounts[6 - i]!.toDouble());
    });

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Theme.of(context).dividerColor.withAlpha(50)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('7-Day Activity Trend', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            AspectRatio(
              aspectRatio: 2,
              child: RepaintBoundary(
                child: LineChart(
                  LineChartData(
                    gridData: const FlGridData(show: false),
                    titlesData: const FlTitlesData(show: false),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        color: Theme.of(context).primaryColor,
                        barWidth: 4,
                        isStrokeCapRound: true,
                        belowBarData: BarAreaData(
                          show: true,
                          color: Theme.of(context).primaryColor.withAlpha(30),
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
    );
  }

  Widget _buildDepthAnalysisCard(BuildContext context, _EarthquakeStats stats) {
    final dist = stats.depthDistribution;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'Depth Analysis',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: _DepthStatCard(
                label: 'Shallow',
                subtitle: '< 70 km',
                count: dist.shallow,
                avgMag: dist.shallowAvgMag,
                color: Colors.red,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _DepthStatCard(
                label: 'Deep',
                subtitle: '> 70 km',
                count: dist.deep + dist.intermediate,
                avgMag: (dist.deepAvgMag + dist.intermediateAvgMag) / 2,
                color: Colors.blue,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTopRegionsCard(BuildContext context, List<Earthquake> earthquakes) {
    final Map<String, int> regionCounts = {};
    for (final eq in earthquakes) {
      String region = eq.place;
      if (region.contains(',')) {
        region = region.split(',').last.trim();
      }
      final words = region.split(' ');
      if (words.length > 2) {
        region = words.take(3).join(' ');
      }
      regionCounts[region] = (regionCounts[region] ?? 0) + 1;
    }

    final topRegions = regionCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top5 = topRegions.take(5).toList();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Theme.of(context).dividerColor.withAlpha(50)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Most Active Regions',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (top5.isEmpty)
              const Center(child: Text('No region data available'))
            else
              ...top5.map((entry) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: Theme.of(context).primaryColor.withAlpha(30),
                      child: Text(
                        (top5.indexOf(entry) + 1).toString(),
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        entry.key,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${entry.value} events',
                      style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor),
                    ),
                  ],
                ),
              )),
          ],
        ),
      ),
    );
  }

  _EarthquakeStats _calculateStatistics(List<Earthquake> earthquakes) {
    if (earthquakes.isEmpty) return _EarthquakeStats();

    int microCount = 0, minorCount = 0, lightCount = 0, moderateCount = 0, strongCount = 0, majorCount = 0, greatCount = 0;
    double shallowTotal = 0, intermediateTotal = 0, deepTotal = 0;
    int shallowCount = 0, intermediateCount = 0, deepCount = 0;
    double totalMagnitude = 0, totalDepth = 0;
    double maxMagnitude = double.negativeInfinity, minMagnitude = double.infinity;
    DateTime? oldestDate, newestDate;

    for (final eq in earthquakes) {
      totalMagnitude += eq.magnitude;
      if (eq.magnitude < 2) {
        microCount++;
      } else if (eq.magnitude < 4) {
        minorCount++;
      } else if (eq.magnitude < 5) {
        lightCount++;
      } else if (eq.magnitude < 6) {
        moderateCount++;
      } else if (eq.magnitude < 7) {
        strongCount++;
      } else if (eq.magnitude < 8) {
        majorCount++;
      } else {
        greatCount++;
      }

      totalDepth += eq.depth;
      if (eq.depth < 70) {
        shallowCount++;
        shallowTotal += eq.magnitude;
      } else if (eq.depth < 300) {
        intermediateCount++;
        intermediateTotal += eq.magnitude;
      } else {
        deepCount++;
        deepTotal += eq.magnitude;
      }

      if (eq.magnitude > maxMagnitude) {
        maxMagnitude = eq.magnitude;
      }
      if (eq.magnitude < minMagnitude) {
        minMagnitude = eq.magnitude;
      }
      if (oldestDate == null || eq.time.isBefore(oldestDate)) {
        oldestDate = eq.time;
      }
      if (newestDate == null || eq.time.isAfter(newestDate)) {
        newestDate = eq.time;
      }
    }

    return _EarthquakeStats(
      totalCount: earthquakes.length,
      averageMagnitude: totalMagnitude / earthquakes.length,
      maxMagnitude: maxMagnitude,
      minMagnitude: minMagnitude,
      averageDepth: totalDepth / earthquakes.length,
      oldestDate: oldestDate,
      newestDate: newestDate,
      magnitudeDistribution: _MagnitudeDistribution(
        micro: microCount, minor: minorCount, light: lightCount, 
        moderate: moderateCount, strong: strongCount, major: majorCount, great: greatCount,
      ),
      depthDistribution: _DepthDistribution(
        shallow: shallowCount, intermediate: intermediateCount, deep: deepCount,
        shallowAvgMag: shallowCount > 0 ? shallowTotal / shallowCount : 0,
        intermediateAvgMag: intermediateCount > 0 ? intermediateTotal / intermediateCount : 0,
        deepAvgMag: deepCount > 0 ? deepTotal / deepCount : 0,
      ),
    );
  }
}

class _BarData {
  final Color color;
  final double value;
  final String label;
  _BarData(this.color, this.value, this.label);
}

class _EarthquakeStats {
  final int totalCount;
  final double averageMagnitude;
  final double maxMagnitude;
  final double minMagnitude;
  final double averageDepth;
  final DateTime? oldestDate;
  final DateTime? newestDate;
  final _MagnitudeDistribution magnitudeDistribution;
  final _DepthDistribution depthDistribution;

  _EarthquakeStats({
    this.totalCount = 0,
    this.averageMagnitude = 0,
    this.maxMagnitude = 0,
    this.minMagnitude = 0,
    this.averageDepth = 0,
    this.oldestDate,
    this.newestDate,
    _MagnitudeDistribution? magnitudeDistribution,
    _DepthDistribution? depthDistribution,
  })  : magnitudeDistribution = magnitudeDistribution ?? _MagnitudeDistribution(),
        depthDistribution = depthDistribution ?? _DepthDistribution();
}

class _MagnitudeDistribution {
  final int micro, minor, light, moderate, strong, major, great;
  _MagnitudeDistribution({this.micro = 0, this.minor = 0, this.light = 0, this.moderate = 0, this.strong = 0, this.major = 0, this.great = 0});
}

class _DepthDistribution {
  final int shallow, intermediate, deep;
  final double shallowAvgMag, intermediateAvgMag, deepAvgMag;
  _DepthDistribution({this.shallow = 0, this.intermediate = 0, this.deep = 0, this.shallowAvgMag = 0, this.intermediateAvgMag = 0, this.deepAvgMag = 0});
}

class _DepthStatCard extends StatelessWidget {
  final String label, subtitle;
  final int count;
  final double avgMag;
  final Color color;

  const _DepthStatCard({required this.label, required this.subtitle, required this.count, required this.avgMag, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(40)),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
          Text(subtitle, style: TextStyle(fontSize: 10, color: Theme.of(context).hintColor)),
          const SizedBox(height: 12),
          Text(count.toString(), style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
          Text('Avg M${avgMag.toStringAsFixed(1)}', style: TextStyle(fontSize: 11, color: Theme.of(context).hintColor)),
        ],
      ),
    );
  }
}
