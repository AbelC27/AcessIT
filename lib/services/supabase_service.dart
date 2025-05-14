import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  final _client = Supabase.instance.client;

  Future<bool> login(String email, String password) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    return response.user != null;
  }

  Future<bool> registerVisitor({
    required String name,
    required String licensePlate,
    required String reason,
  }) async {
    final now = DateTime.now();
    final bleCode = now.millisecondsSinceEpoch.toString();

    final result = await _client.from('visitors').insert({
      'name': name,
      'license_plate': licensePlate,
      'reason': reason,
      'ble_temp_code': bleCode,
      'access_start': now.toIso8601String(),
      'access_end': now.add(Duration(hours: 9)).toIso8601String(),
    });

    return result.error == null;
  }
}
