import 'package:go_router/go_router.dart';

import 'auth/auth_controller.dart';
import 'auth/login_page.dart';
import 'auth/signup_page.dart';
import 'auth/verify_code_page.dart';
import 'feed/feed_page.dart';
import 'onboarding/onboarding_page.dart';

const _publicRoutes = {'/login', '/signup'};

GoRouter createRouter(
  AuthController auth, {
  String initialLocation = '/login',
}) {
  return GoRouter(
    initialLocation: initialLocation,
    refreshListenable: auth,
    redirect: (context, state) {
      final location = state.matchedLocation;
      if (!auth.isSignedIn) {
        return _publicRoutes.contains(location) ? null : '/login';
      }
      if (!auth.isVerified) {
        return location == '/verify' ? null : '/verify';
      }
      if (_publicRoutes.contains(location) || location == '/verify') {
        return '/onboarding';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, _) => const LoginPage()),
      GoRoute(path: '/signup', builder: (_, _) => const SignupPage()),
      GoRoute(path: '/verify', builder: (_, _) => const VerifyCodePage()),
      GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingPage()),
      GoRoute(path: '/feed', builder: (_, _) => const FeedPage()),
    ],
  );
}
