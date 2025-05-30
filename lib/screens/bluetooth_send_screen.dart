import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'dart:typed_data';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../widgets/welcome_animation.dart';
import '../screens/home_screen.dart';

class BluetoothSendScreen extends StatefulWidget {
  final String bluetoothCode;
  const BluetoothSendScreen({super.key, required this.bluetoothCode});

  @override
  State<BluetoothSendScreen> createState() => _BluetoothSendScreenState();
}

class _BluetoothSendScreenState extends State<BluetoothSendScreen> {
  BluetoothDevice? _device;
  BluetoothConnection? _connection;
  bool _isConnected = false;
  bool _sending = false;
  String? _statusMessage;
  String? _esp32Response;
  String? _webResponse;

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
    setState(() {
      _statusMessage = null;
    });
    final BluetoothDevice? selectedDevice =
        await FlutterBluetoothSerial.instance
            .getBondedDevices()
            .then((devices) => showDialog<BluetoothDevice>(
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
                ));

    if (selectedDevice != null) {
      setState(() {
        _device = selectedDevice;
        _statusMessage = "Se conectează la ${_device!.name}...";
      });
      BluetoothConnection.toAddress(_device!.address).then((connection) {
        setState(() {
          _connection = connection;
          _isConnected = true;
          _statusMessage = "Conectat la ${_device!.name}";
        });
        _connection!.input?.listen(_onDataReceived).onDone(() {
          setState(() {
            _isConnected = false;
            _statusMessage = "Deconectat de la ESP32";
          });
        });
      }).catchError((error) {
        setState(() {
          _statusMessage = "Eroare la conectare: $error";
        });
      });
    }
  }

  void _onDataReceived(Uint8List data) {
    String response = String.fromCharCodes(data).trim();
    setState(() {
      _esp32Response = response;
      if (response.contains("ACCESS_GRANTED")) {
        _statusMessage = "Acces cu mașina PERMIS!";
        _showWelcomeAndNavigate(""); // Poți pune numele userului dacă îl ai
      } else if (response.contains("ACCESS_DENIED")) {
        _statusMessage = "Acces cu mașina RESPINS!";
      } else {
        _statusMessage = "Răspuns ESP32: $response";
      }
    });
  }

  Future<void> _sendBluetoothCode() async {
    if (_isConnected && _connection != null) {
      setState(() {
        _sending = true;
        _statusMessage = "Se trimite codul...";
        _esp32Response = null;
      });
      String code = widget.bluetoothCode;
      _connection!.output.add(Uint8List.fromList(code.codeUnits));
      await _connection!.output.allSent;
      setState(() {
        _sending = false;
        _statusMessage = "Bluetooth Code trimis! Aștept răspuns de la ESP32...";
      });
    } else {
      setState(() {
        _statusMessage = "Nu ești conectat la ESP32!";
      });
    }
  }

  Future<void> _sendCodeToWeb() async {
    setState(() {
      _sending = true;
      _webResponse = null;
      _statusMessage = "Se trimite codul la server...";
    });

    try {
      final url = Uri.parse('http://192.168.1.134:8000/validate/');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'ble_code': widget.bluetoothCode}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _webResponse = data['status'] == 'granted'
              ? "Acces pietonal PERMIS!"
              : "Acces pietonal RESPINS!";
          _statusMessage = _webResponse;
          if (data['status'] == 'granted') {
            _showWelcomeAndNavigate(data['user'] ?? "");
          }
        });
      } else {
        setState(() {
          _webResponse = "Eroare server: ${response.statusCode}";
          _statusMessage = _webResponse;
        });
      }
    } catch (e) {
      setState(() {
        _webResponse = "Eroare la trimitere: $e";
        _statusMessage = _webResponse;
      });
    } finally {
      setState(() {
        _sending = false;
      });
    }
  }

  void _showWelcomeAndNavigate(String userName) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => WelcomeAnimation(userName: userName),
    );
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      Navigator.of(context).pop(); // închide dialogul
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => HomeScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trimite Bluetooth Code'),
        backgroundColor: theme.primaryColor,
        elevation: 0,
      ),
      body: Center(
        child: Card(
          elevation: 8,
          margin: const EdgeInsets.all(24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _isConnected ? Icons.bluetooth_connected : Icons.bluetooth,
                  color: _isConnected ? Colors.blue : Colors.grey,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  _isConnected
                      ? 'Conectat la: ${_device?.name ?? ""}'
                      : 'Nu ești conectat',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                Text(
                  'Bluetooth Code:',
                  style: theme.textTheme.bodyLarge!
                      .copyWith(fontWeight: FontWeight.bold),
                ),
                SelectableText(
                  widget.bluetoothCode,
                  style: theme.textTheme.headlineSmall!
                      .copyWith(color: theme.primaryColor),
                ),
                const SizedBox(height: 24),
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.bluetooth_searching),
                        label: Text(_isConnected
                            ? 'Reconectează'
                            : 'Conectează-te la ESP32'),
                        onPressed: _connect,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 14),
                          textStyle: const TextStyle(fontSize: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.directions_car),
                        label: const Text('Acces cu mașina'),
                        onPressed: _isConnected && !_sending
                            ? _sendBluetoothCode
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 14),
                          textStyle: const TextStyle(fontSize: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.directions_walk),
                        label: const Text('Acces pietonal'),
                        onPressed: !_sending ? _sendCodeToWeb : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 14),
                          textStyle: const TextStyle(fontSize: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                if (_statusMessage != null)
                  Text(
                    _statusMessage!,
                    style: TextStyle(
                      color: _statusMessage!.contains('Eroare') ||
                              _statusMessage!.contains('RESPINS')
                          ? Colors.red
                          : Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                if (_sending) const SizedBox(height: 16),
                if (_sending) const CircularProgressIndicator(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}