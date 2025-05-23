// reset_password_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _passwordController = TextEditingController();
  bool _loading = false;

  Future<void> _resetPassword() async {
    setState(() => _loading = true);
    try {
      final res = await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: _passwordController.text.trim()),
      );
      if (res.user != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Password reset successfully!')),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: Unable to reset password')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Set New Password')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'New Password'),
              obscureText: true,
            ),
            SizedBox(height: 20),
            _loading
                ? CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _resetPassword,
                    child: Text('Reset Password'),
                  ),
          ],
        ),
      ),
    );
  }
}
