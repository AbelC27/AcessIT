import 'package:flutter/material.dart';
import '../services/ble_service.dart';

class AccessRequestScreen extends StatefulWidget {
  final String accessCode;
  const AccessRequestScreen({super.key, required this.accessCode});

  @override
  State<AccessRequestScreen> createState() => _AccessRequestScreenState();
}

class _AccessRequestScreenState extends State<AccessRequestScreen> {
  final BLEService _bleService = BLEService();
  bool _sending = false;

  Future<void> _sendAccessCode() async {
    setState(() => _sending = true);
    bool ok = await _bleService.sendCodeOverBluetooth(widget.accessCode);
    setState(() => _sending = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok
            ? 'Cod trimis cu succes prin Bluetooth!'
            : 'Eroare la trimitere!'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Request Access')),
      body: Center(
        child: _sending
            ? CircularProgressIndicator()
            : ElevatedButton(
                onPressed: _sendAccessCode,
                child: Text('Trimite codul prin Bluetooth'),
              ),
      ),
    );
  }
}
