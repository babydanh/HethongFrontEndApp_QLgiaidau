import 'package:app_quanly_giaidau/core/router/app_router.dart';
import 'package:app_quanly_giaidau/features/match/notifiers/score_panel_notifier.dart';
import 'package:app_quanly_giaidau/features/match/notifiers/score_panel_state.dart';
import 'package:app_quanly_giaidau/features/match/widgets/official_score_modal.dart';
import 'package:app_quanly_giaidau/features/match/widgets/racket_court_panel.dart';
import 'package:app_quanly_giaidau/features/match/widgets/racket_court_view.dart';
import 'package:app_quanly_giaidau/features/match/widgets/rally_score_panel.dart';
import 'package:app_quanly_giaidau/features/match/widgets/tennis_score_panel.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/app_driver.dart';
import 'support/backend_api.dart';
import 'support/organizer_journey.dart';

/// TC-TENNIS-LITE-E2E-01/02: a tennis Lite match created on the real Backend,
/// opened from the organizer live desk, scored on the racket court panel
/// (commit 9dc151f4), then read back from the API, authenticated and public.
/// Reverting that commit renders TennisScorePanel and fails both cases.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final api = BackendApi();
  final tennisApi = _TennisLiteApi();

  setUpAll(initializeAppForTests);

  testWidgets(
    'TC-TENNIS-LITE-E2E-01 tennis Lite đơn: chấm trên sân vợt, lưu điểm, chốt set qua Backend thật',
    (tester) async {
      final seeded = await _seedTennisLite(api, tennisApi, doubles: false);
      final container = await signInAsOrganizer(tester);
      await _openScorePage(tester, container, seeded);

      // The fix: Lite tennis uses the court, not the generic tennis panel.
      _expectCourtPanel(tester);
      expect(_panelState(tester).isOpenScoring, isTrue, reason: 'Lite match');
      _expectBoard(tester, '0', '0', 'Game 0-0 · 0-0');

      // Two points for team 1, one for team 2: 30-15 inside game 1.
      await _point(tester, team: 1);
      await _point(tester, team: 1);
      await _point(tester, team: 2);
      _expectBoard(tester, '30', '15', 'Game 0-0 · 0-0');
      _expectNoError(tester);
      await _pollMatch(
        tester,
        tennisApi,
        seeded,
        (m) =>
            _sets(m).toString() == '[(0, 0, false)]' &&
            _pointState(m) == (2, 1),
        what: 'set 0-0 đang đánh, điểm game 30-15 (2-1)',
      );

      // Two more points win game 1 for team 1: games 1-0, points reset.
      await _point(tester, team: 1);
      await _point(tester, team: 1);
      _expectBoard(tester, '0', '0', 'Game 1-0 · 0-0');
      _expectNoError(tester);
      await _pollMatch(
        tester,
        tennisApi,
        seeded,
        (m) =>
            _sets(m).toString() == '[(1, 0, false)]' &&
            _pointState(m) == (0, 0),
        what: 'game 1-0 trong set 1, điểm game về 0-0',
      );

      // Lite never closes the set by itself: the referee taps "Chốt set 1".
      await _closeSet(tester, setNumber: 1, games: '1-0');
      _expectBoard(tester, '0', '0', 'Game 0-0 · 1-0');
      _expectNoError(tester);
      final saved = await _pollMatch(
        tester,
        tennisApi,
        seeded,
        (m) => _sets(m).isNotEmpty && _sets(m).first == (1, 0, true),
        what: 'set 1 chốt 1-0',
      );
      expect(
        saved['status'],
        'ONGOING',
        reason: 'Lite chốt set không kết thúc trận',
      );
      expect(saved['winnerId'], isNull);

      // The public live view (no token) reads the same saved score.
      final public = await tennisApi.getMatch(seeded.matchId);
      expect(_sets(public).first, (1, 0, true));
      expect(public['status'], 'ONGOING');
      _expectNoError(tester);
    },
  );

  testWidgets(
    'TC-TENNIS-LITE-E2E-02 tennis Lite đôi: chọn người giao, lưu courtState, thắng 1 game',
    (tester) async {
      final seeded = await _seedTennisLite(api, tennisApi, doubles: true);
      final container = await signInAsOrganizer(tester);
      await _openScorePage(tester, container, seeded);

      _expectCourtPanel(tester);
      expect(_panelState(tester).tennisDoubles, isTrue, reason: 'trận đôi');
      expect(find.text('Bấm VĐV để chọn người giao.'), findsOneWidget);

      // Team 1 chooses its first player as the server by tapping the cell.
      await _tapPlayer(tester, seeded.team1PlayerSuffix);
      expect(find.text('Bấm VĐV để chọn người giao.'), findsNothing);
      _expectNoError(tester);
      await _pollMatch(
        tester,
        tennisApi,
        seeded,
        (m) => _courtState(m)?['firstServerTeam'] == 1,
        what: 'courtState.firstServerTeam = 1',
      );

      for (var i = 0; i < 4; i++) {
        await _point(tester, team: 1);
      }
      _expectBoard(tester, '0', '0', 'Game 1-0 · 0-0');
      _expectNoError(tester);
      // Score writes must keep the saved court state (who serves).
      await _pollMatch(
        tester,
        tennisApi,
        seeded,
        (m) =>
            _sets(m).toString() == '[(1, 0, false)]' &&
            _courtState(m)?['firstServerTeam'] == 1,
        what: 'game 1-0 và courtState vẫn còn',
      );
    },
  );
}

