import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/tournament_management_section_screen.dart';
import 'package:app_quanly_giaidau/features/tournament/utils/tournament_contact.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/overview_tab.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/tournament_edit_sheet.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/tournament_management_header.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _UnauthenticatedNotifier extends AuthNotifier {
  @override
  AuthState build() => const AuthState();
}

Tournament _tournament({bool hideCardText = false}) => Tournament.fromJson({
  'name': 'Overview edit regression',
  'sport': 'pickleball',
  'category': {'name': 'Pickleball', 'slug': 'pickleball'},
  'format': 'SINGLES',
  'bracketType': 'single_elimination',
  'status': 'registration_open',
  'creator': {'id': 'creator-1', 'fullName': 'Organizer Name'},
  'maxTeams': 16,
  'createdAt': '2026-01-01T00:00:00.000Z',
  'updatedAt': '2026-01-01T00:00:00.000Z',
  'registrationStartDate': '2026-09-01T00:00:00.000Z',
  'registrationEndDate': '2026-09-29T00:00:00.000Z',
  'startDate': '2026-10-01T00:00:00.000Z',
  'endDate': '2026-10-05T00:00:00.000Z',
  'tournamentConfig': {'hideFeaturedCardText': hideCardText},
}, 'tournament-edit');

Widget _app(Widget home) => ProviderScope(
  overrides: [authProvider.overrideWith(_UnauthenticatedNotifier.new)],
  child: MaterialApp(
    theme: AppTheme.lightTheme,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('vi'),
    home: Scaffold(body: home),
  ),
);

void main() {
  testWidgets(
    'TC-OVEDIT-01: the roadmap has a closing row that opens its popup',
    (tester) async {
      tester.view.physicalSize = const Size(390, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      TournamentManagementFocus? tapped;
      await tester.pumpWidget(
        _app(
          OverviewTab(
            tournament: _tournament(),
            teamCount: 0,
            resolveImageUrl: (_) => '',
            onEditTimelineDate: (focus) => tapped = focus,
          ),
        ),
      );
      await tester.pump();

      final row = find.byKey(
        const ValueKey('tournament-overview-timeline-closing-edit'),
      );
      expect(row, findsOneWidget);
      expect(find.text('Kết thúc giải đấu'), findsOneWidget);
      await tester.tap(row);
      expect(tapped, TournamentManagementFocus.tournamentClosing);
    },
  );

  group('TC-OVEDIT-02: founderVisibilityPatch', () {
    test('showing a MANUAL tournament switches it back to PROFILE', () {
      final patch = founderVisibilityPatch({
        'displayMode': 'MANUAL',
        'organizerName': 'Ban to chuc A',
        'hidden': true,
      }, hidden: false);

      expect(patch['hidden'], false);
      expect(patch['displayMode'], 'PROFILE');
      expect(patch['organizerName'], 'Ban to chuc A');
    });

    test('hiding never touches the display mode', () {
      final patch = founderVisibilityPatch({
        'displayMode': 'MANUAL',
        'hidden': false,
      }, hidden: true);

      expect(patch['hidden'], true);
      expect(patch['displayMode'], 'MANUAL');
    });

    test('a tournament with no contact info just gets the flag', () {
      expect(founderVisibilityPatch(null, hidden: false), {
        'hidden': false,
        'displayMode': 'PROFILE',
      });
      expect(founderVisibilityPatch(null, hidden: true), {'hidden': true});
    });
  });

  testWidgets('TC-OVEDIT-03: the banner eye hides then shows the card text', (
    tester,
  ) async {
    bool? requested;
    await tester.pumpWidget(
      _app(
        SizedBox(
          height: 260,
          child: TournamentManagementBanner(
            tournament: _tournament(),
            resolveImageUrl: (_) => '',
            onEdit: () {},
            onToggleCardText: (hide) => requested = hide,
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.visibility_rounded), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey('tournament-banner-card-text-eye')),
    );
    expect(requested, true);
  });

  testWidgets(
    'TC-OVEDIT-04: the banner eye shows a struck eye while text is hidden',
    (tester) async {
      await tester.pumpWidget(
        _app(
          SizedBox(
            height: 260,
            child: TournamentManagementBanner(
              tournament: _tournament(hideCardText: true),
              resolveImageUrl: (_) => '',
              onEdit: () {},
              onToggleCardText: (_) {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.visibility_off_rounded), findsOneWidget);
    },
  );

  testWidgets(
    'TC-OVEDIT-05: the shared sheet shows title and body and closes with its button',
    (tester) async {
      await tester.pumpWidget(
        _app(
          Builder(
            builder: (context) => TextButton(
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                builder: (_) => const TournamentEditSheet(
                  title: 'Tieu de popup',
                  child: Text('Noi dung popup'),
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('Tieu de popup'), findsOneWidget);
      expect(find.text('Noi dung popup'), findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey('tournament-edit-sheet-close')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Noi dung popup'), findsNothing);
    },
  );
}
