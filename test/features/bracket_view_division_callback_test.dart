import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/features/bracket/screens/bracket_view_screen.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:app_quanly_giaidau/providers/standings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _tournamentId = 'division-callback-fixture';
const _divisionA = 'division-a';
const _divisionB = 'division-b';

class _GuestAuthNotifier extends AuthNotifier {
  @override
  AuthState build() => const AuthState();
}

TournamentDivision _division(String id, String name) => TournamentDivision(
  id: id,
  name: name,
  matchType: 'DOUBLES',
  bracketType: 'single_elimination',
  maxParticipants: 16,
  participantCount: 6,
);

Tournament _tournament() => Tournament(
  id: _tournamentId,
  name: 'Division callback fixture',
  sport: 'pickleball',
  format: 'DOUBLES',
  bracketType: 'single_elimination',
  status: 'in_progress',
  visibility: 'PUBLIC',
  adminToken: '',
  refereeToken: '',
  viewerToken: '',
  creatorId: 'fixture-owner',
  maxTeams: 16,
  createdAt: DateTime(2026, 1, 1),
  updatedAt: DateTime(2026, 1, 1),
  divisions: [
    _division(_divisionA, 'Đôi Nam'),
    _division(_divisionB, 'Đôi Nữ'),
  ],
);

MatchModel _match(String id, String divisionId) => MatchModel.fromJson({
  'id': id,
  'tournamentId': _tournamentId,
  'divisionId': divisionId,
  'round': 1,
  'matchNumber': 1,
  'status': 'SCHEDULED',
  'team1Name': 'Đội $id-A',
  'team2Name': 'Đội $id-B',
  'nextMatchId': '',
  'stageType': 'SINGLE_ELIMINATION',
  'bracketPosition': {'bracket': 'winners', 'round': 1, 'position': 0},
}, id);

Future<void> _pump(
  WidgetTester tester, {
  String? selectedDivisionId,
  ValueChanged<String>? onDivisionChanged,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        tournamentProvider.overrideWith(
          (ref, id) => Stream.value(_tournament()),
        ),
        bracketMatchesWithDivisionProvider.overrideWith(
          (ref, params) => Stream.value([
            _match('m-a', _divisionA),
            _match('m-b', _divisionB),
          ]),
        ),
        standingsWithDivisionProvider.overrideWith(
          (ref, params) => Stream.value(const []),
        ),
        authProvider.overrideWith(_GuestAuthNotifier.new),
      ],
      child: MaterialApp(
        theme: ThemeData(splashFactory: NoSplash.splashFactory),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('vi'),
        home: Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: BracketViewScreen(
                  tournamentId: _tournamentId,
                  selectedDivisionId: selectedDivisionId,
                  isEmbedded: true,
                  canEditBracket: true,
                  onDivisionChanged: onDivisionChanged,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Finder _chip(String id) => find.byKey(ValueKey('division-chip-$id'));

Matcher _chipSemantics({required bool selected, required String label}) =>
    matchesSemantics(
      isSelected: selected,
      isButton: true,
      hasSelectedState: true,
      hasTapAction: true,
      label: label,
    );

void main() {
  testWidgets('TC-DIVSHARE-01: tapping a chip reports the chosen division', (
    tester,
  ) async {
    final reported = <String>[];
    await _pump(tester, onDivisionChanged: reported.add);

    await tester.tap(_chip(_divisionB));
    await tester.pumpAndSettle();

    expect(reported, [_divisionB]);
  });

  testWidgets(
    'TC-DIVSHARE-02: a division chosen by the host stays chosen when another chip is tapped',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final reported = <String>[];
      await _pump(
        tester,
        selectedDivisionId: _divisionA,
        onDivisionChanged: reported.add,
      );

      await tester.tap(_chip(_divisionB));
      await tester.pumpAndSettle();

      // The host owns the choice: the screen only reports the tap, so the
      // chip the host passes (division A) is still the selected one.
      expect(reported, [_divisionB]);
      expect(
        tester.getSemantics(_chip(_divisionA)),
        _chipSemantics(selected: true, label: 'Đôi Nam 6/16'),
      );
      expect(
        tester.getSemantics(_chip(_divisionB)),
        _chipSemantics(selected: false, label: 'Đôi Nữ 6/16'),
      );
      semantics.dispose();
    },
  );
}
