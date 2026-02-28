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
              'Earthquake data is provided by multiple sources and is for informational purposes only. The developer is not responsible for any inaccuracies or omissions in the data.'),
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
          content: SingleChildScrollView(
            child: AuthForm(
              onAuthSuccess: () {
                Navigator.of(context).pop();
                _nextStep();
              },
            ),
          ),
        );
      },
    );
  }

  void _showErrorDialog(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
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
                
                try {
                  await locationProvider.requestPermission();
                  await BackgroundService.initialize();
                  userProvider.completeSetup();
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    _nextStep();
                  }
                } catch (e) {
                  _showErrorDialog('Failed to initialize services: $e');
                }
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

class AuthForm extends StatefulWidget {
  final VoidCallback onAuthSuccess;

  const AuthForm({super.key, required this.onAuthSuccess});

  @override
  State<AuthForm> createState() => _AuthFormState();
}

class _AuthFormState extends State<AuthForm> {
  final _formKey = GlobalKey<FormState>();
  bool _isLogin = true;
  String _email = '';
  String _password = '';
  bool _passwordVisible = false; // Added
  String? _error;

  void _showErrorDialog(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _trySubmit() async {
    final isValid = _formKey.currentState!.validate();
    FocusScope.of(context).unfocus();

    if (isValid) {
      _formKey.currentState!.save();
      final authService = context.read<AuthService>();
      try {
        if (_isLogin) {
          await authService.signInWithEmailAndPassword(_email, _password);
        } else {
          await authService.createUserWithEmailAndPassword(_email, _password);
        }
        widget.onAuthSuccess();
      } catch (e) {
        setState(() {
          _error = e.toString();
        });
        _showErrorDialog(_error!);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          TextFormField(
            key: const ValueKey('email'),
            validator: (value) {
              if (value!.isEmpty || !value.contains('@')) {
                return 'Please enter a valid email address.';
              }
              return null;
            },
            onSaved: (value) {
              _email = value!;
            },
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            decoration: const InputDecoration(
              labelText: 'Email address',
            ),
          ),
          TextFormField(
            key: const ValueKey('password'),
            validator: (value) {
              if (value!.isEmpty || value.length < 7) {
                return 'Password must be at least 7 characters long.';
              }
              return null;
            },
            onSaved: (value) {
              _password = value!;
            },
            obscureText: !_passwordVisible,
            autofillHints: const [AutofillHints.password],
            decoration: InputDecoration(
              labelText: 'Password',
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
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _trySubmit,
            child: Text(_isLogin ? 'Login' : 'Signup'),
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
          const Divider(),
          ElevatedButton.icon(
            onPressed: () async {
              final authService = context.read<AuthService>();
              try {
                await authService.signInWithGoogle();
                widget.onAuthSuccess();
              } catch (e) {
                _showErrorDialog(e.toString());
              }
            },
            icon: Semantics(
              label: 'Google logo',
              child: Image.asset(
                'assets/google_logo.png',
                height: 24.0,
              ),
            ),
            label: const Text('Sign in with Google'),
          ),
        ],
      ),
    );
  }
}