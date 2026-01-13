import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'core/config/theme.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/auth/register_screen.dart';
import 'presentation/screens/auth/forgot_password_screen.dart';
import 'presentation/screens/auth/reset_password_screen.dart';
import 'presentation/screens/main_shell.dart';
import 'presentation/screens/library/book_detail_screen.dart';
import 'presentation/screens/reader/reader_screen.dart';

class DiReadApp extends StatefulWidget {
  const DiReadApp({super.key});

  @override
  State<DiReadApp> createState() => _DiReadAppState();
}

class _DiReadAppState extends State<DiReadApp> {
  GoRouter? _router;
  AuthProvider? _authProvider;
  bool _isRouterInitialized = false;

  @override
  void initState() {
    super.initState();

    // Get auth provider and check status
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _authProvider = context.read<AuthProvider>();
      _router = _createRouter();
      _isRouterInitialized = true;
      _authProvider!.checkAuthStatus();
      setState(() {}); // Rebuild after router is created
    });
  }

  GoRouter _createRouter() {
    return GoRouter(
      initialLocation: '/splash',
      refreshListenable: _authProvider!, // Re-evaluate routes when auth changes
      redirect: (context, state) {
        final status = _authProvider!.status;
        final isAuthenticated = _authProvider!.isAuthenticated;
        final isSplash = state.matchedLocation == '/splash';
        final isAuthRoute = state.matchedLocation == '/login' ||
            state.matchedLocation == '/register' ||
            state.matchedLocation == '/forgot-password' ||
            state.matchedLocation.startsWith('/reset-password');

        // Still loading - show splash
        if (status == AuthStatus.initial || status == AuthStatus.loading) {
          return isSplash ? null : '/splash';
        }

        // Done loading - redirect from splash
        if (isSplash) {
          return isAuthenticated ? '/' : '/login';
        }

        // Not authenticated - go to login
        if (!isAuthenticated && !isAuthRoute) {
          return '/login';
        }

        // Authenticated but on auth route - go to home
        if (isAuthenticated && isAuthRoute) {
          return '/';
        }

        return null;
      },
      routes: [
        // Splash Screen
        GoRoute(
          path: '/splash',
          builder: (context, state) => const _SplashScreen(),
        ),
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
          path: '/',
          name: 'home',
          builder: (context, state) => const MainShell(initialIndex: 0),
        ),
        GoRoute(
          path: '/library',
          name: 'library',
          builder: (context, state) => const MainShell(initialIndex: 1),
        ),
        GoRoute(
          path: '/profile',
          name: 'profile',
          builder: (context, state) => const MainShell(initialIndex: 2),
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
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // Show loading while router is being initialized
        if (!_isRouterInitialized) {
          return MaterialApp(
            title: 'diRead',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.system,
            home: const _SplashScreen(),
          );
        }

        return MaterialApp.router(
          title: 'diRead',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.system,
          routerConfig: _router!,
        );
      },
    );
  }
}

// Simple splash screen
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App logo or icon
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.menu_book,
                size: 60,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'diRead',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
