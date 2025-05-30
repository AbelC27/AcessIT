import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/access_log_service.dart';
import '../widgets/access_animation.dart';

class EmployeeAccessScreen extends StatefulWidget {
  final String employeeId; // UUID din employees
  final String userName;
  final String bluetoothCode;

  const EmployeeAccessScreen({
    super.key,
    required this.employeeId,
    required this.userName,
    required this.bluetoothCode,
  });

  @override
  State<EmployeeAccessScreen> createState() => _EmployeeAccessScreenState();
}

class _EmployeeAccessScreenState extends State<EmployeeAccessScreen> {
  bool _loading = true;
  bool _isInside = false;

  @override
  void initState() {
    super.initState();
    _checkIfInside();
  }

  Future<void> _checkIfInside() async {
    setState(() => _loading = true);
    final isInside = await isUserInside(
      employeeId: widget.employeeId,
      visitorId: null,
      isVisitor: false,
    );
    setState(() {
      _isInside = isInside;
      _loading = false;
    });
  }

  Future<void> _logEntry() async {
    setState(() => _loading = true);
    try {
      await logEmployeeAccess(
        employeeId: widget.employeeId,
        direction: 'entry',
        bluetoothCode: widget.bluetoothCode,
      );
      _showAnimationAndUpdate(true, "Bun venit la AccesIT, ${widget.userName}!");
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Eroare la logarea intrării: $e')),
      );
    }
    setState(() => _loading = false);
  }

  Future<void> _logExit() async {
    setState(() => _loading = true);
    try {
      await logEmployeeAccess(
        employeeId: widget.employeeId,
        direction: 'exit',
        bluetoothCode: widget.bluetoothCode,
      );
      _showAnimationAndUpdate(true, "La revedere, ${widget.userName}!");
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Eroare la logarea ieșirii: $e')),
      );
    }
    setState(() => _loading = false);
  }

  void _showAnimationAndUpdate(bool success, String message) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AccessAnimation(success: success, message: message),
    );
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      Navigator.of(context).pop(); // închide dialogul
      setState(() {
        _isInside = !_isInside;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Acces angajat')),
      body: Center(
        child: _loading
            ? CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _isInside
                        ? 'Ești deja în firmă, ${widget.userName}!'
                        : 'Bun venit, ${widget.userName}!',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 24),
                  _isInside
                      ? ElevatedButton.icon(
                          icon: Icon(Icons.exit_to_app),
                          label: Text('Ieși din firmă'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            textStyle: TextStyle(fontSize: 18),
                          ),
                          onPressed: _logExit,
                        )
                      : ElevatedButton.icon(
                          icon: Icon(Icons.login),
                          label: Text('Intră în firmă'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            textStyle: TextStyle(fontSize: 18),
                          ),
                          onPressed: _logEntry,
                        ),
                ],
              ),
      ),
    );
  }
}