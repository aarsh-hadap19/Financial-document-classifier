import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class DocumentService {
  static const String baseUrl = 'http://10.0.2.2:8000'; // Android emulator

  Future<String> classifyDocument(String filePath) async {
    try {
      if (kDebugMode) {
        print('Classifying file: $filePath');
      }

      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('File does not exist: $filePath');
      }

      // Changed from /classify to /predict/ to match your backend
      final uri = Uri.parse('$baseUrl/predict/');
      final request = http.MultipartRequest('POST', uri)
        ..files.add(await http.MultipartFile.fromPath('file', filePath))
        ..headers.addAll({
          'Accept': 'application/json',
          'Content-Type': 'multipart/form-data',
          'User-Agent': 'Flutter-App',
        });

      final fileSize = await file.length();
      final timeout = fileSize > 5 * 1024 * 1024 ? 120 : 60;

      if (kDebugMode) {
        print('Sending request to: $uri');
        print('File size: ${fileSize} bytes');
        print('Timeout: ${timeout} seconds');
      }

      final response = await request.send().timeout(
        Duration(seconds: timeout),
        onTimeout: () {
          throw Exception('Request timed out after $timeout seconds.');
        },
      );

      final responseBody = await response.stream.bytesToString();

      if (kDebugMode) {
        print('Response status: ${response.statusCode}');
        print('Response headers: ${response.headers}');
        print('Response body: $responseBody');
      }

      if (response.statusCode == 200) {
        // First try to parse as JSON
        try {
          final jsonData = json.decode(responseBody);

          if (kDebugMode) {
            print('Parsed JSON response: $jsonData');
          }

          // Handle your backend's response format: {"predictions": [{"class": "...", "confidence": ...}]}
          String classification = 'Unknown';

          if (jsonData is Map<String, dynamic>) {
            // Handle predictions array format from your backend
            if (jsonData.containsKey('predictions')) {
              final predictions = jsonData['predictions'];
              if (predictions is List && predictions.isNotEmpty) {
                final topPrediction = predictions.first;
                if (topPrediction is Map<String, dynamic>) {
                  classification = topPrediction['class'] ?? 'Unknown';

                  // Optional: Include confidence in the result
                  final confidence = topPrediction['confidence'];
                  if (confidence != null) {
                    final confidencePercent = (confidence * 100).toStringAsFixed(1);
                    classification = '$classification ($confidencePercent%)';
                  }
                }
              }
            } else {
              // Fallback to other possible keys
              classification = jsonData['classification'] ??
                  jsonData['class'] ??
                  jsonData['result'] ??
                  jsonData['category'] ??
                  jsonData['predicted_class'] ??
                  jsonData['prediction'] ??
                  jsonData['label'] ??
                  'Unknown';
            }
          } else if (jsonData is String) {
            // If the entire response is just a string classification
            classification = jsonData;
          }

          if (kDebugMode) {
            print('Final classification: $classification');
          }

          return classification;

        } catch (jsonError) {
          if (kDebugMode) {
            print('JSON parsing error: $jsonError');
            print('Treating response as plain text: $responseBody');
          }

          // If JSON parsing fails, treat as plain text
          return responseBody.trim().isNotEmpty ? responseBody.trim() : 'Unknown';
        }

      } else if (response.statusCode == 413) {
        throw Exception('File too large. Try a smaller file.');
      } else if (response.statusCode == 415) {
        throw Exception('Unsupported file type.');
      } else if (response.statusCode == 422) {
        throw Exception('Invalid file format or corrupted file.');
      } else if (response.statusCode >= 500) {
        throw Exception('Server error (HTTP ${response.statusCode}). Please try again.');
      } else {
        if (kDebugMode) {
          print('Error response body: $responseBody');
        }
        throw Exception('Classification failed (HTTP ${response.statusCode}): $responseBody');
      }

    } on SocketException catch (e) {
      if (kDebugMode) {
        print('Socket exception: $e');
      }
      throw Exception('Network error. Check if backend is running on $baseUrl');
    } on TimeoutException catch (e) {
      if (kDebugMode) {
        print('Timeout exception: $e');
      }
      throw Exception('Request timed out. Server may be busy.');
    } on FormatException catch (e) {
      if (kDebugMode) {
        print('Format exception: $e');
      }
      throw Exception('Invalid response format from server.');
    } catch (e) {
      if (kDebugMode) {
        print('Unexpected error: $e');
      }
      throw Exception('Unexpected error: $e');
    }
  }

  Future<bool> testConnection() async {
    try {
      if (kDebugMode) {
        print('Testing connection to: $baseUrl');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (kDebugMode) {
        print('Connection test response: ${response.statusCode}');
        print('Connection test body: ${response.body}');
      }

      return response.statusCode < 500;
    } catch (e) {
      if (kDebugMode) {
        print('Connection test failed: $e');
      }
      return false;
    }
  }

  Future<String> checkServerStatus() async {
    final isConnected = await testConnection();
    return isConnected ? 'Server is reachable' : 'Server is not responding';
  }
}