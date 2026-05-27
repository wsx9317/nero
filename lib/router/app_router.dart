import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:nero/screens/Home.dart';
import 'package:nero/screens/flutter_tts_page.dart';

String _initialRouteFromEnv() {
  final mainValue = (dotenv.env['MAIN'] ?? 'HOME').toUpperCase();

  switch (mainValue) {
    case 'LOGIN':
      return '/login';
    case 'HOME':
    default:
      return '/';
  }
}

GoRouter createAppRouter() {
  return GoRouter(
    initialLocation: _initialRouteFromEnv(),
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const Home(),
      ),
      GoRoute(
        path: '/tts/flutter',
        builder: (context, state) => const FlutterTtsPage(),
      ),
      
    ],
  );
}