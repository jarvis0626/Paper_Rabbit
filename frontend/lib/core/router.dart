import 'package:go_router/go_router.dart';
import '../features/splash_screen.dart';
import '../features/login_screen.dart';
import '../features/home_screen.dart';
import '../features/search_screen.dart';
import '../features/bookmarks_screen.dart';
import '../features/graph_screen.dart';

final router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/search',
      builder: (context, state) => const SearchScreen(),
    ),
    GoRoute(
      path: '/bookmarks',
      builder: (context, state) => const BookmarksScreen(),
    ),
    GoRoute(
      path: '/graph',
      builder: (context, state) => const GraphScreen(),
    ),
  ],
);
