import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/di.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:app_quanly_giaidau/features/home/screens/home_screen.dart';
import 'package:app_quanly_giaidau/features/home/screens/qr_scanner_screen.dart';
import 'package:app_quanly_giaidau/features/auth/screens/splash_screen.dart';
import 'package:app_quanly_giaidau/features/auth/screens/login_register_screen.dart';
import 'package:app_quanly_giaidau/features/auth/screens/forgot_password_screen.dart';
import 'package:app_quanly_giaidau/features/auth/screens/reset_password_screen.dart';
import 'package:app_quanly_giaidau/features/auth/screens/login_loading_screen.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/tournament_detail_screen.dart';
import 'package:app_quanly_giaidau/data/models/team_model.dart';
import 'package:app_quanly_giaidau/features/teams/screens/team_list_screen.dart';
import 'package:app_quanly_giaidau/features/teams/screens/add_team_screen.dart';
import 'package:app_quanly_giaidau/features/bracket/screens/bracket_view_screen.dart';
import 'package:app_quanly_giaidau/features/match/screens/live_score_screen.dart';
import 'package:app_quanly_giaidau/features/bracket/screens/auto_draw_screen.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/token_management_screen.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/tournament_intro_screen.dart';
import 'package:app_quanly_giaidau/features/notification/screens/notification_screen.dart';
import 'package:app_quanly_giaidau/features/community/screens/club_detail_screen.dart';
import 'package:app_quanly_giaidau/features/community/screens/club_tournaments_screen.dart';
import 'package:app_quanly_giaidau/features/community/screens/create_club_screen.dart';
import 'package:app_quanly_giaidau/features/community/screens/create_club_tournament_screen.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/create_public_quick_tournament_screen.dart';
import 'package:app_quanly_giaidau/features/community/screens/club_management_screen.dart';
import 'package:app_quanly_giaidau/features/community/screens/club_invites_screen.dart';
import 'package:app_quanly_giaidau/features/community/screens/edit_club_screen.dart';
import 'package:app_quanly_giaidau/features/payment/screens/payments_screen.dart';
import 'package:app_quanly_giaidau/features/payment/screens/checkout_screen.dart';
import 'package:app_quanly_giaidau/features/payment/screens/payos_verify_screen.dart';
import 'package:app_quanly_giaidau/features/payment/screens/payment_result_screen.dart';
import 'package:app_quanly_giaidau/features/profile/screens/profile_screen.dart';
import 'package:app_quanly_giaidau/features/profile/screens/user_profile_screen.dart';
import 'package:app_quanly_giaidau/features/profile/screens/settings_screen.dart';
import 'package:app_quanly_giaidau/features/profile/screens/change_password_screen.dart';
import 'package:app_quanly_giaidau/features/reports/screens/my_reports_screen.dart';
import 'package:app_quanly_giaidau/features/rankings/screens/elo_history_screen.dart';
import 'package:app_quanly_giaidau/features/rankings/screens/leaderboard_screen.dart';
import 'package:app_quanly_giaidau/providers/user_provider.dart';
import 'package:app_quanly_giaidau/features/admin/screens/admin_clubs_screen.dart';
import 'package:app_quanly_giaidau/features/admin/screens/change_requests_screen.dart';
import 'package:app_quanly_giaidau/features/admin/screens/disputes_screen.dart';
import 'package:app_quanly_giaidau/features/admin/screens/transactions_screen.dart';
import 'package:app_quanly_giaidau/features/admin/screens/verification_screen.dart';
import 'package:app_quanly_giaidau/features/referee/screens/referee_invites_screen.dart';
import 'package:app_quanly_giaidau/features/live/screens/live_match_screen.dart';
import 'package:app_quanly_giaidau/features/live/screens/device_pairing_screen.dart';
import 'package:app_quanly_giaidau/features/football_team/screens/football_teams_screen.dart';

