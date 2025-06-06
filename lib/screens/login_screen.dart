// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;

  Future<void> _login() async {
    setState(() => _loading = true);
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      print('Login result: ${response.user?.id ?? 'null'}');

      if (response.user != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => HomeScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Eroare la logare}')),
        );
      }
    } catch (e) {
      print('Eroare la logare: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

Future<void> _sendResetPasswordEmail() async {
  final email = _emailController.text.trim();
  if (email.isNotEmpty) {
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(
        email,
        redirectTo: 'parkaccess://reset-password?email=$email',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Email de resetare trimis! Verifică-ți inbox-ul.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Eroare la trimiterea de resetare: $e')),
      );
    }
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Te rog introdu un email valid.')),  
    );
  }
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/logo.png',
            ),
            SizedBox(height: 60),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Parola'),
              obscureText: true,
            ),
            SizedBox(height: 20),
            _loading
                ? CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _login,
                    child: Text('Login'),
                  ),
            SizedBox(height: 20),
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/visitor-register');
              },
              child: Text("Înregistrare Vizitator"),
            ),
            TextButton(
              onPressed: _sendResetPasswordEmail,
              child: Text('Ai uitat parola?'),
            ),
          ],
        ),
      ),
    );
  }
}