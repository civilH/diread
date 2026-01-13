import 'package:shared_preferences/shared_preferences.dart';

/// Service to manage API configuration dynamically
/// Allows users to set their own server URL
class ApiConfigService {
  static const String _serverUrlKey = 'server_url';
  static const String _defaultUrl = 'http://localhost:8000/api/v1';

  static String? _cachedUrl;

  /// Get the current API base URL
  static Future<String> getApiBaseUrl() async {
    if (_cachedUrl != null) return _cachedUrl!;

    final prefs = await SharedPreferences.getInstance();
    _cachedUrl = prefs.getString(_serverUrlKey) ?? _defaultUrl;
    return _cachedUrl!;
  }

  /// Get the current API base URL synchronously (uses cached value)
  static String getApiBaseUrlSync() {
    return _cachedUrl ?? _defaultUrl;
  }

  /// Set the API base URL
  static Future<bool> setApiBaseUrl(String url) async {
    // Clean up the URL
    String cleanUrl = url.trim();

    // Remove trailing slash
    if (cleanUrl.endsWith('/')) {
      cleanUrl = cleanUrl.substring(0, cleanUrl.length - 1);
    }

    // Add /api/v1 if not present
    if (!cleanUrl.contains('/api/')) {
      cleanUrl = '$cleanUrl/api/v1';
    }

    // Add http:// if no protocol specified
    if (!cleanUrl.startsWith('http://') && !cleanUrl.startsWith('https://')) {
      cleanUrl = 'http://$cleanUrl';
    }

    final prefs = await SharedPreferences.getInstance();
    final success = await prefs.setString(_serverUrlKey, cleanUrl);
    if (success) {
      _cachedUrl = cleanUrl;
    }
    return success;
  }

  /// Check if a custom server URL has been configured
  static Future<bool> hasCustomUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_serverUrlKey);
  }

  /// Get just the server host:port (without /api/v1)
  static Future<String> getServerHost() async {
    final url = await getApiBaseUrl();
    return url.replaceAll('/api/v1', '').replaceAll('/api', '');
  }

  /// Clear the saved URL (reset to default)
  static Future<void> clearUrl() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_serverUrlKey);
    _cachedUrl = null;
  }

  /// Initialize the service (call at app startup)
  static Future<void> init() async {
    await getApiBaseUrl();
  }

  /// Test connection to the server
  static Future<bool> testConnection(String url) async {
    try {
      // This would make a simple health check request
      // For now, just validate the URL format
      final uri = Uri.tryParse(url);
      return uri != null && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }
}
