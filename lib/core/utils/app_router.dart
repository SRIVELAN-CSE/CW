import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../screens/auth/user_type_selection_screen.dart';
import '../../screens/public/public_login_screen.dart';
import '../../screens/public/public_register_screen.dart';
import '../../screens/public/public_dashboard_screen.dart';
import '../../screens/officer/officer_login_screen.dart';
import '../../screens/officer/officer_dashboard_screen.dart';
import '../../screens/admin/admin_login_screen.dart';
import '../../screens/admin/admin_dashboard_screen.dart';
import '../../models/user.dart';

class AppRouter {
  static final GoRouter _router = GoRouter(
    initialLocation: '/user-type',
    routes: [
      // User Type Selection
      GoRoute(
        path: '/user-type',
        name: 'user-type-selection',
        builder: (context, state) => const UserTypeSelectionScreen(),
      ),
      
      // Public Routes
      GoRoute(
        path: '/public/login',
        name: 'public-login',
        builder: (context, state) => const PublicLoginScreen(),
      ),
      GoRoute(
        path: '/public/register',
        name: 'public-register',
        builder: (context, state) => const PublicRegisterScreen(),
      ),
      GoRoute(
        path: '/public/dashboard',
        name: 'public-dashboard',
        builder: (context, state) => const PublicDashboardScreen(),
      ),
      
      // Officer Routes
      GoRoute(
        path: '/officer/login',
        name: 'officer-login',
        builder: (context, state) => const OfficerLoginScreen(),
      ),
      GoRoute(
        path: '/officer/dashboard',
        name: 'officer-dashboard',
        builder: (context, state) => const OfficerDashboardScreen(),
      ),
      
      // Admin Routes
      GoRoute(
        path: '/admin/login',
        name: 'admin-login',
        builder: (context, state) => const AdminLoginScreen(),
      ),
      GoRoute(
        path: '/admin/dashboard',
        name: 'admin-dashboard',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Page Not Found')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64),
            const SizedBox(height: 16),
            Text(
              'Page not found: ${state.matchedLocation}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/user-type'),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );

  static GoRouter get router => _router;

  // Navigation Helper Methods
  static void navigateToUserTypeSelection(BuildContext context) {
    context.go('/user-type');
  }

  static void navigateToLogin(BuildContext context, UserType userType) {
    switch (userType) {
      case UserType.public:
        context.go('/public/login');
        break;
      case UserType.officer:
        context.go('/officer/login');
        break;
      case UserType.admin:
        context.go('/admin/login');
        break;
    }
  }

  static void navigateToRegister(BuildContext context, UserType userType) {
    switch (userType) {
      case UserType.public:
        context.go('/public/register');
        break;
      case UserType.officer:
        // Officers don't register, redirect to login
        context.go('/officer/login');
        break;
      case UserType.admin:
        // Admins don't register, redirect to login
        context.go('/admin/login');
        break;
    }
  }

  static void navigateToDashboard(BuildContext context, UserType userType) {
    switch (userType) {
      case UserType.public:
        context.go('/public/dashboard');
        break;
      case UserType.officer:
        context.go('/officer/dashboard');
        break;
      case UserType.admin:
        context.go('/admin/dashboard');
        break;
    }
  }
}