import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/data/models/club_match_session_model.dart';
import 'package:app_quanly_giaidau/data/models/community_member_model.dart';
import 'package:app_quanly_giaidau/data/models/community_social_models.dart';
import 'package:app_quanly_giaidau/data/models/social_session_model.dart';
import 'package:app_quanly_giaidau/data/repositories/api/api_club_match_session_repository.dart';
import 'package:app_quanly_giaidau/domain/repositories/community_repository.dart';
import 'package:app_quanly_giaidau/features/social/widgets/match_tab/social_match_tab.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
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

  @override
  Future<List<ClubSessionMatchModel>> standaloneMatches(
    String communityId,
  ) async {
    lastCommunityId = communityId;
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
  required String communityId,
  required List<SocialParticipantModel> approvedParticipants,
  required ApiClubMatchSessionRepository repository,
  List<CommunityMemberModel> clubMembers = const [],
}) {
  return ProviderScope(
    overrides: [
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
}
