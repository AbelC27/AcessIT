import 'package:flutter/material.dart';
import 'bluetooth_send_screen.dart';

class BluetoothAccessScreen extends StatelessWidget {
  final String bluetoothCode;
  final String userName;

  const BluetoothAccessScreen({
    super.key,
    required this.bluetoothCode,
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Acces Bluetooth'),
        backgroundColor: theme.primaryColor,
        elevation: 0,
      ),
      body: Center(
        child: Card(
          elevation: 10,
          margin: const EdgeInsets.all(24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.bluetooth, color: Colors.indigo, size: 60),
                const SizedBox(height: 18),
                Text(
                  'Salut, $userName!',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Pentru a solicita acces, asigură-te că ești aproape de poartă și ai Bluetooth activat.',
                  style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  icon: const Icon(Icons.send),
                  label: const Text('Trimite codul Bluetooth'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 16),
                    textStyle: const TextStyle(fontSize: 18),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BluetoothSendScreen(
                          bluetoothCode: bluetoothCode,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 18),
                Text(
                  'Codul tău Bluetooth:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                SelectableText(
                  bluetoothCode,
                  style: TextStyle(
                    fontSize: 20,
                    color: theme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Dacă întâmpini probleme, contactează administratorul AccesIT.',
                  style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}