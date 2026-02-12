import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/disclaimer_provider.dart';
import '../services/auth_service.dart';

class DisclaimerScreen extends StatelessWidget {
  const DisclaimerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Disclaimer'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'No liabilities or damages shall be accepted from inferences of information provided in the app.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Provider.of<DisclaimerProvider>(context, listen: false)
                    .acceptDisclaimer();

                final authService =
                    Provider.of<AuthService>(context, listen: false);
                if (authService.currentUser != null) {
                  context.go('/permission');
                } else {
                  context.go('/auth');
                }
              },
              child: const Text('Accept'),
            ),
          ],
        ),
      ),
    );
  }
}
