import 'dart:async';

import 'package:app_quanly_giaidau/core/di/core_di_providers.dart';
import 'package:app_quanly_giaidau/data/models/community_member_model.dart';
import 'package:app_quanly_giaidau/data/models/community_social_models.dart';
import 'package:app_quanly_giaidau/domain/entities/user.dart';
import 'package:app_quanly_giaidau/features/profile/screens/user_profile_screen.dart';
import 'package:app_quanly_giaidau/features/profile/widgets/user_profile_bottom_sheet.dart';
import 'package:app_quanly_giaidau/features/rankings/screens/elo_history_screen.dart';
import 'package:app_quanly_giaidau/core/widgets/rank_tier_badge.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/community_provider.dart';
import 'package:app_quanly_giaidau/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import '../../support/fake_api_adapter.dart';

const _userId = 'user-42';
const _communityId = 'club-7';

UserPublicRank _rank({
  String category = 'Pickleball',
  String categoryId = 'cat-pb',
  int elo = 1200,
  int played = 10,
  int won = 6,
  String? matchType,
  String? partnerName,
  String? streakType,
  int streakCount = 0,
  bool adminEligible = false,
}) => UserPublicRank(
  categoryId: categoryId,
  categoryName: category,
  eloPoints: elo,
  tierName: 'Bạc',
  matchesPlayed: played,
  matchesWon: won,
  matchType: matchType,
  partnerName: partnerName,
  currentStreakType: streakType,
  currentStreakCount: streakCount,
  adminLeaderboardEligible: adminEligible,
);

UserPublicProfile _profile({
  String name = 'Nguyễn Văn An',
  String? bio,
  String? gender,
  String? role,
  bool verified = false,
  List<UserPublicRank> ranks = const [],
  List<UserPublicAchievement> achievements = const [],
}) => UserPublicProfile(
  id: _userId,
  fullName: name,
  bio: bio,
  gender: gender,
  role: role,
  isVerified: verified,
  ranks: ranks,
  achievements: achievements,
);

UserPublicAchievement _achievement(int rank, String tournament) =>
    UserPublicAchievement(
      tournamentId: 't-$tournament',
      tournamentName: tournament,
      rank: rank,
    );

Map<String, dynamic> _matchJson(
  String id, {
  String status = 'COMPLETED',
  String team1 = 'Đội Xanh',
  String team2 = 'Đội Đỏ',
  String team1Id = 'a',
  String team2Id = 'b',
  int score1 = 11,
  int score2 = 7,
  String? tournament = 'Giải Mùa Hè',
}) => {
  'id': id,
  'status': status,
  'team1Id': team1Id,
  'team2Id': team2Id,
  'team1Name': team1,
  'team2Name': team2,
  'score1': score1,
  'score2': score2,
  'tournamentName': ?tournament,
};

Map<String, FakeReply> _routes({
  bool canMessage = true,
  List<Map<String, dynamic>> matches = const [],
}) => {
  'GET /chat/direct-policy/$_userId': FakeReply(200, {
    'data': {'canMessage': canMessage},
  }),
  'GET /matches': FakeReply(200, {'data': matches}),
};

/// DioClient dùng I/O thật nên cho vài nhịp thời gian thật rồi dựng lại khung
/// hình (màn có shimmer nên không dùng pumpAndSettle).
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 4; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 30)),
    );
    await tester.pump(const Duration(milliseconds: 200));
  }
}

