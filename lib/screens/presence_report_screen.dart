import 'package:flutter/material.dart';
import '../models/access_log_model.dart';
import 'package:intl/intl.dart';

class PresenceReportScreen extends StatelessWidget {
  final List<AccessLog> logs;

  const PresenceReportScreen({super.key, required this.logs});

  String _formatDateTime(DateTime dt) {
    // Exemplu: 2025-05-11 17:35
    return DateFormat('yyyy-MM-dd HH:mm').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Raport prezență'),
        backgroundColor: const Color.fromARGB(255, 176, 140, 235),
      ),
      body: logs.isEmpty
          ? Center(
              child: Text(
                'Nu există înregistrări de acces.',
                style: TextStyle(fontSize: 18, color: Colors.grey[600]),
              ),
            )
          : ListView.separated(
              itemCount: logs.length,
              separatorBuilder: (_, __) => Divider(height: 1),
              itemBuilder: (context, index) {
                final log = logs[index];
                final isEntry = log.direction == 'entry';
                final icon = isEntry ? Icons.login : Icons.logout;
                final color = isEntry ? Colors.green : Colors.red;
                final type = log.isVisitor ? 'Vizitator' : 'Angajat';
                final validator = log.validatorName ?? 'Automat/ESP32';

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: color.withOpacity(0.15),
                    child: Icon(icon, color: color),
                  ),
                  title: Text(
                    isEntry ? 'Intrare' : 'Ieșire',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Data și ora: ${_formatDateTime(log.timestamp)}'),
                      Text('Tip: $type'),
                      if (log.validatorName != null)
                        Text('Validat de: $validator'),
                    ],
                  ),
                  trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
                );
              },
            ),
    );
  }
}