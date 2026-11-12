import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/data/models/club_match_session_model.dart';
import 'package:app_quanly_giaidau/data/models/community_member_model.dart';
import 'package:app_quanly_giaidau/data/models/community_social_models.dart';
import 'package:app_quanly_giaidau/data/models/social_session_model.dart';
import 'package:app_quanly_giaidau/data/repositories/api/api_club_match_session_repository.dart';
import 'package:app_quanly_giaidau/domain/entities/match.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/domain/repositories/community_repository.dart';
import 'package:app_quanly_giaidau/domain/repositories/match_repository.dart';
import 'package:app_quanly_giaidau/features/community/widgets/club_standalone_match_result_dialog.dart';
import 'package:app_quanly_giaidau/features/match/widgets/official_score_modal.dart';
import 'package:app_quanly_giaidau/features/social/widgets/match_tab/social_match_tab.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:app_quanly_giaidau/providers/club_match_session_provider.dart';
import 'package:app_quanly_giaidau/providers/community_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fake tối giản: chỉ override [standaloneMatches] mà widget thật sự gọi;
/// mọi method khác thừa hưởng `noSuchMethod` của `Fake` (ném lỗi nếu lỡ gọi).
class _FakeMatchSessionRepository extends Fake
    implements ApiClubMatchSessionRepository {
  _FakeMatchSessionRepository(this.standaloneMatchesToReturn);

  final List<ClubSessionMatchModel> standaloneMatchesToReturn;
  String? lastCommunityId;
  String? lastSocialSessionId;

  @override
  Future<List<ClubSessionMatchModel>> standaloneMatches(
    String? communityId, {
    String? socialSessionId,
  }) async {
    lastCommunityId = communityId;
    lastSocialSessionId = socialSessionId;
    return standaloneMatchesToReturn;
  }
}

/// Fake tối giản cho [ICommunityRepository]: chỉ trả về danh sách thành viên
/// CLB đã JOINED mà `SocialMatchTab` dùng để lọc khách mời khỏi ghép đội.
/// `getMyMembership`/`getSocialSettings` trả giá trị mặc định vì các test
/// hiện tại không kiểm trạng thái nút "Tạo trận đấu".
class _FakeCommunityRepository extends Fake implements ICommunityRepository {
  _FakeCommunityRepository(this.membersToReturn);

  final List<CommunityMemberModel> membersToReturn;

  @override
  Future<List<CommunityMemberModel>> getMembers(
    String communityId, {
    int limit = 50,
    String? status,
    String? search,
    bool mentionableOnly = false,
  }) async => membersToReturn;

  @override
  Future<Map<String, dynamic>?> getMyMembership(String communityId) async =>
      null;

  @override
  Future<CommunitySocialSettings> getSocialSettings(
    String communityId,
  ) async => const CommunitySocialSettings();
}

/// Chỉ để [matchRepositoryProvider] không đòi DotEnv; trang bấm điểm mở được.
class _FakeMatchRepository extends Fake implements IMatchRepository {}

class _SignedInAuth extends AuthNotifier {
  @override
  AuthState build() => const AuthState(status: AuthStatus.authenticated);
}

SocialParticipantModel _participant(String id) => SocialParticipantModel(
  id: id,
  userId: 'user-$id',
  joinedAt: DateTime(2026, 1, 1),
  fullName: 'VĐV $id',
);

CommunityMemberModel _clubMember(String id) => CommunityMemberModel(
  id: 'member-$id',
  userId: 'user-$id',
  communityId: 'club-1',
  status: 'JOINED',
  joinedAt: DateTime(2026, 1, 1).toIso8601String(),
);

Widget _buildTestApp({
  String? communityId,
  String sessionId = 'session-1',
  bool isHost = false,
  required List<SocialParticipantModel> approvedParticipants,
  required ApiClubMatchSessionRepository repository,
  List<CommunityMemberModel> clubMembers = const [],
  String? bracketTournamentId,
  bool signedIn = false,
  Future<MatchModel?> Function(BuildContext)? createMatchLauncher,
}) {
  return ProviderScope(
    overrides: [
      if (signedIn) authProvider.overrideWith(_SignedInAuth.new),
      clubMatchSessionRepositoryProvider.overrideWithValue(repository),
      matchRepositoryProvider.overrideWithValue(_FakeMatchRepository()),
      communityRepositoryProvider.overrideWithValue(
        _FakeCommunityRepository(clubMembers),
      ),
    ],
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      locale: const Locale('vi'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SocialMatchTab(
          communityId: communityId,
          sessionId: sessionId,
          isHost: isHost,
          approvedParticipants: approvedParticipants,
          bracketTournamentId: bracketTournamentId,
          createMatchLauncher: createMatchLauncher,
        ),
      ),
    ),
  );
}

