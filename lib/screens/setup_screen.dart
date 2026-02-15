import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../providers/location_provider.dart';
import '../providers/user_provider.dart';
import '../services/background_service.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _showSetupDialogs());
  }

  void _showSetupDialogs() {
    _showDialogStep(_currentStep);
  }

  void _showDialogStep(int step) {
    if (!mounted) return;

    switch (step) {
      case 0:
        _showIntroDialog();
        break;
      case 1:
        _showDisclaimerDialog();
        break;
      case 2:
        _showAuthDialog();
        break;
      case 3:
        _showPermissionsDialog();
        break;
      default:
        context.go('/');
    }
  }

  void _nextStep() {
    setState(() {
      _currentStep++;
      _showDialogStep(_currentStep);
    });
  }

  void _showIntroDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Welcome to QuakeTrack'),
          content: const Text(
              'Your real-time earthquake monitoring companion. Get notified of seismic activities and stay informed.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Next'),
              onPressed: () {
                Navigator.of(context).pop();
                _nextStep();
              },
            ),
          ],
        );
      },
    );
  }

  void _showDisclaimerDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Disclaimer'),
          content: const Text(
              'The earthquake data is provided by the USGS and is for informational purposes only. The developer is not responsible for any inaccuracies or omissions in the data.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Accept'),
              onPressed: () {
                Navigator.of(context).pop();
                _nextStep();
              },
            ),
          ],
        );
      },
    );
  }

  void _showAuthDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Sign In'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton.icon(
                onPressed: () async {
                  final authService = context.read<AuthService>();
                  final messenger = ScaffoldMessenger.of(context);
                  final navigator = Navigator.of(context);
                  try {
                    await authService.signInWithGoogle();
                    navigator.pop();
                    _nextStep();
                  } catch (e) {
                    messenger.showSnackBar(
                      SnackBar(content: Text(e.toString())),
                    );
                  }
                },
                icon: Image.asset(
                  'assets/google_logo.png',
                  height: 24.0,
                ),
                label: const Text('Sign in with Google'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showPermissionsDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Permissions'),
          content: const Text(
              'We need your location and notification permission to provide accurate and timely earthquake information.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Grant Permissions'),
              onPressed: () async {
                final locationProvider = context.read<LocationProvider>();
                final userProvider = context.read<UserProvider>();
                final navigator = Navigator.of(context);

                await locationProvider.requestPermission();
                await BackgroundService.initialize();

                userProvider.completeSetup();

                navigator.pop();
                _nextStep();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
