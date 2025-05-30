// screens/visitor_register_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../widgets/visitor_result_animation.dart';
import 'visitor_session_screen.dart';
class VisitorRegisterScreen extends StatefulWidget {
  const VisitorRegisterScreen({super.key});

  @override
  _VisitorRegisterScreenState createState() => _VisitorRegisterScreenState();
}

class _VisitorRegisterScreenState extends State<VisitorRegisterScreen> {
  final _nameController = TextEditingController();
  final _licenseController = TextEditingController();
  final _reasonController = TextEditingController();
  bool _loading = false;
Future<void> _registerVisitor() async {
  setState(() => _loading = true);
  final name = _nameController.text.trim();
  final license = _licenseController.text.trim();
  final reason = _reasonController.text.trim();
  final bleCode = DateTime.now().millisecondsSinceEpoch.toString();

  try {
    // 1. Salvează în Supabase și obține id-ul
    final response = await Supabase.instance.client.from('visitors').insert({
      'name': name,
      'license_plate': license,
      'reason': reason,
      'ble_temp_code': bleCode,
      'access_start': DateTime.now().toIso8601String(),
      'access_end': DateTime.now().add(Duration(hours: 2)).toIso8601String(),
    }).select().single();

    final visitorId = response['id'];

    // 2. Loghează intrarea în access_logs
    await Supabase.instance.client.from('access_logs').insert({
      'user_id': visitorId,
      'timestamp': DateTime.now().toIso8601String(),
      'direction': 'entry',
      'is_visitor': true,
    });

    // 3. Navighează la ecranul de sesiune vizitator
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => VisitorSessionScreen(
          visitorId: visitorId,
          name: name,
        ),
      ),
    );
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
      appBar: AppBar(title: Text('Visitor Access')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Full Name'),
            ),
            TextField(
              controller: _licenseController,
              decoration: InputDecoration(labelText: 'License Plate'),
            ),
            TextField(
              controller: _reasonController,
              decoration: InputDecoration(labelText: 'Reason for Visit'),
            ),
            SizedBox(height: 20),
            _loading
                ? CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _registerVisitor,
                    child: Text('Request Access'),
                  ),
          ],
        ),
      ),
    );
  }
}