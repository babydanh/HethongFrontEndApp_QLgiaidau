import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:app_quanly_giaidau/features/home/screens/home_screen.dart';
import 'package:app_quanly_giaidau/features/home/screens/qr_scanner_screen.dart';
import 'package:app_quanly_giaidau/features/auth/screens/splash_screen.dart';
import 'package:app_quanly_giaidau/features/auth/screens/login_register_screen.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/create_tournament_screen.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/tournament_detail_screen.dart';
import 'package:app_quanly_giaidau/features/teams/screens/team_list_screen.dart';
import 'package:app_quanly_giaidau/features/teams/screens/add_team_screen.dart';
import 'package:app_quanly_giaidau/features/bracket/screens/bracket_view_screen.dart';
import 'package:app_quanly_giaidau/features/match/screens/live_score_screen.dart';
import 'package:app_quanly_giaidau/features/bracket/screens/auto_draw_screen.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/token_management_screen.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/tournament_intro_screen.dart';
import 'package:app_quanly_giaidau/data/models/team_model.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final auth = ref.read(authProvider);
      final isAuth = auth.status == AuthStatus.authenticated;
      final currentPath = state.matchedLocation;

      // Splash screen & Login screen — luôn cho phép
      if (currentPath == '/' || currentPath == '/login') return null;

      // Chưa auth nhưng cố truy cập referee hoặc admin
      if (!isAuth && (currentPath.startsWith('/referee') || currentPath.startsWith('/admin'))) {
        return '/login';
      }

      // Chưa auth thì mặc định về /home
      if (!isAuth && currentPath != '/home' && currentPath != '/scan-qr') {
        return '/home';
      }

      // Đã auth và ở /login -> về /home
      if (isAuth && currentPath == '/login') {
        return '/home';
      }
      
      // Kiểm tra quyền truy cập route
      if (isAuth) {
        if (currentPath.startsWith('/admin') && auth.role != UserRole.admin) {
          return auth.role == UserRole.referee ? '/referee' : '/viewer';
        }
        if (currentPath.startsWith('/referee') && auth.role == UserRole.viewer) {
          return '/viewer';
        }
      }

      return null;
    },
    routes: [
      // ─── Splash ───
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),

      // ─── Login/Register ───
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginRegisterScreen(),
      ),

      // ─── Home ───
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),

      // ─── QR Scanner ───
      GoRoute(
        path: '/scan-qr',
        builder: (context, state) => const QrScannerScreen(),
      ),

      // ─── Admin Routes ───
      GoRoute(
        path: '/admin',
        redirect: (context, state) {
          if (state.uri.path == '/admin') return '/home';
          return null;
        },
        routes: [
          GoRoute(
            path: 'create',
            builder: (context, state) => const CreateTournamentScreen(),
          ),
          GoRoute(
            path: 'tournament/:id',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return TournamentDetailScreen(tournamentId: id);
            },
            routes: [
              GoRoute(
                path: 'teams',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return TeamListScreen(tournamentId: id);
                },
                routes: [
                  GoRoute(
                    path: 'add',
                    builder: (context, state) {
                      final id = state.pathParameters['id']!;
                      return AddTeamScreen(tournamentId: id);
                    },
                  ),
                  GoRoute(
                    path: 'edit',
                    builder: (context, state) {
                      final id = state.pathParameters['id']!;
                      final team = state.extra as Team?;
                      return AddTeamScreen(tournamentId: id, teamToEdit: team);
                    },
                  ),
                ],
              ),
              GoRoute(
                path: 'bracket',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return BracketViewScreen(tournamentId: id);
                },
              ),
              GoRoute(
                path: 'tokens',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return TokenManagementScreen(tournamentId: id);
                },
              ),
              GoRoute(
                path: 'match/:matchId',
                builder: (context, state) {
                  final tournamentId = state.pathParameters['id']!;
                  final matchId = state.pathParameters['matchId']!;
                  return LiveScoreScreen(
                    tournamentId: tournamentId,
                    matchId: matchId,
                  );
                },
              ),
              GoRoute(
                path: 'draw',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return AutoDrawScreen(tournamentId: id);
                },
              ),
            ],
          ),
        ],
      ),

      // ─── Intro Screen ───
      GoRoute(
        path: '/intro/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return TournamentIntroScreen(tournamentId: id);
        },
      ),

      // ─── Referee Routes ───
      GoRoute(
        path: '/referee',
        builder: (context, state) {
          final tournamentId = ref.read(authProvider).tournamentId ?? '';
          return BracketViewScreen(
            tournamentId: tournamentId,
            isReferee: true,
          );
        },
        routes: [
          GoRoute(
            path: 'match/:matchId',
            builder: (context, state) {
              final matchId = state.pathParameters['matchId']!;
              return LiveScoreScreen(
                tournamentId: ref.read(authProvider).tournamentId ?? '',
                matchId: matchId,
              );
            },
          ),
        ],
      ),

      // ─── Viewer Routes ───
      GoRoute(
        path: '/viewer',
        builder: (context, state) {
          final tournamentId = ref.read(authProvider).tournamentId ?? '';
          return BracketViewScreen(tournamentId: tournamentId);
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Trang không tồn tại',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => context.go('/'),
              child: const Text('Về trang chủ'),
            ),
          ],
        ),
      ),
    ),
  );
});
