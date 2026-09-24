import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/data/models/team_model.dart';
import 'package:app_quanly_giaidau/domain/entities/token.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/features/bracket/screens/auto_draw_screen.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/token_management_screen.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:app_quanly_giaidau/providers/token_management_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _tournamentId = 'layout-test-tournament';

String _longTokenCode() => List.filled(300, 'T').join();

class _TokenNotifier extends TokenManagementNotifier {
  _TokenNotifier() : super(_tournamentId);

  @override
  Future<List<TokenModel>> build() async => [
    TokenModel(
      id: 'token-1',
      code: _longTokenCode(),
      role: 'admin',
      tournamentId: _tournamentId,
      createdAt: DateTime.utc(2026),
    ),
  ];
}

Tournament _tournament() => Tournament.fromJson({
  'name': 'Layout regression tournament',
  'sport': 'badminton',
  'format': 'SINGLES',
  'bracketType': 'single_elimination',
  'status': 'upcoming',
  'maxTeams': 8,
  'createdAt': '2026-01-01T00:00:00.000Z',
  'updatedAt': '2026-01-01T00:00:00.000Z',
}, _tournamentId);

void _setPhoneViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(320, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget _localizedApp(Widget child) => MaterialApp(
  theme: AppTheme.lightTheme,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: const Locale('vi'),
  home: child,
);

void main() {
  testWidgets('long token remains accessible without horizontal overflow', (
    tester,
  ) async {
    _setPhoneViewport(tester);
    final tokenCode = _longTokenCode();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tokenManagementProvider(
            _tournamentId,
          ).overrideWith(_TokenNotifier.new),
        ],
        child: _localizedApp(
          const TokenManagementScreen(tournamentId: _tournamentId),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SelectableText), findsOneWidget);
    expect(
      tester.widget<SelectableText>(find.byType(SelectableText)).data,
      tokenCode,
    );
    expect(find.byIcon(Icons.qr_code), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('auto and manual draw actions fit a narrow viewport', (
    tester,
  ) async {
    _setPhoneViewport(tester);
    const tournamentId = _tournamentId;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          teamsProvider(
            tournamentId,
          ).overrideWith((ref) => Stream.value(<Team>[])),
          tournamentProvider(
            tournamentId,
          ).overrideWith((ref) => Stream.value(_tournament())),
          matchesProvider(
            tournamentId,
          ).overrideWith((ref) => Stream.value(<MatchModel>[])),
        ],
        child: _localizedApp(const AutoDrawScreen(tournamentId: tournamentId)),
      ),
    );
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(AutoDrawScreen));
    final l10n = AppLocalizations.of(context)!;
    expect(find.text(l10n.autoDraw_auto), findsOneWidget);
    expect(find.text(l10n.autoDraw_manual), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
