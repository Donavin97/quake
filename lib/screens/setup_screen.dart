import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/auth_service.dart';
import '../providers/location_provider.dart';
import '../providers/user_provider.dart';
import '../providers/service_providers.dart';
import '../services/background_service.dart';
import '../theme.dart';

class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({super.key});

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  void _nextStep() {
    if (_currentStep < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      context.go('/');
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark 
          ? AppTheme.obsidian 
          : const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: List.generate(4, (index) {
                  return Expanded(
                    child: Container(
                      height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: index <= _currentStep
                            ? Theme.of(context).primaryColor
                            : Colors.grey.withAlpha(50),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (page) {
                  setState(() {
                    _currentStep = page;
                  });
                },
                children: [
                  _buildIntroStep(),
                  _buildDisclaimerStep(),
                  _buildAuthStep(),
                  _buildPermissionsStep(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIntroStep() {
    return _buildStepLayout(
      title: 'Welcome to QuakeTrack',
      description: 'Your real-time earthquake monitoring companion. Get notified of seismic activities and stay informed.',
      icon: Icons.public,
      buttonText: 'Get Started',
      onPressed: _nextStep,
    );
  }

  Widget _buildDisclaimerStep() {
    return _buildStepLayout(
      title: 'Disclaimer',
      description: 'Earthquake data is provided by multiple sources and is for informational purposes only. The developer is not responsible for any inaccuracies or omissions in the data.',
      icon: Icons.gavel,
      buttonText: 'I Accept',
      onPressed: _nextStep,
    );
  }

  Widget _buildAuthStep() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_outline, size: 80, color: Theme.of(context).primaryColor),
          const SizedBox(height: 24),
          Text(
            'Sign In',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontFamily: 'Oswald',
            ),
          ),
          const SizedBox(height: 8),
          const Text('Create an account to save your preferences'),
          const SizedBox(height: 32),
          AuthForm(
            onAuthSuccess: _nextStep,
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionsStep() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.location_on_outlined, size: 80, color: Theme.of(context).primaryColor),
          const SizedBox(height: 24),
          Text(
            'Location & Alerts',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontFamily: 'Oswald',
            ),
          ),
          const SizedBox(height: 24),
          const SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'QuakeTrack uses your location to provide accurate earthquake information relative to your position.',
                ),
                SizedBox(height: 16),
                Text(
                  'Prominent Disclosure:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'This app collects location data to enable "Life-Safety Proximity Alerts" even when the app is closed or not in use. This ensures you receive critical notifications if a significant earthquake occurs near your current physical location.',
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
                SizedBox(height: 16),
                Text(
                  'Notification Permission:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'We require notification permissions to deliver immediate, life-safety alerts to your device. This ensures you stay informed of seismic threats even when the app is not actively in use.',
                ),
              ],
            ),
          ),
          const Spacer(),
          ElevatedButton(
            key: const ValueKey('grant_permissions_button'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
            ),
            onPressed: () async {
              final locationNotifier = ref.read(locationProvider.notifier);
              final userNotifier = ref.read(userNotifierProvider.notifier);
              
              try {
                await locationNotifier.requestPermission();
                await BackgroundService.initialize();
                await userNotifier.completeSetup();
                _nextStep();
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to initialize services: $e')),
                  );
                }
              }
            },
            child: const Text('Grant Permissions'),
          ),
        ],
      ),
    );
  }

  Widget _buildStepLayout({
    required String title,
    required String description,
    required IconData icon,
    required String buttonText,
    required VoidCallback onPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          Icon(icon, size: 100, color: Theme.of(context).primaryColor),
          const SizedBox(height: 40),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontFamily: 'Oswald',
            ),
          ),
          const SizedBox(height: 24),
          Text(
            description,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const Spacer(),
          ElevatedButton(
            key: ValueKey('setup_next_button_${buttonText.replaceAll(' ', '_').toLowerCase()}'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
            ),
            onPressed: onPressed,
            child: Text(buttonText),
          ),
        ],
      ),
    );
  }
}

class AuthForm extends ConsumerStatefulWidget {
  final VoidCallback onAuthSuccess;

  const AuthForm({super.key, required this.onAuthSuccess});

