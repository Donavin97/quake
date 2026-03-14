import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quaketrack/theme.dart';

// Helper to load fonts so they appear in golden screenshots
Future<void> _loadFonts() async {
  final fontFiles = {
    'Oswald': 'fonts/Oswald-Bold.ttf',
    'Roboto': 'fonts/Roboto-Medium.ttf',
    'OpenSans': 'fonts/OpenSans-Regular.ttf',
  };

  for (final entry in fontFiles.entries) {
    final fontData = File(entry.value).readAsBytesSync();
    final loader = FontLoader(entry.key);
    loader.addFont(Future.value(ByteData.view(fontData.buffer)));
    await loader.load();
  }
}

void main() {
  setUpAll(() async {
    // This is required to load the fonts before any tests run
    await _loadFonts();
  });

  testWidgets('Generate 4 Real App Screenshots', (WidgetTester tester) async {
    final devices = {
      'tablet_7': const Size(600, 1024),
      'tablet_10': const Size(800, 1280),
    };

    for (final device in devices.entries) {
      final name = device.key;
      final size = device.value;

      await tester.binding.setSurfaceSize(size);
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;

      // --- SCREEN 1: MAP ---
      await tester.pumpWidget(_buildFakeMapScreen(size));
      await tester.pumpAndSettle();
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/${name}_01_map.png'));

      // --- SCREEN 2: LIST ---
      await tester.pumpWidget(_buildFakeListScreen(size));
      await tester.pumpAndSettle();
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/${name}_02_list.png'));

      // --- SCREEN 3: STATS ---
      await tester.pumpWidget(_buildFakeStatsScreen(size));
      await tester.pumpAndSettle();
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/${name}_03_stats.png'));

      // --- SCREEN 4: SAFETY ---
      await tester.pumpWidget(_buildFakeSafetyScreen(size));
      await tester.pumpAndSettle();
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/${name}_04_safety.png'));
    }
  });
}

Widget _buildFakeMapScreen(Size size) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.darkTheme,
    home: Scaffold(
      appBar: AppBar(title: const Text('QuakeTrack Map', style: TextStyle(fontFamily: 'Oswald'))),
      body: Stack(
        children: [
          Container(color: const Color(0xFF1A1C1E)), 
          const Center(child: Icon(Icons.public, size: 300, color: Colors.white10)),
          _buildMapMarker(200, 300, 7.2, Colors.red),
          _buildMapMarker(400, 150, 5.4, Colors.orange),
          _buildMapMarker(150, 600, 4.1, Colors.green),
          Positioned(
            right: 20, top: 20,
            child: Column(
              children: [
                _buildMapButton(Icons.add),
                const SizedBox(height: 10),
                _buildMapButton(Icons.remove),
                const SizedBox(height: 10),
                _buildMapButton(Icons.my_location),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildMapMarker(double x, double y, double mag, Color color) {
  return Positioned(
    left: x, top: y,
    child: Container(
      width: 40, height: 40,
      decoration: BoxDecoration(color: color.withAlpha(150), shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
      child: Center(child: Text(mag.toString(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12, fontFamily: 'Roboto'))),
    ),
  );
}

Widget _buildMapButton(IconData icon) {
  return Container(
    padding: const EdgeInsets.all(12),
    decoration: const BoxDecoration(color: AppTheme.mantleGray, shape: BoxShape.circle),
    child: Icon(icon, color: Colors.white),
  );
}

Widget _buildFakeListScreen(Size size) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.darkTheme,
    home: Scaffold(
      appBar: AppBar(title: const Text('Recent Earthquakes', style: TextStyle(fontFamily: 'Oswald'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildFakeListItem('M 7.2', 'Off the coast of Honshu, Japan', '2h ago', Colors.red),
          _buildFakeListItem('M 5.8', 'Central Turkey', '5h ago', Colors.orange),
          _buildFakeListItem('M 4.5', 'Southern California, USA', '12h ago', Colors.yellow),
          _buildFakeListItem('M 6.1', 'Andean Mountains, Chile', '1d ago', Colors.orange),
          _buildFakeListItem('M 3.2', 'Reykjanes, Iceland', '2d ago', Colors.green),
        ],
      ),
    ),
  );
}

Widget _buildFakeListItem(String mag, String place, String time, Color color) {
  return Card(
    margin: const EdgeInsets.only(bottom: 16),
    child: ListTile(
      leading: Container(
        width: 60, height: 60,
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
        child: Center(child: Text(mag, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18, fontFamily: 'Oswald'))),
      ),
      title: Text(place, style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Roboto'), overflow: TextOverflow.ellipsis),
      subtitle: Text(time, style: const TextStyle(fontFamily: 'OpenSans')),
      trailing: const Icon(Icons.chevron_right),
    ),
  );
}

Widget _buildFakeStatsScreen(Size size) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.darkTheme,
    home: Scaffold(
      appBar: AppBar(title: const Text('Seismic Insights', style: TextStyle(fontFamily: 'Oswald'))),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Row(
              children: [
                Expanded(child: _StatCard('Total Quakes', '1,248', Icons.analytics)),
                SizedBox(width: 20),
                Expanded(child: _StatCard('Avg Mag', '4.2', Icons.trending_up)),
              ],
            ),
            const SizedBox(height: 40),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(color: AppTheme.mantleGray, borderRadius: BorderRadius.circular(24)),
                child: const Center(child: Text('Activity Trend Graph (30 Days)', style: TextStyle(color: Colors.white54, fontFamily: 'OpenSans'))),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _buildFakeSafetyScreen(Size size) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.darkTheme,
    home: Scaffold(
      appBar: AppBar(title: const Text('Safety Dashboard', style: TextStyle(fontFamily: 'Oswald'))),
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
             _buildFakeSafetyAction(Icons.notifications_active, 'Life-Safety Alerts', 'Enabled', AppTheme.magmaOrange),
             const SizedBox(height: 20),
             _buildFakeSafetyAction(Icons.medical_services, 'Emergency Toolbox', 'Ready', Colors.green),
             const SizedBox(height: 20),
             _buildFakeSafetyAction(Icons.waves, 'Sonification', 'Active', AppTheme.tectonicBlue),
          ],
        ),
      ),
    ),
  );
}

Widget _buildFakeSafetyAction(IconData icon, String title, String status, Color color) {
  return Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(color: color.withAlpha(20), borderRadius: BorderRadius.circular(24), border: Border.all(color: color.withAlpha(50))),
    child: Row(
      children: [
        Icon(icon, size: 48, color: color),
        const SizedBox(width: 24),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'Oswald'), overflow: TextOverflow.ellipsis),
            Text('Status: $status', style: TextStyle(color: color, fontFamily: 'Roboto')),
          ]),
        ),
        const SizedBox(width: 12),
        const Icon(Icons.check_circle, color: Colors.green),
      ],
    ),
  );
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  const _StatCard(this.title, this.value, this.icon);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: AppTheme.mantleGray, borderRadius: BorderRadius.circular(24)),
      child: Column(children: [
        Icon(icon, color: AppTheme.magmaOrange),
        const SizedBox(height: 12),
        FittedBox(fit: BoxFit.scaleDown, child: Text(value, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, fontFamily: 'Oswald'))),
        Text(title, style: const TextStyle(color: Colors.white54, fontFamily: 'OpenSans'), overflow: TextOverflow.ellipsis),
      ]),
    );
  }
}
