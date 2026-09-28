import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/data/models/social_session_model.dart';
import 'package:app_quanly_giaidau/features/social/widgets/detail_tab/social_details_tab.dart';
import 'package:app_quanly_giaidau/features/social/widgets/detail_tab/social_find_players_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

SocialSessionModel sessionWithCode(String? code) =>
    SocialSessionModel.fromJson({
      'id': '22222222-2222-4222-8222-222222222222',
      'shortCode': code,
      'hostUserId': '33333333-3333-4333-8333-333333333333',
      'title': 'Tennis giao hữu',
      'startAt': '2026-10-01T14:45:00+07:00',
      'venueName': 'Sân Tennis Khánh Hội',
      'venueAddress': 'Quận 4, Hồ Chí Minh',
      'sport': 'tennis',
      'sportName': 'Tennis',
    });

void main() {
  testWidgets('Social details and invite sheet use the short share URL', (
    tester,
  ) async {
    final session = sessionWithCode('abc12345678');
    const expectedUrl = 'https://sporto.asia/s/abc12345678';

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: SocialDetailsTab(
            session: session,
            isHost: false,
            onContactHost: () {},
            onFindPlayers: () {},
          ),
        ),
      ),
    );
    expect(find.text(expectedUrl), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: SocialFindPlayersSheet(session: session, onShareToChat: () {}),
        ),
      ),
    );
    expect(find.text('Link: $expectedUrl'), findsOneWidget);
    expect(find.textContaining('/social/${session.id}'), findsNothing);
  });

  testWidgets('missing short code does not expose an old ID link', (
    tester,
  ) async {
    final session = sessionWithCode(null);
    expect(session.shareUrl, isNull);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: SocialFindPlayersSheet(session: session, onShareToChat: () {}),
        ),
      ),
    );
    expect(find.textContaining('Link rút gọn chưa sẵn sàng'), findsOneWidget);
    expect(find.textContaining('/social/${session.id}'), findsNothing);
    final copyTile = tester.widget<ListTile>(
      find.widgetWithText(ListTile, 'Sao chép tin nhắn'),
    );
    expect(copyTile.onTap, isNull);
  });
}
