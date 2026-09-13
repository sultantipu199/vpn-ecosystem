import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';

class ApiService {
  final String baseUrl;

  ApiService({this.baseUrl = 'https://vpn-license-backend.onrender.com'});

  Future<UserModel> login({
    required String username,
    required String password,
    required String hwid,
  }) async {
    final url = Uri.parse('$baseUrl/api/auth');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
        'hwid': hwid,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return UserModel.fromJson(data);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Authentication failed');
    }
  }

  Future<Map<String, dynamic>> createUser({
    required String username,
    required String password,
    String tier = 'Premium',
    required int durationMinutes,
  }) async {
    final url = Uri.parse('$baseUrl/api/admin/create-user');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
        'tier': tier,
        'duration_minutes': durationMinutes,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Failed to create user');
    }
  }
}
