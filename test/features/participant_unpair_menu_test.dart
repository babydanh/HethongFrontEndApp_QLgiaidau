import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/domain/entities/organizer_ops.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/domain/repositories/tournament_management_repository.dart';
import 'package:app_quanly_giaidau/domain/repositories/tournament_repository.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/tournament_management_people_section.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _ParticipantsRepository implements ITournamentRepository {
  _ParticipantsRepository(this.participants);

  final List<OrganizerOpsParticipant> participants;
  int calls = 0;

  @override
  Future<List<OrganizerOpsParticipant>> getOrganizerParticipants(
    String tournamentId, {
    String? divisionId,
  }) async {
    calls += 1;
    return participants;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _RecordingManagementRepository implements TournamentManagementRepository {
  final unpaired = <String>[];

  @override
  Future<void> unpairParticipant(String id, String participantId) async {
    unpaired.add(participantId);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Tournament _tournament(String status) => Tournament.fromJson({
  'name': 'Community Doubles Cup',
  'sport': 'pickleball',
  'format': 'doubles',
  'bracketType': 'single_elimination',
  'status': status,
  'maxTeams': 8,
  'maxPlayersPerTeam': 2,
  'createdAt': '2026-01-01T00:00:00Z',
  'updatedAt': '2026-01-01T00:00:00Z',
}, 'tournament-1');

Future<_ParticipantsRepository> _pump(
  WidgetTester tester,
  _RecordingManagementRepository management, {
  required String tournamentStatus,
  required bool canUnpair,
}) async {
  final repo = _ParticipantsRepository([
    OrganizerOpsParticipant(
      id: 'p-1',
      teamName: 'Danh – Luân',
      teamStatus: 'COMPLETE',
      isPaid: true,
      canUnpair: canUnpair,
      members: const [
        OrganizerOpsMember(userId: 'u-danh', fullName: 'Danh'),
        OrganizerOpsMember(userId: 'u-luan', fullName: 'Luân'),
      ],
      divisionId: 'div-1',
    ),
  ]);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        tournamentRepositoryProvider.overrideWithValue(repo),
        tournamentManagementRepositoryProvider.overrideWithValue(management),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('vi'),
        home: Scaffold(
          body: TournamentManagementPeopleSection(
            tournament: _tournament(tournamentStatus),
            showRegistration: true,
            divisionId: 'div-1',
            embedded: true,
            pairFormat: true,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return repo;
}

void main() {
  testWidgets('TC-WP-03-05: menu dòng có Tách cặp, confirm rồi gọi unpair', (
    tester,
  ) async {
    final management = _RecordingManagementRepository();
    final repo = await _pump(
      tester,
      management,
      tournamentStatus: 'IN_PROGRESS',
      canUnpair: true,
    );

    final menu = find.byKey(const ValueKey('participant-row-menu-p-1'));
    expect(menu, findsOneWidget);
    await tester.tap(menu);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('participant-unpair-p-1')));
    await tester.pumpAndSettle();
    // Chưa confirm thì chưa gọi API.
    expect(management.unpaired, isEmpty);

    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(FilledButton, 'Tách cặp'),
      ),
    );
    await tester.pumpAndSettle();

    expect(management.unpaired, ['p-1']);
    // Xong phải làm mới danh sách (lần 1 lúc mở, lần 2 sau unpair).
    expect(repo.calls, 2);
  });

  testWidgets('TC-WP-03-05: server không cho tách thì không có menu', (
    tester,
  ) async {
    final management = _RecordingManagementRepository();
    await _pump(
      tester,
      management,
      tournamentStatus: 'IN_PROGRESS',
      canUnpair: false,
    );

    expect(
      find.byKey(const ValueKey('participant-row-menu-p-1')),
      findsNothing,
    );
  });

  testWidgets('TC-WP-03-05: giải đã kết thúc thì ẩn menu tách cặp', (
    tester,
  ) async {
    final management = _RecordingManagementRepository();
    await _pump(
      tester,
      management,
      tournamentStatus: 'COMPLETED',
      canUnpair: true,
    );

    expect(
      find.byKey(const ValueKey('participant-row-menu-p-1')),
      findsNothing,
    );
  });
}
