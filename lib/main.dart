import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'data/services/api_service.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/book_repository.dart';
import 'data/repositories/progress_repository.dart';
import 'data/local/database_helper.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/library_provider.dart';
import 'presentation/providers/reader_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Initialize services
  final apiService = ApiService();
  final dbHelper = DatabaseHelper();

  // Initialize repositories
  final authRepository = AuthRepository(apiService: apiService);
  final bookRepository = BookRepository(apiService: apiService);
  final progressRepository = ProgressRepository(
    apiService: apiService,
    dbHelper: dbHelper,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(authRepository: authRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => LibraryProvider(
            bookRepository: bookRepository,
            dbHelper: dbHelper,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => ReaderProvider(
            bookRepository: bookRepository,
            progressRepository: progressRepository,
            dbHelper: dbHelper,
          ),
        ),
      ],
      child: const DiReadApp(),
    ),
  );
}
