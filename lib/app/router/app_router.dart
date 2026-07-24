import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/view_models/auth_view_model.dart';
import '../../features/auth/presentation/views/login_screen.dart';
import '../../features/auth/presentation/views/register_screen.dart';
import '../../features/auth/presentation/views/phone_login_screen.dart';
import '../../features/auth/presentation/views/phone_otp_verify_screen.dart';
import '../../features/albums/presentation/views/album_list_screen.dart';
import '../../features/albums/presentation/views/album_detail_screen.dart';
import '../../features/albums/presentation/views/create_album_screen.dart';
import '../../features/albums/presentation/views/join_album_screen.dart';
import '../../features/memories/presentation/views/capture_screen.dart';
import '../../features/memories/presentation/views/memory_detail_screen.dart';
import '../../features/map/presentation/views/map_screen.dart';
import '../../features/notes/presentation/views/note_editor_screen.dart';
import '../../features/messages/presentation/views/chat_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final user = ref.watch(authStateProvider).asData?.value;

  return GoRouter(
    initialLocation: '/albums',
    redirect: (context, state) {
      final isAuth = user != null;
      final isLogin = state.matchedLocation == '/login' || state.matchedLocation == '/register' || state.matchedLocation.startsWith('/login/phone');
      if (!isAuth && !isLogin) return '/login';
      if (isAuth && isLogin) return '/albums';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/login/phone', builder: (_, __) => const PhoneLoginScreen()),
      GoRoute(
        path: '/login/phone/verify',
        builder: (_, state) => PhoneOtpVerifyScreen(phoneNumber: state.extra as String? ?? ''),
      ),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(path: '/albums', builder: (_, __) => const AlbumListScreen()),
      GoRoute(path: '/albums/create', builder: (_, __) => const CreateAlbumScreen()),
      GoRoute(path: '/albums/join', builder: (_, __) => const JoinAlbumScreen()),
      GoRoute(path: '/albums/:id', builder: (_, state) => AlbumDetailScreen(albumId: state.pathParameters['id']!)),
      GoRoute(path: '/albums/:id/capture', builder: (_, state) => CaptureScreen(albumId: state.pathParameters['id']!)),
      GoRoute(path: '/albums/:id/map', builder: (_, state) => MapScreen(albumId: state.pathParameters['id']!)),
      GoRoute(path: '/albums/:id/notes/:phase', builder: (_, state) => NoteEditorScreen(albumId: state.pathParameters['id']!, phase: state.pathParameters['phase']!)),
      GoRoute(path: '/memories/:id', builder: (_, state) => MemoryDetailScreen(memoryId: state.pathParameters['id']!)),
      GoRoute(
        path: '/albums/:id/chat',
        builder: (_, state) => ChatScreen(
          albumId: state.pathParameters['id']!,
          albumTitle: state.uri.queryParameters['title'] ?? 'Chat',
        ),
      ),
    ],
  );
});
