import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/domain/repositories/tournament_management_repository.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/schedule_grid.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/tournament_schedule_court_grid.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sân của giải: 3 sân, trong đó "Sân 3" không có trận nào.
class _VenuesRepository implements TournamentManagementRepository {
  @override
  Future<List<Map<String, dynamic>>> getVenues(String id) async => [
    {
      'id': 'venue-1',
      'name': 'Sân nhà thi đấu',
      'courts': [
        {'id': 'court-1', 'name': 'Sân 1'},
        {'id': 'court-2', 'name': 'Sân 2'},
      ],
    },
    {
      'id': 'venue-2',
      'name': 'Sân phụ',
      'courts': [
        {'id': 'court-3', 'name': 'Sân 3'},
      ],
    },
  ];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _EmptyVenuesRepository implements TournamentManagementRepository {
  @override
  Future<List<Map<String, dynamic>>> getVenues(String id) async => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

MatchModel _match(String id, {required String court, DateTime? at}) =>
    MatchModel.fromJson({
      'id': id,
      'tournamentId': 't-1',
      'round': 1,
      'matchNumber': 1,
      'status': 'SCHEDULED',
      'team1Name': 'Đội $id A',
      'team2Name': 'Đội $id B',
      'courtName': court,
      if (at != null) 'scheduledAt': at.toIso8601String(),
    }, id);

Future<void> _pump(
  WidgetTester tester, {
  required TournamentManagementRepository repository,
  List<MatchModel> matches = const [],
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        tournamentManagementRepositoryProvider.overrideWithValue(repository),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('vi'),
        home: Scaffold(
          body: SingleChildScrollView(
            child: TournamentScheduleCourtGrid(
              tournamentId: 't-1',
              matches: matches,
              scheduleSettings: const {
                'operatingStart': '07:00',
                'operatingEnd': '10:00',
                'minutesPerSet': 15,
              },
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('columns come from the tournament courts, including empty ones', (
    tester,
  ) async {
    await _pump(
      tester,
      repository: _VenuesRepository(),
      matches: [
        _match('m1', court: 'Sân 1', at: DateTime(2026, 10, 24, 7, 30)),
      ],
    );

    expect(find.byType(ScheduleGrid), findsOneWidget);
    // "Sân 3" không có trận nào: nếu cột suy từ trận thì nó sẽ mất.
    // Tên đầy đủ nằm ở tooltip của tiêu đề cột (chữ hiển thị đã rút gọn "3").
    expect(find.byTooltip('Sân 3'), findsOneWidget);
    expect(find.byTooltip('Sân 1'), findsOneWidget);
    expect(find.text('Đội m1 A'), findsOneWidget);
  });

  testWidgets('turning a court off removes its column', (tester) async {
    await _pump(
      tester,
      repository: _VenuesRepository(),
      matches: [
        _match('m1', court: 'Sân 1', at: DateTime(2026, 10, 24, 7, 30)),
        _match('m3', court: 'Sân 3', at: DateTime(2026, 10, 24, 8, 0)),
      ],
    );
    expect(find.byTooltip('Sân 3'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('court-picker-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('court-picker-item-Sân 3')));
    await tester.pumpAndSettle();
    // Đóng hộp chọn: trạng thái áp dụng khi hộp đóng.
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Sân 3'), findsNothing);
    expect(find.text('Đội m3 A'), findsNothing);
    expect(find.text('Đội m1 A'), findsOneWidget);
  });

  testWidgets('bật lại sân thì cột quay lại', (tester) async {
    await _pump(
      tester,
      repository: _VenuesRepository(),
      matches: [
        _match('m1', court: 'Sân 1', at: DateTime(2026, 10, 24, 7, 30)),
        _match('m3', court: 'Sân 3', at: DateTime(2026, 10, 24, 8, 0)),
      ],
    );

    await tester.tap(find.byKey(const ValueKey('court-picker-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('court-picker-item-Sân 3')));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    expect(find.text('Đội m3 A'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('court-picker-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('court-picker-item-Sân 3')));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    expect(find.text('Đội m3 A'), findsOneWidget);
  });

  testWidgets('no courts yet shows the venues empty message, not a grid', (
    tester,
  ) async {
    await _pump(tester, repository: _EmptyVenuesRepository());

    expect(find.byType(ScheduleGrid), findsNothing);
    final l10n = AppLocalizations.of(
      tester.element(find.byType(TournamentScheduleCourtGrid)),
    )!;
    expect(find.text(l10n.tournamentManagementVenuesEmpty), findsOneWidget);
  });
}
