import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/data/models/club_match_session_model.dart';
import 'package:app_quanly_giaidau/data/models/social_session_model.dart';
import 'package:app_quanly_giaidau/data/repositories/api/api_club_match_session_repository.dart';
import 'package:app_quanly_giaidau/features/social/widgets/match_tab/social_match_tab.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/club_match_session_provider.dart';
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

SocialParticipantModel _participant(String id) => SocialParticipantModel(
  id: id,
  userId: 'user-$id',
  joinedAt: DateTime(2026, 1, 1),
  fullName: 'VĐV $id',
);

Widget _buildTestApp({
  required String communityId,
  required List<SocialParticipantModel> approvedParticipants,
  required ApiClubMatchSessionRepository repository,
}) {
  return ProviderScope(
    overrides: [
      clubMatchSessionRepositoryProvider.overrideWithValue(repository),
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
    'shows empty state and no warning when enough approved participants',
    (tester) async {
      final repo = _FakeMatchSessionRepository(const []);
      await tester.pumpWidget(
        _buildTestApp(
          communityId: 'club-1',
          approvedParticipants: [_participant('1'), _participant('2')],
          repository: repo,
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
    'shows not-enough-participants warning when fewer than 2 approved',
    (tester) async {
      final repo = _FakeMatchSessionRepository(const []);
      await tester.pumpWidget(
        _buildTestApp(
          communityId: 'club-1',
          approvedParticipants: [_participant('1')],
          repository: repo,
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
    await tester.pumpWidget(
      _buildTestApp(
        communityId: 'club-1',
        approvedParticipants: [_participant('1'), _participant('2')],
        repository: repo,
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
