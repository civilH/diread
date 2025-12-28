import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'core/config/theme.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/auth/register_screen.dart';
import 'presentation/screens/auth/forgot_password_screen.dart';
import 'presentation/screens/auth/reset_password_screen.dart';
import 'presentation/screens/library/library_screen.dart';
import 'presentation/screens/library/book_detail_screen.dart';
import 'presentation/screens/reader/reader_screen.dart';
import 'presentation/screens/profile/profile_screen.dart';

class DiReadApp extends StatefulWidget {
  const DiReadApp({super.key});

  @override
  State<DiReadApp> createState() => _DiReadAppState();
}

class _DiReadAppState extends State<DiReadApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = _createRouter();

    // Check auth status on app start
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().checkAuthStatus();
    });
  }

  GoRouter _createRouter() {
    return GoRouter(
      initialLocation: '/login',
      redirect: (context, state) {
        final authProvider = context.read<AuthProvider>();
        final isAuthenticated = authProvider.isAuthenticated;
        final isAuthRoute = state.matchedLocation == '/login' ||
            state.matchedLocation == '/register' ||
            state.matchedLocation == '/forgot-password' ||
            state.matchedLocation.startsWith('/reset-password');

        if (!isAuthenticated && !isAuthRoute) {
          return '/login';
        }

        if (isAuthenticated && isAuthRoute) {
          return '/library';
        }

        return null;
      },
      routes: [
        // Auth Routes
        GoRoute(
          path: '/login',
          name: 'login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/register',
          name: 'register',
          builder: (context, state) => const RegisterScreen(),
        ),
        GoRoute(
          path: '/forgot-password',
          name: 'forgot-password',
          builder: (context, state) => const ForgotPasswordScreen(),
        ),
        GoRoute(
          path: '/reset-password',
          name: 'reset-password',
          builder: (context, state) {
            final token = state.uri.queryParameters['token'];
            return ResetPasswordScreen(token: token);
          },
        ),

        // Main App Routes
        GoRoute(
          path: '/library',
          name: 'library',
          builder: (context, state) => const LibraryScreen(),
        ),
        GoRoute(
          path: '/book/:id',
          name: 'book-detail',
          builder: (context, state) {
            final bookId = state.pathParameters['id']!;
            return BookDetailScreen(bookId: bookId);
          },
        ),
        GoRoute(
          path: '/reader/:id',
          name: 'reader',
          builder: (context, state) {
            final bookId = state.pathParameters['id']!;
            return ReaderScreen(bookId: bookId);
          },
        ),
        GoRoute(
          path: '/profile',
          name: 'profile',
          builder: (context, state) => const ProfileScreen(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return MaterialApp.router(
          title: 'diRead',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.system,
          routerConfig: _router,
        );
      },
    );
  }
}
