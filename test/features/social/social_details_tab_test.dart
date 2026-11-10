import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/data/models/social_session_model.dart';
import 'package:app_quanly_giaidau/features/social/widgets/detail_tab/social_details_tab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

SocialParticipantModel _p(String id, String name, {bool host = false}) =>
    SocialParticipantModel(
      id: id,
      userId: id,
      fullName: name,
      role: host ? 'HOST' : 'PLAYER',
      joinedAt: DateTime(2026, 11, 9),
    );

Future<void> _pump(WidgetTester tester, SocialSessionModel session) async {
  tester.view.physicalSize = const Size(360, 780);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.lightTheme,
      home: Scaffold(
        body: SocialDetailsTab(
          session: session,
          isHost: true,
          onContactHost: () {},
          onFindPlayers: () {},
        ),
      ),
    ),
  );
}

SocialSessionModel _session(List<SocialParticipantModel> ps) =>
    SocialSessionModel(
      id: 's1',
      hostUserId: 'h',
      title: 'Cầu lông giao lưu',
      playFormat: 'Giao lưu',
      startAt: DateTime(2026, 11, 9, 18),
      venueName: 'Sân A',
      venueAddress: '1 Đường B',
      sport: 'BADMINTON',
      sportName: 'Cầu lông',
      participants: ps,
      currentSlots: ps.length,
    );

void main() {
  testWidgets('hiển thị host thật, người tham gia thật, không "MQ"/"+4" giả', (
    tester,
  ) async {
    await _pump(
      tester,
      _session([_p('h', 'Nguyễn Minh Danh', host: true), _p('a', 'An Bình')]),
    );
    expect(find.text('Host'), findsOneWidget);
    // TC-GL-AVATAR-01: the host avatar shows once (host card only).
    expect(find.text('ND'), findsOneWidget);
    expect(find.text('AB'), findsOneWidget);
    expect(find.text('MQ'), findsNothing);
    expect(find.text('+4'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    '9 người: host ở thẻ riêng, hàng avatar chỉ +3 thật, không tràn ở 360px',
    (tester) async {
      await _pump(
        tester,
        _session([
          _p('h', 'Host Một', host: true),
          for (var i = 0; i < 8; i++) _p('$i', 'Người $i'),
        ]),
      );
      expect(find.text('+3'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
