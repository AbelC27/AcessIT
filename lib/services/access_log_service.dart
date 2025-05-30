// services/ access_log_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> logEntry(int userId, bool isVisitor, {String? validatedBy}) async {
  await Supabase.instance.client.from('access_logs').insert({
    'user_id': userId,
    'timestamp': DateTime.now().toIso8601String(),
    'direction': 'entry',
    'is_visitor': isVisitor,
    'validated_by': validatedBy,
  });
}

Future<void> logEmployeeAccess({
  required String employeeId, // UUID din employees
  required String direction, // 'entry' sau 'exit'
  String? bluetoothCode,
}) async {
  await Supabase.instance.client.from('access_logs').insert({
    'employee_id': employeeId,
    'timestamp': DateTime.now().toIso8601String(),
    'direction': direction,
    'is_visitor': false,
    'bluetooth_code': bluetoothCode,
  });
}
Future<bool> isUserInside({
  String? employeeId,
  int? visitorId,
  required bool isVisitor,
}) async {
  final client = Supabase.instance.client;
  final filterColumn = isVisitor ? 'user_id' : 'employee_id';
  final filterValue = isVisitor ? visitorId : employeeId;

  if (filterValue == null) {
    // Nu are sens să cauți dacă nu ai id-ul
    return false;
  }

  final response = await client
      .from('access_logs')
      .select('direction')
      .eq(filterColumn, filterValue)
      .order('timestamp', ascending: false)
      .limit(1)
      .maybeSingle();

  if (response == null) return false;
  return response['direction'] == 'entry';
}