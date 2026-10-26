import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/domain/entities/organizer_ops.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/domain/repositories/tournament_management_repository.dart';
import 'package:app_quanly_giaidau/domain/repositories/tournament_repository.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/tournament_management_section_screen.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/lifecycle_opening_sheet.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Mock repository vòng đời cho sheet khai mạc: ghi nhận thứ tự cuộc gọi và
/// danh sách id hạng mục gửi qua `close-registration`.
class _OpeningRepository
    implements TournamentManagementRepository, TournamentLifecycleRepository {
  final divisions = <Map<String, dynamic>>[];
  final calls = <String>[];
  final closedDivisionIds = <List<String>>[];

  @override
  Future<List<Map<String, dynamic>>> getManageDivisions(String id) async =>
      divisions;

  @override
  Future<Map<String, dynamic>> closeDivisionRegistrations(
    String id,
    List<String> divisionIds,
  ) async {
    calls.add('close-registration');
    closedDivisionIds.add(List.of(divisionIds));
    return const {};
  }

  @override
  Future<Map<String, dynamic>> startTournament(String id) async {
    calls.add('start');
    return const {};
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _ParticipantsRepository implements ITournamentRepository {
  _ParticipantsRepository(this.participants);

  final List<OrganizerOpsParticipant> participants;

  @override
  Future<List<OrganizerOpsParticipant>> getOrganizerParticipants(
    String tournamentId, {
    String? divisionId,
  }) async => participants;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Tournament _closedTournament() => Tournament.fromJson({
  'name': 'City Pickleball Cup',
  'sport': 'pickleball',
  'format': 'doubles',
  'bracketType': 'single_elimination',
  'status': 'REGISTRATION_CLOSED',
  'maxTeams': 8,
  'maxPlayersPerTeam': 2,
  'divisions': [
    {'id': 'div-3', 'name': 'Đơn Nam', 'matchType': 'SINGLES'},
  ],
  'createdAt': '2026-01-01T00:00:00Z',
  'updatedAt': '2026-01-01T00:00:00Z',
}, 'tournament-1');

/// Giải đã đóng đăng ký nhưng div-1/div-2 vẫn mở đăng ký riêng (mở lại từng
/// nội dung giữ nguyên trạng thái giải); div-3 đã đóng.
_OpeningRepository _repositoryWithOpenDivisions() =>
    _OpeningRepository()
      ..divisions.addAll([
        {'id': 'div-1', 'name': 'Đôi Nam', 'registrationOpen': true},
        {'id': 'div-2', 'name': 'Đôi Nữ', 'registrationOpen': true},
        {'id': 'div-3', 'name': 'Đơn Nam', 'registrationOpen': false},
      ]);

Widget _app(
  _OpeningRepository management, {
  required ITournamentRepository tournamentRepository,
}) => ProviderScope(
  overrides: [
    tournamentManagementRepositoryProvider.overrideWithValue(management),
    tournamentRepositoryProvider.overrideWithValue(tournamentRepository),
    matchesProvider(
      'tournament-1',
    ).overrideWith((ref) => Stream.value(const <MatchModel>[])),
    tournamentProvider(
      'tournament-1',
    ).overrideWith((ref) => Stream.value(_closedTournament())),
  ],
  child: MaterialApp(
    theme: AppTheme.lightTheme,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('vi'),
    home: Scaffold(
      body: ListView(
        children: [TournamentLifecycleCard(tournament: _closedTournament())],
      ),
    ),
  ),
);

/// Mở sheet khai mạc: bấm nút "Khai mạc giải" trên card vòng đời rồi chờ tải
/// danh sách hạng mục.
Future<void> _openSheet(
  WidgetTester tester,
  _OpeningRepository management,
  ITournamentRepository tournamentRepository,
) async {
  await tester.pumpWidget(
    _app(management, tournamentRepository: tournamentRepository),
  );
  await tester.pumpAndSettle();
  final l10n = AppLocalizations.of(
    tester.element(find.byType(TournamentLifecycleCard)),
  )!;
  await tester.tap(find.text(l10n.tournamentManagementStartTournament));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'TC-WP-01-01: khai mạc khi còn hạng mục mở — sheet liệt kê từng hạng mục, đóng đúng hạng mục đã chọn rồi start',
    (tester) async {
      tester.view.physicalSize = const Size(390, 1300);
      tester.view.devicePixelRatio = 1;
      final management = _repositoryWithOpenDivisions();
      // Một lượt đăng ký đang chờ duyệt để cảnh báo hiện trong sheet.
      final pending = OrganizerOpsParticipant.fromJson({
        'id': 'p-1',
        'teamStatus': 'PENDING',
      });
      await _openSheet(tester, management, _ParticipantsRepository([pending]));
      final l10n = AppLocalizations.of(
        tester.element(find.byType(LifecycleOpeningSheet)),
      )!;

      // Sheet liệt kê đúng 2 hạng mục đang mở (div-3 đã đóng không hiện),
      // tick sẵn "đóng đăng ký" cho cả hai.
      expect(
        find.byKey(const ValueKey('lifecycle-opening-division-div-1')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('lifecycle-opening-division-div-2')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('lifecycle-opening-division-div-3')),
        findsNothing,
      );
      expect(
        tester
            .widget<CheckboxListTile>(
              find.byKey(const ValueKey('lifecycle-opening-division-div-1')),
            )
            .value,
        isTrue,
      );

      // Cảnh báo: chưa có hạng mục nào có sơ đồ + lượt đăng ký chờ duyệt.
      expect(
        find.text(
          l10n.lifecycleOpeningWarningNoBracket('Đôi Nam, Đôi Nữ, Đơn Nam'),
        ),
        findsOneWidget,
      );
      expect(find.text(l10n.lifecycleOpeningWarningPending(1)), findsOneWidget);

      // Bỏ đóng "Đôi Nữ": chỉ gửi đúng hạng mục còn chọn, rồi khai mạc.
      await tester.tap(
        find.byKey(const ValueKey('lifecycle-opening-division-div-2')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.lifecycleOpeningStart));
      await tester.pumpAndSettle();

      expect(management.calls, ['close-registration', 'start']);
      expect(management.closedDivisionIds, [
        ['div-1'],
      ]);
      expect(find.byType(LifecycleOpeningSheet), findsNothing);
    },
  );

  testWidgets(
    'TC-WP-01-02: tắt chọn đóng hết — phải bấm qua cảnh báo và chỉ gọi start',
    (tester) async {
      tester.view.physicalSize = const Size(390, 1300);
      tester.view.devicePixelRatio = 1;
      final management = _repositoryWithOpenDivisions();
      await _openSheet(tester, management, _ParticipantsRepository(const []));
      final l10n = AppLocalizations.of(
        tester.element(find.byType(LifecycleOpeningSheet)),
      )!;

      // "Chọn hết" bấm một lần bỏ tick toàn bộ hạng mục.
      await tester.tap(
        find.byKey(const ValueKey('lifecycle-opening-select-all')),
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<CheckboxListTile>(
              find.byKey(const ValueKey('lifecycle-opening-division-div-1')),
            )
            .value,
        isFalse,
      );

      // Bấm khai mạc lần đầu: chỉ hiện cảnh báo, chưa gọi API.
      await tester.tap(find.text(l10n.lifecycleOpeningStart));
      await tester.pumpAndSettle();
      expect(find.text(l10n.lifecycleOpeningForceWarning), findsOneWidget);
      expect(find.text(l10n.lifecycleOpeningOpenAnyway), findsOneWidget);
      expect(management.calls, isEmpty);

      // Bấm qua cảnh báo: chỉ khai mạc, không đóng đăng ký hạng mục nào.
      await tester.tap(find.text(l10n.lifecycleOpeningOpenAnyway));
      await tester.pumpAndSettle();
      expect(management.calls, ['start']);
      expect(management.closedDivisionIds, isEmpty);
      expect(find.byType(LifecycleOpeningSheet), findsNothing);
    },
  );
}
