import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament_registration.dart';
import 'package:app_quanly_giaidau/features/home/widgets/explore_new_tournaments.dart';
import 'package:flutter_test/flutter_test.dart';

final _now = DateTime(2026, 11, 9, 10);

Tournament _t(
  String id,
  String status, {
  DateTime? created,
  DateTime? start,
  DateTime? regStart,
  TournamentDivisionCapacity? capacity,
}) => Tournament(
  id: id,
  name: id,
  sport: 'PICKLEBALL',
  format: 'single_elimination',
  bracketType: 'single_elimination',
  adminToken: 'a',
  refereeToken: 'r',
  viewerToken: 'v',
  creatorId: 'u1',
  status: status,
  createdAt: created ?? DateTime(2026, 1, 1),
  updatedAt: DateTime(2026, 1, 1),
  startDate: start,
  registrationStartDate: regStart,
  capacity: capacity,
);

void main() {
  test('TC-EXPLORE-NEW-01 opened = registration open within 7 days', () {
    final picked = pickNewTournaments([
      _t('fresh', 'registration', created: DateTime(2026, 11, 8)),
      _t('old', 'registration', created: DateTime(2026, 10, 1)),
      _t('scheduled', 'registration',
          created: DateTime(2026, 10, 1), regStart: DateTime(2026, 11, 5)),
      _t('future-open', 'registration',
          created: DateTime(2026, 11, 8), regStart: DateTime(2026, 11, 20)),
      _t('closed', 'registration_closed', created: DateTime(2026, 11, 8)),
    ], _now);

    // future-open falls back to createdAt (scheduled date not reached yet).
    expect(picked.opened.map((t) => t.id), ['fresh', 'future-open', 'scheduled']);
    expect(picked.started, isEmpty);
  });

  test('TC-EXPLORE-NEW-02 started = in progress with start in last 48h', () {
    final picked = pickNewTournaments([
      _t('now', 'in_progress', start: DateTime(2026, 11, 9, 8)),
      _t('yesterday', 'in_progress', start: DateTime(2026, 11, 8, 10)),
      _t('stale', 'in_progress', start: DateTime(2026, 11, 1)),
      _t('nodate', 'in_progress'),
      _t('future', 'in_progress', start: DateTime(2026, 11, 12)),
    ], _now);

    expect(picked.started.map((t) => t.id), ['now', 'yesterday']);
    expect(picked.opened, isEmpty);
  });

  test('TC-EXPLORE-NEW-03 full tournaments are hidden from opened', () {
    final picked = pickNewTournaments([
      _t('full', 'registration',
          created: DateTime(2026, 11, 8),
          capacity: const TournamentDivisionCapacity(
            occupiedTeamSlots: 16,
            maxTeamSlots: 16,
            isFull: true,
          )),
      _t('free', 'registration',
          created: DateTime(2026, 11, 8),
          capacity: const TournamentDivisionCapacity(
            occupiedTeamSlots: 3,
            maxTeamSlots: 16,
            isFull: false,
          )),
    ], _now);

    expect(picked.opened.map((t) => t.id), ['free']);
  });

  test('TC-EXPLORE-NEW-04 each group is capped at 6, newest first, no dupes', () {
    final list = [
      for (var i = 0; i < 8; i++)
        _t('t$i', 'registration', created: DateTime(2026, 11, 1 + i)),
      _t('t7', 'registration', created: DateTime(2026, 11, 8)),
    ];
    final picked = pickNewTournaments(list, _now);

    expect(picked.opened.map((t) => t.id), ['t7', 't6', 't5', 't4', 't3', 't2']);
  });

  test('TC-EXPLORE-NEW-05 empty or irrelevant input hides the block', () {
    expect(pickNewTournaments(const [], _now).isEmpty, isTrue);
    expect(
      pickNewTournaments([_t('done', 'completed', created: DateTime(2026, 11, 8))], _now)
          .isEmpty,
      isTrue,
    );
  });
}
