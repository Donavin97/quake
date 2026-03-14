import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:quaketrack/main.dart' as app;

void main() {
  debugPrint('--- [QUAKE_TEST] Integration test main() started ---');
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  testWidgets('Capture Full Store Screenshots', (WidgetTester tester) async {
    debugPrint('--- [QUAKE_TEST] testWidgets block started ---');
    
    // 1. Launch the app
    try {
      debugPrint('--- [QUAKE_TEST] Calling app.main()... ---');
      await app.main();
      debugPrint('--- [QUAKE_TEST] app.main() called and awaited ---');
    } catch (e, stack) {
      debugPrint('--- [QUAKE_TEST] Error calling app.main(): $e\n$stack ---');
    }
    
    // Wait for the app to settle initially (extended wait for splash screen)
    debugPrint('--- [QUAKE_TEST] Waiting for App to load and splash to clear... ---');
    bool appLoaded = false;
    for (int i = 0; i < 15; i++) {
      await tester.pump(const Duration(seconds: 1));
      debugPrint('--- [QUAKE_TEST] Wait iteration $i ---');
      
      // Check if we are past the initial blank screen
      if (find.byType(MaterialApp).evaluate().isNotEmpty || 
          find.byType(CircularProgressIndicator).evaluate().isNotEmpty ||
          find.text('Welcome to QuakeTrack').evaluate().isNotEmpty) {
        debugPrint('--- [QUAKE_TEST] App detected in tree at iteration $i ---');
        appLoaded = true;
        break;
      }
    }
    
    if (!appLoaded) {
      debugPrint('--- [QUAKE_TEST] APP FAILED TO LOAD WITHIN 15s. Dumping tree: ---');
      // debugDumpApp();
    }

    await tester.pumpAndSettle();
    debugPrint('--- [QUAKE_TEST] App settling finished ---');

    // Helper to tap and wait
    Future<void> robustTap(Finder finder, String label) async {
      debugPrint('--- [QUAKE_TEST] Attempting to tap $label ---');
      try {
        await tester.pumpAndSettle();
        final actualFinder = finder.last;
        
        // Ensure it's in the tree
        if (actualFinder.evaluate().isEmpty) {
          debugPrint('--- [QUAKE_TEST] Finder for $label returned EMPTY. ---');
          return;
        }

        await tester.ensureVisible(actualFinder);
        
        // Get center and tap via coordinates (often more reliable)
        final Offset center = tester.getCenter(actualFinder);
        debugPrint('--- [QUAKE_TEST] Tapping $label at $center ---');
        await tester.tapAt(center);
        debugPrint('--- [QUAKE_TEST] Tapped $label ---');
      } catch (e) {
        debugPrint('--- [QUAKE_TEST] FAILED to tap $label: $e ---');
      }
      await tester.pumpAndSettle();
    }

    bool isSurfaceConverted = false;

    Future<void> safeScreenshot(String name) async {
      debugPrint('--- [QUAKE_TEST] Starting screenshot: $name ---');
      try {
        if (!isSurfaceConverted) {
          await binding.convertFlutterSurfaceToImage();
          isSurfaceConverted = true;
          debugPrint('--- [QUAKE_TEST] Surface converted to image ---');
        }
        await tester.pump(const Duration(milliseconds: 500));
        await binding.takeScreenshot(name);
        debugPrint('--- [QUAKE_TEST] Finished screenshot: $name ---');
      } catch (e) {
        debugPrint('--- [QUAKE_TEST] FAILED screenshot $name: $e ---');
      }
    }

    // 2. Step 1: Intro Screen
    debugPrint('--- [QUAKE_TEST] Checking for Intro screen... ---');
    await tester.pumpAndSettle();

    final getStarted = find.byKey(const ValueKey('setup_next_button_get_started'));
    final getStartedText = find.text('Get Started');

    if (getStarted.evaluate().isNotEmpty) {
      debugPrint('--- [QUAKE_TEST] On Intro screen (Key found) ---');
      await safeScreenshot('01_intro');
      await robustTap(getStarted, 'Get Started');
    } else if (getStartedText.evaluate().isNotEmpty) {
      debugPrint('--- [QUAKE_TEST] On Intro screen (Text found) ---');
      await safeScreenshot('01_intro');
      await robustTap(getStartedText, 'Get Started');
    }
 else {
      debugPrint('--- [QUAKE_TEST] Intro screen buttons NOT FOUND. Printing tree... ---');
      // debugDumpApp();
    }
    debugPrint('--- [QUAKE_TEST] Step 1 Finished ---');

    // 3. Step 2: Disclaimer
    debugPrint('--- [QUAKE_TEST] Checking for Disclaimer screen... ---');
    await tester.pumpAndSettle();
    final iAccept = find.byKey(const ValueKey('setup_next_button_i_accept'));
    final iAcceptText = find.text('I Accept');
    
    if (iAccept.evaluate().isNotEmpty) {
      debugPrint('--- [QUAKE_TEST] On Disclaimer screen (Key found) ---');
      await safeScreenshot('02_disclaimer');
      await robustTap(iAccept, 'I Accept');
    } else if (iAcceptText.evaluate().isNotEmpty) {
      debugPrint('--- [QUAKE_TEST] On Disclaimer screen (Text found) ---');
      await safeScreenshot('02_disclaimer');
      await robustTap(iAcceptText, 'I Accept');
    }
    debugPrint('--- [QUAKE_TEST] Step 2 Finished ---');

    // 4. Step 3: Auth Screen
    debugPrint('--- [QUAKE_TEST] Checking for Auth screen... ---');
    await tester.pumpAndSettle();
    final emailField = find.byKey(const ValueKey('email'));
    
    if (emailField.evaluate().isNotEmpty) {
      debugPrint('--- [QUAKE_TEST] AUTH: On Login screen, performing manual login ---');
      await safeScreenshot('03_login');
      
      await tester.enterText(emailField, 'donavin@email.com');
      await tester.pump();
      await tester.enterText(find.byKey(const ValueKey('password')), 'titanic26');
      await tester.pump();
      
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      
      final loginButton = find.text('Login');
      await robustTap(loginButton, 'Login');
      debugPrint('--- [QUAKE_TEST] AUTH: Login tapped, waiting for transition (10s)... ---');
      await Future.delayed(const Duration(seconds: 10));
      await tester.pumpAndSettle();
    }
    debugPrint('--- [QUAKE_TEST] Step 3 Finished ---');

    // 5. Step 4: Permissions Screen
    debugPrint('--- [QUAKE_TEST] Checking for Permissions screen... ---');
    await tester.pumpAndSettle();
    final grantButton = find.byKey(const ValueKey('grant_permissions_button'));
    if (grantButton.evaluate().isNotEmpty) {
      debugPrint('--- [QUAKE_TEST] Tapping Grant Permissions ---');
      await safeScreenshot('04_permissions');
      await robustTap(grantButton, 'Grant Permissions');
      // Wait for possible system dialogs and transition
      await Future.delayed(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    }
    debugPrint('--- [QUAKE_TEST] Step 4 Finished ---');

    // 6. MAIN APP SCREENS
    debugPrint('--- [QUAKE_TEST] Checking for Main App screens... ---');
    
    // Helper to navigate tabs
    Future<void> goToTab(String text, String label) async {
      debugPrint('--- [QUAKE_TEST] Navigating to $label ($text) ---');
      final tab = find.text(text);
      if (tab.evaluate().isNotEmpty) {
        await robustTap(tab, label);
        await tester.pumpAndSettle();
        await safeScreenshot(label);
        debugPrint('--- [QUAKE_TEST] Screenshotted $label ---');
      } else {
        debugPrint('--- [QUAKE_TEST] Tab $label ($text) NOT FOUND ---');
      }
    }

    await goToTab('Map', '05_map');
    await goToTab('List', '06_list');
    await goToTab('Stats', '07_stats');
    await goToTab('Safety', '08_safety');
    
    debugPrint('--- [QUAKE_TEST] Completed successfully ---');
  });
}