/// A seeded tennis Lite match ready to be opened by the organizer.
class _SeededTennis {
  const _SeededTennis({
    required this.tournamentId,
    required this.matchId,
    required this.token,
    required this.team1PlayerSuffix,
  });

  final String tournamentId;
  final String matchId;
  final String token;

  /// Last word of team 1's first player name ("P3A"); the court abbreviates
  /// the leading words, so the cell is found by this suffix.
  final String team1PlayerSuffix;
}

/// Organizer creates a tennis Lite tournament, admin approves, 4 entries are
/// imported, the bracket is drawn and the tournament is started.
Future<_SeededTennis> _seedTennisLite(
  BackendApi api,
  _TennisLiteApi tennisApi, {
  required bool doubles,
}) async {
  final tag = 'E2E${DateTime.now().millisecondsSinceEpoch}';
  final token = await api.login(kOrganizerEmail, kE2ePassword);
  final created = await tennisApi.createTennisLite(
    token: token,
    name: '$tag Tennis Lite ${doubles ? 'doi' : 'don'}',
    matchType: doubles ? 'DOUBLES' : 'SINGLES',
  );
  final tid = created.tournamentId;
  await api.approveTournamentAsAdmin(tid);
  await api.importRoster(
    token: token,
    tournamentId: tid,
    divisionId: created.divisionId,
    tag: tag,
    count: 4,
    singles: !doubles,
  );
  await api.generateBracket(
    token: token,
    tournamentId: tid,
    divisionId: created.divisionId,
  );
  await api.startTournament(token: token, tournamentId: tid);
  final match = await _firstPlayableMatch(api, token, created);
  return _SeededTennis(
    tournamentId: tid,
    matchId: match.id,
    token: token,
    team1PlayerSuffix: await _team1PlayerSuffix(api, token, created, match),
  );
}

Future<({String id, String participant1Id})> _firstPlayableMatch(
  BackendApi api,
  String token,
  CreatedTournament t,
) async {
  final matches = await api.listMatches(
    token: token,
    tournamentId: t.tournamentId,
    divisionId: t.divisionId,
  );
  final playable = matches
      .where(
        (m) => m['participant1Id'] is String && m['participant2Id'] is String,
      )
      .toList();
  expect(playable, isNotEmpty, reason: 'Sơ đồ 4 VĐV phải có trận đủ đối thủ');
  final m = playable.first;
  return (id: m['id'] as String, participant1Id: m['participant1Id'] as String);
}

/// Roster import names entry i `TAG VDV i` / `TAG Doi i` and its first
/// player `TAG PiA`.
Future<String> _team1PlayerSuffix(
  BackendApi api,
  String token,
  CreatedTournament t,
  ({String id, String participant1Id}) match,
) async {
  final participants = await api.listParticipants(
    token: token,
    tournamentId: t.tournamentId,
    divisionId: t.divisionId,
  );
  final team = participants.firstWhere((p) => p['id'] == match.participant1Id);
  final number = RegExp(r'(\d+)$').firstMatch('${team['teamName']}')?.group(1);
  expect(number, isNotNull, reason: 'teamName không theo mẫu: $team');
  return 'P${number}A';
}

