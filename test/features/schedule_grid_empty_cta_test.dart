import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament_workspace.dart';
import 'package:app_quanly_giaidau/domain/entities/user.dart';
import 'package:app_quanly_giaidau/domain/repositories/tournament_management_repository.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/schedule_court_management_screen.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/tournament_schedule_court_grid.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/my_tournament_workspace_provider.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:app_quanly_giaidau/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _tid = 'tour-1';

class _EmptyWorkspace extends MyTournamentWorkspaceNotifier {
  @override
  Future<TournamentWorkspace> build() async => TournamentWorkspace.empty;
}

class _NoVenues extends Fake implements TournamentManagementRepository {
  @override
  Future<List<Map<String, dynamic>>> getVenues(String id) async => const [];
}

Tournament _tournament({bool lite = false}) => Tournament.fromJson({
  'name': 'Empty courts',
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
  String userId = 'owner-1',
  bool lite = false,
  bool hostGrantsScheduling = false,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: [
        tournamentProvider(
          _tid,
        ).overrideWith((ref) => Stream.value(_tournament(lite: lite))),
        userProfileProvider.overrideWith(
          (ref) async => UserProfile(id: userId, fullName: 'U', email: ''),
        ),
        myTournamentWorkspaceProvider.overrideWith(_EmptyWorkspace.new),
        tournamentManagementRepositoryProvider.overrideWithValue(_NoVenues()),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        locale: const Locale('vi'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: TournamentScheduleCourtGrid(
              tournamentId: _tid,
              matches: const [],
              scheduleSettings: const {
                'operatingStart': '07:00',
                'operatingEnd': '10:00',
              },
              onScheduleDrop: hostGrantsScheduling
                  ? (matchId, courtId, courtName, scheduledAt) {}
                  : null,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  const cta = ValueKey('schedMgmt-empty-create');

  testWidgets(
    'TC-APP-SCHED-EMPTY-01 manager sees Tạo sân and it opens the court editor once',
    (tester) async {
      await _pump(tester);
      expect(find.text('Tạo sân'), findsOneWidget);
      expect(
        find.text('Chưa có sân nào. Tạo sân để bắt đầu xếp lịch.'),
        findsOneWidget,
      );

      await tester.tap(find.byKey(cta));
      await tester.tap(find.byKey(cta), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.byType(ScheduleCourtManagementScreen), findsOneWidget);
    },
  );

  testWidgets(
    'TC-APP-SCHED-EMPTY-01 viewer and Lite tournament get no Tạo sân',
    (tester) async {
      await _pump(tester, userId: 'someone-else');
      expect(find.byKey(cta), findsNothing);
      expect(find.text('Chưa cấu hình địa điểm'), findsOneWidget);

      await _pump(tester, lite: true);
      expect(find.byKey(cta), findsNothing);
    },
  );

  testWidgets(
    'TC-APP-SCHED-EMPTY-02 host-granted scheduling shows Tạo sân even when the creator/workspace lookup does not match (e.g. admin)',
    (tester) async {
      await _pump(
        tester,
        userId: 'admin-not-creator',
        hostGrantsScheduling: true,
      );
      expect(find.byKey(cta), findsOneWidget);

      await tester.tap(find.byKey(cta));
      await tester.pumpAndSettle();
      expect(find.byType(ScheduleCourtManagementScreen), findsOneWidget);
    },
  );

  testWidgets(
    'TC-APP-SCHED-EMPTY-03 host-granted scheduling still hides Tạo sân on a Lite tournament',
    (tester) async {
      await _pump(
        tester,
        userId: 'admin-not-creator',
        lite: true,
        hostGrantsScheduling: true,
      );
      expect(find.byKey(cta), findsNothing);
    },
  );
}
