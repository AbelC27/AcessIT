// /visitor_session_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class VisitorSessionScreen extends StatefulWidget {
  final int visitorId; // id-ul vizitatorului din baza de date
  final String name;

  const VisitorSessionScreen({super.key, required this.visitorId, required this.name});

  @override
  State<VisitorSessionScreen> createState() => _VisitorSessionScreenState();
}

class _VisitorSessionScreenState extends State<VisitorSessionScreen> {
  bool _loading = false;
  bool _hasExited = false;


 Future<void> _logExit() async {
  setState(() => _loading = true);
  try {
    // 1. Actualizează access_end în tabela visitors
    await Supabase.instance.client.from('visitors').update({
      'access_end': DateTime.now().toIso8601String(),
    }).eq('id', widget.visitorId);

    // 2. Loghează ieșirea în access_logs
    await Supabase.instance.client.from('access_logs').insert({
      'user_id': widget.visitorId,
      'timestamp': DateTime.now().toIso8601String(),
      'direction': 'exit',
      'is_visitor': true,
    });

    setState(() {
      _hasExited = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Ieșirea a fost înregistrată. Mulțumim pentru vizită!')),
    );
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) Navigator.of(context).pop();
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Eroare la înregistrarea ieșirii: $e')),
    );
  }
  setState(() => _loading = false);
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Vizită în desfășurare')),
      body: Center(
        child: _hasExited
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 80),
                  SizedBox(height: 16),
                  Text('Vizita ta s-a încheiat. O zi bună!', style: TextStyle(fontSize: 18)),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Bun venit, ${widget.name}!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  SizedBox(height: 24),
                  Text('Când părăsești firma, apasă butonul de mai jos pentru a înregistra ieșirea.'),
                  SizedBox(height: 32),
                  _loading
                      ? CircularProgressIndicator()
                      : ElevatedButton.icon(
                          icon: Icon(Icons.exit_to_app),
                          label: Text('Ieși din firmă'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            textStyle: TextStyle(fontSize: 18),
                          ),
                          onPressed: _logExit,
                        ),
                ],
              ),
      ),
    );
  }
}