Future<void> _pump(
  WidgetTester tester, {
  FutureOr<UserPublicProfile> Function()? profile,
  Map<String, FakeReply>? routes,
  String? communityId,
  Map<String, CommunityMemberModel>? members,
  List<CommunityTagPreset> presets = const [],
  FakeApiAdapter? adapter,
}) async {
  tester.view.physicalSize = const Size(900, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final api = adapter ?? FakeApiAdapter(routes ?? _routes());
  final router = GoRouter(
    initialLocation: '/start',
    routes: [
      GoRoute(
        path: '/start',
        builder: (context, _) => Scaffold(
          body: TextButton(
            onPressed: () => context.push('/profile'),
            child: const Text('MỞ HỒ SƠ'),
          ),
        ),
      ),
      GoRoute(
        path: '/profile',
        builder: (_, _) =>
            UserProfileScreen(userId: _userId, communityId: communityId),
      ),
      GoRoute(
        path: '/home',
        builder: (_, _) => const Scaffold(body: Text('AT /home')),
      ),
    ],
  );
  final overrides = <Override>[
    dioClientProvider.overrideWithValue(fakeDioClient(api)),
    userPublicProfileProvider(
      _userId,
    ).overrideWith((ref) async => (profile ?? _profile).call()),
    if (communityId != null) ...[
      communityMemberDirectoryProvider(
        communityId,
      ).overrideWith((ref) async => members ?? const {}),
      communityTagPresetsProvider(
        communityId,
      ).overrideWith((ref) async => presets),
    ],
  ];
  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: overrides,
      child: MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('vi'),
        theme: ThemeData.light(),
      ),
    ),
  );
  await tester.pump();
  await tester.tap(find.text('MỞ HỒ SƠ'));
  await tester.pump();
  await _settle(tester);
}

Future<void> _openTab(WidgetTester tester, String label) async {
  await tester.tap(find.text(label));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump(const Duration(milliseconds: 400));
  await _settle(tester);
}

