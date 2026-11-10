import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/data/models/club_match_session_model.dart';
import 'package:app_quanly_giaidau/data/models/community_member_model.dart';
import 'package:app_quanly_giaidau/data/models/community_social_models.dart';
import 'package:app_quanly_giaidau/data/models/social_session_model.dart';
import 'package:app_quanly_giaidau/data/repositories/api/api_club_match_session_repository.dart';
import 'package:app_quanly_giaidau/domain/repositories/community_repository.dart';
import 'package:app_quanly_giaidau/features/community/widgets/club_standalone_match_result_dialog.dart';
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
  bool signedIn = false,
}) {
  return ProviderScope(
    overrides: [
      if (signedIn) authProvider.overrideWith(_SignedInAuth.new),
      clubMatchSessionRepositoryProvider.overrideWithValue(repository),
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
        ),
      ),
    ),
  );
}

void main() {
  testWidgets(
    'shows empty state and no warning when enough eligible club members',
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
    'shows not-enough-participants warning when fewer than 4 eligible club members',
    (tester) async {
      final repo = _FakeMatchSessionRepository(const []);
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

      expect(
        find.text('Buổi chưa đủ người tham gia đã duyệt để ghép đội.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'shows not-enough-participants warning when approved guests are not club members',
    (tester) async {
      final repo = _FakeMatchSessionRepository(const []);
      // 4 người tham gia đã duyệt nhưng chỉ 1 người là thành viên CLB JOINED
      // thật (3 còn lại là khách mời/ngoài CLB) — vẫn phải cảnh báo thiếu người.
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
          clubMembers: [_clubMember('1')],
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Buổi chưa đủ người tham gia đã duyệt để ghép đội.'),
        findsOneWidget,
      );
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

    expect(find.text('Đã lên lịch'), findsOneWidget);
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

    final quick = find.byKey(const ValueKey('match-quick-entry-match-1'));
    final live = find.byKey(const ValueKey('match-live-score-match-1'));

    testWidgets('TC-SOC-CARD-01 players without a photo show initials', (
      tester,
    ) async {
      await pump(tester, match('SCHEDULED'));

      expect(find.text('ND'), findsOneWidget);
      expect(find.text('S'), findsOneWidget);
      expect(find.text('Nguyễn Minh Danh'), findsOneWidget);
    });

    testWidgets('TC-SOC-CARD-02 an unfinished match has both score buttons', (
      tester,
    ) async {
      await pump(tester, match('SCHEDULED'));

      expect(quick, findsOneWidget);
      expect(live, findsOneWidget);
      expect(find.text('Nhập nhanh'), findsOneWidget);
      expect(find.text('Bấm điểm'), findsOneWidget);
    });

    testWidgets('TC-SOC-CARD-03 a finished match shows the score, no buttons', (
      tester,
    ) async {
      await pump(tester, match('COMPLETED', a: 11, b: 7));

      expect(quick, findsNothing);
      expect(live, findsNothing);
      expect(find.text('11'), findsOneWidget);
      expect(find.text('7'), findsOneWidget);
    });

    testWidgets('TC-SOC-CARD-04 signed-out viewers get no score buttons', (
      tester,
    ) async {
      await pump(tester, match('SCHEDULED'), signedIn: false);

      expect(quick, findsNothing);
      expect(live, findsNothing);
    });

    testWidgets('TC-SOC-CARD-05 "Nhập nhanh" opens the result dialog', (
      tester,
    ) async {
      await pump(tester, match('SCHEDULED'));

      await tester.tap(quick);
      await tester.pumpAndSettle();

      expect(find.byType(ClubStandaloneMatchResultDialog), findsOneWidget);
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

    testWidgets('host: nút tạo bật và không cảnh báo thiếu người khi đủ 4', (
      tester,
    ) async {
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
      expect(
        find.text('Buổi chưa đủ người tham gia đã duyệt để ghép đội.'),
        findsNothing,
      );
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

    testWidgets('khách không có tài khoản không tính vào số người ghép đội', (
      tester,
    ) async {
      final withGuests = [
        _participant('1'),
        _participant('2'),
        SocialParticipantModel(
          id: 'g1',
          joinedAt: DateTime(2026, 1, 1),
          guestName: 'Khách 1',
        ),
        SocialParticipantModel(
          id: 'g2',
          joinedAt: DateTime(2026, 1, 1),
          guestName: 'Khách 2',
        ),
      ];
      await tester.pumpWidget(
        _buildTestApp(
          approvedParticipants: withGuests,
          repository: _FakeMatchSessionRepository(const []),
          isHost: true,
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Buổi chưa đủ người tham gia đã duyệt để ghép đội.'),
        findsOneWidget,
      );
    });
  });
}
