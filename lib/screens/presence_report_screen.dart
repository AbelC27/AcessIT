//presence report screen
// Root: lib/screens/presence_report_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/access_log_model.dart';
import '../services/local_storage_service.dart';

class PresenceReportScreen extends StatefulWidget {
  const PresenceReportScreen({super.key});

  @override
  State<PresenceReportScreen> createState() => _PresenceReportScreenState();
}

class _PresenceReportScreenState extends State<PresenceReportScreen> {
  List<AccessLog> _logs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchLogs();
  }

  Future<void> _fetchLogs() async {
    try {
      final sessionUser = Supabase.instance.client.auth.currentUser;
      if (sessionUser == null) return;

      final employee = await Supabase.instance.client
          .from('employees')
          .select('id')
          .eq('id', sessionUser.id)
          .maybeSingle();

      final uuid = employee?['id'];
      if (uuid == null) return;

      final response = await Supabase.instance.client
          .from('access_logs')
          .select()
          .eq('employee_id', uuid)
          .order('timestamp', ascending: false);

      setState(() {
        _logs = (response as List).map((e) => AccessLog.fromMap(e)).toList();
        _loading = false;
      });
    } catch (e) {
      print('Error fetching access logs: $e');
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Istoric Acces')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _logs.isEmpty
              ? const Center(child: Text('Nu există intrări înregistrate.'))
              : ListView.builder(
                  itemCount: _logs.length,
                  itemBuilder: (context, index) {
                    final log = _logs[index];
                    return ListTile(
                      leading: Icon(
                        log.direction == 'entry' ? Icons.login : Icons.logout,
                        color: log.direction == 'entry'
                            ? Colors.green
                            : Colors.red,
                      ),
                      title:
                          Text(log.direction == 'entry' ? 'Intrare' : 'Ieșire'),
                      subtitle: Text(log.timestamp.toString()),
                    );
                  },
                ),
    );
  }
}