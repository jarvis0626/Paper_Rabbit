import 'package:go_router/go_router.dart';
import '../features/home_screen.dart';
import '../features/search_screen.dart';
import '../features/bookmarks_screen.dart';
import '../features/graph_screen.dart';
import '../features/papers/presentation/paper_details_screen.dart';

final router = GoRouter(
  initialLocation: '/home',
  routes: [
    GoRoute(path: '/', redirect: (context, state) => '/home'),
    GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
    GoRoute(path: '/search', builder: (context, state) => const SearchScreen()),
    GoRoute(
      path: '/bookmarks',
      builder: (context, state) => const BookmarksScreen(),
    ),
    GoRoute(path: '/graph', builder: (context, state) => const GraphScreen()),
    GoRoute(
      path: '/graph/:paperId',
      builder: (context, state) =>
          GraphScreen(paperId: state.pathParameters['paperId']),
    ),
    GoRoute(
      path: '/papers/:paperId',
      builder: (context, state) =>
          PaperDetailsScreen(paperId: state.pathParameters['paperId']!),
    ),
  ],
);
