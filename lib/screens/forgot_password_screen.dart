// forgot_password_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gotrue/gotrue.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _loading = false;

  Future<void> _sendResetEmail() async {
    setState(() => _loading = true);
    final email = _emailController.text.trim();
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(
  email,
  redirectTo: 'parkaccess://reset-password?email=$email',
);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Verifică emailul pentru linkul de resetare!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Eroare la trimiterea emailului: $e')),
      );
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Am uitat parola')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: 20),
            _loading
                ? CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _sendResetEmail,
                    child: Text('Trimite email de resetare'),
                  ),
          ],
        ),
      ),
    );
  }
}