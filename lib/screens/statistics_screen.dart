import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

import '../models/earthquake.dart';
import '../providers/earthquake_provider.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Earthquake Statistics'),
      ),
      body: Consumer<EarthquakeProvider>(
        builder: (context, provider, child) {
          final earthquakes = provider.earthquakes;
          
          if (earthquakes.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.analytics_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No earthquake data available',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Statistics will appear once data is loaded',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final stats = _calculateStatistics(earthquakes);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSummaryCard(context, stats, earthquakes.length),
              const SizedBox(height: 16),
              _buildMagnitudeDistributionCard(context, stats),
              const SizedBox(height: 16),
              _buildDepthAnalysisCard(context, stats),
              const SizedBox(height: 16),
              _buildTimeDistributionCard(context, stats),
              const SizedBox(height: 16),
              _buildTopRegionsCard(context, earthquakes),
            ],
          );
        },
      ),
    );
  }

  _EarthquakeStats _calculateStatistics(List<Earthquake> earthquakes) {
    if (earthquakes.isEmpty) {
      return _EarthquakeStats();
    }

    // Magnitude distribution
    int microCount = 0; // < 2
    int minorCount = 0; // 2-3.9
    int lightCount = 0; // 4-4.9
    int moderateCount = 0; // 5-5.9
    int strongCount = 0; // 6-6.9
    int majorCount = 0; // 7-7.9
    int greatCount = 0; // >= 8

    // Depth distribution
    double shallowTotal = 0; // < 70km
    double intermediateTotal = 0; // 70-300km
    double deepTotal = 0; // > 300km
    int shallowCount = 0;
    int intermediateCount = 0;
    int deepCount = 0;

    // Time distribution
    int lastHour = 0;
    int lastDay = 0;
    int lastWeek = 0;
    int older = 0;

    double totalMagnitude = 0;
    double totalDepth = 0;
    double maxMagnitude = double.negativeInfinity;
    double minMagnitude = double.infinity;
    DateTime? oldestDate;
    DateTime? newestDate;

    final now = DateTime.now();

    for (final eq in earthquakes) {
      // Magnitude
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

      // Depth
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

      // Time
      final diff = now.difference(eq.time);
      if (diff.inHours < 1) {
        lastHour++;
      } else if (diff.inHours >= 1 && diff.inDays < 1) {
        lastDay++;
      } else if (diff.inDays >= 1 && diff.inDays < 7) {
        lastWeek++;
      } else {
        older++;
      }

      // Min/Max
      if (eq.magnitude > maxMagnitude) maxMagnitude = eq.magnitude;
      if (eq.magnitude < minMagnitude) minMagnitude = eq.magnitude;
      
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
      maxMagnitude: maxMagnitude == double.negativeInfinity ? 0 : maxMagnitude,
      minMagnitude: minMagnitude == double.infinity ? 0 : minMagnitude,
      averageDepth: totalDepth / earthquakes.length,
      oldestDate: oldestDate,
      newestDate: newestDate,
      magnitudeDistribution: _MagnitudeDistribution(
        micro: microCount,
        minor: minorCount,
        light: lightCount,
        moderate: moderateCount,
        strong: strongCount,
        major: majorCount,
        great: greatCount,
      ),
      depthDistribution: _DepthDistribution(
        shallow: shallowCount,
        intermediate: intermediateCount,
        deep: deepCount,
        shallowAvgMag: shallowCount > 0 ? shallowTotal / shallowCount : 0,
        intermediateAvgMag: intermediateCount > 0 ? intermediateTotal / intermediateCount : 0,
        deepAvgMag: deepCount > 0 ? deepTotal / deepCount : 0,
      ),
      timeDistribution: _TimeDistribution(
        lastHour: lastHour,
        lastDay: lastDay,
        lastWeek: lastWeek,
        older: older,
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, _EarthquakeStats stats, int total) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Summary',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _StatItem(
                    icon: Icons.public,
                    label: 'Total Events',
                    value: stats.totalCount.toString(),
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                Expanded(
                  child: _StatItem(
                    icon: Icons.speed,
                    label: 'Avg Magnitude',
                    value: stats.averageMagnitude.toStringAsFixed(1),
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StatItem(
                    icon: Icons.trending_up,
                    label: 'Max Magnitude',
                    value: stats.maxMagnitude.toStringAsFixed(1),
                    color: Colors.red,
                  ),
                ),
                Expanded(
                  child: _StatItem(
                    icon: Icons.trending_down,
                    label: 'Min Magnitude',
                    value: stats.minMagnitude.toStringAsFixed(1),
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StatItem(
                    icon: Icons.vertical_align_bottom,
                    label: 'Avg Depth',
                    value: '${stats.averageDepth.toStringAsFixed(0)} km',
                    color: Colors.blue,
                  ),
                ),
                Expanded(
                  child: _StatItem(
                    icon: Icons.calendar_today,
                    label: 'Date Range',
                    value: (stats.oldestDate != null && stats.newestDate != null)
                        ? '${stats.newestDate!.difference(stats.oldestDate!).inDays}d'
                        : 'N/A',
                    color: Colors.purple,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMagnitudeDistributionCard(BuildContext context, _EarthquakeStats stats) {
    final dist = stats.magnitudeDistribution;
    final total = dist.micro + dist.minor + dist.light + dist.moderate + dist.strong + dist.major + dist.great;
    
    if (total == 0) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Magnitude Distribution', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              const Center(child: Text('No data available')),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Magnitude Distribution',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: Row(
                children: [
                  Expanded(
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                        sections: [
                          if (dist.micro > 0) PieChartSectionData(
                            value: dist.micro.toDouble(),
                            title: '${(dist.micro / total * 100).toStringAsFixed(0)}%',
                            color: Colors.green,
                            radius: 50,
                            titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          if (dist.minor > 0) PieChartSectionData(
                            value: dist.minor.toDouble(),
                            title: '${(dist.minor / total * 100).toStringAsFixed(0)}%',
                            color: Colors.lightGreen,
                            radius: 50,
                            titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          if (dist.light > 0) PieChartSectionData(
                            value: dist.light.toDouble(),
                            title: '${(dist.light / total * 100).toStringAsFixed(0)}%',
                            color: Colors.yellow,
                            radius: 50,
                            titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black),
                          ),
                          if (dist.moderate > 0) PieChartSectionData(
                            value: dist.moderate.toDouble(),
                            title: '${(dist.moderate / total * 100).toStringAsFixed(0)}%',
                            color: Colors.orange,
                            radius: 50,
                            titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          if (dist.strong > 0) PieChartSectionData(
                            value: dist.strong.toDouble(),
                            title: '${(dist.strong / total * 100).toStringAsFixed(0)}%',
                            color: Colors.deepOrange,
                            radius: 50,
                            titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          if (dist.major > 0) PieChartSectionData(
                            value: dist.major.toDouble(),
                            title: '${(dist.major / total * 100).toStringAsFixed(0)}%',
                            color: Colors.red,
                            radius: 50,
                            titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          if (dist.great > 0) PieChartSectionData(
                            value: dist.great.toDouble(),
                            title: '${(dist.great / total * 100).toStringAsFixed(0)}%',
                            color: Colors.purple,
                            radius: 50,
                            titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLegendItem('Micro (<2)', Colors.green, dist.micro),
                      _buildLegendItem('Minor (2-3.9)', Colors.lightGreen, dist.minor),
                      _buildLegendItem('Light (4-4.9)', Colors.yellow, dist.light),
                      _buildLegendItem('Moderate (5-5.9)', Colors.orange, dist.moderate),
                      _buildLegendItem('Strong (6-6.9)', Colors.deepOrange, dist.strong),
                      _buildLegendItem('Major (7-7.9)', Colors.red, dist.major),
                      _buildLegendItem('Great (8+)', Colors.purple, dist.great),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text('$label: $count', style: const TextStyle(fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildDepthAnalysisCard(BuildContext context, _EarthquakeStats stats) {
    final dist = stats.depthDistribution;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Depth Analysis',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
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
                const SizedBox(width: 8),
                Expanded(
                  child: _DepthStatCard(
                    label: 'Intermediate',
                    subtitle: '70-300 km',
                    count: dist.intermediate,
                    avgMag: dist.intermediateAvgMag,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _DepthStatCard(
                    label: 'Deep',
                    subtitle: '> 300 km',
                    count: dist.deep,
                    avgMag: dist.deepAvgMag,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeDistributionCard(BuildContext context, _EarthquakeStats stats) {
    final dist = stats.timeDistribution;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Activity',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _TimeStatItem(
                    label: 'Last Hour',
                    count: dist.lastHour,
                    color: Colors.red,
                  ),
                ),
                Expanded(
                  child: _TimeStatItem(
                    label: 'Last 24h',
                    count: dist.lastDay,
                    color: Colors.orange,
                  ),
                ),
                Expanded(
                  child: _TimeStatItem(
                    label: 'Last Week',
                    count: dist.lastWeek,
                    color: Colors.yellow[700]!,
                  ),
                ),
                Expanded(
                  child: _TimeStatItem(
                    label: 'Older',
                    count: dist.older,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopRegionsCard(BuildContext context, List<Earthquake> earthquakes) {
    // Count earthquakes by region (extract region from place)
    final Map<String, int> regionCounts = {};
    for (final eq in earthquakes) {
      // Extract main region name - take first part before comma or just use full place
      String region = eq.place;
      if (region.contains(',')) {
        region = region.split(',').last.trim();
      }
      // Further simplify - take first 2-3 words for grouping
      final words = region.split(' ');
      if (words.length > 2) {
        region = words.take(3).join(' ');
      }
      regionCounts[region] = (regionCounts[region] ?? 0) + 1;
    }

    // Sort by count and take top 5
    final topRegions = regionCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top5 = topRegions.take(5).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Most Active Regions',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            if (top5.isEmpty)
              const Text('No region data available')
            else
              ...topRegions.take(5).map((entry) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    const Icon(Icons.location_on, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        entry.key,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        entry.value.toString(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
          ],
        ),
      ),
    );
  }
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
  final _TimeDistribution timeDistribution;

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
    _TimeDistribution? timeDistribution,
  })  : magnitudeDistribution = magnitudeDistribution ?? _MagnitudeDistribution(),
        depthDistribution = depthDistribution ?? _DepthDistribution(),
        timeDistribution = timeDistribution ?? _TimeDistribution();
}

class _MagnitudeDistribution {
  final int micro;
  final int minor;
  final int light;
  final int moderate;
  final int strong;
  final int major;
  final int great;

  _MagnitudeDistribution({
    this.micro = 0,
    this.minor = 0,
    this.light = 0,
    this.moderate = 0,
    this.strong = 0,
    this.major = 0,
    this.great = 0,
  });
}

class _DepthDistribution {
  final int shallow;
  final int intermediate;
  final int deep;
  final double shallowAvgMag;
  final double intermediateAvgMag;
  final double deepAvgMag;

  _DepthDistribution({
    this.shallow = 0,
    this.intermediate = 0,
    this.deep = 0,
    this.shallowAvgMag = 0,
    this.intermediateAvgMag = 0,
    this.deepAvgMag = 0,
  });
}

class _TimeDistribution {
  final int lastHour;
  final int lastDay;
  final int lastWeek;
  final int older;

  _TimeDistribution({
    this.lastHour = 0,
    this.lastDay = 0,
    this.lastWeek = 0,
    this.older = 0,
  });
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
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
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}

class _DepthStatCard extends StatelessWidget {
  final String label;
  final String subtitle;
  final int count;
  final double avgMag;
  final Color color;

  const _DepthStatCard({
    required this.label,
    required this.subtitle,
    required this.count,
    required this.avgMag,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(fontSize: 10, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            'Avg: ${avgMag.toStringAsFixed(1)}',
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}

class _TimeStatItem extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _TimeStatItem({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              count.toString(),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}