/// Opens the organizer live desk of the match, starts it from the app and
/// waits for the official score page (Lite opens it on start).
Future<void> _openScorePage(
  WidgetTester tester,
  ProviderContainer container,
  _SeededTennis seeded,
) async {
  final start = find.text('BẮT ĐẦU TRẬN ĐẤU');
  await _goUntilFound(
    tester,
    container,
    '/organizer/tournaments/${seeded.tournamentId}/ops/match/${seeded.matchId}',
    start,
  );
  await tapCentered(tester, start);
  final scorePage = find.byType(OfficialScorePage);
  final openBoard = find.byTooltip('MỞ BẢNG');
  await pumpUntilCondition(
    tester,
    () => scorePage.evaluate().isNotEmpty || openBoard.evaluate().isNotEmpty,
    what: 'bảng điểm tự mở hoặc nút MỞ BẢNG',
  );
  if (scorePage.evaluate().isEmpty) await tapCentered(tester, openBoard);
  await pumpUntilFound(tester, scorePage, what: 'trang bảng điểm chính thức');
  // The panel hydrates from the match stream before scoring is possible.
  await pumpUntilFound(
    tester,
    find.byKey(const ValueKey('racketPlus1')),
    what: 'nút + của đội 1 trên sân vợt',
  );
  _expectNoError(tester);
}

/// Right after login the router can still move to another page and replace
/// the first navigation (seen on the first test of a run), so navigate again
/// every 10 s until [target] shows, for at most 60 s.
Future<void> _goUntilFound(
  WidgetTester tester,
  ProviderContainer container,
  String route,
  Finder target,
) async {
  final deadline = DateTime.now().add(const Duration(seconds: 60));
  while (true) {
    container.read(routerProvider).go(route);
    final retryAt = DateTime.now().add(const Duration(seconds: 10));
    while (target.evaluate().isEmpty && DateTime.now().isBefore(retryAt)) {
      await tester.pump(const Duration(milliseconds: 250));
    }
    if (target.evaluate().isNotEmpty) return;
    if (DateTime.now().isAfter(deadline)) {
      // Fails and lists the texts on screen.
      await pumpUntilFound(
        tester,
        target,
        what: '$target sau khi mở $route',
        timeout: Duration.zero,
      );
    }
  }
}

void _expectCourtPanel(WidgetTester tester) {
  expect(find.byType(RacketCourtPanel), findsOneWidget);
  expect(find.byType(TennisScorePanel), findsNothing);
  expect(find.byType(RallyScorePanel), findsNothing);
}

/// Taps the "+" of [team] and lets the 250 ms live-sync debounce fire.
Future<void> _point(WidgetTester tester, {required int team}) async {
  await tester.tap(find.byKey(ValueKey('racketPlus$team')));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 700));
}

Future<void> _tapPlayer(WidgetTester tester, String suffix) async {
  final cell = find.descendant(
    of: find.byType(RacketCourtView),
    matching: find.byWidgetPredicate(
      (w) => w is Text && (w.data ?? '').endsWith(' $suffix'),
      description: 'ô VĐV có tên kết thúc bằng "$suffix"',
    ),
  );
  await pumpUntilFound(tester, cell, what: 'ô VĐV $suffix trên sân');
  await tester.tap(cell.first);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 700));
}

/// Taps "Chốt set N", checks the confirm text and confirms.
Future<void> _closeSet(
  WidgetTester tester, {
  required int setNumber,
  required String games,
}) async {
  final label = 'Chốt set $setNumber';
  await tester.tap(find.widgetWithText(OutlinedButton, label));
  await tester.pump();
  final dialog = find.byType(AlertDialog);
  await pumpUntilFound(tester, dialog, what: 'hộp xác nhận $label');
  expect(
    find.descendant(
      of: dialog,
      matching: find.text('Kết thúc set $setNumber với tỉ số $games?'),
    ),
    findsOneWidget,
  );
  await tester.tap(
    find.descendant(
      of: dialog,
      matching: find.widgetWithText(FilledButton, label),
    ),
  );
  await tester.pump();
  await pumpUntilCondition(
    tester,
    () => dialog.evaluate().isEmpty && !_panelState(tester).isSubmitting,
    what: 'đóng hộp xác nhận và gửi xong',
  );
}

/// Checks the two big scores (team 1, team 2) and the "Game a-b · sets" line
/// the court shows.
void _expectBoard(WidgetTester tester, String a, String b, String setText) {
  final view = tester.widget<RacketCourtView>(find.byType(RacketCourtView));
  expect((view.scoreText1, view.scoreText2), (a, b));
  expect(view.setText, setText);
  expect(
    find.descendant(
      of: find.byType(RacketCourtView),
      matching: find.text(setText),
    ),
    findsOneWidget,
  );
}

/// No snackbar, no stray dialog, no panel error, no framework exception.
void _expectNoError(WidgetTester tester) {
  expect(find.byType(SnackBar), findsNothing, reason: 'snackbar lỗi');
  expect(find.byType(AlertDialog), findsNothing, reason: 'hộp thoại lỗi');
  expect(_panelState(tester).errorMessage, isNull);
  expect(tester.takeException(), isNull);
}

