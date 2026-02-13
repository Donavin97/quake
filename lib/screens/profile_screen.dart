import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _passwordVisible = false;

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'New Email'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your new email';
                  }
                  return null;
                },
              ),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    final messenger = ScaffoldMessenger.of(context);
                    try {
                      await authService.updateEmail(_emailController.text);
                      messenger.showSnackBar(
                        const SnackBar(content: Text('Verification email sent')),
                      );
                    } catch (e) {
                      messenger.showSnackBar(
                        SnackBar(content: Text('Error updating email: $e')),
                      );
                    }
                  }
                },
                child: const Text('Update Email'),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'New Password',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _passwordVisible ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _passwordVisible = !_passwordVisible;
                      });
                    },
                  ),
                ),
                obscureText: !_passwordVisible,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your new password';
                  }
                  return null;
                },
              ),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    final messenger = ScaffoldMessenger.of(context);
                    try {
                      await authService.updatePassword(_passwordController.text);
                      messenger.showSnackBar(
                        const SnackBar(content: Text('Password updated successfully')),
                      );
                    } catch (e) {
                      messenger.showSnackBar(
                        SnackBar(content: Text('Error updating password: $e')),
                      );
                    }
                  }
                },
                child: const Text('Update Password'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  final router = GoRouter.of(context);
                  final messenger = ScaffoldMessenger.of(context);
                  try {
                    await authService.deleteUser();
                    router.go('/auth');
                  } catch (e) {
                    messenger.showSnackBar(
                      SnackBar(content: Text('Error deleting account: $e')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Delete Account'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
