import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BleScanScreen extends StatefulWidget {
  const BleScanScreen({super.key});

  @override
  State<BleScanScreen> createState() => _BleScanScreenState();
}

class _BleScanScreenState extends State<BleScanScreen> {
  List<ScanResult> _devices = [];
  bool _scanning = false;

  void _startScan() async {
    setState(() {
      _devices.clear();
      _scanning = true;
    });

    // Oprește orice scanare anterioară
    await FlutterBluePlus.stopScan();

    // Ascultă rezultatele scanării
    FlutterBluePlus.scanResults.listen((results) {
      setState(() {
        _devices = results;
      });
    });

    // Pornește scanarea pentru 5 secunde
    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));

    setState(() {
      _scanning = false;
    });
  }

  @override
  void dispose() {
    FlutterBluePlus.stopScan();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scanare BLE')),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: _scanning ? null : _startScan,
            child: Text(_scanning ? 'Scanare...' : 'Scanează BLE'),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _devices.length,
              itemBuilder: (context, index) {
                final device = _devices[index].device;
                return ListTile(
                  title: Text(device.platformName.isNotEmpty
                      ? device.platformName
                      : device.remoteId.str),
                  subtitle: Text(device.remoteId.str),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
// Aceasta este o aplicație simplă care scanează dispozitivele Bluetooth Low Energy (BLE) din apropiere.