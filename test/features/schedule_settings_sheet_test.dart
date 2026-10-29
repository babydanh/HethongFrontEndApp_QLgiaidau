import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/domain/repositories/match_repository.dart';
import 'package:app_quanly_giaidau/domain/repositories/tournament_management_repository.dart';
import 'package:app_quanly_giaidau/features/organizer_ops/screens/organizer_ops_screen.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/organizer_ops_provider.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// TC-WP-04-05 — Cài đặt khung giờ sân (task 4.3): sheet đổi giờ mở/đóng +
/// bước ô 5/10/15/30/60, lưu vào cấu hình giải qua đúng route Web dùng
/// (`PATCH /tournaments/:id` body `tournamentConfig`), lưới vẽ lại theo bước
/// mới và bước giữ sau khi tải lại.
const _tournamentId = 't-1';
const _divisionId = 'd-1';

class _SettingsRepository
    implements TournamentManagementRepository, TournamentSettingsRepository {
  _SettingsRepository(this.serverTournament);

  /// Giải "trên server": lưu xong thì thay bằng bản cấu hình mới để lần tải
  /// lại sau invalidate nhận đúng giá trị đã lưu.
  Tournament Function() serverTournament;

  final List<Map<String, dynamic>> updateCalls = [];

  @override
  Future<List<Map<String, dynamic>>> getVenues(String id) async => [
    {
      'id': 'venue-1',
      'name': 'Nhà thi đấu',
      'courts': [
        {'id': 'court-1', 'name': 'Sân 1'},
      ],
    },
  ];

  @override
  Future<void> updateTournament(String id, Map<String, dynamic> payload) async {
    updateCalls.add({'id': id, 'payload': payload});
    final config = (payload['tournamentConfig'] as Map<String, dynamic>)
        .cast<String, dynamic>();
    serverTournament = () => _tournament(config);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MatchRepository implements IMatchRepository {
  @override
  Stream<List<MatchModel>> watchManagedByTournament(
    String tournamentId, {
    String? divisionId,
  }) => Stream.value(const []);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Tournament _tournament([Map<String, dynamic>? config]) => Tournament.fromJson({
  'name': 'Settings fixture',
  'sport': 'pickleball',
  'format': 'doubles',
  'status': 'in_progress',
  'maxTeams': 8,
  'maxPlayersPerTeam': 2,
  'tournamentConfig':
      config ??
      {
        'bracketType': 'SINGLE_ELIMINATION',
        'maxTeams': 8,
        'minutesPerSet': 15,
        'operatingStart': '07:00',
        'operatingEnd': '09:00',
      },
  'createdAt': '2026-01-01T00:00:00Z',
  'updatedAt': '2026-01-01T00:00:00Z',
}, _tournamentId);

Future<_SettingsRepository> _pump(WidgetTester tester) async {
  tester.view.physicalSize = const Size(720, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final repository = _SettingsRepository(() => _tournament());
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        tournamentProvider(
          _tournamentId,
        ).overrideWith((ref) => Stream.value(repository.serverTournament())),
        tournamentDivisionsProvider(_tournamentId).overrideWith(
          (ref) async => [
            {'id': _divisionId, 'name': 'Open', 'matchType': 'DOUBLES'},
          ],
        ),
        managedMatchesWithDivisionProvider((
          tournamentId: _tournamentId,
          divisionId: _divisionId,
        )).overrideWith((ref) => Stream.value(const <MatchModel>[])),
        tournamentManagementRepositoryProvider.overrideWithValue(repository),
        matchRepositoryProvider.overrideWithValue(_MatchRepository()),
        organizerOpsReadModelProvider((
          tournamentId: _tournamentId,
          divisionId: _divisionId,
        )).overrideWith(
          (ref) async => const OrganizerOpsReadModel(
            participants: [],
            referees: [],
            auditEntries: [],
          ),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        locale: const Locale('vi'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: OrganizerOpsScreen(
          tournamentId: _tournamentId,
          initialDivisionId: _divisionId,
          view: OrganizerOpsView.matches,
          initialMatchesView: OrganizerOpsMatchesView.grid,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return repository;
}

void main() {
  testWidgets(
    'TC-WP-04-05: đổi bước ô sang 10 phút và lưu — PATCH đúng tournamentConfig, lưới vẽ lại ô 10 phút',
    (tester) async {
      final repository = await _pump(tester);

      // Bước 15 mặc định: không có mốc 07:10 trên lưới.
      expect(find.text('07:10'), findsNothing);
      expect(find.text('07:15'), findsWidgets);

      await tester.tap(find.byKey(const ValueKey('schedule-more-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('schedule-settings-button')));
      await tester.pumpAndSettle();
      expect(find.text('Cài đặt khung giờ sân'), findsOneWidget);

      // Bước 5/10/15/30/60: chọn 10 phút.
      await tester.tap(find.byKey(const ValueKey('schedule-settings-step-10')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('schedule-settings-save')));
      await tester.pumpAndSettle();

      // Lưu qua PATCH /tournaments/:id với tournamentConfig GỐC đã merge:
      // giữ bracketType/maxTeams/minutesPerSet, đổi stepMinutes.
      expect(repository.updateCalls, hasLength(1));
      final call = repository.updateCalls.single;
      expect(call['id'], _tournamentId);
      final config =
          (call['payload'] as Map<String, dynamic>)['tournamentConfig']
              as Map<String, dynamic>;
      expect(config['bracketType'], 'SINGLE_ELIMINATION');
      expect(config['maxTeams'], 8);
      expect(config['minutesPerSet'], 15);
      expect(config['operatingStart'], '07:00');
      expect(config['operatingEnd'], '09:00');
      expect(config['stepMinutes'], 10);

      // Server đã lưu cấu hình mới -> màn chờ tải lại rồi dựng lưới theo bước
      // 10 phút; bước giữ sau khi tải lại (scenario "Đổi bước ô sang 10 phút").
      await tester.pumpAndSettle();
      expect(find.text('07:10'), findsWidgets);
      expect(find.text('Cảnh báo trùng lịch thi đấu'), findsNothing);
    },
  );

  testWidgets('giờ đóng trước giờ mở bị chặn, không lưu', (tester) async {
    final repository = await _pump(tester);

    await tester.tap(find.byKey(const ValueKey('schedule-more-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('schedule-settings-button')));
    await tester.pumpAndSettle();

    // Đưa giờ bắt đầu lên 08:30 (kề giá trị đang chọn 07:00 trong menu) rồi
    // chọn giờ kết thúc 08:00 — trước giờ bắt đầu.
    await tester.tap(
      find.byKey(const ValueKey('schedule-settings-time-start')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('08:30').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('schedule-settings-time-end')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('08:00').last);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('schedule-settings-time-invalid')),
      findsOneWidget,
    );
    final save = find.byKey(const ValueKey('schedule-settings-save'));
    await tester.tap(save);
    await tester.pump();
    expect(repository.updateCalls, isEmpty);
  });
}
