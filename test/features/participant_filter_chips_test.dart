import 'dart:ui' show Tristate;

import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/domain/entities/organizer_ops.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/domain/repositories/tournament_repository.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/tournament_management_people_section.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Mock repository: đếm số lần tải danh sách để chứng minh lọc KHÔNG gọi lại API.
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

Tournament _tournament() => Tournament.fromJson({
  'name': 'Community Doubles Cup',
  'sport': 'pickleball',
  'format': 'doubles',
  'bracketType': 'single_elimination',
  'status': 'in_progress',
  'maxTeams': 8,
  'maxPlayersPerTeam': 2,
  'createdAt': '2026-01-01T00:00:00Z',
  'updatedAt': '2026-01-01T00:00:00Z',
}, 'tournament-1');

const _participants = [
  // 2 đã duyệt (1 chưa đóng phí), 1 chờ duyệt, 1 chờ đối tác, 1 bị từ chối.
  OrganizerOpsParticipant(
    id: 'p-1',
    teamName: 'Đã Duyệt Đóng Phí',
    teamStatus: 'COMPLETE',
    isPaid: true,
    members: [],
    divisionId: 'div-1',
  ),
  OrganizerOpsParticipant(
    id: 'p-2',
    teamName: 'An – Bình',
    teamStatus: 'PENDING_APPROVAL',
    isPaid: false,
    members: [],
    divisionId: 'div-1',
  ),
  OrganizerOpsParticipant(
    id: 'p-3',
    teamName: 'Chờ Đối Tác',
    teamStatus: 'PENDING_PARTNER',
    isPaid: true,
    members: [],
    divisionId: 'div-1',
  ),
  OrganizerOpsParticipant(
    id: 'p-4',
    teamName: 'Đã Duyệt Chưa Phí',
    teamStatus: 'COMPLETE',
    isPaid: false,
    members: [],
    divisionId: 'div-1',
  ),
  OrganizerOpsParticipant(
    id: 'p-5',
    teamName: 'Bị Từ Chối',
    teamStatus: 'REJECTED',
    isPaid: true,
    members: [],
    divisionId: 'div-1',
  ),
];

Future<_ParticipantsRepository> _pump(
  WidgetTester tester, {
  List<OrganizerOpsParticipant> participants = _participants,
  bool pairFormat = true,
}) async {
  final repo = _ParticipantsRepository(participants);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [tournamentRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('vi'),
        home: Scaffold(
          body: TournamentManagementPeopleSection(
            tournament: _tournament(),
            showRegistration: true,
            divisionId: 'div-1',
            embedded: true,
            pairFormat: pairFormat,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return repo;
}

/// Số đếm trong chip = Text cuối cùng của chip (sau nhãn).
String _chipCount(WidgetTester tester, String name) {
  final chip = find.byKey(ValueKey('participant-filter-$name'));
  final texts = find.descendant(of: chip, matching: find.byType(Text));
  return tester.widget<Text>(texts.last).data!;
}

void main() {
  testWidgets(
    'filter chips are 44px tall and expose button+selected semantics',
    (tester) async {
      final handle = tester.ensureSemantics();
        await _pump(tester);

      final chip = find.byKey(const ValueKey('participant-filter-all'));
      expect(tester.getSize(chip).height, greaterThanOrEqualTo(44));

      final data = tester.getSemantics(chip);
      expect(data.flagsCollection.isButton, isTrue);
      expect(data.flagsCollection.isSelected, Tristate.isTrue);
      expect(data.label, contains('5'));

      final other = tester.getSemantics(
        find.byKey(const ValueKey('participant-filter-pending')),
      );
      expect(other.flagsCollection.isSelected, Tristate.isFalse);
    handle.dispose();
    },
  );

  testWidgets('TC-WP-03-01: chips lọc trạng thái hiện đủ 6 mục kèm số đếm', (
    tester,
  ) async {
    await _pump(tester);

    expect(_chipCount(tester, 'all'), '5');
    expect(_chipCount(tester, 'pending'), '1');
    expect(_chipCount(tester, 'pendingPartner'), '1');
    expect(_chipCount(tester, 'approved'), '2');
    expect(_chipCount(tester, 'unpaid'), '2');
    expect(_chipCount(tester, 'rejected'), '1');
  });

  testWidgets('TC-WP-03-01: chọn "Chờ duyệt" lọc ngay tại chỗ, không gọi API', (
    tester,
  ) async {
    final repo = await _pump(tester);

    await tester.tap(find.byKey(const ValueKey('participant-filter-pending')));
    await tester.pumpAndSettle();

    // Chỉ hồ sơ chờ duyệt còn lại; các trạng thái khác biến mất khỏi danh sách.
    expect(find.byKey(const ValueKey('athlete-team-row-p-2')), findsOneWidget);
    expect(find.byKey(const ValueKey('athlete-team-row-p-1')), findsNothing);
    expect(find.byKey(const ValueKey('athlete-team-row-p-3')), findsNothing);
    expect(find.byKey(const ValueKey('athlete-team-row-p-4')), findsNothing);
    expect(find.byKey(const ValueKey('athlete-team-row-p-5')), findsNothing);
    // Lọc tại chỗ: đúng 1 lần tải danh sách lúc mở tab.
    expect(repo.calls, 1);

    await tester.tap(find.byKey(const ValueKey('participant-filter-all')));
    await tester.pumpAndSettle();
    for (final id in ['p-1', 'p-2', 'p-3', 'p-4', 'p-5']) {
      expect(find.byKey(ValueKey('athlete-team-row-$id')), findsOneWidget);
    }
  });

  testWidgets('TC-WP-03-01: chip "Chưa thanh toán" lọc theo isPaid', (
    tester,
  ) async {
    await _pump(tester);

    await tester.tap(find.byKey(const ValueKey('participant-filter-unpaid')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('athlete-team-row-p-2')), findsOneWidget);
    expect(find.byKey(const ValueKey('athlete-team-row-p-4')), findsOneWidget);
    expect(find.byKey(const ValueKey('athlete-team-row-p-1')), findsNothing);
    expect(find.byKey(const ValueKey('athlete-team-row-p-5')), findsNothing);
  });

  testWidgets('TC-WP-03-01: chip "Chờ đối tác" ẩn khi đơn và không ai chờ', (
    tester,
  ) async {
    final singles = _participants
        .map(
          (item) => OrganizerOpsParticipant(
            id: item.id,
            teamName: item.teamName,
            teamStatus: item.teamStatus == 'PENDING_PARTNER'
                ? 'COMPLETE'
                : item.teamStatus,
            isPaid: item.isPaid,
            members: const [],
            divisionId: 'div-1',
          ),
        )
        .toList(growable: false);
    await _pump(tester, participants: singles, pairFormat: false);

    expect(
      find.byKey(const ValueKey('participant-filter-pendingPartner')),
      findsNothing,
    );
  });
}
