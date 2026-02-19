import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
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
                  final shouldDelete = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete Account'),
                      content: const Text(
                        'Are you sure you want to delete your account? This action cannot be undone.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );

                  if (!context.mounted) return;

                  if (shouldDelete == true) {
                    final messenger = ScaffoldMessenger.of(context);
                    try {
                      await authService.deleteUser();
                      // Navigation handled by auth state change listener in AppRouter
                    } on FirebaseAuthException catch (e) {
                      if (!context.mounted) return;
                      if (e.code == 'requires-recent-login') {
                        // Handle re-authentication
                        final user = authService.currentUser;
                        if (user != null) {
                          bool reauthSuccess = false;
                          if (user.providerData.any((p) => p.providerId == 'google.com')) {
                             try {
                               await authService.reauthenticateWithGoogle();
                               reauthSuccess = true;
                             } catch (reauthError) {
                               messenger.showSnackBar(
                                 SnackBar(content: Text('Re-authentication failed: $reauthError')),
                               );
                             }
                          } else if (user.providerData.any((p) => p.providerId == 'password')) {
                            // Prompt for password
                            final passwordController = TextEditingController();
                            final passwordFormKey = GlobalKey<FormState>();
                            await showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Re-authentication Required'),
                                content: Form(
                                  key: passwordFormKey,
                                  child: TextFormField(
                                    controller: passwordController,
                                    obscureText: true,
                                    decoration: const InputDecoration(labelText: 'Password'),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter your password';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      if (passwordFormKey.currentState!.validate()) {
                                        try {
                                          final password = passwordController.text;
                                          // Capture navigator to pop dialog
                                          final navigator = Navigator.of(context); 
                                          await authService.reauthenticateWithEmailAndPassword(password);
                                          reauthSuccess = true;
                                          navigator.pop();
                                        } catch (reauthError) {
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('Re-authentication failed: $reauthError')),
                                            );
                                          }
                                        }
                                      }
                                    },
                                    child: const Text('Confirm'),
                                  ),
                                ],
                              ),
                            );
                          }

                          if (reauthSuccess) {
                            try {
                              await authService.deleteUser();
                              // Navigation handled by auth state change listener in AppRouter
                            } catch (retryError) {
                               messenger.showSnackBar(
                                SnackBar(content: Text('Error deleting account after re-auth: $retryError')),
                              );
                            }
                          }
                        }
                      } else {
                        messenger.showSnackBar(
                          SnackBar(content: Text('Error deleting account: ${e.message}')),
                        );
                      }
                    } catch (e) {
                      messenger.showSnackBar(
                        SnackBar(content: Text('Error deleting account: $e')),
                      );
                    }
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
