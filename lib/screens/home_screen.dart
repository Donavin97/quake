import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/earthquake_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/earthquake_list_item.dart';
import 'detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch earthquakes when the widget is first created
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<EarthquakeProvider>(
        context,
        listen: false,
      ).fetchEarthquakes();
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recent Earthquakes'),
        actions: [
          IconButton(
            icon: Icon(
              themeProvider.themeMode == ThemeMode.dark
                  ? Icons.light_mode
                  : Icons.dark_mode,
            ),
            onPressed: () => themeProvider.toggleTheme(),
            tooltip: 'Toggle Theme',
          ),
        ],
      ),
      body: Consumer<EarthquakeProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(child: Text('Error: ${provider.error}'));
          }

          if (provider.earthquakes.isEmpty) {
            return const Center(child: Text('No earthquakes found.'));
          }

          return ListView.builder(
            itemCount: provider.earthquakes.length,
            itemBuilder: (context, index) {
              final earthquake = provider.earthquakes[index];
              return EarthquakeListItem(
                earthquake: earthquake,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          DetailScreen(earthquake: earthquake),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
