import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/domain/entities/match.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament_workspace.dart';
import 'package:app_quanly_giaidau/domain/entities/user.dart';
import 'package:app_quanly_giaidau/domain/repositories/tournament_management_repository.dart';
import 'package:app_quanly_giaidau/features/organizer_ops/screens/schedule_settings_sheet.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/schedule_court_management_screen.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/tournament_management_widgets.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/matches_tab.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/schedule_manager_bar.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/my_tournament_workspace_provider.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:app_quanly_giaidau/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

const _tid = 'tour-1';

class _EmptyWorkspace extends MyTournamentWorkspaceNotifier {
  @override
  Future<TournamentWorkspace> build() async => TournamentWorkspace.empty;
}

class _Venues extends Fake implements TournamentManagementRepository {
  _Venues({this.fail = false});
  final bool fail;

  @override
  Future<List<Map<String, dynamic>>> getVenues(String id) async {
    if (fail) throw Exception('offline');
    return const [];
  }
}

Tournament _tournament({bool lite = false}) => Tournament.fromJson({
  'name': 'Schedule manager',
  'sport': 'pickleball',
  'category': {'name': 'Pickleball', 'slug': 'pickleball'},
  'format': 'SINGLES',
  'bracketType': 'single_elimination',
  'status': 'registration_open',
  'creator': {'id': 'owner-1', 'fullName': 'Owner'},
  'maxTeams': 16,
  'isLite': lite,
  'createdAt': '2026-01-01T00:00:00.000Z',
  'updatedAt': '2026-01-01T00:00:00.000Z',
}, _tid);

