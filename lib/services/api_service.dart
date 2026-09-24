import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:8080';

  Future<dynamic> get(String endpoint) async {
    final response = await http.get(
      Uri.parse('$baseUrl$endpoint'),
    );

    return _handleResponse(response);
  }

  Future<dynamic> post(
      String endpoint,
      Map<String, dynamic> body,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    return _handleResponse(response);
  }

  Future<dynamic> put(
      String endpoint,
      Map<String, dynamic> body,
  ) async {
    final response = await http.put(
      Uri.parse('$baseUrl$endpoint'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    return _handleResponse(response);
  }

  Future<dynamic> delete(String endpoint) async {
    final response = await http.delete(
      Uri.parse('$baseUrl$endpoint'),
    );

    return _handleResponse(response);
  }

  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 &&
        response.statusCode < 300) {

      if (response.body.isEmpty) {
        return null;
      }

      return jsonDecode(response.body);
    }

    throw Exception(
      'Request failed: ${response.statusCode} ${response.body}',
    );
  }
}