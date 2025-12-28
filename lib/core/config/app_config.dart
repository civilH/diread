class AppConfig {
  static const String appName = 'diRead';
  static const String appVersion = '1.0.0';

  // API Configuration
  // For local development, use your Mac's IP address
  // For production, change this to your deployed backend URL
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000/api/v1',
  );

  // File Upload Limits
  static const int maxFileSize = 100 * 1024 * 1024; // 100MB
  static const List<String> allowedFileTypes = ['pdf', 'epub'];

  // Token Configuration
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userIdKey = 'user_id';

  // Reading Settings Defaults
  static const double defaultFontSize = 18.0;
  static const double minFontSize = 12.0;
  static const double maxFontSize = 32.0;
  static const double defaultLineHeight = 1.6;
  static const double defaultMargin = 16.0;

  // Cache Configuration
  static const int maxCachedBooks = 10;
  static const Duration cacheExpiry = Duration(days: 30);
}
