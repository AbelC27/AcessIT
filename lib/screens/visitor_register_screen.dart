import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'dart:typed_data';
import '../screens/visitor_session_screen.dart';

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
  BluetoothDevice? _device;
  BluetoothConnection? _connection;
  bool _isConnected = false;
  String? _statusMessage;

  Future<void> _connectToESP32() async {
    setState(() {
      _statusMessage = null;
    });
    try {
      final devices = await FlutterBluetoothSerial.instance.getBondedDevices();
      // Afișează dialog pentru a alege device-ul
      final selectedDevice = await showDialog<BluetoothDevice>(
        context: context,
        builder: (context) => SimpleDialog(
          title: const Text('Selectează dispozitivul ESP32'),
          children: devices
              .map((d) => SimpleDialogOption(
                    child: Text(d.name ?? d.address),
                    onPressed: () => Navigator.pop(context, d),
                  ))
              .toList(),
        ),
      );

      if (selectedDevice == null) return;

      final connection = await BluetoothConnection.toAddress(selectedDevice.address);
      setState(() {
        _device = selectedDevice;
        _connection = connection;
        _isConnected = true;
        _statusMessage = "Conectat la ${selectedDevice.name}";
      });
    } catch (e) {
      setState(() {
        _statusMessage = "Eroare la conectare: $e";
        _isConnected = false;
      });
    }
  }

  Future<void> _sendTrueToESP32() async {
    try {
      if (_isConnected && _connection != null) {
        String message = "TRUE";
        _connection!.output.add(Uint8List.fromList(message.codeUnits));
        await _connection!.output.allSent;
      } else {
        throw Exception("Nu ești conectat la ESP32!");
      }
    } catch (e) {
      print('Eroare la trimiterea mesajului la ESP32: $e');
    }
  }

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
        'validated_by': 'c302e64d-601c-4cc2-895d-09648c83bbed',
      });

      // 3. Trimite mesajul "TRUE" la ESP32 prin Bluetooth
      await _sendTrueToESP32();

      // 4. Navighează la ecranul de sesiune vizitator
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
      appBar: AppBar(title: Text('Acces vizitator')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Nume Prenume'),
            ),
            TextField(
              controller: _licenseController,
              decoration: InputDecoration(labelText: 'Numarul masinii'),
            ),
            TextField(
              controller: _reasonController,
              decoration: InputDecoration(labelText: 'Motivul vizitei'),
            ),
            SizedBox(height: 20),
            ElevatedButton.icon(
              icon: Icon(_isConnected ? Icons.bluetooth_connected : Icons.bluetooth),
              label: Text(_isConnected ? 'Conectat la ESP32' : 'Conectează-te la ESP32'),
              onPressed: _isConnected ? null : _connectToESP32,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isConnected ? Colors.green : Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
            SizedBox(height: 20),
            _loading
                ? CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _isConnected ? _registerVisitor : null,
                    child: Text('Înregistrează Vizitator'),
                  ),
            if (_statusMessage != null) ...[
              SizedBox(height: 16),
              Text(
                _statusMessage!,
                style: TextStyle(
                  color: _isConnected ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}