MatchModel _created(String status) => MatchModel(
  id: 'new-1',
  round: 1,
  matchNumber: 1,
  bracketPosition: const BracketPosition(round: 1, position: 1),
  status: status,
  updatedAt: DateTime(2026, 1, 1),
);

void main() {
  testWidgets(
    'shows empty state and the create button without any warning text',
    (tester) async {
      final repo = _FakeMatchSessionRepository(const []);
      final participants = [
        _participant('1'),
        _participant('2'),
        _participant('3'),
        _participant('4'),
      ];
      await tester.pumpWidget(
        _buildTestApp(
          communityId: 'club-1',
          approvedParticipants: participants,
          repository: repo,
          clubMembers: [for (final p in participants) _clubMember(p.id)],
        ),
      );
      await tester.pumpAndSettle();

      expect(repo.lastCommunityId, 'club-1');
      expect(
        find.text('Chưa có trận đấu nào được tạo cho CLB này.'),
        findsOneWidget,
      );
      expect(
        find.text('Buổi chưa đủ người tham gia đã duyệt để ghép đội.'),
        findsNothing,
      );
      expect(find.text('Tạo trận đấu'), findsOneWidget);
    },
  );

  testWidgets(
    'TC-SOC-HEAD-01 never shows a warning or a note above the match list',
    (tester) async {
      final participants = [_participant('1'), _participant('2')];
      await tester.pumpWidget(
        _buildTestApp(
          communityId: 'club-1',
          approvedParticipants: participants,
          repository: _FakeMatchSessionRepository(const []),
          clubMembers: [for (final p in participants) _clubMember(p.id)],
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Buổi chưa đủ người tham gia đã duyệt để ghép đội.'),
        findsNothing,
      );
      expect(find.text('Tạo trận đấu'), findsOneWidget);
    },
  );

  testWidgets('renders a scheduled match returned by the repository', (
    tester,
  ) async {
    final repo = _FakeMatchSessionRepository([
      const ClubSessionMatchModel(
        id: 'match-1',
        status: 'SCHEDULED',
        sideAUserIds: ['user-1'],
        sideBUserIds: ['user-2'],
        sideAScore: 0,
        sideBScore: 0,
        revision: 1,
        eloStatus: 'PENDING',
      ),
    ]);
    final participants = [_participant('1'), _participant('2')];
    await tester.pumpWidget(
      _buildTestApp(
        communityId: 'club-1',
        approvedParticipants: participants,
        repository: repo,
        clubMembers: [for (final p in participants) _clubMember(p.id)],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Chưa bắt đầu'), findsOneWidget);
    expect(find.text('Đã lên lịch'), findsNothing);
    expect(
      find.text('Chưa có trận đấu nào được tạo cho CLB này.'),
      findsNothing,
    );
  });

  group('thẻ trận', () {
    ClubSessionMatchModel match(String status, {int a = 0, int b = 0}) =>
        ClubSessionMatchModel(
          id: 'match-1',
          status: status,
          sideAUserIds: const ['user-1'],
          sideBUserIds: const ['user-2'],
          sideAScore: a,
          sideBScore: b,
          revision: 1,
          eloStatus: 'PENDING',
          sideAMembers: const [
            ClubSessionMatchMemberModel(
              userId: 'user-1',
              displayName: 'Nguyễn Minh Danh',
            ),
          ],
          sideBMembers: const [
            ClubSessionMatchMemberModel(
              userId: 'user-2',
              displayName: 'sigma6969',
            ),
          ],
        );

    Future<void> pump(
      WidgetTester tester,
      ClubSessionMatchModel m, {
      bool signedIn = true,
    }) async {
      final participants = [_participant('1'), _participant('2')];
      await tester.pumpWidget(
        _buildTestApp(
          approvedParticipants: participants,
          repository: _FakeMatchSessionRepository([m]),
          signedIn: signedIn,
        ),
      );
      await tester.pumpAndSettle();
    }

    final openScoreboard = find.text('Mở bảng điểm');

    testWidgets('TC-SOC-CARD-01 players without a photo show initials', (
      tester,
    ) async {
      await pump(tester, match('SCHEDULED'));

      expect(find.text('ND'), findsOneWidget);
      expect(find.text('S'), findsOneWidget);
      expect(find.text('Nguyễn Minh Danh'), findsOneWidget);
    });

    testWidgets('TC-SOC-CARD-02 the card has no quick-entry inline button', (
      tester,
    ) async {
      await pump(tester, match('SCHEDULED'));

      expect(find.text('Nhập nhanh'), findsNothing);
      expect(find.byType(OutlinedButton), findsNothing);
    });

    testWidgets('TC-SOC-CARD-03 a finished match shows the score and status', (
      tester,
    ) async {
      await pump(tester, match('COMPLETED', a: 11, b: 7));

      expect(find.text('Đã hoàn thành'), findsOneWidget);
      expect(find.text('11'), findsOneWidget);
      expect(find.text('7'), findsOneWidget);
    });

    testWidgets('TC-SOC-CARD-04 signed-out viewers get no live scoring', (
      tester,
    ) async {
      await pump(tester, match('SCHEDULED'), signedIn: false);

      await tester.tap(find.text('Nguyễn Minh Danh'));
      await tester.pumpAndSettle();

      expect(find.byType(ClubStandaloneMatchResultDialog), findsOneWidget);
      expect(openScoreboard, findsNothing);
    });

    testWidgets('TC-SOC-CARD-05 tapping the card opens quick entry', (
      tester,
    ) async {
      await pump(tester, match('SCHEDULED'));

      await tester.tap(find.text('Nguyễn Minh Danh'));
      await tester.pumpAndSettle();

      expect(find.byType(ClubStandaloneMatchResultDialog), findsOneWidget);
    });

    testWidgets('TC-SOC-CARD-06 quick entry holds the live scoring button', (
      tester,
    ) async {
      await pump(tester, match('SCHEDULED'));

      await tester.tap(find.text('Nguyễn Minh Danh'));
      await tester.pumpAndSettle();

      expect(openScoreboard, findsOneWidget);
    });

    testWidgets('TC-SOC-CARD-07 a finished match offers no live scoring', (
      tester,
    ) async {
      await pump(tester, match('COMPLETED', a: 11, b: 7));

      await tester.tap(find.text('Nguyễn Minh Danh'));
      await tester.pumpAndSettle();

      expect(openScoreboard, findsNothing);
    });

    testWidgets('TC-SOC-CARD-08 status reads as a real match state', (
      tester,
    ) async {
      await pump(tester, match('ONGOING', a: 5, b: 3));

      expect(find.text('Đang diễn ra'), findsOneWidget);
      expect(find.text('Đã lên lịch'), findsNothing);
      expect(find.text('5'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });
  });

  group('nút Bấm điểm', () {
    ClubSessionMatchModel match(String status) => ClubSessionMatchModel(
      id: 'match-1',
      status: status,
      sideAUserIds: const ['user-1'],
      sideBUserIds: const ['user-2'],
      sideAScore: 0,
      sideBScore: 0,
      revision: 1,
      eloStatus: 'PENDING',
      sideAMembers: const [
        ClubSessionMatchMemberModel(userId: 'user-1', displayName: 'Danh'),
      ],
      sideBMembers: const [
        ClubSessionMatchMemberModel(userId: 'user-2', displayName: 'Kha'),
      ],
    );

    Future<void> pump(
      WidgetTester tester,
      String status, {
      bool signedIn = true,
      Future<MatchModel?> Function(BuildContext)? createMatchLauncher,
      bool isHost = false,
    }) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        _buildTestApp(
          approvedParticipants: [_participant('1'), _participant('2')],
          repository: _FakeMatchSessionRepository([match(status)]),
          signedIn: signedIn,
          isHost: isHost,
          createMatchLauncher: createMatchLauncher,
        ),
      );
      await tester.pumpAndSettle();
    }

    final scoreButton = find.widgetWithText(FilledButton, 'Bấm điểm');

    testWidgets('TC-SOCIAL-SCORE-01 thẻ trận chưa xong có nút Bấm điểm đủ 44px', (
      tester,
    ) async {
      await pump(tester, 'SCHEDULED');

      expect(scoreButton, findsOneWidget);
      expect(tester.getSize(scoreButton).height, greaterThanOrEqualTo(44));
      expect(tester.takeException(), isNull);
    });

    testWidgets('TC-SOCIAL-SCORE-02 trận đang diễn ra cũng có nút Bấm điểm', (
      tester,
    ) async {
      await pump(tester, 'ONGOING');

      expect(scoreButton, findsOneWidget);
    });

    testWidgets('TC-SOCIAL-SCORE-03 trận đã hoàn thành không có nút Bấm điểm', (
      tester,
    ) async {
      await pump(tester, 'COMPLETED');

      expect(scoreButton, findsNothing);
    });

    testWidgets('TC-SOCIAL-SCORE-04 chưa đăng nhập không có nút Bấm điểm', (
      tester,
    ) async {
      await pump(tester, 'SCHEDULED', signedIn: false);

      expect(scoreButton, findsNothing);
    });

    testWidgets('TC-SOCIAL-SCORE-05 bấm nút mở thẳng bảng bấm điểm, không qua dialog', (
      tester,
    ) async {
      await pump(tester, 'SCHEDULED');

      await tester.tap(scoreButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(OfficialScorePage), findsOneWidget);
      expect(find.byType(ClubStandaloneMatchResultDialog), findsNothing);
    });

    testWidgets('TC-SOCIAL-SCORE-06 sau khi tạo trận, dialog kết quả có nút Mở bảng điểm', (
      tester,
    ) async {
      await pump(
        tester,
        'SCHEDULED',
        isHost: true,
        createMatchLauncher: (_) async => _created('scheduled'),
      );

      await tester.tap(find.widgetWithText(FilledButton, 'Tạo trận đấu'));
      await tester.pumpAndSettle();

      expect(find.byType(ClubStandaloneMatchResultDialog), findsOneWidget);
      expect(find.text('Mở bảng điểm'), findsOneWidget);
    });

    testWidgets('TC-SOCIAL-SCORE-07 trận vừa tạo đã hoàn thành thì không có Mở bảng điểm', (
      tester,
    ) async {
      await pump(
        tester,
        'SCHEDULED',
        isHost: true,
        createMatchLauncher: (_) async => _created('COMPLETED'),
      );

      await tester.tap(find.widgetWithText(FilledButton, 'Tạo trận đấu'));
      await tester.pumpAndSettle();

      expect(find.byType(ClubStandaloneMatchResultDialog), findsOneWidget);
      expect(find.text('Mở bảng điểm'), findsNothing);
    });
  });

  group('buổi cá nhân không gắn CLB', () {
    final four = [
      _participant('1'),
      _participant('2'),
      _participant('3'),
      _participant('4'),
    ];

    testWidgets('liệt kê theo socialSessionId, không gọi theo communityId', (
      tester,
    ) async {
      final repo = _FakeMatchSessionRepository(const []);
      await tester.pumpWidget(
        _buildTestApp(
          communityId: '',
          approvedParticipants: four,
          repository: repo,
          isHost: true,
        ),
      );
      await tester.pumpAndSettle();

      expect(repo.lastSocialSessionId, 'session-1');
      expect(repo.lastCommunityId, isNull);
      expect(find.text('Chưa có trận đấu nào trong buổi này.'), findsOneWidget);
    });

    testWidgets('host: nút tạo bật khi đủ 4 người', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          approvedParticipants: four,
          repository: _FakeMatchSessionRepository(const []),
          isHost: true,
        ),
      );
      await tester.pumpAndSettle();

      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNotNull);
    });

    testWidgets('không phải host: nút tạo bị khoá', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          approvedParticipants: four,
          repository: _FakeMatchSessionRepository(const []),
        ),
      );
      await tester.pumpAndSettle();

      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);
    });

  });

  testWidgets('TC-SOCIAL-BRACKET-APP-12: Xem bracket chỉ hiện khi kèo đã có bracket', (
    tester,
  ) async {
    final participants = [for (final id in ['1', '2', '3', '4']) _participant(id)];

    await tester.pumpWidget(
      _buildTestApp(
        isHost: true,
        approvedParticipants: participants,
        repository: _FakeMatchSessionRepository(const []),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Xem bracket'), findsNothing);

    await tester.pumpWidget(
      _buildTestApp(
        isHost: true,
        approvedParticipants: participants,
        repository: _FakeMatchSessionRepository(const []),
        bracketTournamentId: 't1',
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Xem bracket'), findsOneWidget);
  });

  testWidgets('TC-SOCIAL-BRACKET-APP-13: chỉ host kèo cá nhân thấy Thể thức Bracket khi tạo trận', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final participants = [for (final id in ['1', '2', '3', '4']) _participant(id)];

    await tester.pumpWidget(
      _buildTestApp(
        isHost: true,
        approvedParticipants: participants,
        repository: _FakeMatchSessionRepository(const []),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Tạo trận đấu'));
    await tester.pumpAndSettle();
    expect(find.text('Bracket'), findsOneWidget);
  });
}
