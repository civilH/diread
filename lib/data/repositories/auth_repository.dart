import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/config/app_config.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class AuthRepository {
  final ApiService _apiService;
  final FlutterSecureStorage _storage;

  AuthRepository({
    required ApiService apiService,
    FlutterSecureStorage? storage,
  })  : _apiService = apiService,
        _storage = storage ?? const FlutterSecureStorage();

  Future<User> register({
    required String email,
    required String password,
    String? name,
  }) async {
    final response = await _apiService.register(
      email: email,
      password: password,
      name: name,
    );

    await _saveTokens(response);
    return User.fromJson(response['user']);
  }

  Future<User> login({
    required String email,
    required String password,
  }) async {
    final response = await _apiService.login(
      email: email,
      password: password,
    );

    await _saveTokens(response);
    return User.fromJson(response['user']);
  }

  Future<void> logout() async {
    await _apiService.logout();
  }

  Future<void> forgotPassword(String email) async {
    await _apiService.forgotPassword(email);
  }

  Future<void> resetPassword({
    required String token,
    required String password,
  }) async {
    await _apiService.resetPassword(
      token: token,
      password: password,
    );
  }

  Future<User> getCurrentUser() async {
    final response = await _apiService.getCurrentUser();
    return User.fromJson(response);
  }

  Future<User> updateProfile({String? name}) async {
    final response = await _apiService.updateProfile(name: name);
    return User.fromJson(response);
  }

  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: AppConfig.accessTokenKey);
    return token != null;
  }

  Future<String?> getUserId() async {
    return await _storage.read(key: AppConfig.userIdKey);
  }

  Future<void> _saveTokens(Map<String, dynamic> response) async {
    if (response['access_token'] != null) {
      await _storage.write(
        key: AppConfig.accessTokenKey,
        value: response['access_token'],
      );
    }
    if (response['refresh_token'] != null) {
      await _storage.write(
        key: AppConfig.refreshTokenKey,
        value: response['refresh_token'],
      );
    }
    if (response['user'] != null && response['user']['id'] != null) {
      await _storage.write(
        key: AppConfig.userIdKey,
        value: response['user']['id'],
      );
    }
  }
}
