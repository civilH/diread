class ApiConstants {
  // Auth Endpoints
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String refreshToken = '/auth/refresh';
  static const String logout = '/auth/logout';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';
  static const String changePassword = '/auth/change-password';

  // User Endpoints
  static const String userProfile = '/users/me';
  static const String updateProfile = '/users/me';
  static const String uploadAvatar = '/users/me/avatar';

  // Books Endpoints
  static const String books = '/books';
  static const String uploadBook = '/books/upload';
  static const String refreshMetadata = '/books/refresh-metadata';
  static String bookDetail(String id) => '/books/$id';
  static String deleteBook(String id) => '/books/$id';
  static String downloadBook(String id) => '/books/$id/download';
  static String bookCover(String id) => '/books/$id/cover';

  // Reading Progress Endpoints
  static String readingProgress(String bookId) => '/books/$bookId/progress';

  // Bookmarks Endpoints
  static String bookmarks(String bookId) => '/books/$bookId/bookmarks';
  static String deleteBookmark(String id) => '/bookmarks/$id';

  // Highlights Endpoints
  static String highlights(String bookId) => '/books/$bookId/highlights';
  static String updateHighlight(String id) => '/highlights/$id';
  static String deleteHighlight(String id) => '/highlights/$id';

  // Notes Endpoints
  static String notes(String bookId) => '/books/$bookId/notes';
  static String updateNote(String id) => '/notes/$id';
  static String deleteNote(String id) => '/notes/$id';

  // Search Endpoints
  static String searchBooks(String query) => '/books/search?q=$query';
  static String searchInBook(String bookId, String query) => '/books/$bookId/search?q=$query';

  // HTTP Headers
  static const String contentType = 'Content-Type';
  static const String authorization = 'Authorization';
  static const String bearer = 'Bearer';

  // Response Keys
  static const String accessToken = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String tokenType = 'token_type';
  static const String message = 'message';
  static const String data = 'data';
  static const String error = 'error';
}