ScorePanelState _panelState(WidgetTester tester) {
  final panel = find.byType(RacketCourtPanel);
  final params = tester.widget<RacketCourtPanel>(panel).params;
  return ProviderScope.containerOf(
    tester.element(panel),
  ).read(scorePanelNotifierProvider(params));
}

/// Polls `GET /matches/:id` (organizer token) until [ok] holds.
Future<Map<String, dynamic>> _pollMatch(
  WidgetTester tester,
  _TennisLiteApi tennisApi,
  _SeededTennis seeded,
  bool Function(Map<String, dynamic> match) ok, {
  required String what,
}) async {
  final deadline = DateTime.now().add(const Duration(seconds: 30));
  while (true) {
    final match = await tennisApi.getMatch(seeded.matchId, token: seeded.token);
    if (ok(match)) return match;
    if (DateTime.now().isAfter(deadline)) {
      fail(
        'Hết 30s mà Backend chưa có: $what. '
        'scoreDetails cuối: ${match['scoreDetails']}',
      );
    }
    await tester.pump(const Duration(milliseconds: 500));
  }
}

Map<String, dynamic> _details(Map<String, dynamic> match) {
  final details = match['scoreDetails'];
  return details is Map ? Map<String, dynamic>.from(details) : const {};
}

/// Saved sets as (team 1 games, team 2 games, finished).
List<(int, int, bool)> _sets(Map<String, dynamic> match) {
  final sets = _details(match)['sets'];
  if (sets is! List) return const [];
  return [
    for (final s in sets.whereType<Map>())
      (
        (s['team1Score'] as num?)?.toInt() ?? -1,
        (s['team2Score'] as num?)?.toInt() ?? -1,
        s['isFinished'] == true,
      ),
  ];
}

/// Saved tennis point state of the open game as (team 1, team 2).
(int, int)? _pointState(Map<String, dynamic> match) {
  final live = _details(match)['liveState'];
  final point = live is Map ? live['tennisPointState'] : null;
  if (point is! Map) return null;
  return (
    (point['team1Point'] as num?)?.toInt() ?? -1,
    (point['team2Point'] as num?)?.toInt() ?? -1,
  );
}

Map<String, dynamic>? _courtState(Map<String, dynamic> match) {
  final court = _details(match)['courtState'];
  return court is Map ? Map<String, dynamic>.from(court) : null;
}

/// Calls BackendApi does not have: a tennis Lite tournament (its helper is
/// pickleball only) and the match detail, with or without a token.
class _TennisLiteApi {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: kE2eApiBaseUrl,
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 60),
      contentType: Headers.jsonContentType,
      validateStatus: (_) => true,
    ),
  );

  Future<CreatedTournament> createTennisLite({
    required String token,
    required String name,
    required String matchType,
  }) async {
    final data = await _send(
      'POST',
      '/tournaments/lite',
      token: token,
      body: {
        'name': name,
        'sport': 'tennis',
        'format': matchType == 'SINGLES' ? 'singles' : 'doubles',
        'bracketType': 'single_elimination',
        'maxTeams': 8,
        'visibility': 'PUBLIC',
        if (matchType != 'SINGLES') 'doublesPairingMode': 'ORGANIZER',
        'divisions': [
          {
            'name': 'Nội dung chính',
            'matchType': matchType,
            'bracketType': 'SINGLE_ELIMINATION',
            'maxParticipants': 8,
          },
        ],
      },
    );
    final ids = data['divisionIds'];
    if (data['id'] is! String || ids is! List || ids.isEmpty) {
      fail('POST /tournaments/lite thiếu id/divisionIds: $data');
    }
    return CreatedTournament(
      tournamentId: data['id'] as String,
      divisionId: ids.first as String,
    );
  }

  /// `GET /matches/:id`; without [token] it is the public live view.
  Future<Map<String, dynamic>> getMatch(String id, {String? token}) =>
      _send('GET', '/matches/$id', token: token);

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    String? token,
    Object? body,
  }) async {
    final response = await _dio.request<Object?>(
      path,
      data: body,
      options: Options(
        method: method,
        headers: token == null ? null : {'Authorization': 'Bearer $token'},
      ),
    );
    final code = response.statusCode ?? 0;
    final raw = response.data;
    if (code < 200 || code >= 300) {
      fail('$method $path -> HTTP $code: $raw');
    }
    final data = raw is Map && raw['data'] is Map ? raw['data'] : raw;
    if (data is! Map) fail('$method $path không trả object: $raw');
    return Map<String, dynamic>.from(data);
  }
}
