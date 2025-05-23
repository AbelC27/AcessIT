// presence_report_screen.dart
import 'package:flutter/material.dart';
import '../models/access_log_model.dart';

class PresenceReportScreen extends StatelessWidget {
  final List<AccessLog> logs;

  const PresenceReportScreen({super.key, required this.logs});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: logs.isEmpty
          ? Center(child: Text('No access records available.'))
          : ListView.builder(
              itemCount: logs.length,
              itemBuilder: (context, index) {
                final log = logs[index];
                return ListTile(
                  leading: Icon(
                      log.direction == 'entry' ? Icons.login : Icons.logout),
                  title: Text(
                    '${log.direction.toUpperCase()} - ${log.timestamp.toLocal()}'
                        .split('.')
                        .first,
                  ),
                  subtitle: Text(log.isVisitor ? 'Visitor' : 'Employee'),
                );
              },
            ),
    );
  }
}
