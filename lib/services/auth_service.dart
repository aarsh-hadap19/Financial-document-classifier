import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/document_model.dart';
import '../models/user_model.dart';

class AuthService {
  // Mock authentication - replace with your actual API
  Future<UserModel> login(String email, String password) async {
    await Future.delayed(const Duration(seconds: 2)); // Simulate API call

    // Demo credentials
    if (email == 'demo@example.com' && password == 'password') {
      return UserModel(
        id: '1',
        email: email,
        name: 'Demo User',
      );
    }

    throw Exception('Invalid credentials');
  }

  Future<UserModel> register(String name, String email, String password) async {
    await Future.delayed(const Duration(seconds: 2)); // Simulate API call

    return UserModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      email: email,
      name: name,
    );
  }

  void logout() {
    // Clear stored tokens/data
  }
}