Future<void> _pump(
  WidgetTester tester, {
  required Widget child,
  String userId = 'owner-1',
  bool lite = false,
  bool venuesFail = false,
  VoidCallback? onTournamentRead,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => Scaffold(body: child),
      ),
      GoRoute(
        path: '/organizer/tournaments/:id/ops',
        builder: (_, _) => const Scaffold(body: Text('ops-workspace')),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: [
        tournamentProvider(_tid).overrideWith((ref) {
          onTournamentRead?.call();
          return Stream.value(_tournament(lite: lite));
        }),
        userProfileProvider.overrideWith(
          (ref) async => UserProfile(id: userId, fullName: 'U', email: ''),
        ),
        myTournamentWorkspaceProvider.overrideWith(_EmptyWorkspace.new),
        matchesProvider(
          _tid,
        ).overrideWith((ref) => Stream.value(const <MatchModel>[])),
        tournamentManagementRepositoryProvider.overrideWithValue(
          _Venues(fail: venuesFail),
        ),
      ],
      child: MaterialApp.router(
        theme: AppTheme.lightTheme,
        locale: const Locale('vi'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

const _bar = ScheduleManagerBar(tournamentId: _tid);
Finder _key(String key) => find.byKey(ValueKey(key));

/// Pops the court editor like the system back gesture does.
Future<void> _back(WidgetTester tester) async {
  Navigator.of(
    tester.element(find.byType(ScheduleCourtManagementScreen)),
  ).pop();
  await tester.pumpAndSettle();
}

void main() {
  group('TC-SCHED-MGMT-01 who sees the manager icons', () {
    testWidgets('creator sees courts, hours and arrange icons with tooltips', (
      tester,
    ) async {
      await _pump(tester, child: _bar);

      expect(_key('schedMgmt-courts'), findsOneWidget);
      expect(_key('schedMgmt-hours'), findsOneWidget);
      expect(_key('schedMgmt-arrange'), findsOneWidget);
      expect(find.byTooltip('Tạo sân và quản lý sân'), findsOneWidget);
      expect(find.byTooltip('Khung giờ sân'), findsOneWidget);
      expect(find.byTooltip('Xếp lịch trận'), findsOneWidget);
    });

    testWidgets('a viewer who does not run the tournament sees nothing', (
      tester,
    ) async {
      await _pump(tester, child: _bar, userId: 'someone-else');

      expect(_key('schedMgmt-courts'), findsNothing);
      expect(_key('schedMgmt-hours'), findsNothing);
      expect(_key('schedMgmt-arrange'), findsNothing);
    });

    testWidgets('a lite tournament has no court actions even for its owner', (
      tester,
    ) async {
      await _pump(tester, child: _bar, lite: true);

      expect(_key('schedMgmt-courts'), findsNothing);
    });
  });

  group('TC-SCHED-MGMT-02 create courts', () {
    testWidgets('court icon opens the venue and court editor', (tester) async {
      await _pump(tester, child: _bar);

      await tester.tap(_key('schedMgmt-courts'));
      await tester.pumpAndSettle();

      expect(find.byType(ScheduleCourtManagementScreen), findsOneWidget);
      // Empty venue list still offers the way to create the first venue.
      expect(_key('venue-add'), findsOneWidget);
    });

    testWidgets('a second tap while the editor opens does not stack it', (
      tester,
    ) async {
      await _pump(tester, child: _bar);

      await tester.tap(_key('schedMgmt-courts'));
      await tester.tap(_key('schedMgmt-courts'), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.byType(ScheduleCourtManagementScreen), findsOneWidget);
      await _back(tester);
      await tester.pumpAndSettle();
      expect(find.byType(ScheduleCourtManagementScreen), findsNothing);
    });

    testWidgets('a failed venue load shows the retry state', (tester) async {
      await _pump(tester, child: _bar, venuesFail: true);

      await tester.tap(_key('schedMgmt-courts'));
      await tester.pumpAndSettle();

      expect(find.byType(TournamentManagementError), findsOneWidget);
    });

    testWidgets('coming back reloads the tournament', (tester) async {
      var reads = 0;
      await _pump(tester, child: _bar, onTournamentRead: () => reads++);
      final before = reads;

      await tester.tap(_key('schedMgmt-courts'));
      await tester.pumpAndSettle();
      await _back(tester);
      await tester.pumpAndSettle();

      expect(reads, greaterThan(before));
    });
  });

  group('TC-SCHED-MGMT-03 hours and arrange', () {
    testWidgets('hours icon opens the court hours sheet', (tester) async {
      await _pump(tester, child: _bar);

      await tester.tap(_key('schedMgmt-hours'));
      await tester.pumpAndSettle();

      expect(find.byType(ScheduleSettingsSheet), findsOneWidget);
    });

    testWidgets('arrange icon goes to the scheduling workspace', (
      tester,
    ) async {
      await _pump(tester, child: _bar);

      await tester.tap(_key('schedMgmt-arrange'));
      await tester.pumpAndSettle();

      expect(find.text('ops-workspace'), findsOneWidget);
    });
  });

  group('TC-SCHED-MGMT-04 schedule tab', () {
    testWidgets('manager with no courts gets a Create court button', (
      tester,
    ) async {
      await _pump(tester, child: const MatchesTab(tournamentId: _tid));

      expect(_key('schedMgmt-empty-create'), findsOneWidget);
      expect(find.text('Tạo sân'), findsOneWidget);
      // The icon row sits next to the search box.
      expect(_key('schedMgmt-courts'), findsOneWidget);
    });

    testWidgets('a plain viewer sees the empty state without any button', (
      tester,
    ) async {
      await _pump(
        tester,
        child: const MatchesTab(tournamentId: _tid),
        userId: 'someone-else',
      );

      expect(_key('schedMgmt-empty-create'), findsNothing);
      expect(_key('schedMgmt-courts'), findsNothing);
    });

    testWidgets('Create court button opens the editor', (tester) async {
      await _pump(tester, child: const MatchesTab(tournamentId: _tid));

      await tester.tap(_key('schedMgmt-empty-create'));
      await tester.pumpAndSettle();

      expect(find.byType(ScheduleCourtManagementScreen), findsOneWidget);
    });
  });
}
