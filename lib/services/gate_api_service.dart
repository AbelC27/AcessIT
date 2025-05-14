import 'dart:convert';
import 'package:http/http.dart' as http;

class GateApiService {
  final String baseUrl;

  GateApiService({required this.baseUrl});

  Future<bool> validateAccess(String bleCode) async {
    final url = Uri.parse('$baseUrl/validate');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'ble_code': bleCode}),
    );
    return response.statusCode == 200;
  }

  Future<List<dynamic>> fetchAccessLogs(String userId) async {
    final url = Uri.parse('$baseUrl/logs/$userId');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load logs');
    }
  }
}
