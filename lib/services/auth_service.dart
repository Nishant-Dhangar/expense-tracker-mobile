import 'package:dio/dio.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
class AuthService {
  static const String baseUrl = 'http://10.21.25.70:8080';

  final Dio _dio = Dio();
  late final PersistCookieJar _cookieJar;
late final Future<void> _cookieInitialization;
 AuthService() {
  _cookieInitialization = _initializeCookies();
}

Future<void> _initializeCookies() async {
  final directory = await getApplicationDocumentsDirectory();

  _cookieJar = PersistCookieJar(
    storage: FileStorage(
      '${directory.path}/cookies',
    ),
  );

  _dio.interceptors.add(
    CookieManager(_cookieJar),
  );
}

  Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    await _cookieInitialization;
    try {
      final response = await _dio.post(
        '$baseUrl/api/auth/login',
        data: {
          'email': email,
          'password': password,
        },
      );
      final prefs = await SharedPreferences.getInstance();
await prefs.setBool('isLoggedIn', true);

      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Invalid email or password');
      }

      throw Exception('Login failed: ${e.message}');
    }
  }

  Future<Map<String, dynamic>> getCurrentUser() async {
    await _cookieInitialization;
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
  Future<Map<String, dynamic>> updateProfile(String name) async {
  await _cookieInitialization;

  try {
    final response = await _dio.put(
      '$baseUrl/api/auth/profile',
      data: {
        'name': name,
      },
    );

    return Map<String, dynamic>.from(response.data);
  } on DioException catch (e) {
    if (e.response?.statusCode == 400) {
      throw Exception(
        e.response?.data?.toString() ?? 'Invalid name',
      );
    }

    throw Exception(
      'Unable to update profile: ${e.message}',
    );
  }
}

Future<void> logout() async {
  await _cookieInitialization;
  try {
    await _dio.post('$baseUrl/api/auth/logout');

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);

    _cookieJar.deleteAll();
  } on DioException catch (e) {
    throw Exception('Logout failed: ${e.message}');
  }
}

  Future<List<dynamic>> getTransactions() async {
    await _cookieInitialization;
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
    await _cookieInitialization;
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
    await _cookieInitialization;
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
    await _cookieInitialization;
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
  await _cookieInitialization;
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
  await _cookieInitialization;
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
  await _cookieInitialization;
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
