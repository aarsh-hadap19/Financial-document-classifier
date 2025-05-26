import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/document_model.dart';
import '../models/user_model.dart';

class AuthService {
  static const String baseUrl = 'YOUR_API_BASE_URL';

  Future<UserModel> login(String email, String password) async {
    // Simulate API call - Replace with actual API endpoint
    await Future.delayed(const Duration(seconds: 2));

    if (email == 'demo@example.com' && password == 'password') {
      return UserModel(
        id: '1',
        email: email,
        name: 'Demo User',
      );
    } else {
      throw Exception('Invalid credentials');
    }

    /* Actual API implementation:
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return UserModel.fromJson(data['user']);
    } else {
      throw Exception('Login failed');
    }
    */
  }

  Future<UserModel> register(String name, String email, String password) async {
    // Simulate API call - Replace with actual API endpoint
    await Future.delayed(const Duration(seconds: 2));

    return UserModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      email: email,
      name: name,
    );

    /* Actual API implementation:
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return UserModel.fromJson(data['user']);
    } else {
      throw Exception('Registration failed');
    }
    */
  }

  void logout() {
    // Clear stored tokens/session data
  }
}

