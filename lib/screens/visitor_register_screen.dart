// Root: lib/screens/visitor_register_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
    final name = _nameController.text;
    final license = _licenseController.text;
    final reason = _reasonController.text;

    try {
      await Supabase.instance.client.from('visitors').insert({
        'name': name,
        'license_plate': license,
        'reason': reason,
        'ble_temp_code': DateTime.now().millisecondsSinceEpoch.toString(),
        'access_start': DateTime.now().toIso8601String(),
        'access_end': DateTime.now().add(Duration(hours: 2)).toIso8601String(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Access registered. Please proceed to gate.')),
      );
      Navigator.pop(context);
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
