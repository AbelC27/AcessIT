import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'dart:typed_data';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
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

  Future<bool> isEmployeeInside(String employeeId) async {
    try {
      print('Verific statusul pentru employeeId: $employeeId');
      
      final logs = await Supabase.instance.client
          .from('access_logs')
          .select('direction, timestamp, employee_id')
          .eq('employee_id', employeeId)
          .order('timestamp', ascending: false)
          .limit(1);

      print('Query rezultat pentru angajatul $employeeId: $logs');
      print('Tipul rezultatului: ${logs.runtimeType}');
      
      if (logs is List && logs.isNotEmpty) {
        final lastDirection = logs[0]['direction'];
        print('Ultima direcție găsită: "$lastDirection"');
        print('Timestamp: ${logs[0]['timestamp']}');
        
        // Verifică exact ce string ai în baza de date
        final isInside = lastDirection == 'entry';
        print('Comparația "$lastDirection" == "entry" = $isInside');
        return isInside;
      }
      
      print('Nu există loguri pentru angajatul $employeeId');
      return false;
    } catch (e) {
      print('Eroare la verificarea statusului angajatului: $e');
      return false;
    }
  }

  Future<void> logEmployeeAccess({
    required String employeeId,
    required String direction,
    String? bluetoothCode,
  }) async {
    await Supabase.instance.client.from('access_logs').insert({
      'employee_id': employeeId,
      'timestamp': DateTime.now().toIso8601String(),
      'direction': direction,
      'is_visitor': false,
      'bluetooth_code': bluetoothCode,
    });
  }

  void _onAccessButtonPressed() async {
    final employee = await Supabase.instance.client
        .from('employees')
        .select('id, name')
        .eq('bluetooth_code', widget.bluetoothCode)
        .maybeSingle();

    if (employee == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Angajatul nu a fost găsit!')),
      );
      return;
    }

    final employeeId = employee['id'];
    final inside = await isEmployeeInside(employeeId);

    if (inside) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ești deja înăuntru! Folosește butonul "Ieși din firmă" pentru a ieși.')),
      );
      return;
    } else {
      await _sendBluetoothCode();
      // Logarea accesului se face în _onDataReceived după ce primești ACCESS_GRANTED
    }
  }

  void _onDataReceived(Uint8List data) async {
    String response = String.fromCharCodes(data).trim();
    setState(() {
      _esp32Response = response;
    });
    
    if (response.contains("ACCESS_GRANTED")) {
      final employee = await Supabase.instance.client
          .from('employees')
          .select('id, name')
          .eq('bluetooth_code', widget.bluetoothCode)
          .maybeSingle();

      if (employee != null) {
        final employeeId = employee['id'];
        final inside = await isEmployeeInside(employeeId);
        
        if (!inside) {
          await logEmployeeAccess(
            employeeId: employeeId,
            direction: 'entry',
            bluetoothCode: widget.bluetoothCode,
          );
          _showWelcomeAndNavigate(employee['name'] ?? "");
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ești deja înăuntru! Folosește butonul "Ieși din firmă" pentru a ieși.')),
          );
        }
      }
    } else if (response.contains("ACCESS_DENIED")) {
      setState(() {
        _statusMessage = "Acces cu mașina RESPINS!";
      });
    } else {
      setState(() {
        _statusMessage = "Răspuns ESP32: $response";
      });
    }
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
    // Verifică statusul înainte să trimiți codul
    final employee = await Supabase.instance.client
        .from('employees')
        .select('id, name')
        .eq('bluetooth_code', widget.bluetoothCode)
        .maybeSingle();

    if (employee != null) {
      final employeeId = employee['id'];
      final inside = await isEmployeeInside(employeeId);
      
      if (inside) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ești deja înăuntru! Folosește butonul "Ieși din firmă" pentru a ieși.')),
        );
        return;
      }
    }

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
        });

        if (data['status'] == 'granted' && employee != null) {
          final employeeId = employee['id'];
          final inside = await isEmployeeInside(employeeId);
          
          if (!inside) {
            await logEmployeeAccess(
              employeeId: employeeId,
              direction: 'entry',
              bluetoothCode: widget.bluetoothCode,
            );
            _showWelcomeAndNavigate(data['user'] ?? "");
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Ești deja înăuntru! Folosește butonul "Ieși din firmă" pentru a ieși.')),
            );
          }
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

  Future<void> logEmployeeExit({
    required String employeeId,
    String? bluetoothCode,
  }) async {
    try {
      print('Încerc să logez ieșirea pentru employee ID: $employeeId');
      
      final result = await Supabase.instance.client.from('access_logs').insert({
        'employee_id': employeeId,
        'timestamp': DateTime.now().toIso8601String(),
        'direction': 'exit',
        'is_visitor': false,
        'bluetooth_code': bluetoothCode,
      });
      
      print('Rezultat insert exit: $result');
      print('Exit logged successfully pentru employee: $employeeId');
    } catch (e) {
      print('Eroare la logging exit: $e');
    }
  }

  void _onCarExitButtonPressed() async {
    print('Car exit button pressed - începe procesul de ieșire cu mașina');
    
    try {
      final employee = await Supabase.instance.client
          .from('employees')
          .select('id, name')
          .eq('bluetooth_code', widget.bluetoothCode)
          .maybeSingle();

      if (employee == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Angajatul nu a fost găsit!')),
        );
        return;
      }

      final employeeId = employee['id'];
      final inside = await isEmployeeInside(employeeId);

      // TEMPORAR: Permite ieșirea chiar dacă nu este înăuntru (pentru testare)
      // if (!inside) {
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     SnackBar(content: Text('Nu ești în firmă! Folosește butonul de acces pentru a intra.')),
      //   );
      //   return;
      // }

      // Trimite comanda de ieșire prin Bluetooth
      setState(() {
        _sending = true;
        _statusMessage = "Se trimite comanda de ieșire cu mașina...";
      });

      if (_isConnected && _connection != null) {
        String exitCommand = "EXIT_CAR_${widget.bluetoothCode}";
        _connection!.output.add(Uint8List.fromList(exitCommand.codeUnits));
        await _connection!.output.allSent;
        
        setState(() {
          _statusMessage = "Comandă de ieșire trimisă! Aștept răspuns de la ESP32...";
        });

        // Simulează răspuns pozitiv după 2 secunde (înlocuiește cu logica reală)
        await Future.delayed(Duration(seconds: 2));
        
        await logEmployeeExit(
          employeeId: employeeId,
          bluetoothCode: widget.bluetoothCode,
        );

        _showExitAnimation(employee['name']);
      } else {
        setState(() {
          _statusMessage = "Nu ești conectat la ESP32!";
          _sending = false;
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = "Eroare la ieșire cu mașina: $e";
        _sending = false;
      });
    }
  }

  void _onPedestrianExitButtonPressed() async {
    print('Pedestrian exit button pressed - începe procesul de ieșire pietonală');
    
    try {
      final employee = await Supabase.instance.client
          .from('employees')
          .select('id, name')
          .eq('bluetooth_code', widget.bluetoothCode)
          .maybeSingle();

      if (employee == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Angajatul nu a fost găsit!')),
        );
        return;
      }

      final employeeId = employee['id'];
      final inside = await isEmployeeInside(employeeId);

      // TEMPORAR: Permite ieșirea chiar dacă nu este înăuntru (pentru testare)
      // if (!inside) {
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     SnackBar(content: Text('Nu ești în firmă! Folosește butonul de acces pentru a intra.')),
      //   );
      //   return;
      // }

      setState(() {
        _sending = true;
        _statusMessage = "Se trimite comanda de ieșire pietonală...";
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
            _statusMessage = data['status'] == 'granted'
                ? "Ieșire pietonală PERMISĂ!"
                : "Ieșire pietonală RESPINSĂ!";
          });

          if (data['status'] == 'granted') {
            await logEmployeeExit(
              employeeId: employeeId,
              bluetoothCode: widget.bluetoothCode,
            );
            _showExitAnimation(employee['name']);
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
    } catch (e) {
      setState(() {
        _statusMessage = "Eroare la ieșire pietonală: $e";
        _sending = false;
      });
    }
  }

  void _showExitAnimation(String userName) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => WelcomeAnimation(userName: "La revedere, $userName!"),
    );
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      Navigator.of(context).pop();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => HomeScreen()),
        (route) => false,
      );
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
                            ? _onAccessButtonPressed
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
                    const SizedBox(height: 24),
                    // Separator pentru butoanele de ieșire
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
                        icon: const Icon(Icons.car_rental),
                        label: const Text('Ieșire cu mașina'),
                        onPressed: _isConnected && !_sending
                            ? _onCarExitButtonPressed
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
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
                        icon: const Icon(Icons.exit_to_app),
                        label: const Text('Ieșire pietonală'),
                        onPressed: !_sending ? _onPedestrianExitButtonPressed : null,
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
    );
  }
}