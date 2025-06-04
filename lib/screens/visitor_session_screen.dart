import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'dart:typed_data';

class VisitorSessionScreen extends StatefulWidget {
  final int visitorId; // id-ul vizitatorului din baza de date
  final String name;

  const VisitorSessionScreen({super.key, required this.visitorId, required this.name});

  @override
  State<VisitorSessionScreen> createState() => _VisitorSessionScreenState();
}

class _VisitorSessionScreenState extends State<VisitorSessionScreen> {
  bool _loading = false;
  bool _hasExited = false;
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
        String message = "TRUE"; // sau "EXIT" dacă vrei să diferențiezi
        _connection!.output.add(Uint8List.fromList(message.codeUnits));
        await _connection!.output.allSent;
      } else {
        throw Exception("Nu ești conectat la ESP32!");
      }
    } catch (e) {
      print('Eroare la trimiterea mesajului la ESP32: $e');
    }
  }

  Future<void> _logExit() async {
    setState(() => _loading = true);
    try {
      // 1. Actualizează access_end în tabela visitors
      await Supabase.instance.client.from('visitors').update({
        'access_end': DateTime.now().toIso8601String(),
      }).eq('id', widget.visitorId);

      // 2. Loghează ieșirea în access_logs
      await Supabase.instance.client.from('access_logs').insert({
        'user_id': widget.visitorId,
        'timestamp': DateTime.now().toIso8601String(),
        'direction': 'exit',
        'is_visitor': true,
        'validated_by': 'c302e64d-601c-4cc2-895d-09648c83bbed',
      });

      // 3. Trimite mesajul "TRUE" la ESP32
      await _sendTrueToESP32();

      setState(() {
        _hasExited = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ieșirea a fost înregistrată. Mulțumim pentru vizită!')),
      );
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Eroare la înregistrarea ieșirii: $e')),
      );
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Vizită în desfășurare')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: _hasExited
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 80),
                    SizedBox(height: 16),
                    Text('Vizita ta s-a încheiat. O zi bună!', style: TextStyle(fontSize: 18)),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Bun venit, ${widget.name}!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    SizedBox(height: 24),
                    Text('Când părăsești firma, conectează-te la ESP32 și apasă butonul de mai jos pentru a înregistra ieșirea.'),
                    SizedBox(height: 32),
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
                        : ElevatedButton.icon(
                            icon: Icon(Icons.exit_to_app),
                            label: Text('Ieși din firmă'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                              textStyle: TextStyle(fontSize: 18),
                            ),
                            onPressed: _isConnected ? _logExit : null,
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
      ),
    );
  }
}