  @override
  ConsumerState<AuthForm> createState() => _AuthFormState();
}

class _AuthFormState extends ConsumerState<AuthForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true;
  bool _passwordVisible = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showErrorDialog(String message, {bool isBindingError = false, bool isGoogle = false}) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Device Binding'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('CANCEL'),
          ),
          if (isBindingError) ...[
            TextButton(
              onPressed: () async {
                final authService = ref.read(authServiceProvider);
                final navigator = Navigator.of(context);
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                try {
                  await authService.unlinkCurrentDevice();
                  if (mounted) {
                    navigator.pop();
                    scaffoldMessenger.showSnackBar(
                      const SnackBar(content: Text('Device unlinked successfully. You can now sign in or register.')),
                    );
                  }
                } catch (e) {
                  _showErrorDialog('Failed to unlink device: $e');
                }
              },
              child: const Text('UNLINK DEVICE'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                final authService = ref.read(authServiceProvider);
                try {
                  if (isGoogle) {
                    await authService.forceSwitchDeviceWithGoogle();
                  } else {
                    await authService.forceSwitchDevice(
                      _emailController.text.trim(),
                      _passwordController.text.trim(),
                    );
                  }
                  widget.onAuthSuccess();
                } catch (e) {
                  _showErrorDialog(e.toString());
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('SWITCH DEVICE'),
            ),
          ],
        ],
      ),
    );
  }

  void _resetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email address first.')),
      );
      return;
    }

    final authService = ref.read(authServiceProvider);
    try {
      await authService.sendPasswordResetEmail(email);
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Password Reset'),
            content: const Text(
                'A password reset link has been sent to your email. If your account was locked, it will automatically unlock after 30 minutes of inactivity.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send reset email: $e')),
        );
      }
    }
  }

  void _trySubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authService = ref.read(authServiceProvider);
    try {
      if (_isLogin) {
        await authService.signInWithEmailAndPassword(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
      } else {
        await authService.createUserWithEmailAndPassword(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
      }
      widget.onAuthSuccess();
    } on DeviceBindingException catch (e) {
      _showErrorDialog(e.message, isBindingError: true);
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
      _showErrorDialog(_error!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AutofillGroup(
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextFormField(
              controller: _emailController,
              key: const ValueKey('email'),
              validator: (value) {
                if (value == null || value.isEmpty || !value.contains('@')) {
                  return 'Please enter a valid email address.';
                }
                return null;
              },
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Email address',
                prefixIcon: Icon(Icons.email),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              key: const ValueKey('password'),
              validator: (value) {
                if (value == null || value.isEmpty || value.length < 7) {
                  return 'Password must be at least 7 characters long.';
                }
                return null;
              },
              obscureText: !_passwordVisible,
              autofillHints: const [AutofillHints.password],
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _trySubmit(),
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(
                    _passwordVisible ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _passwordVisible = !_passwordVisible;
                    });
                  },
                  tooltip: _passwordVisible ? 'Hide password' : 'Show password',
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _trySubmit,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
                backgroundColor: Theme.of(context).primaryColor,
              ),
              child: Text(_isLogin ? 'Login' : 'Signup'),
            ),
            if (_isLogin)
              TextButton(
                onPressed: _resetPassword,
                child: const Text('Forgot password?'),
              ),
            TextButton(
              child: Text(_isLogin ? 'Create new account' : 'I already have an account'),
              onPressed: () {
                setState(() {
                  _isLogin = !_isLogin;
                  _error = null;
                });
              },
            ),
            const Divider(height: 32),
            ElevatedButton.icon(
              onPressed: () async {
                final authService = ref.read(authServiceProvider);
                try {
                  await authService.signInWithGoogle();
                  widget.onAuthSuccess();
                } on DeviceBindingException catch (e) {
                  _showErrorDialog(e.message, isBindingError: true, isGoogle: true);
                } catch (e) {
                  _showErrorDialog(e.toString());
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                minimumSize: const Size.fromHeight(56),
                side: const BorderSide(color: Colors.grey),
              ),
              icon: Image.asset(
                'assets/google_logo.png',
                height: 24.0,
              ),
              label: const Text('Sign in with Google'),
            ),
          ],
        ),
      ),
    );
  }
}
