// screens/visitor_register_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'dart:typed_data';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  bool _isInside = false; // variabilă locală pentru starea de "în firmă"

  @override
  void initState() {
    super.initState();
    _askPermissions();
    _loadIsInside();
  }

  Future<void> _askPermissions() async {
    await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();
  }

  Future<void> _saveIsInside(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isInside', value);
  }

  Future<void> _loadIsInside() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isInside = prefs.getBool('isInside') ?? false;
    });
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

  // Pentru "Acces cu mașina" trimitem direct la web
  void _onAccessButtonPressed() async {
    if (_isInside) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ești deja înăuntru! Folosește butonul "Ieși din firmă" pentru a ieși.')),
      );
      return;
    }
    await _sendCodeToWeb(isCar: true);
  }

  // Pentru "Acces pietonal" folosești direct _sendCodeToWeb(isCar: false)
  // (vezi butonul din build)

  // Poți păstra funcția pentru debugging, dar nu mai folosești răspunsul ESP32 pentru acces
  void _onDataReceived(Uint8List data) async {
    String response = String.fromCharCodes(data).trim();
    setState(() {
      _esp32Response = response;
      _statusMessage = "Răspuns ESP32: $response";
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
        _statusMessage = "Bluetooth Code trimis!";
      });
    } else {
      setState(() {
        _statusMessage = "Nu ești conectat la ESP32!";
      });
    }
  }

  Future<void> _sendCodeToWeb({bool isCar = false}) async {
    if (_isInside) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ești deja înăuntru! Folosește butonul "Ieși din firmă" pentru a ieși.')),
      );
      return;
    }

    setState(() {
      _sending = true;
      _webResponse = null;
      _statusMessage = "Se trimite codul la server...";
    });

    try {
      final url = Uri.parse('http://192.168.127.234:3000/verify-access-from-mobile/');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'ble_code': widget.bluetoothCode,
          'type': isCar ? 'car' : 'pedestrian',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _webResponse = data['granted'] == true
              ? (isCar ? "Acces cu mașina PERMIS!" : "Acces pietonal PERMIS!")
              : (isCar ? "Acces cu mașina RESPINS!" : "Acces pietonal RESPINS!");
          _statusMessage = _webResponse;
        });

        if (data['granted'] == true) {
          setState(() {
            _isInside = true;
          });
          await _saveIsInside(true);
          _showWelcomeAndNavigate(data['user'] ?? "");
        }
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

  // NOU: Trimitere ieșire la web
  Future<void> _sendExitToWeb() async {
    setState(() {
      _sending = true;
      _statusMessage = "Se trimite cererea de ieșire la server...";
    });

    try {
      final url = Uri.parse('http://192.168.127.234:3000/verify-access-from-mobile/');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'ble_code': widget.bluetoothCode,
          'direction': 'exit',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['can_exit'] == true) {
          setState(() {
            _isInside = false;
          });
          await _saveIsInside(false);

          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => WelcomeAnimation(userName: data['message'] ?? "La revedere!"),
          );
          await Future.delayed(const Duration(seconds: 2));
          if (mounted) {
            Navigator.of(context).pop(); // închide dialogul
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => HomeScreen()),
              (route) => false,
            );
          }
        } else {
          setState(() {
            _statusMessage = data['message'] ?? "Nu poți ieși!";
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message'] ?? "Nu poți ieși!")),
          );
        }
      } else {
        setState(() {
          _statusMessage = "Eroare server: ${response.statusCode}";
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = "Eroare la trimitere: $e";
      });
    } finally {
      setState(() {
        _sending = false;
      });
    }
  }

  void _onExitButtonPressed() async {
    if (!_isInside) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nu ești în firmă!')),
      );
      return;
    }
    await _sendExitToWeb();
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
        child: SingleChildScrollView(
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
                              ? _onAccessButtonPressed
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromARGB(255, 213, 220, 255),
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
                          onPressed: !_sending ? () => _sendCodeToWeb(isCar: false) : null,
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
                      const SizedBox(height: 24),
                      const Divider(thickness: 2),
                      const SizedBox(height: 16),
                      Text(
                        'IEȘIRE DIN FIRMĂ',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red[700],
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.exit_to_app),
                          label: const Text('Ieși din firmă'),
                          onPressed: _onExitButtonPressed,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
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
      ),
    );
  }
}