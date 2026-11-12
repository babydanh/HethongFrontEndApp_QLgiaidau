import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/data/models/social_session_model.dart';
import 'package:app_quanly_giaidau/features/social/widgets/social_session_card.dart';
import 'package:app_quanly_giaidau/features/social/widgets/social_session_sport_icon.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

SocialSessionModel _session({
  String sport = 'badminton',
  String sportName = 'Cầu lông',
}) => SocialSessionModel(
  id: 's1',
  hostUserId: 'h1',
  title: 'Giao lưu với Danh',
  playFormat: 'Giao lưu',
  startAt: DateTime(2026, 11, 20, 18),
  venueName: 'Sân A',
  venueAddress: 'Q7',
  sport: sport,
  sportName: sportName,
  community: const SocialCommunitySummary(id: 'c1', name: 'CLB Test'),
);

Widget _app(Widget child, {double width = 360}) => MaterialApp(
  theme: AppTheme.lightTheme,
  locale: const Locale('vi'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(
    body: Center(
      child: SizedBox(width: width, child: child),
    ),
  ),
);

void main() {
  // TC-SOCIAL-ICON-01
  testWidgets(
    'card shows sport only as an SVG icon at the start, labelled with the sport name',
    (tester) async {
      await tester.pumpWidget(
        _app(SocialSessionCard(session: _session(), onTap: () {})),
      );
      expect(find.byType(SvgPicture), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('Cầu lông')), findsWidgets);
      expect(find.byTooltip('Cầu lông'), findsOneWidget);
      expect(find.text('Cầu lông'), findsNothing);
      expect(find.byIcon(Icons.sports_tennis_outlined), findsNothing);
      final iconLeft = tester
          .getTopLeft(find.byType(SocialSessionSportIcon))
          .dx;
      final titleLeft = tester.getTopLeft(find.text('Giao lưu với Danh')).dx;
      expect(iconLeft, lessThan(titleLeft));
    },
  );

  // TC-SOCIAL-ICON-02
  testWidgets('card does not overflow at 360px with a long title', (
    tester,
  ) async {
    final session = _session();
    await tester.pumpWidget(
      _app(
        SocialSessionCard(
          session: SocialSessionModel(
            id: 's2',
            hostUserId: 'h',
            title:
                'Giao lưu cầu lông cuối tuần rất dài rất dài rất dài rất dài',
            playFormat: 'Giao lưu',
            startAt: session.startAt,
            venueName: 'Sân vận động rất dài tên',
            venueAddress: '',
            sport: 'badminton',
            sportName: 'Cầu lông',
            community: session.community,
          ),
          onTap: () {},
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(
      tester.getSize(find.byType(SocialSessionSportIcon)).width,
      inInclusiveRange(28, 32),
    );
  });

  // TC-SOCIAL-ICON-03
  testWidgets(
    'icon widget falls back to the sport name from l10n when sportName is empty',
    (tester) async {
      await tester.pumpWidget(
        _app(const SocialSessionSportIcon(sport: 'tennis', sportName: '')),
      );
      expect(find.bySemanticsLabel('Tennis'), findsOneWidget);
    },
  );
}