void main() {
  setUpAll(() {
    dotenv.loadFromString(envString: 'API_BASE_URL=https://api.example.test');
  });

  final l10n = lookupAppLocalizations(const Locale('vi'));

  group('tải hồ sơ', () {
    testWidgets('đang tải: hiện khung shimmer, chưa có tên hay tab', (
      tester,
    ) async {
      final gate = Completer<UserPublicProfile>();
      await _pump(tester, profile: () => gate.future);

      expect(find.byType(Shimmer), findsWidgets);
      expect(find.text(l10n.publicProfileTabOverview), findsNothing);

      gate.complete(_profile());
      await _settle(tester);
      expect(find.text('Nguyễn Văn An'), findsOneWidget);
    });

    testWidgets(
      'tải lỗi: báo không thể tải và nút Về trang chủ dẫn tới /home',
      (tester) async {
        await _pump(tester, profile: () => throw StateError('hết phiên'));

        expect(find.text(l10n.publicProfileLoadError), findsOneWidget);
        expect(find.byIcon(Icons.person_off_rounded), findsOneWidget);
        expect(find.text(l10n.publicProfileTabOverview), findsNothing);

        await tester.tap(find.text(l10n.publicProfileHomeButton));
        await _settle(tester);
        expect(find.text('AT /home'), findsOneWidget);
      },
    );

    // BUG-PROFILE-01: màn lỗi in nguyên err.toString() ("Bad state: ...",
    // "DioException [...]") cho người dùng cuối thay vì thông điệp đã dịch.
    testWidgets(
      'BUG-PROFILE-01 màn lỗi không lộ chuỗi ngoại lệ kỹ thuật cho người dùng',
      (tester) async {
        await _pump(tester, profile: () => throw StateError('socket closed'));

        expect(find.textContaining('Bad state'), findsNothing);
        expect(find.textContaining('socket closed'), findsNothing);
      },
      skip: true,
    );
  });

  group('tab Tổng quan', () {
    testWidgets('hiện tên, 3 tab và vai trò mặc định Vận động viên', (
      tester,
    ) async {
      await _pump(tester);

      expect(find.text('Nguyễn Văn An'), findsOneWidget);
      expect(find.text(l10n.publicProfileTabOverview), findsOneWidget);
      expect(find.text(l10n.publicProfileTabMatches), findsOneWidget);
      expect(find.text(l10n.publicProfileTabAchievements), findsOneWidget);
      expect(find.text(l10n.infoPlayer), findsOneWidget);
    });

    for (final entry in {
      'ADMIN': 'infoAdmin',
      'organizer': 'infoOrganizer',
      'REFEREE': 'infoReferee',
      'CAPTAIN': 'infoLeader',
      'COACH': 'infoCoach',
      'không-biết': 'infoPlayer',
    }.entries) {
      testWidgets('vai ${entry.key} hiển thị nhãn ${entry.value}', (
        tester,
      ) async {
        await _pump(tester, profile: () => _profile(role: entry.key));
        final label = switch (entry.value) {
          'infoAdmin' => l10n.infoAdmin,
          'infoOrganizer' => l10n.infoOrganizer,
          'infoReferee' => l10n.infoReferee,
          'infoLeader' => l10n.infoLeader,
          'infoCoach' => l10n.infoCoach,
          _ => l10n.infoPlayer,
        };

        expect(find.text(label), findsOneWidget);
      });
    }

    testWidgets('tích xác thực chỉ hiện khi đã xác thực', (tester) async {
      await _pump(tester, profile: () => _profile(verified: true));
      expect(find.byIcon(Icons.verified_rounded), findsOneWidget);
    });

    testWidgets('chưa xác thực: không có tích xác thực', (tester) async {
      await _pump(tester);
      expect(find.byIcon(Icons.verified_rounded), findsNothing);
    });

    testWidgets('hiện tiểu sử và giới tính khi có, ẩn khi trống', (
      tester,
    ) async {
      await _pump(
        tester,
        profile: () => _profile(bio: 'Mê pickleball', gender: 'Nam'),
      );
      expect(find.text('Mê pickleball'), findsOneWidget);
      expect(find.text('Nam'), findsOneWidget);
      expect(find.byIcon(Icons.male_rounded), findsOneWidget);
    });

    testWidgets('không có tiểu sử hay giới tính: không dựng dòng tương ứng', (
      tester,
    ) async {
      await _pump(tester);
      expect(find.byIcon(Icons.male_rounded), findsNothing);
      expect(find.byIcon(Icons.female_rounded), findsNothing);
    });

    testWidgets(
      'chưa có xếp hạng: hiện Chưa có dữ liệu xếp hạng và thống kê bằng 0',
      (tester) async {
        await _pump(tester);

        expect(find.text(l10n.publicProfileRankBySport), findsOneWidget);
        expect(find.text(l10n.publicProfileNoRankData), findsOneWidget);
        expect(find.text('0%'), findsOneWidget);
      },
    );

    testWidgets('rank chưa đấu trận nào và chưa được admin duyệt thì bị ẩn', (
      tester,
    ) async {
      await _pump(
        tester,
        profile: () => _profile(
          ranks: [_rank(category: 'Cầu lông', played: 0, won: 0, elo: 1000)],
        ),
      );

      expect(find.text('Cầu lông'), findsNothing);
      expect(find.text(l10n.publicProfileNoRankData), findsOneWidget);
    });

    testWidgets('rank chưa đấu nhưng admin cho phép lên bảng vẫn hiện', (
      tester,
    ) async {
      await _pump(
        tester,
        profile: () => _profile(
          ranks: [
            _rank(
              category: 'Tennis',
              played: 0,
              won: 0,
              elo: 1500,
              adminEligible: true,
            ),
          ],
        ),
      );

      expect(find.text('Tennis'), findsOneWidget);
      expect(find.text(l10n.publicProfileNoRankData), findsNothing);
    });

    testWidgets('thẻ xếp hạng: tên môn, ELO, số trận, thắng và tỉ lệ thắng', (
      tester,
    ) async {
      await _pump(
        tester,
        profile: () => _profile(ranks: [_rank(elo: 1337, played: 8, won: 6)]),
      );

      expect(find.text('Pickleball'), findsWidgets);
      expect(find.text('1337'), findsOneWidget);
      expect(find.text('8'), findsWidgets);
      expect(find.text('75%'), findsWidgets);
    });

    testWidgets(
      'thống kê tổng hợp cộng trận, thắng, thua và tỉ lệ qua mọi môn',
      (tester) async {
        await _pump(
          tester,
          profile: () => _profile(
            ranks: [
              _rank(category: 'A', categoryId: 'a', played: 10, won: 7),
              _rank(category: 'B', categoryId: 'b', played: 10, won: 3),
            ],
          ),
        );

        // 20 trận, 10 thắng, 10 thua, 50%
        expect(find.text('20'), findsOneWidget);
        expect(find.text('10'), findsWidgets);
        expect(find.text('50%'), findsWidgets);
      },
    );

    testWidgets('chuỗi hiện tại: thắng, thua và không có chuỗi', (
      tester,
    ) async {
      await _pump(
        tester,
        profile: () => _profile(
          ranks: [
            _rank(
              category: 'A',
              categoryId: 'a',
              streakType: 'WIN',
              streakCount: 3,
            ),
            _rank(
              category: 'B',
              categoryId: 'b',
              streakType: 'LOSS',
              streakCount: 2,
            ),
            _rank(category: 'C', categoryId: 'c', streakType: 'NONE'),
          ],
        ),
      );

      expect(
        find.text(
          '${l10n.publicProfileCurrentStreak}: ${l10n.publicProfileWinStreak(3)}',
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          '${l10n.publicProfileCurrentStreak}: ${l10n.publicProfileLossStreak(2)}',
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          '${l10n.publicProfileCurrentStreak}: ${l10n.publicProfileNoStreak}',
        ),
        findsOneWidget,
      );
    });

    testWidgets('rank đôi có tên đồng đội và nhãn phạm vi Đôi', (tester) async {
      await _pump(
        tester,
        profile: () => _profile(
          ranks: [_rank(matchType: 'DOUBLES', partnerName: 'Lê Hoa')],
        ),
      );

      expect(find.text('${l10n.publicProfilePartner}: Lê Hoa'), findsOneWidget);
      expect(find.text(l10n.publicProfileScopeDoubles), findsOneWidget);
    });

    testWidgets('rank đơn không có dòng đồng đội, nhãn phạm vi là Đơn', (
      tester,
    ) async {
      await _pump(tester, profile: () => _profile(ranks: [_rank()]));

      expect(find.textContaining(l10n.publicProfilePartner), findsNothing);
      expect(find.text(l10n.publicProfileScopeSingles), findsOneWidget);
    });

    testWidgets('huy hiệu cạnh tên: tối đa 2 môn khác nhau có ELO cao nhất', (
      tester,
    ) async {
      await _pump(
        tester,
        profile: () => _profile(
          ranks: [
            _rank(category: 'A', categoryId: 'a', elo: 1900),
            _rank(
              category: 'A',
              categoryId: 'a',
              elo: 1800,
              matchType: 'DOUBLES',
            ),
            _rank(category: 'B', categoryId: 'b', elo: 1500),
            _rank(category: 'C', categoryId: 'c', elo: 1100),
          ],
        ),
      );

      // 2 huy hiệu ở tiêu đề (môn A và B), không trùng môn, bỏ môn C.
      final header = find.ancestor(
        of: find.text('Nguyễn Văn An'),
        matching: find.byType(Row),
      );
      expect(
        find.descendant(of: header.first, matching: find.byType(RankTierBadge)),
        findsNWidgets(2),
      );
    });

    testWidgets('chạm thẻ xếp hạng mở màn lịch sử ELO', (tester) async {
      await _pump(tester, profile: () => _profile(ranks: [_rank()]));

      await tester.tap(find.text(l10n.publicProfileScopeSingles));
      await _settle(tester);

      expect(find.byType(EloHistoryScreen), findsOneWidget);
    });
  });

  group('danh hiệu CLB', () {
    final member = CommunityMemberModel(
      id: 'm1',
      userId: _userId,
      communityId: _communityId,
      tags: const ['Đội trưởng', 'Tài trợ'],
    );

    testWidgets(
      'mở từ CLB và thành viên có nhãn: hiện mục DANH HIỆU CLB với số nhãn',
      (tester) async {
        await _pump(
          tester,
          communityId: _communityId,
          members: {_userId: member},
        );

        expect(find.text(l10n.publicProfileClubTitles), findsOneWidget);
        expect(find.text('2 ${l10n.publicProfileTagUnit}'), findsOneWidget);
        expect(find.text('Đội trưởng'), findsOneWidget);
        expect(find.text('Tài trợ'), findsOneWidget);
      },
    );

    testWidgets('không có ngữ cảnh CLB: không hiện mục danh hiệu CLB', (
      tester,
    ) async {
      await _pump(tester);

      expect(find.text(l10n.publicProfileClubTitles), findsNothing);
    });

    testWidgets('thành viên không có nhãn nào: ẩn mục danh hiệu CLB', (
      tester,
    ) async {
      await _pump(
        tester,
        communityId: _communityId,
        members: {
          _userId: CommunityMemberModel(
            id: 'm1',
            userId: _userId,
            communityId: _communityId,
          ),
        },
      );

      expect(find.text(l10n.publicProfileClubTitles), findsNothing);
    });

    testWidgets('người xem không có trong danh bạ CLB: ẩn mục, không lỗi', (
      tester,
    ) async {
      await _pump(tester, communityId: _communityId, members: const {});

      expect(find.text(l10n.publicProfileClubTitles), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('nút hành động theo quyền', () {
    testWidgets(
      'được phép nhắn tin: hiện nút Nhắn tin và mở bottom sheet khi chạm',
      (tester) async {
        await _pump(tester);

        expect(find.byTooltip(l10n.userProfileMessage), findsOneWidget);
        await tester.tap(find.byTooltip(l10n.userProfileMessage));
        await _settle(tester);

        expect(find.byType(UserProfileBottomSheet), findsOneWidget);
      },
    );

    testWidgets(
      'không được phép nhắn tin (canMessage=false): ẩn nút Nhắn tin',
      (tester) async {
        await _pump(tester, routes: _routes(canMessage: false));

        expect(find.byTooltip(l10n.userProfileMessage), findsNothing);
        expect(find.byTooltip(l10n.publicProfileShareSubtitle), findsOneWidget);
      },
    );

    testWidgets(
      'API chính sách nhắn tin lỗi 403: ẩn nút Nhắn tin (fail closed)',
      (tester) async {
        await _pump(
          tester,
          routes: {
            ..._routes(),
            'GET /chat/direct-policy/$_userId': const FakeReply(403, {
              'message': 'forbidden',
            }),
          },
        );

        expect(find.byTooltip(l10n.userProfileMessage), findsNothing);
      },
    );

    testWidgets('nút quay lại trở về màn trước', (tester) async {
      await _pump(tester);

      await tester.tap(find.byIcon(Icons.arrow_back_ios_rounded));
      await _settle(tester);

      expect(find.text('MỞ HỒ SƠ'), findsOneWidget);
    });
  });

  group('tab Trận đấu', () {
    testWidgets('chưa có trận công khai: hiện thông báo rỗng', (tester) async {
      await _pump(tester);
      await _openTab(tester, l10n.publicProfileTabMatches);

      expect(find.text(l10n.publicProfileNoPublicMatches), findsOneWidget);
    });

    testWidgets('API trận lỗi: hiện thông báo chưa tải được lịch sử', (
      tester,
    ) async {
      await _pump(
        tester,
        routes: {
          ..._routes(),
          'GET /matches': const FakeReply(400, {'message': 'bad'}),
        },
      );
      await _openTab(tester, l10n.publicProfileTabMatches);

      expect(find.text(l10n.publicProfileMatchesLoadError), findsOneWidget);
    });

    testWidgets('liệt kê trận: hai bên, giải, trạng thái và tỉ số', (
      tester,
    ) async {
      await _pump(
        tester,
        routes: _routes(
          matches: [
            _matchJson('m1'),
            _matchJson(
              'm2',
              status: 'SCHEDULED',
              team1: 'Sấm',
              team2: 'Chớp',
              score1: 0,
              score2: 0,
              tournament: null,
            ),
          ],
        ),
      );
      await _openTab(tester, l10n.publicProfileTabMatches);

      expect(find.text('Đội Xanh ${l10n.matchVsLabel} Đội Đỏ'), findsOneWidget);
      expect(find.text('11 - 7'), findsOneWidget);
      expect(
        find.text('Giải Mùa Hè  •  ${l10n.publicProfileMatchCompleted}'),
        findsOneWidget,
      );
      expect(
        find.text(
          '${l10n.publicProfileTournamentFallback}  •  ${l10n.publicProfileMatchUpcoming}',
        ),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.check_circle_outline_rounded), findsOneWidget);
      expect(find.byIcon(Icons.schedule_rounded), findsOneWidget);
    });

    testWidgets(
      'trận chưa xác định đối thủ (thiếu id đội) bị lọc khỏi danh sách',
      (tester) async {
        await _pump(
          tester,
          routes: _routes(
            matches: [
              _matchJson('ok', team1: 'Hợp Lệ 1', team2: 'Hợp Lệ 2'),
              _matchJson('bye', team1: 'Chưa Có', team2Id: ''),
            ],
          ),
        );
        await _openTab(tester, l10n.publicProfileTabMatches);

        expect(
          find.text('Hợp Lệ 1 ${l10n.matchVsLabel} Hợp Lệ 2'),
          findsOneWidget,
        );
        expect(find.textContaining('Chưa Có'), findsNothing);
      },
    );

    testWidgets('chỉ gọi /matches với userId và limit 10', (tester) async {
      final adapter = FakeApiAdapter(_routes());
      await _pump(tester, adapter: adapter);
      await _openTab(tester, l10n.publicProfileTabMatches);

      final call = adapter.requests.firstWhere((r) => r.path == '/matches');
      expect(call.query, {'userId': _userId, 'limit': 10});
    });
  });

  group('tab Danh hiệu', () {
    testWidgets('chưa có thành tích: hiện Chưa có thành tích nào', (
      tester,
    ) async {
      await _pump(tester);
      await _openTab(tester, l10n.publicProfileTabAchievements);

      expect(find.text(l10n.publicProfileAchievementsTitle), findsOneWidget);
      expect(find.text(l10n.publicProfileNoAchievements), findsOneWidget);
    });

    testWidgets(
      'quán quân, á quân, hạng ba: mỗi nhóm một dòng với số lượng và tên giải',
      (tester) async {
        await _pump(
          tester,
          profile: () => _profile(
            achievements: [
              _achievement(3, 'Giải C'),
              _achievement(1, 'Giải A'),
              _achievement(2, 'Giải B'),
              _achievement(1, 'Giải D'),
            ],
          ),
        );
        await _openTab(tester, l10n.publicProfileTabAchievements);

        expect(find.text(l10n.publicProfileChampion), findsOneWidget);
        expect(find.text(l10n.publicProfileRunnerUp), findsOneWidget);
        expect(find.text(l10n.publicProfileThirdPlace), findsOneWidget);
        expect(
          find.text('2 ${l10n.publicProfileCategoryUnit} · Giải A, Giải D'),
          findsOneWidget,
        );
        expect(
          find.text('1 ${l10n.publicProfileCategoryUnit} · Giải B'),
          findsOneWidget,
        );
        expect(find.text(l10n.publicProfileNoAchievements), findsNothing);
      },
    );

    testWidgets(
      'trên 2 giải trong một nhóm: chỉ liệt kê 2 tên rồi thêm dấu ba chấm',
      (tester) async {
        await _pump(
          tester,
          profile: () => _profile(
            achievements: [
              _achievement(1, 'G1'),
              _achievement(1, 'G2'),
              _achievement(1, 'G3'),
            ],
          ),
        );
        await _openTab(tester, l10n.publicProfileTabAchievements);

        expect(
          find.text('3 ${l10n.publicProfileCategoryUnit} · G1, G2...'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'chỉ có hạng tư trở đi (rank 4): không hiện nhóm huy chương nào',
      (tester) async {
        await _pump(
          tester,
          profile: () => _profile(achievements: [_achievement(4, 'Giải Tư')]),
        );
        await _openTab(tester, l10n.publicProfileTabAchievements);

        expect(find.text(l10n.publicProfileNoAchievements), findsOneWidget);
        expect(find.text(l10n.publicProfileChampion), findsNothing);
      },
    );
  });
}
