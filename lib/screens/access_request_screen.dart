import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'dart:typed_data';
import 'package:permission_handler/permission_handler.dart';

class AccessRequestScreen extends StatefulWidget {
  final String accessCode;
  const AccessRequestScreen({super.key, required this.accessCode});

  @override
  State<AccessRequestScreen> createState() => _AccessRequestScreenState();
}

class _AccessRequestScreenState extends State<AccessRequestScreen> {
  BluetoothDevice? _device;
  BluetoothConnection? _connection;
  bool _isConnected = false;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _askPermissions();
  }

  Future<void> _askPermissions() async {
    await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();
  }

  Future<void> _connect() async {
    final BluetoothDevice? selectedDevice =
        await FlutterBluetoothSerial.instance
            .getBondedDevices()
            .then((devices) => showDialog<BluetoothDevice>(
                  context: context,
                  builder: (context) => SimpleDialog(
                    title: Text('Selectează dispozitivul ESP32'),
                    children: devices
                        .map((d) => SimpleDialogOption(
                              child: Text(d.name ?? d.address),
                              onPressed: () => Navigator.pop(context, d),
                            ))
                        .toList(),
                  ),
                ));

    if (selectedDevice != null) {
      setState(() {
        _device = selectedDevice;
      });
      BluetoothConnection.toAddress(_device!.address).then((connection) {
        setState(() {
          _connection = connection;
          _isConnected = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Conectat la ${_device!.name}')),
        );
      }).catchError((error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Eroare la conectare: $error')),
        );
      });
    }
  }

  Future<void> _sendAccessCode() async {
    if (_isConnected && _connection != null) {
      setState(() => _sending = true);
      String text = widget.accessCode;
      _connection!.output.add(Uint8List.fromList(text.codeUnits));
      await _connection!.output.allSent;
      setState(() => _sending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cod trimis: $text')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nu ești conectat la ESP32!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Request Access')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _connect,
              child: Text(_isConnected
                  ? 'Conectat la ${_device?.name ?? ""}'
                  : 'Conectează-te la ESP32'),
            ),
            SizedBox(height: 24),
            _sending
                ? CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _isConnected ? _sendAccessCode : null,
                    child: Text('Trimite codul prin Bluetooth'),
                  ),
          ],
        ),
      ),
    );
  }
}