import 'package:app_quanly_giaidau/features/register/screens/tournament_register_screen.dart';
import 'package:app_quanly_giaidau/features/register/screens/football_team_register_screen.dart';
import 'package:app_quanly_giaidau/features/register/screens/doubles_registration_screen.dart';
import 'package:app_quanly_giaidau/features/register/screens/join_team_screen.dart';
import 'package:app_quanly_giaidau/features/register/screens/invite_code_join_screen.dart';
import 'package:app_quanly_giaidau/features/lite/screens/lite_join_screen.dart';
import 'package:app_quanly_giaidau/features/lite/screens/lite_pairing_screen.dart';
import 'package:app_quanly_giaidau/features/lite/screens/lite_management_screen.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament_registration.dart';
import 'package:app_quanly_giaidau/features/dashboard/screens/dashboard_screen.dart';
import 'package:app_quanly_giaidau/features/organizer_ops/screens/organizer_ops_screen.dart';
import 'package:app_quanly_giaidau/features/series/screens/series_screen.dart';
import 'package:app_quanly_giaidau/features/series/screens/series_detail_screen.dart';
import 'package:app_quanly_giaidau/features/match/screens/matches_list_screen.dart';
import 'package:app_quanly_giaidau/features/chat/screens/chat_screen.dart';
import 'package:app_quanly_giaidau/features/chat/screens/chat_detail_screen.dart';
import 'package:app_quanly_giaidau/features/community/social/community_social_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final auth = ref.read(authProvider);
      final isAuth = auth.status == AuthStatus.authenticated;
      final currentPath = state.matchedLocation;
      final isPublicRegistrationRoute =
          currentPath.startsWith('/register/') ||
          currentPath.startsWith('/join/') ||
          currentPath == '/join-team' ||
          currentPath.startsWith('/lite-join/');

      // Splash screen & Login screen — luôn cho phép
      if (currentPath == '/' ||
          currentPath == '/login' ||
          currentPath == '/login-loading' ||
          currentPath == '/forgot-password' ||
          currentPath == '/reset-password') {
        return null;
      }

      // Chưa auth nhưng cố truy cập referee hoặc admin
      if (!isAuth &&
          (currentPath.startsWith('/referee') ||
              currentPath.startsWith('/admin') ||
              currentPath.startsWith('/organizer/tournaments'))) {
        return '/login';
      }

      // Camera pairing is an operator-only flow; it must not inherit the public live-viewer allowlist.
      if (!isAuth && currentPath.startsWith('/live/device-pairing')) {
        return '/login';
      }

      // Chưa auth thì mặc định về /home (cho phép truy cập các trang công khai)
      if (!isAuth &&
          currentPath != '/home' &&
          currentPath != '/login-loading' &&
          currentPath != '/forgot-password' &&
          currentPath != '/reset-password' &&
          currentPath != '/scan-qr' &&
          !currentPath.startsWith('/profile') &&
          !currentPath.startsWith('/intro') &&
          !currentPath.startsWith('/club') &&
          !currentPath.startsWith('/communities') &&
          !currentPath.startsWith('/tournament') &&
          !currentPath.startsWith('/tournaments') &&
          !currentPath.startsWith('/live-matches') &&
          !currentPath.startsWith('/live') &&
          !currentPath.startsWith('/matches') &&
          !currentPath.startsWith('/chat') &&
          !currentPath.startsWith('/user') &&
          !currentPath.startsWith('/series') &&
          !currentPath.startsWith('/rankings') &&
          !isPublicRegistrationRoute) {
        return '/home';
      }

      // Đã auth và ở /login -> về /home
      if (isAuth && currentPath == '/login') {
        return '/home';
      }

      // Kiểm tra quyền truy cập route
      if (isAuth) {
        final hasTournament =
            auth.tournamentId != null && auth.tournamentId!.isNotEmpty;
        if ((currentPath == '/referee' || currentPath == '/viewer') &&
            !hasTournament) {
          return '/home';
        }

        if (currentPath.startsWith('/admin') && auth.role != UserRole.admin) {
          return auth.role == UserRole.referee ? '/referee' : '/viewer';
        }
        // OP access is tournament-scoped. Authenticated users may enter the
        // workspace so the protected API can verify owner/co-organizer access;
        // non-managers must receive a fail-closed 403 state from the screen.
        if (currentPath.startsWith('/referee') &&
            auth.role == UserRole.viewer) {
          return '/viewer';
        }
      }

      return null;
    },
    routes: [
      // ─── Splash ───
      GoRoute(path: '/', builder: (context, state) => const SplashScreen()),

      // ─── Login/Register ───
      GoRoute(
        path: '/login',
        builder: (context, state) => LoginRegisterScreen(
          redirectPath: state.uri.queryParameters['redirect'],
        ),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/reset-password',
        builder: (context, state) {
          final token = state.uri.queryParameters['token'] ?? '';
          return ResetPasswordScreen(token: token);
        },
      ),

      // ─── Login Loading Transition ───
      GoRoute(
        path: '/login-loading',
        builder: (context, state) =>
            LoginLoadingScreen(redirectPath: state.extra as String?),
      ),

      // ─── Home ───
      GoRoute(
        path: '/home',
        builder: (context, state) {
          final tabStr = state.uri.queryParameters['tab'];
          final initialTab = int.tryParse(tabStr ?? '') ?? 0;
          return HomeScreen(initialTab: initialTab);
        },
      ),

      // ─── Public Leaderboard ───
      GoRoute(
        path: '/rankings',
        builder: (context, state) => LeaderboardScreen(
          standalone: true,
          selectedSport: state.uri.queryParameters['sport'] ?? 'all',
          searchQuery: state.uri.queryParameters['q'] ?? '',
        ),
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
            path: 'social',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              final l10n = AppLocalizations.of(context)!;
              final name =
                  state.uri.queryParameters['name'] ??
                  l10n.routerDefaultCommunity;
              return CommunitySocialScreen(
                communityId: id,
                communityName: name,
                targetPostId: state.uri.queryParameters['postId'],
              );
            },
          ),
          GoRoute(
            path: 'chat',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              final l10n = AppLocalizations.of(context)!;
              final name =
                  state.uri.queryParameters['name'] ??
                  l10n.routerDefaultCommunity;
              final avatar = state.uri.queryParameters['avatar'];
              return _ClubChatRouteWrapper(
                communityId: id,
                communityName: name,
                communityAvatar: avatar,
              );
            },
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
          // Admin: Quản lý CLB
          GoRoute(
            path: 'clubs',
            builder: (context, state) => const AdminClubsScreen(),
          ),
          GoRoute(
            path: 'change-requests',
            builder: (context, state) => const AdminChangeRequestsScreen(),
          ),
          GoRoute(
            path: 'disputes',
            builder: (context, state) => const AdminDisputesScreen(),
          ),
          GoRoute(
            path: 'transactions',
            builder: (context, state) => const AdminTransactionsScreen(),
          ),
          GoRoute(
            path: 'verification',
            builder: (context, state) => const AdminVerificationScreen(),
          ),
        ],
      ),

      // ─── Create Tournament Standalone (Must be placed before /tournaments/:id) ───
      GoRoute(
        path: '/tournaments/create',
        builder: (context, state) => const CreatePublicQuickTournamentScreen(),
      ),
      GoRoute(
        path: '/tournament/create',
        builder: (context, state) => const CreatePublicQuickTournamentScreen(),
      ),
      GoRoute(
        path: '/tournament-create',
        builder: (context, state) => const CreatePublicQuickTournamentScreen(),
      ),

      // ─── Advanced Organizer Operations ───
      GoRoute(
        path: '/organizer/tournaments/:id/ops',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return OrganizerOpsScreen(
            tournamentId: id,
            initialDivisionId: state.uri.queryParameters['divisionId'],
            initialFocusMatchId: state.uri.queryParameters['focusMatchId'],
          );
        },
        routes: [
          GoRoute(
            path: 'bracket',
            builder: (context, state) {
              final tournamentId = state.pathParameters['id']!;
              return BracketViewScreen(
                tournamentId: tournamentId,
                divisionId: state.uri.queryParameters['divisionId'],
                canEditBracket: true,
              );
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
        ],
      ),

      // ─── Public Tournament Intro Screen (Both /intro/:id, /tournament/:id and /tournaments/:id) ───
      GoRoute(
        path: '/intro/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          final invite = state.uri.queryParameters['invite'];
          return TournamentIntroScreen(tournamentId: id, inviteCode: invite);
        },
      ),
      GoRoute(
        path: '/tournament/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          final invite = state.uri.queryParameters['invite'];
          return TournamentIntroScreen(tournamentId: id, inviteCode: invite);
        },
      ),
      GoRoute(
        path: '/tournaments/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          final invite = state.uri.queryParameters['invite'];
          return TournamentIntroScreen(tournamentId: id, inviteCode: invite);
        },
      ),

      // ─── Public User Profile (/user/:id and /users/:id) ───
      GoRoute(
        path: '/user/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return UserProfileScreen(
            userId: id,
            communityId: state.uri.queryParameters['communityId'],
          );
        },
      ),
      GoRoute(
        path: '/users/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return UserProfileScreen(
            userId: id,
            communityId: state.uri.queryParameters['communityId'],
          );
        },
      ),
      GoRoute(
        path: '/profile/user/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return UserProfileScreen(
            userId: id,
            communityId: state.uri.queryParameters['communityId'],
          );
        },
      ),

      // ─── Live Matches Screen ───
      GoRoute(
        path: '/live-matches/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return LiveMatchScreen(tournamentId: id);
        },
      ),

      // ─── Camera Device Pairing Route ───
      GoRoute(
        path: '/live/device-pairing/:communityId',
        builder: (context, state) {
          final communityId = state.pathParameters['communityId']!;
          return DevicePairingScreen(communityId: communityId);
        },
      ),

      // ─── Public Live Match Viewer Route ───
      GoRoute(
        path: '/live/:matchId',
        builder: (context, state) {
          final matchId = state.pathParameters['matchId']!;
          return LiveScoreScreen(
            tournamentId: '',
            matchId: matchId,
            isViewer: true,
          );
        },
      ),

      // ─── Referee Routes ───
      GoRoute(
        path: '/referee',
        builder: (context, state) {
          final tournamentId = ref.read(authProvider).tournamentId ?? '';
          return BracketViewScreen(tournamentId: tournamentId, isReferee: true);
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
          GoRoute(
            path: 'invites',
            builder: (context, state) => const RefereeInvitesScreen(),
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

      // ─── Notifications ───
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationScreen(),
      ),

      // ─── Create Club ───
      GoRoute(
        path: '/club-create',
        builder: (context, state) => const CreateClubScreen(),
      ),
      GoRoute(
        path: '/club/create',
        builder: (context, state) => const CreateClubScreen(),
      ),

      // ─── Club Detail (Both /club/:id and /communities/:id and /clubs/:id) ───
      GoRoute(
        path: '/club/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ClubDetailScreen(clubId: id);
        },
        routes: [
          GoRoute(
            path: 'chat',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              final l10n = AppLocalizations.of(context)!;
              final name =
                  state.uri.queryParameters['name'] ??
                  l10n.routerDefaultCommunity;
              final avatar = state.uri.queryParameters['avatar'];
              return _ClubChatRouteWrapper(
                communityId: id,
                communityName: name,
                communityAvatar: avatar,
              );
            },
          ),
          GoRoute(
            path: 'create-tournament',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return CreateClubTournamentScreen(clubId: id);
            },
          ),
          GoRoute(
            path: 'edit',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return EditClubScreen(clubId: id);
            },
          ),
          GoRoute(
            path: 'manage',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              final isOwner = state.extra as bool? ?? false;
              return ClubManagementScreen(clubId: id, isOwner: isOwner);
            },
          ),
          GoRoute(
            path: 'tournaments',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return ClubTournamentsScreen(clubId: id);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/communities/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ClubDetailScreen(clubId: id);
        },
        routes: [
          GoRoute(
            path: 'chat',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              final l10n = AppLocalizations.of(context)!;
              final name =
                  state.uri.queryParameters['name'] ??
                  l10n.routerDefaultCommunity;
              final avatar = state.uri.queryParameters['avatar'];
              return _ClubChatRouteWrapper(
                communityId: id,
                communityName: name,
                communityAvatar: avatar,
              );
            },
          ),
          GoRoute(
            path: 'social',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              final l10n = AppLocalizations.of(context)!;
              final name =
                  state.uri.queryParameters['name'] ??
                  l10n.routerDefaultCommunity;
              return CommunitySocialScreen(
                communityId: id,
                communityName: name,
              );
            },
          ),
        ],
      ),
      GoRoute(
        path: '/clubs/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ClubDetailScreen(clubId: id);
        },
      ),

      // ─── Public Tournament Bracket ───
      GoRoute(
        path: '/tournament/:id/bracket',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          final auth = ref.read(authProvider);
          return BracketViewScreen(
            tournamentId: id,
            isReferee: auth.role == UserRole.referee && auth.tournamentId == id,
          );
        },
      ),

      GoRoute(
        path: '/football-teams',
        builder: (context, state) => FootballTeamsScreen(
          initialTeamId: state.uri.queryParameters['teamId'],
        ),
      ),

      // ─── Profile & Subroutes ───
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
        routes: [
          GoRoute(
            path: 'edit',
            builder: (context, state) => const SettingsScreen(),
          ),
          GoRoute(
            path: 'change-password',
            builder: (context, state) => const ChangePasswordScreen(),
          ),
          GoRoute(
            path: 'settings',
            builder: (context, state) => const SettingsScreen(),
          ),
          GoRoute(
            path: 'reports',
            builder: (context, state) => const MyReportsScreen(),
          ),
          GoRoute(
            path: 'elo',
            builder: (context, state) {
              return Consumer(
                builder: (context, ref, _) {
                  final profile = ref.watch(userProfileProvider).asData?.value;
                  final userId = profile?.id ?? '';
                  final l10n = AppLocalizations.of(context)!;
                  final userName = profile?.fullName ?? l10n.routerDefaultUser;
                  final avatarUrl = profile?.avatarUrl;
                  return EloHistoryScreen(
                    userId: userId,
                    userName: userName,
                    avatarUrl: avatarUrl,
                    currentElo: 1000,
                  );
                },
              );
            },
          ),
          GoRoute(
            path: 'user/:id',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              // Query communityId: mở hồ sơ từ ngữ cảnh CLB → hiện "Danh hiệu CLB".
              return UserProfileScreen(
                userId: id,
                communityId: state.uri.queryParameters['communityId'],
              );
            },
          ),
        ],
      ),

      // ─── Join by Invite ───
      GoRoute(
        path: '/join/:inviteCode',
        builder: (context, state) {
          final code = state.pathParameters['inviteCode']!;
          return InviteCodeJoinScreen(inviteCode: code);
        },
      ),
      GoRoute(
        path: '/join-team',
        builder: (context, state) {
          final extra = state.extra as Map?;
          return JoinTeamScreen(
            tournamentId:
                extra?['tournamentId'] ??
                state.uri.queryParameters['tournamentId'] ??
                '',
            participantId:
                extra?['participantId'] ??
                state.uri.queryParameters['pid'] ??
                '',
            token: extra?['token'] ?? state.uri.queryParameters['token'] ?? '',
          );
        },
      ),
      GoRoute(
        path: '/lite-join/:inviteCode',
        builder: (context, state) {
          final inviteCode = state.pathParameters['inviteCode']!;
          return LiteJoinScreen(inviteCode: inviteCode);
        },
      ),
      GoRoute(
        path: '/lite/tournaments/join/:inviteCode',
        builder: (context, state) {
          final inviteCode = state.pathParameters['inviteCode']!;
          return LiteJoinScreen(inviteCode: inviteCode);
        },
      ),

      // ─── Tournament Register ───
      GoRoute(
        path: '/register/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          final inviteCode = state.uri.queryParameters['invite'];
          final divisionId = state.uri.queryParameters['divisionId'];
          return TournamentRegisterScreen(
            tournamentId: id,
            inviteCode: inviteCode,
            divisionId: divisionId,
          );
        },
      ),
      GoRoute(
        path: '/register/:id/doubles',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          final inviteCode = state.uri.queryParameters['invite'];
          // Division info passed via extra
          final extra = state.extra;
          return DoublesRegistrationFlow(
            tournamentId: id,
            division: extra as TournamentDivisionOption,
            inviteCode: inviteCode,
          );
        },
      ),
      // Team sport (bóng đá): đăng ký đội nhiều người
      GoRoute(
        path: '/register/:id/team',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return FootballTeamRegisterScreen(
            tournamentId: id,
            divisionId: state.uri.queryParameters['divisionId'],
            categoryId: state.uri.queryParameters['categoryId'],
            inviteCode: state.uri.queryParameters['invite'],
            participantId: state.uri.queryParameters['participantId'],
            teamSize:
                int.tryParse(state.uri.queryParameters['teamSize'] ?? '') ?? 7,
            maxReserve:
                int.tryParse(state.uri.queryParameters['maxReserve'] ?? '') ??
                0,
          );
        },
      ),

      // ─── Series ───
      GoRoute(
        path: '/series',
        builder: (context, state) => const SeriesScreen(),
      ),
      GoRoute(
        path: '/series/:slug',
        builder: (context, state) {
          final slug = state.pathParameters['slug']!;
          return SeriesDetailScreen(slug: slug);
        },
      ),

      // ─── Matches List ───
      GoRoute(
        path: '/matches',
        builder: (context, state) => const MatchesListScreen(),
      ),

      // ─── Chat ───
      GoRoute(
        path: '/chat',
        builder: (context, state) => const ChatScreen(),
        routes: [
          GoRoute(
            path: ':id',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              final name = state.uri.queryParameters['name'];
              final avatar = state.uri.queryParameters['avatar'];
              final type = state.uri.queryParameters['type'];
              final communityId = state.uri.queryParameters['communityId'];
              return ChatDetailScreen(
                roomId: id,
                roomName: name,
                roomAvatar: avatar,
                roomType: type,
                communityId: communityId,
              );
            },
          ),
        ],
      ),

      // ─── Dashboard ───
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/lite-pairing/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return LitePairingScreen(tournamentId: id);
        },
      ),

      GoRoute(
        path: '/lite-manage/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return LiteManagementScreen(tournamentId: id);
        },
      ),
      GoRoute(
        path: '/lite/tournaments/:id/manage',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return LiteManagementScreen(tournamentId: id);
        },
      ),

      // ─── Club Invites ───
      GoRoute(
        path: '/club-invites',
        builder: (context, state) => const ClubInvitesScreen(),
      ),

      // ─── Payment Routes ───
      GoRoute(
        path: '/payments',
        builder: (context, state) => const PaymentsScreen(),
      ),
      GoRoute(
        path: '/payment/checkout',
        builder: (context, state) {
          final extra = state.extra as Map?;
          final q = state.uri.queryParameters;
          final tournamentId =
              extra?['tournamentId']?.toString() ?? q['tournamentId'] ?? '';
          final participantId =
              extra?['participantId']?.toString() ?? q['participantId'] ?? '';
          final divisionId =
              extra?['divisionId']?.toString() ?? q['divisionId'];
          final amount =
              (extra?['amount'] as num?)?.toDouble() ??
              double.tryParse(q['amount'] ?? '') ??
              0.0;
          final tournamentName =
              extra?['tournamentName']?.toString() ?? q['tournamentName'];

          return CheckoutScreen(
            tournamentId: tournamentId,
            participantId: participantId,
            divisionId: divisionId,
            amount: amount,
            tournamentName: tournamentName,
          );
        },
      ),
      GoRoute(
        path: '/payment/payos-verify',
        builder: (context, state) {
          final extra = state.extra as Map?;
          final q = state.uri.queryParameters;
          final paymentId =
              extra?['paymentId']?.toString() ?? q['paymentId'] ?? '';
          final amount =
              (extra?['amount'] as num?)?.toDouble() ??
              double.tryParse(q['amount'] ?? '') ??
              0.0;
          final tournamentId =
              extra?['tournamentId']?.toString() ?? q['tournamentId'] ?? '';
          final tournamentName =
              extra?['tournamentName']?.toString() ?? q['tournamentName'];
          final paymentUrl =
              extra?['paymentUrl']?.toString() ?? q['paymentUrl'];
          final qrCode = extra?['qrCode']?.toString() ?? q['qrCode'];
          final expiresAt = extra?['expiresAt']?.toString() ?? q['expiresAt'];
          final orderCode = extra?['orderCode']?.toString() ?? q['orderCode'];

          return PayOSVerifyScreen(
            paymentId: paymentId,
            amount: amount,
            tournamentId: tournamentId,
            tournamentName: tournamentName,
            paymentUrl: paymentUrl,
            qrCode: qrCode,
            expiresAt: expiresAt,
            orderCode: orderCode,
          );
        },
      ),
      GoRoute(
        path: '/payment/result',
        builder: (context, state) => const PaymentResultScreen(),
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
              AppLocalizations.of(context)!.tournamentNotFound,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => context.go('/'),
              child: Text(AppLocalizations.of(context)!.coreBackToHome),
            ),
          ],
        ),
      ),
    ),
  );
});

