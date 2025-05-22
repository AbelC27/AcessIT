import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

class BleConnectScreen extends StatefulWidget {
  const BleConnectScreen({super.key});

  @override
  State<BleConnectScreen> createState() => _BleConnectScreenState();
}

class _BleConnectScreenState extends State<BleConnectScreen> {
  BluetoothDevice? _espDevice;
  bool _connecting = false;
  String _status = '';

  Future<void> _scanAndConnect() async {
    setState(() {
      _status = 'Scanare...';
      _connecting = true;
    });

    final bluetooth = FlutterBluetoothSerial.instance;

    // Pornește Bluetooth dacă nu e pornit
    if (!(await bluetooth.isEnabled ?? false)) {
      await bluetooth.requestEnable();
    }

    // Caută device-urile deja împerecheate
    List<BluetoothDevice> devices = await bluetooth.getBondedDevices();
    BluetoothDevice? espDevice = devices.firstWhere(
      (d) => d.name == "ESP32_GATE",
    );

    if (espDevice == null) {
      setState(() {
        _status = 'ESP32_GATE nu este împerecheat! Împerechează-l din setările Bluetooth.';
        _connecting = false;
      });
      return;
    }

    setState(() {
      _status = 'Se conectează la ${espDevice.name}...';
    });

    try {
      BluetoothConnection connection =
          await BluetoothConnection.toAddress(espDevice.address);
      setState(() {
        _status = 'Conectat la ${espDevice.name}!';
        _espDevice = espDevice;
      });
      await connection.close();
    } catch (e) {
      setState(() {
        _status = 'Eroare la conectare: $e';
      });
    } finally {
      setState(() {
        _connecting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Conectare ESP32')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_status),
            SizedBox(height: 20),
            _connecting
                ? CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _scanAndConnect,
                    child: Text('Conectează la ESP32_GATE'),
                  ),
          ],
        ),
      ),
    );
  }
}
