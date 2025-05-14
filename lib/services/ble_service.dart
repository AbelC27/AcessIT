import 'dart:async';
import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class BLEService {
  static const String bleDeviceName = 'ESP32_GATE';
  static const String bleServiceUuid = '12345678-1234-5678-1234-56789abcdef0';
  static const String bleCharacteristicUuid = 'abcdef12-3456-7890-abcd-ef1234567890';
Future<bool> sendCodeOverBLE(String code) async {
  try {
    await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();

    await FlutterBluePlus.stopScan();

    bool found = false;
    late final StreamSubscription scanSubscription;
    scanSubscription = FlutterBluePlus.scanResults.listen((results) async {
      for (ScanResult r in results) {
        if (r.device.platformName == bleDeviceName) {
          found = true;
          await FlutterBluePlus.stopScan();
          await scanSubscription.cancel();

          try {
            await r.device.connect();
            List<BluetoothService> services = await r.device.discoverServices();
            for (BluetoothService service in services) {
              if (service.uuid.toString().toLowerCase() == bleServiceUuid.toLowerCase()) {
                for (BluetoothCharacteristic c in service.characteristics) {
                  if (c.uuid.toString().toLowerCase() == bleCharacteristicUuid.toLowerCase() &&
                      c.properties.write) {
                    await c.write(utf8.encode(code));
                  }
                }
              }
            }
            await r.device.disconnect();
          } catch (e) {
            // Poți trata erorile aici
          }
          return;
        }
      }
    });

    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));
    await scanSubscription.cancel();

    return found;
  } catch (e) {
    // Poți loga sau returna false
    return false;
  }
}

}
