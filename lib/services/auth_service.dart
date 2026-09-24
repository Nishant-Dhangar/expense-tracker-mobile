import 'package:dio/dio.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';

class AuthService {
  static const String baseUrl = 'http://10.21.25.70:8080';

  final Dio _dio = Dio();
  final CookieJar _cookieJar = CookieJar();

  AuthService() {
    _dio.interceptors.add(
      CookieManager(_cookieJar),
    );
  }

  Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    try {
      final response = await _dio.post(
        '$baseUrl/api/auth/login',
        data: {
          'email': email,
          'password': password,
        },
      );

      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Invalid email or password');
      }

      throw Exception('Login failed: ${e.message}');
    }
  }

  Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      final response = await _dio.get(
        '$baseUrl/api/auth/me',
      );

      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      throw Exception(
        'Unable to get current user: ${e.message}',
      );
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post(
        '$baseUrl/api/auth/logout',
      );

      _cookieJar.deleteAll();
    } on DioException catch (e) {
      throw Exception(
        'Logout failed: ${e.message}',
      );
    }
  }

  Future<List<dynamic>> getTransactions() async {
    try {
      final response = await _dio.get(
        '$baseUrl/api/transactions',
      );

      return List<dynamic>.from(response.data);
    } on DioException catch (e) {
      throw Exception(
        'Unable to load transactions: ${e.message}',
      );
    }
  }

  Future<List<dynamic>> getCategories() async {
    try {
      final response = await _dio.get(
        '$baseUrl/api/categories',
      );

      return List<dynamic>.from(response.data);
    } on DioException catch (e) {
      throw Exception(
        'Unable to load categories: ${e.message}',
      );
    }
  }

  Future<Map<String, dynamic>> addTransaction({
    required double amount,
    required String type,
    required String description,
    required String transactionDate,
    required int categoryId,
  }) async {
    try {
      final response = await _dio.post(
        '$baseUrl/api/transactions',
        data: {
          'amount': amount,
          'type': type,
          'description': description,
          'transactionDate': transactionDate,
          'category': {
            'id': categoryId,
          },
        },
      );

      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        throw Exception(
          e.response?.data?.toString() ??
              'Invalid transaction',
        );
      }

      throw Exception(
        'Unable to add transaction: ${e.message}',
      );
    }
  }

  Future<void> deleteTransaction(int id) async {
    try {
      await _dio.delete(
        '$baseUrl/api/transactions/$id',
      );
    } on DioException catch (e) {
      throw Exception(
        'Unable to delete transaction: ${e.message}',
      );
    }
  }
  Future<Map<String, dynamic>> updateTransaction({
  required int id,
  required double amount,
  required String type,
  required String description,
  required String transactionDate,
  required int categoryId,
}) async {
  try {
    final response = await _dio.put(
      '$baseUrl/api/transactions/$id',
      data: {
        'amount': amount,
        'type': type,
        'description': description,
        'transactionDate': transactionDate,
        'category': {
          'id': categoryId,
        },
      },
    );

    return Map<String, dynamic>.from(response.data);
  } on DioException catch (e) {
    if (e.response?.statusCode == 400) {
      throw Exception(
        e.response?.data?.toString() ??
            'Invalid transaction',
      );
    }

    throw Exception(
      'Unable to update transaction: ${e.message}',
    );
  }
}
Future<Map<String, dynamic>?> getBudget(
  int year,
  int month,
) async {
  try {
    final response = await _dio.get(
      '$baseUrl/api/budgets/$year/$month',
    );

    return Map<String, dynamic>.from(response.data);
  } on DioException catch (e) {
    // No budget set for this month
    if (e.response?.statusCode == 404) {
      return null;
    }

    throw Exception(
      'Unable to load budget: ${e.message}',
    );
  }
}

Future<Map<String, dynamic>> saveBudget({
  required int month,
  required int year,
  required double amount,
}) async {
  try {
    final response = await _dio.post(
      '$baseUrl/api/budgets',
      data: {
        'month': month,
        'year': year,
        'amount': amount,
      },
    );

    return Map<String, dynamic>.from(response.data);
  } on DioException catch (e) {
    throw Exception(
      'Unable to save budget: ${e.message}',
    );
  }
}
}
