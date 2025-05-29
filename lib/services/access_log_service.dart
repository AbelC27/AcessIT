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