class _ClubChatRouteWrapper extends ConsumerStatefulWidget {
  final String communityId;
  final String communityName;
  final String? communityAvatar;

  const _ClubChatRouteWrapper({
    required this.communityId,
    required this.communityName,
    this.communityAvatar,
  });

  @override
  ConsumerState<_ClubChatRouteWrapper> createState() =>
      _ClubChatRouteWrapperState();
}

class _ClubChatRouteWrapperState extends ConsumerState<_ClubChatRouteWrapper> {
  String? _roomId;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRoom();
  }

  Future<void> _loadRoom() async {
    try {
      final dio = ref.read(dioClientProvider).dio;
      final res = await dio.get(
        '/chat/rooms',
        queryParameters: {'type': 'CLUB', 'communityId': widget.communityId},
      );
      final raw = res.data is Map ? (res.data['data'] ?? res.data) : res.data;
      final room = raw is List
          ? (raw.isEmpty ? null : raw.first as Map<String, dynamic>)
          : (raw as Map<String, dynamic>?);
      final roomId = room?['id']?.toString();
      if (roomId == null || roomId.isEmpty) {
        throw Exception('Không tìm thấy phòng chat CLB');
      }
      if (mounted) {
        setState(() {
          _roomId = roomId;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            widget.communityName,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppTheme.primary),
        ),
      );
    }
    if (_error != null || _roomId == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            widget.communityName,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.cloud_off_rounded,
                  size: 48,
                  color: Colors.red,
                ),
                const SizedBox(height: 12),
                Text(
                  _error ?? 'Không thể tải phòng chat',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () {
                    setState(() {
                      _loading = true;
                      _error = null;
                    });
                    _loadRoom();
                  },
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return ChatDetailScreen(
      roomId: _roomId!,
      roomName: widget.communityName,
      roomAvatar: widget.communityAvatar,
      roomType: 'CLUB',
      communityId: widget.communityId,
    );
  }
}
