import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'dart:convert';

class BLEService {
  static const String deviceName = "ESP32_GATE";

  Future<bool> sendCodeOverBluetooth(String code) async {
    final bluetooth = FlutterBluetoothSerial.instance;

    if (!(await bluetooth.isEnabled ?? false)) {
      await bluetooth.requestEnable();
    }

    List<BluetoothDevice> devices = await bluetooth.getBondedDevices();
    BluetoothDevice? espDevice;
    try {
      espDevice = devices.firstWhere(
        (d) => d.name == deviceName,
      );
    } catch (e) {
      // Device not found
      espDevice = null;
    }

    if (espDevice == null) return false;

    try {
      BluetoothConnection connection =
          await BluetoothConnection.toAddress(espDevice.address);
      connection.output.add(utf8.encode("$code\n"));
      await connection.output.allSent;
      await connection.close();
      return true;
    } catch (e) {
      return false;
    }
  }
}
