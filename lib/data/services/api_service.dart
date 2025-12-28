import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/config/app_config.dart';
import '../../core/constants/api_constants.dart';
import '../../core/errors/exceptions.dart';

class ApiService {
  late final Dio _dio;
  final FlutterSecureStorage _storage;

  ApiService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: AppConfig.accessTokenKey);
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          // Try to refresh token
          final refreshed = await _refreshToken();
          if (refreshed) {
            // Retry the original request
            final token = await _storage.read(key: AppConfig.accessTokenKey);
            error.requestOptions.headers['Authorization'] = 'Bearer $token';
            try {
              final response = await _dio.fetch(error.requestOptions);
              return handler.resolve(response);
            } catch (e) {
              return handler.next(error);
            }
          }
        }
        return handler.next(error);
      },
    ));
  }

  Future<bool> _refreshToken() async {
    try {
      final refreshToken = await _storage.read(key: AppConfig.refreshTokenKey);
      if (refreshToken == null) return false;

      final response = await Dio().post(
        '${AppConfig.apiBaseUrl}${ApiConstants.refreshToken}',
        data: {'refresh_token': refreshToken},
      );

      if (response.statusCode == 200) {
        await _storage.write(
          key: AppConfig.accessTokenKey,
          value: response.data['access_token'],
        );
        if (response.data['refresh_token'] != null) {
          await _storage.write(
            key: AppConfig.refreshTokenKey,
            value: response.data['refresh_token'],
          );
        }
        return true;
      }
    } catch (e) {
      // Token refresh failed, user needs to re-login
    }
    return false;
  }

  // Auth Methods
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    String? name,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.register,
        data: {
          'email': email,
          'password': password,
          if (name != null) 'name': name,
        },
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.login,
        data: {
          'email': email,
          'password': password,
        },
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> logout() async {
    try {
      final refreshToken = await _storage.read(key: AppConfig.refreshTokenKey);
      await _dio.post(
        ApiConstants.logout,
        data: {'refresh_token': refreshToken},
      );
    } catch (e) {
      // Ignore logout errors
    } finally {
      await _storage.delete(key: AppConfig.accessTokenKey);
      await _storage.delete(key: AppConfig.refreshTokenKey);
      await _storage.delete(key: AppConfig.userIdKey);
    }
  }

  Future<void> forgotPassword(String email) async {
    try {
      await _dio.post(
        ApiConstants.forgotPassword,
        data: {'email': email},
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> resetPassword({
    required String token,
    required String password,
  }) async {
    try {
      await _dio.post(
        ApiConstants.resetPassword,
        data: {
          'token': token,
          'password': password,
        },
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // User Methods
  Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      final response = await _dio.get(ApiConstants.userProfile);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> updateProfile({
    String? name,
  }) async {
    try {
      final response = await _dio.put(
        ApiConstants.updateProfile,
        data: {
          if (name != null) 'name': name,
        },
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Book Methods
  Future<List<dynamic>> getBooks() async {
    try {
      final response = await _dio.get(ApiConstants.books);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> uploadBook(File file, {String? title}) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: file.path.split('/').last,
        ),
        if (title != null) 'title': title,
      });

      final response = await _dio.post(
        ApiConstants.uploadBook,
        data: formData,
        options: Options(
          headers: {'Content-Type': 'multipart/form-data'},
        ),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> uploadBookBytes(
    Uint8List bytes, {
    required String fileName,
    String? title,
  }) async {
    try {
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          bytes,
          filename: fileName,
        ),
        if (title != null) 'title': title,
      });

      final response = await _dio.post(
        ApiConstants.uploadBook,
        data: formData,
        options: Options(
          headers: {'Content-Type': 'multipart/form-data'},
        ),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getBook(String id) async {
    try {
      final response = await _dio.get(ApiConstants.bookDetail(id));
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> deleteBook(String id) async {
    try {
      await _dio.delete(ApiConstants.deleteBook(id));
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<int>> downloadBook(String id) async {
    try {
      final response = await _dio.get<List<int>>(
        ApiConstants.downloadBook(id),
        options: Options(responseType: ResponseType.bytes),
      );
      return response.data!;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Reading Progress Methods
  Future<Map<String, dynamic>?> getReadingProgress(String bookId) async {
    try {
      final response = await _dio.get(ApiConstants.readingProgress(bookId));
      return response.data;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> updateReadingProgress({
    required String bookId,
    required int currentPage,
    String? currentCfi,
    required double progressPercent,
  }) async {
    try {
      final response = await _dio.put(
        ApiConstants.readingProgress(bookId),
        data: {
          'current_page': currentPage,
          if (currentCfi != null) 'current_cfi': currentCfi,
          'progress_percent': progressPercent,
        },
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Bookmark Methods
  Future<List<dynamic>> getBookmarks(String bookId) async {
    try {
      final response = await _dio.get(ApiConstants.bookmarks(bookId));
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> addBookmark({
    required String bookId,
    int? pageNumber,
    String? cfi,
    String? title,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.bookmarks(bookId),
        data: {
          if (pageNumber != null) 'page_number': pageNumber,
          if (cfi != null) 'cfi': cfi,
          if (title != null) 'title': title,
        },
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> deleteBookmark(String id) async {
    try {
      await _dio.delete(ApiConstants.deleteBookmark(id));
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Highlight Methods
  Future<List<dynamic>> getHighlights(String bookId) async {
    try {
      final response = await _dio.get(ApiConstants.highlights(bookId));
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> addHighlight({
    required String bookId,
    required String text,
    int? pageNumber,
    String? cfi,
    String? color,
    String? note,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.highlights(bookId),
        data: {
          'text': text,
          if (pageNumber != null) 'page_number': pageNumber,
          if (cfi != null) 'cfi': cfi,
          if (color != null) 'color': color,
          if (note != null) 'note': note,
        },
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> updateHighlight({
    required String id,
    String? color,
    String? note,
  }) async {
    try {
      final response = await _dio.put(
        ApiConstants.updateHighlight(id),
        data: {
          if (color != null) 'color': color,
          if (note != null) 'note': note,
        },
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> deleteHighlight(String id) async {
    try {
      await _dio.delete(ApiConstants.deleteHighlight(id));
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  AppException _handleError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return NetworkException('Connection timeout');
    }

    if (e.type == DioExceptionType.connectionError) {
      return NetworkException('No internet connection');
    }

    final statusCode = e.response?.statusCode;
    final data = e.response?.data;
    final message = data is Map ? data['detail'] ?? data['message'] : null;

    switch (statusCode) {
      case 400:
        return ValidationException(message ?? 'Invalid request');
      case 401:
        return UnauthorizedException(message ?? 'Unauthorized');
      case 403:
        return AuthException(message ?? 'Access denied');
      case 404:
        return NotFoundException(message ?? 'Not found');
      case 409:
        return UserAlreadyExistsException(message ?? 'User already exists');
      case 413:
        return FileTooLargeException(message ?? 'File too large');
      case 422:
        return ValidationException(message ?? 'Validation error');
      default:
        return ServerException(
          message ?? 'Server error',
          statusCode: statusCode,
        );
    }
  }
}
