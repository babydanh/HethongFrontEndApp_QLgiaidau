import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/data/models/club_match_session_model.dart';
import 'package:app_quanly_giaidau/features/community/screens/club_match_sessions_screen.dart';
import 'package:app_quanly_giaidau/features/community/widgets/club_manage_sessions_section.dart';
import 'package:app_quanly_giaidau/features/social/widgets/social_session_card.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/club_match_session_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _clubId = 'club-1';

class _FakeSessions extends ClubMatchSessionsNotifier {
  final List<ClubMatchSessionModel> items;
  _FakeSessions(this.items) : super(_clubId);

  @override
  Future<List<ClubMatchSessionModel>> build() async => items;
}

ClubMatchSessionModel _session(int i, {String status = 'OPEN'}) =>
    ClubMatchSessionModel(
      id: 's$i',
      communityId: _clubId,
      resolvedName: 'Giao lưu cuối tuần của câu lạc bộ cầu lông Quận 7 số $i',
      status: status,
      registrationMode: 'MIXED',
      isRanked: i.isEven,
      maxParticipants: 16,
      participantCount: i,
      version: 1,
      canManage: true,
    );

Future<void> _pump(
  WidgetTester tester,
  Widget child,
  List<ClubMatchSessionModel> items,
) async {
  tester.view.physicalSize = const Size(360, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        clubMatchSessionsProvider(
          _clubId,
        ).overrideWith(() => _FakeSessions(items)),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        locale: const Locale('vi'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: child,
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
}

Widget _section() => const Scaffold(
  body: SingleChildScrollView(
    child: ClubManageSessionsSection(clubId: _clubId),
  ),
);

void main() {
  final sessions = [
    _session(1),
    _session(2, status: 'LIVE'),
    _session(3, status: 'ENDED'),
    _session(4, status: 'CANCELLED'),
  ];

  // TC-CLB-MANAGE-APP-01
  testWidgets('manage section shows exactly one create-session button', (
    tester,
  ) async {
    await _pump(tester, _section(), sessions);
    expect(find.text('Tạo buổi giao lưu'), findsOneWidget);
    expect(find.byType(FilledButton), findsOneWidget);
  });

  // TC-CLB-MANAGE-APP-02
  testWidgets('session rows reuse the Social card with a short status chip', (
    tester,
  ) async {
    await _pump(tester, _section(), sessions);
    // Inline list is capped at 3 rows; the 4th sits behind "Tất cả".
    expect(find.byType(SocialSessionCard), findsNWidgets(3));
    expect(find.text('Đang mở'), findsOneWidget);
    expect(find.text('Đang diễn ra'), findsOneWidget);
    expect(find.text('Kết thúc'), findsOneWidget);
    expect(find.text('Tất cả'), findsOneWidget);
    // Stats are icon + number, not a long sentence.
    expect(find.byIcon(Icons.people_outline_rounded), findsNWidgets(3));
    expect(find.textContaining('người tham gia'), findsNothing);
  });

  // TC-CLB-MANAGE-APP-03
  testWidgets('section does not overflow at 360px with long names', (
    tester,
  ) async {
    await _pump(tester, _section(), sessions);
    expect(tester.takeException(), isNull);
  });

  // TC-CLB-MANAGE-APP-04
  testWidgets(
    'sessions screen lists Social cards under a single create button',
    (tester) async {
      await _pump(
        tester,
        const ClubMatchSessionsScreen(communityId: _clubId),
        sessions,
      );
      expect(find.byType(SocialSessionCard), findsNWidgets(4));
      expect(find.text('Tạo buổi giao lưu'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  // TC-CLB-MANAGE-APP-05
  testWidgets('section shows the empty hint and still one create button', (
    tester,
  ) async {
    await _pump(tester, _section(), const []);
    expect(find.text('Chưa có buổi giao lưu nào'), findsOneWidget);
    expect(find.byType(SocialSessionCard), findsNothing);
    expect(find.text('Tạo buổi giao lưu'), findsOneWidget);
  });
}
