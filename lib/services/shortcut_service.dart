import 'package:flutter/material.dart';
import 'package:quick_actions/quick_actions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/earthquake_provider.dart';
import 'navigation_service.dart';

class ShortcutService {
  static const QuickActions _quickActions = QuickActions();

  static void initialize(BuildContext context, WidgetRef ref) {
    _quickActions.setShortcutItems(<ShortcutItem>[
      const ShortcutItem(
        type: 'action_map',
        localizedTitle: 'Main Map',
        icon: 'ic_launcher',
      ),
      const ShortcutItem(
        type: 'action_major',
        localizedTitle: 'Last Major Quake',
        icon: 'ic_launcher',
      ),
      const ShortcutItem(
        type: 'action_safety',
        localizedTitle: 'Safety Toolbox',
        icon: 'ic_launcher',
      ),
    ]);

    _quickActions.initialize((String shortcutType) {
      final context = NavigationService.navigatorKey.currentContext;
      if (context == null) return;

      if (shortcutType == 'action_map') {
        NavigationService.tabChangeNotifier.value = 0;
        GoRouter.of(context).go('/'); 
      } else if (shortcutType == 'action_major') {
        final eqState = ref.read(earthquakeNotifierProvider);
        final majorQuakes = eqState.allEarthquakes.where((eq) => eq.magnitude >= 6.0).toList();
        if (majorQuakes.isNotEmpty) {
          final latest = majorQuakes.first; 
          GoRouter.of(context).go('/details/${Uri.encodeComponent(latest.id)}', extra: latest);
        } else {
          NavigationService.tabChangeNotifier.value = 1; // Go to list if no major
          GoRouter.of(context).go('/');
        }
      } else if (shortcutType == 'action_safety') {
        NavigationService.tabChangeNotifier.value = 3; // Safety tab
        GoRouter.of(context).go('/'); 
      }
    });
  }
}
