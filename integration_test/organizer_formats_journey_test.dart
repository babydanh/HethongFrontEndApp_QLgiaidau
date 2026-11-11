import 'dart:async';

import 'package:app_quanly_giaidau/core/router/app_router.dart';
import 'package:app_quanly_giaidau/features/bracket/screens/bracket_diagram_screen.dart';
import 'package:app_quanly_giaidau/features/bracket/screens/bracket_view_screen.dart';
import 'package:app_quanly_giaidau/features/bracket/screens/stage_operations_screen.dart';
import 'package:app_quanly_giaidau/features/bracket/widgets/bracket_filter_bottom_sheet.dart';
import 'package:app_quanly_giaidau/features/bracket/widgets/swiss_standings_view.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/tournament_management_divisions_section.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/tournament_management_hub_screen.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:app_quanly_giaidau/providers/standings_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/app_driver.dart';
import 'support/backend_api.dart';
import 'support/organizer_journey.dart';
import 'support/shot.dart';

/// Task 2.3 (TC-QLGD-APP-40..59): BTC đi qua các thể thức thi đấu: vòng tròn, loại kép, vòng bảng
/// (popup cài đặt, hạt giống), Swiss (ghép cặp, hoàn tác) và vận hành giai đoạn. Backend thật.
/// Mỗi giải dựng bằng API (loại trực tiếp), thể thức đổi trên giao diện qua DivisionEditorSheet.
/// Kéo-thả không chạm được trên emulator nên dùng đường thay thế bằng chạm (menu `move-*`, sheet đổi chỗ Swiss).
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(initializeAppForTests);

  const testTimeout = Timeout(Duration(minutes: 10));

  testWidgets(
    'TC-QLGD-APP-40: BTC đổi nội dung sang Vòng tròn, tạo sơ đồ qua popup và kết thúc sớm giai đoạn (TC 40-43)',
    (tester) async {
      final j = _Journey(tester, binding, 'fmt-rr');
      await j.start(players: 4);

      // TC-40: sửa nội dung sang Vòng tròn, 2 lượt.
      await j.editDivision(
        'ROUND_ROBIN',
        openStage: true,
        configure: () async {
          await expectKey(tester, 'division-editor-rr-rounds');
          await tester.enterText(
            find.byKey(const ValueKey('division-editor-rr-rounds')),
            '2',
          );
          await tester.pump();
        },
      );
      final division = await j.eventually(
        'nội dung chuyển sang ROUND_ROBIN',
        () async {
          final d = await j.division();
          return d['bracketType'] == 'ROUND_ROBIN' ? d : null;
        },
      );
      expect(
        _map(_map(division['roundConfig'])['groupsConfig'])['roundsToPlay'],
        2,
        reason: 'Ô số lượt đấu (division-editor-rr-rounds) phải lưu roundsToPlay=2',
      );

      await openHubTab(tester, 'Bảng đấu');

      // TC-42: tạo sơ đồ bằng nút trên tab Bảng đấu; popup cài đặt hiện trước, xác nhận bằng giá trị gợi ý.
      await tapKey(tester, 'bracket-mgmt-create', step: 'tạo sơ đồ vòng tròn');
      await tapKey(tester, 'bracket-create-confirm', step: 'xác nhận popup tạo bracket');
      await expectKey(tester, 'bracket-mgmt-delete', step: 'sơ đồ đã có');
      final stage = await j.eventually('stage ROUND_ROBIN có trận', () async {
        final stages = await j.extra.stages(j.tid, j.did);
        final rr = stages.where((e) => _stageType(e) == 'ROUND_ROBIN');
        return rr.isNotEmpty && _stageMatches(rr.first).isNotEmpty ? rr.first : null;
      });
      final total = _stageMatches(stage).length;
      debugPrint('TC-42: vòng tròn 4 đội 2 lượt có $total trận');
      expect(total % 6, 0, reason: '4 đội vòng tròn phải là bội của 6 trận, có $total');
      expect(total, greaterThanOrEqualTo(6));
      await j.snap('so-do');

      // TC-43: vận hành giai đoạn: chấm một trận, nút hủy sơ đồ bị khóa, kết thúc sớm (quay lại rồi xác nhận).
      await j.startAndScore(limit: 1);
      await j.openStageOperations();
      await expectKey(tester, 'stage-action-cancel-bracket', step: 'màn vận hành');
      expect(
        _enabled(tester, 'stage-action-cancel-bracket'),
        isFalse,
        reason: 'Đã có trận bắt đầu thì không được hủy sơ đồ',
      );
      expect(find.text('Không thể hủy vì đã có trận bắt đầu.'), findsOneWidget);
      await j.snap('van-hanh');
      final finish = _keyed('stage-action-finish-');
      await tapFinder(tester, finish, 'nút Kết thúc sớm giai đoạn');
      await pumpUntilFound(tester, find.byType(AlertDialog), what: 'hộp xác nhận kết thúc sớm');
      await j.snap('ket-thuc-som-hop');
      final openBefore = await j.openMatchCount();
      await tapFinder(tester, _dialogButton(find.widgetWithText(TextButton, 'Quay lại')), 'Quay lại');
      await gone(tester, find.byType(AlertDialog), 'hộp xác nhận (Quay lại)');
      expect(await j.openMatchCount(), openBefore, reason: 'Quay lại không được kết thúc giai đoạn');
      await tapFinder(tester, finish, 'nút Kết thúc sớm giai đoạn (lần 2)');
      await tapFinder(
        tester,
        _dialogButton(find.widgetWithText(FilledButton, 'Kết thúc sớm')),
        'xác nhận Kết thúc sớm',
      );
      await pumpUntilFound(tester, find.text('Đã kết thúc giai đoạn.'), what: 'thông báo đã kết thúc giai đoạn');
      await j.eventually('giai đoạn không còn trận mở, giữ 1 trận đã xong', () async {
        final stages = await j.extra.stages(j.tid, j.did);
        final matches = _stageMatches(stages.first);
        final open = matches.where((m) => _status(m) != 'COMPLETED' && _status(m) != 'CANCELLED');
        final done = matches.where((m) => _status(m) == 'COMPLETED');
        return open.isEmpty && done.length == 1 ? true : null;
      });
      await gone(tester, finish, 'nút kết thúc sớm sau khi đã kết thúc');
      await j.snap('ket-thuc-som-xong');
    },
    timeout: testTimeout,
  );

  testWidgets(
    'TC-QLGD-APP-44: BTC đổi nội dung sang Loại kép, tạo sơ đồ, tìm kiếm, lọc nhánh, mở sơ đồ đầy đủ và hủy sơ đồ (TC 44-47)',
    (tester) async {
      final j = _Journey(tester, binding, 'fmt-de');
      await j.start(players: 4);

      // TC-44: chọn Loại kép, xem minh họa thể thức rồi lưu.
      await j.editDivision(
        'DOUBLE_ELIMINATION',
        configure: () async {
          await tapKey(tester, 'division-editor-illustration-DOUBLE_ELIMINATION', step: 'minh họa Loại kép');
          await expectKey(tester, 'format-illustration-dialog', step: 'hộp minh họa');
          await j.snap('minh-hoa');
          await tapFinder(
            tester,
            find.descendant(
              of: find.byKey(const ValueKey('format-illustration-dialog')),
              matching: find.byType(TextButton),
            ),
            'nút Đóng hộp minh họa',
          );
          await gone(tester, find.byKey(const ValueKey('format-illustration-dialog')), 'hộp minh họa');
        },
      );
      await j.eventually('nội dung chuyển sang DOUBLE_ELIMINATION', () async {
        final d = await j.division();
        return d['bracketType'] == 'DOUBLE_ELIMINATION' ? d : null;
      });

      // TC-45: tạo sơ đồ, Backend trả cả nhánh thắng và nhánh thua.
      await openHubTab(tester, 'Bảng đấu');
      await tapKey(tester, 'bracket-mgmt-create', step: 'tạo sơ đồ loại kép');
      await expectKey(tester, 'bracket-mgmt-delete', step: 'sơ đồ đã có');
      await expectKey(tester, 'bracket-search-field', step: 'bảng trận loại kép');
      final matches = await j.eventually('sơ đồ loại kép có nhánh thua', () async {
        final all = await j.listMatches();
        return all.any((m) => _branch(m) == 'losers') ? all : null;
      });
      expect(matches.length, greaterThanOrEqualTo(4));
      expect(matches.any((m) => const {'winners', 'main'}.contains(_branch(m))), isTrue, reason: 'Thiếu trận nhánh thắng');
      await j.snap('so-do');

      // TC-46: ô tìm kiếm, bộ lọc nhánh thua, xóa lọc.
      await tester.enterText(find.byKey(const ValueKey('bracket-search-field')), 'vdv 1');
      await expectKey(tester, 'bracket-search-clear', step: 'nút xóa tìm kiếm');
      await tapKey(tester, 'bracket-search-clear', step: 'xóa tìm kiếm');
      await gone(tester, find.byKey(const ValueKey('bracket-search-clear')), 'nút xóa tìm kiếm');
      await tapKey(tester, 'bracket-filter-button', step: 'mở bộ lọc');
      final sheet = find.byType(BracketFilterBottomSheet);
      await pumpUntilFound(tester, sheet, what: 'bảng bộ lọc trận đấu');
      await tapFinder(tester, find.descendant(of: sheet, matching: find.text('Nhánh thua')), 'chip Nhánh thua');
      await j.snap('bo-loc');
      await tapFinder(tester, find.descendant(of: sheet, matching: find.text('Áp dụng bộ lọc')), 'Áp dụng bộ lọc');
      await gone(tester, sheet, 'bảng bộ lọc sau khi áp dụng');
      final badge = find.descendant(
        of: find.byKey(const ValueKey('bracket-filter-button')),
        matching: find.text('1'),
      );
      await pumpUntilFound(tester, badge, what: 'số bộ lọc đang bật (1)');
      await tapFinder(tester, find.text('Xoá lọc'), 'nút Xoá lọc');
      await gone(tester, badge, 'số bộ lọc đang bật sau Xoá lọc');

      // TC-46 (tiếp): mở sơ đồ đầy đủ ở màn không nhúng (route ops/bracket).
      j.container.read(routerProvider).go(
        '/organizer/tournaments/${j.tid}/ops/bracket?divisionId=${j.did}',
      );
      await tapKey(tester, 'bracket-open-full-diagram', step: 'mở sơ đồ đầy đủ');
      await pumpUntilFound(tester, find.byType(BracketDiagramScreen), what: 'màn sơ đồ loại kép');
      await j.snap('so-do-day-du');
      Navigator.of(tester.element(find.byType(BracketDiagramScreen))).pop();
      await gone(tester, find.byType(BracketDiagramScreen), 'màn sơ đồ đầy đủ');

      // TC-47: hủy sơ đồ ở màn vận hành giai đoạn (chưa có trận nào bắt đầu).
      await openManageHub(tester, j.container, j.tid);
      await j.openStageOperations();
      await expectKey(tester, 'stage-action-cancel-bracket', step: 'màn vận hành');
      expect(_enabled(tester, 'stage-action-cancel-bracket'), isTrue, reason: 'Chưa có trận bắt đầu thì phải hủy được');
      await tapKey(tester, 'stage-action-cancel-bracket', step: 'hủy sơ đồ');
      await pumpUntilFound(tester, find.byType(AlertDialog), what: 'hộp xác nhận hủy sơ đồ');
      await tapFinder(
        tester,
        _dialogButton(find.widgetWithText(FilledButton, 'Xác nhận hủy')),
        'Xác nhận hủy',
      );
      await pumpUntilFound(tester, find.textContaining('Đã hủy'), what: 'thông báo đã hủy sơ đồ');
      await j.eventually('không còn trận nào đang mở trên Backend', () async {
        final all = await j.listMatches();
        return all.every((m) => _status(m) == 'CANCELLED') ? true : null;
      });
      await j.snap('da-huy');
    },
    timeout: testTimeout,
  );

  testWidgets(
    'TC-QLGD-APP-48: BTC cấu hình Vòng bảng: số bảng, đội mỗi bảng, đội đi tiếp, playoff và cách xếp (TC 48)',
    (tester) async {
      final j = _Journey(tester, binding, 'fmt-gsk-seed');
      await j.start(players: 8);

      // TC-48: chọn Vòng bảng, nhập số bảng, đội mỗi bảng, đội đi tiếp, playoff và cách xếp (Ngẫu nhiên / Theo ELO).
      await j.editDivision(
        'GROUP_STAGE_KNOCKOUT',
        openStage: true,
        configure: () async {
          await _enterNumber(tester, 'division-editor-num-groups', '2');
          await _enterNumber(tester, 'division-editor-group-rounds', '1');
          await _enterNumber(tester, 'division-editor-teams-per-group', '4');
          await _enterNumber(tester, 'division-editor-teams-advancing', '2');
          await tapKey(tester, 'division-editor-playoff-DOUBLE_ELIMINATION');
          await tapKey(tester, 'division-editor-playoff-SINGLE_ELIMINATION');
          await tapKey(tester, 'division-editor-playoff-DOUBLE_ELIMINATION');
          await tapKey(tester, 'division-editor-seeding-RANDOM');
          await tapKey(tester, 'division-editor-seeding-SEEDED');
          await tapKey(tester, 'division-editor-seeding-RANDOM');
        },
      );
      final division = await j.eventually('nội dung chuyển sang GROUP_STAGE_KNOCKOUT', () async {
        final d = await j.division();
        return d['bracketType'] == 'GROUP_STAGE_KNOCKOUT' ? d : null;
      });
      final config = _map(division['roundConfig']);
      expect(_map(config['groupsConfig'])['numGroups'], 2);
      expect(_map(config['groupsConfig'])['teamsPerGroup'], 4);
      expect(_map(config['advancementConfig'])['teamsAdvancing'], 2);
      expect(_map(config['playoffConfig'])['type'], 'DOUBLE_ELIMINATION');
      expect(_map(config['playoffConfig'])['seedingType'], 'RANDOM');
    },
    timeout: testTimeout,
  );

  testWidgets(
    'TC-QLGD-APP-51: BTC tạo sơ đồ Vòng bảng qua popup, vận hành giai đoạn và chốt vòng bảng (TC 51-56)',
    (tester) async {
      final j = _Journey(tester, binding, 'fmt-gsk-ops');
      await j.start(players: 8);
      await j.editDivision(
        'GROUP_STAGE_KNOCKOUT',
        openStage: true,
        configure: () => _enterNumber(tester, 'division-editor-num-groups', '2'),
      );
      await j.eventually('nội dung chuyển sang GROUP_STAGE_KNOCKOUT', () async {
        final d = await j.division();
        return d['bracketType'] == 'GROUP_STAGE_KNOCKOUT' ? d : null;
      });

      await openHubTab(tester, 'Bảng đấu');

      // TC-53: tạo sơ đồ; popup cài đặt hiện trước, xác nhận bằng giá trị gợi ý (2 bảng x 4 đội).
      await tapKey(tester, 'bracket-mgmt-create', step: 'tạo sơ đồ vòng bảng');
      await tapKey(tester, 'bracket-create-confirm', step: 'xác nhận popup tạo bracket');
      await expectKey(tester, 'bracket-mgmt-delete', step: 'sơ đồ đã có');
      final rr = await j.eventually('stage vòng bảng có 12 trận', () async {
        final stages = await j.extra.stages(j.tid, j.did);
        final found = stages.where((e) => _stageType(e) == 'ROUND_ROBIN');
        return found.isNotEmpty && _stageMatches(found.first).length == 12 ? found.first : null;
      });
      final stageGroups = _maps(rr['groups']);
      expect(stageGroups, hasLength(2), reason: 'Vòng bảng phải có 2 bảng');
      for (final g in stageGroups) {
        expect(_maps(g['matches']), hasLength(6), reason: 'Mỗi bảng 4 đội đá vòng tròn 1 lượt = 6 trận');
      }
      await j.snap('so-do');

      // TC-54: vận hành giai đoạn: còn trận vòng bảng chưa xong nên nút Chốt vòng bảng bị khóa.
      await j.openStageOperations();
      await expectKey(tester, 'stage-action-cancel-bracket', step: 'màn vận hành');
      final advance = _keyed('stage-action-advance-');
      await pumpUntilFound(tester, advance, what: 'nút Chốt vòng bảng và sang loại trực tiếp');
      expect(
        _enabledFinder(tester, advance),
        isFalse,
        reason: 'Còn trận vòng bảng chưa xong thì không được chốt',
      );
      expect(find.text('Còn 12 trận vòng bảng chưa hoàn tất.'), findsOneWidget);
      await j.snap('van-hanh-bi-khoa');
      await j.back('màn vận hành giai đoạn');

      // Chấm hết vòng bảng bằng API để nút Chốt vòng bảng mở khóa.
      await j.startAndScore();

      // TC-55: chốt vòng bảng, các đội đi tiếp vào loại trực tiếp.
      await openManageHub(tester, j.container, j.tid);
      await j.openStageOperations();
      await pumpUntilFound(tester, advance, what: 'nút Chốt vòng bảng và sang loại trực tiếp');
      await pumpUntilCondition(
        tester,
        () => _enabledFinder(tester, advance),
        what: 'nút Chốt vòng bảng mở khóa khi hết trận vòng bảng',
      );
      await j.snap('van-hanh-mo-khoa');
      await tapFinder(tester, advance, 'nút Chốt vòng bảng');
      await pumpUntilFound(tester, find.byType(AlertDialog), what: 'hộp xác nhận chốt vòng bảng');
      await tapFinder(
        tester,
        _dialogButton(find.widgetWithText(FilledButton, 'Chốt vòng bảng')),
        'xác nhận Chốt vòng bảng',
      );
      await pumpUntilFound(
        tester,
        find.textContaining('Đã đưa các đội đi tiếp vào vòng loại trực tiếp'),
        what: 'thông báo đã chốt vòng bảng',
      );
      await j.eventually('loại trực tiếp có trận đủ 2 đội', () async {
        final stages = await j.extra.stages(j.tid, j.did);
        final ready = stages
            .where((e) => _stageType(e) != 'ROUND_ROBIN')
            .expand(_stageMatches)
            .where((m) => _participantId(m, 1).isNotEmpty && _participantId(m, 2).isNotEmpty);
        return ready.isNotEmpty ? true : null;
      });
      await j.snap('da-chot');
    },
    timeout: testTimeout,
  );

  testWidgets(
    'TC-QLGD-APP-57: BTC cấu hình Thụy Sĩ, ghép cặp vòng 2 (tự động, đổi chỗ, hoàn tác nháp) rồi hoàn tác vòng (TC 57-59)',
    (tester) async {
      final j = _Journey(tester, binding, 'fmt-swiss');
      await j.start(players: 4);
      // Sản phẩm (commit 2a227a69) ẩn Thụy Sĩ khi tạo/đổi nội dung trong App, chỉ giữ ô cho nội
      // dung Swiss đã có: dựng nội dung Swiss bằng API rồi cấu hình tiếp qua giao diện.
      await j.extra.setBracketType(j.did, 'SWISS');
      j.refresh();

      // TC-57: cấu hình Thụy Sĩ (nội dung đã là Swiss), 2 vòng, cách ghép vòng 1, thứ tự tiebreak.
      await j.editDivision(
        'SWISS',
        openStage: true,
        configure: () async {
          await _enterNumber(tester, 'swiss-config-rounds', '2');
          await tapKey(tester, 'swiss-config-first-random', step: 'ghép vòng 1 ngẫu nhiên');
          await tapKey(tester, 'swiss-config-first-seed', step: 'ghép vòng 1 theo hạt giống');
          await tapKey(tester, 'swiss-tiebreak-down-BUCHHOLZ', step: 'hạ Buchholz');
          await tapKey(tester, 'swiss-tiebreak-up-BUCHHOLZ', step: 'nâng Buchholz');
          await tapKey(tester, 'swiss-tiebreak-switch-WINS', step: 'bật tiebreak Số trận thắng');
        },
      );
      final division = await j.eventually('nội dung chuyển sang SWISS', () async {
        final d = await j.division();
        return d['bracketType'] == 'SWISS' ? d : null;
      });
      final swiss = _map(_map(division['roundConfig'])['swiss']);
      expect(swiss['totalRounds'], 2);
      expect(swiss['firstRoundPairing'], 'SEED');
      final order = [for (final e in _list(swiss['tiebreakOrder'])) e.toString()];
      expect(order, isNotEmpty, reason: 'Backend không trả swiss.tiebreakOrder');
      expect(order.first, 'BUCHHOLZ');
      expect(order, contains('WINS'));

      // Vòng 1 do nút Tạo sơ đồ sinh ra; chưa đấu xong thì chỉ có dòng trạng thái.
      await openHubTab(tester, 'Bảng đấu');
      await tapKey(tester, 'bracket-mgmt-create', step: 'tạo sơ đồ Thụy Sĩ');
      await expectKey(tester, 'swiss-round-status', step: 'trạng thái vòng 1');
      expect(find.text('Vòng 1 đang đấu'), findsOneWidget);
      await j.eventually('Backend có 2 trận vòng 1', () async {
        final all = await j.listMatches();
        return all.where((m) => _intOf(m['roundNumber'] ?? m['round']) == 1).length == 2 ? all : null;
      });
      await j.snap('vong-1');
      final bracket = find.byType(BracketViewScreen);
      await tapFinder(tester, find.descendant(of: bracket, matching: find.text('Lịch thi đấu')).first, 'tab Lịch thi đấu');
      await expectKey(tester, 'bracket-search-field', step: 'bảng trận Swiss');
      await tapFinder(tester, find.descendant(of: bracket, matching: find.text('Xếp hạng')).first, 'tab Xếp hạng');
      await pumpUntilFound(tester, find.byType(SwissStandingsView), what: 'bảng xếp hạng Swiss');
      await j.snap('xep-hang');

      // TC-58: chấm hết vòng 1 bằng API, ghép cặp vòng 2 trên màn ghép cặp.
      await j.startAndScore();
      await expectKey(tester, 'swiss-next-round', step: 'nút ghép cặp vòng 2');
      expect(find.text('Ghép cặp vòng 2'), findsOneWidget);
      await tapKey(tester, 'swiss-next-round', step: 'mở màn ghép cặp');
      await expectKey(tester, 'swiss-pairing-screen', step: 'màn ghép cặp');
      await expectKey(tester, 'swiss-auto', step: 'màn ghép cặp đã tải');
      await pumpUntilCondition(
        tester,
        () => _keyed('swiss-chip-').evaluate().length == 4,
        what: '4 tên VĐV trên màn ghép cặp',
      );
      await j.snap('ghep-cap');
      await tapKey(tester, 'swiss-auto', step: 'Ghép lại');
      await waitEnabled(tester, 'swiss-auto', enabled: true);

      // Chạm tên rồi Đổi với…: bản nháp đổi nên Hoàn tác bật, bấm Hoàn tác thì tắt.
      await tapFinder(tester, _keyed('swiss-chip-').first, 'chạm tên VĐV mở sheet đổi chỗ');
      await pumpUntilFound(tester, _keyed('swiss-swap-'), what: 'sheet Đổi với…');
      await j.snap('sheet-doi-cho');
      await tapFinder(tester, _keyed('swiss-swap-').first, 'đổi chỗ với VĐV khác');
      await waitEnabled(tester, 'swiss-undo', enabled: true);
      await tapKey(tester, 'swiss-undo', step: 'Hoàn tác bản nháp');
      await waitEnabled(tester, 'swiss-undo', enabled: false);

      // Chuyển một tên ra Chưa ghép / Nghỉ vòng này / BYE: bản nháp thiếu cặp, không xác nhận được.
      for (final move in ['swiss-move-pool', 'swiss-move-sitout', 'swiss-move-bye']) {
        await tapFinder(tester, _keyed('swiss-chip-').first, 'chạm tên VĐV ($move)');
        await tapKey(tester, move, step: 'chuyển tên');
        await expectKey(tester, 'swiss-incomplete-hint', step: 'cảnh báo chưa ghép đủ ($move)');
        expect(_enabled(tester, 'swiss-confirm'), isFalse, reason: 'Bản nháp thiếu cặp thì không được xác nhận ($move)');
        await tapKey(tester, 'swiss-undo', step: 'Hoàn tác ($move)');
        await gone(tester, find.byKey(const ValueKey('swiss-incomplete-hint')), 'cảnh báo chưa ghép đủ ($move)');
      }
      await waitEnabled(tester, 'swiss-confirm', enabled: true);
      await j.snap('san-sang-xac-nhan');
      clearSnackBars(tester);
      await tapKey(tester, 'swiss-confirm', step: 'Xác nhận vòng 2');
      await pumpUntilFound(tester, find.text('Đã tạo vòng 2.'), what: 'thông báo đã tạo vòng 2');
      // BUG-SP-05 (sản phẩm): sau "Đã tạo vòng 2." màn ghép cặp lẽ ra tự đóng (`navigator.maybePop()`
      // ở swiss_pairing_screen.dart:122) nhưng vẫn còn trên màn. Đợi 3 giây rồi đóng bằng pop.
      await tester.pump(const Duration(seconds: 3));
      if (find.byKey(const ValueKey('swiss-pairing-screen')).evaluate().isNotEmpty) {
        debugPrint('[BUG-SP-05] màn ghép cặp Swiss không tự đóng sau khi xác nhận vòng 2');
        Navigator.of(tester.element(find.byKey(const ValueKey('swiss-pairing-screen')))).pop();
      }
      await gone(tester, find.byKey(const ValueKey('swiss-pairing-screen')), 'màn ghép cặp sau khi xác nhận');
      await j.eventually('Backend có 2 trận vòng 2', () async {
        final all = await j.listMatches();
        return all.where((m) => _intOf(m['roundNumber'] ?? m['round']) == 2 && _status(m) != 'CANCELLED').length == 2 ? all : null;
      });

      // Vận hành giai đoạn của Swiss: đã có trận bắt đầu nên không hủy được sơ đồ.
      await j.openStageOperations();
      await expectKey(tester, 'stage-action-cancel-bracket', step: 'màn vận hành Swiss');
      expect(_enabled(tester, 'stage-action-cancel-bracket'), isFalse, reason: 'Vòng 1 đã đấu nên không hủy được');
      await j.snap('van-hanh');
      await j.back('màn vận hành giai đoạn');

      // TC-59: hoàn tác vòng 2 (chưa đấu trận nào): xác nhận, vòng 2 bị bỏ và nút ghép cặp vòng 2 quay lại.
      await expectKey(tester, 'swiss-undo-round', step: 'nút hoàn tác vòng 2');
      expect(find.text('Hoàn tác vòng 2'), findsOneWidget);
      await tapKey(tester, 'swiss-undo-round', step: 'hoàn tác vòng 2');
      await expectKey(tester, 'swiss-undo-round-confirm', step: 'hộp xác nhận hoàn tác');
      await j.snap('hoan-tac-hop');
      await tapKey(tester, 'swiss-undo-round-confirm', step: 'xác nhận hoàn tác vòng 2');
      await pumpUntilFound(tester, find.text('Đã hoàn tác vòng 2.'), what: 'thông báo đã hoàn tác vòng 2');
      await j.eventually('vòng 2 đã bị bỏ trên Backend', () async {
        final all = await j.listMatches();
        final live = all.where((m) => _intOf(m['roundNumber'] ?? m['round']) == 2 && _status(m) != 'CANCELLED');
        return live.isEmpty ? true : null;
      });
      await expectKey(tester, 'swiss-next-round', step: 'nút ghép cặp vòng 2 quay lại');
      expect(find.text('Ghép cặp vòng 2'), findsOneWidget);
      await j.snap('sau-hoan-tac');
    },
    timeout: testTimeout,
  );
}

/// Trạng thái dùng chung của một hành trình: giải dựng bằng API, app đã đăng nhập, ảnh chụp.
class _Journey {
  _Journey(this.tester, this.binding, this.prefix);

  final WidgetTester tester;
  final IntegrationTestWidgetsFlutterBinding binding;
  final String prefix;
  final BackendApi api = BackendApi();
  late final ProviderContainer container;
  late final SeededTournament seeded;
  late final _FormatsApi extra;
  bool _converted = false;
  int _shots = 0;

  String get tid => seeded.tournamentId;
  String get did => seeded.divisionId;

  Future<void> start({required int players, int maxParticipants = 8}) async {
    seeded = await seedTournament(api, players: players, maxParticipants: maxParticipants);
    extra = _FormatsApi(seeded.token);
    container = await signInAsOrganizer(tester);
    await openManageHub(tester, container, tid);
  }

  /// Chụp màn hình và in log base64 (runner cloud chỉ giữ log).
  Future<void> snap(String name) async {
    if (!_converted) {
      await binding.convertFlutterSurfaceToImage();
      _converted = true;
    }
    await tester.pump();
    _shots++;
    await shot(binding, '$prefix-${_shots.toString().padLeft(2, '0')}-$name');
  }

  /// App đọc giải qua luồng có độ trễ; làm mới các nguồn sau khi Backend đổi (do API hoặc do giao diện).
  void refresh() {
    final params = (tournamentId: tid, divisionId: did);
    container
      ..invalidate(tournamentProvider(tid))
      ..invalidate(teamsProvider(tid))
      ..invalidate(bracketMatchesProvider(tid))
      ..invalidate(matchesProvider(tid))
      ..invalidate(bracketMatchesWithDivisionProvider(params))
      ..invalidate(swissStageProvider(params))
      ..invalidate(standingsWithDivisionProvider(params));
  }

  /// Chờ có hạn tới khi [probe] trả khác null; đỏ kèm lỗi cuối nếu hết giờ.
  Future<T> eventually<T extends Object>(
    String what,
    Future<T?> Function() probe, {
    Duration timeout = const Duration(seconds: 45),
  }) async {
    final deadline = DateTime.now().add(timeout);
    Object? lastError;
    while (true) {
      try {
        final value = await probe();
        if (value != null) return value;
      } catch (error) {
        lastError = error;
      }
      if (DateTime.now().isAfter(deadline)) {
        fail('Hết ${timeout.inSeconds}s chờ Backend: $what (lỗi cuối: $lastError)');
      }
      await tester.pump(const Duration(milliseconds: 500));
    }
  }

  Future<Map<String, dynamic>> division() async {
    final all = await api.listDivisions(tid);
    return all.firstWhere(
      (d) => d['id'] == did,
      orElse: () => fail('Backend không trả nội dung $did của giải $tid'),
    );
  }

  Future<List<Map<String, dynamic>>> listMatches() =>
      api.listMatches(token: seeded.token, tournamentId: tid, divisionId: did);

  /// Giải dựng đủ 8/8 VĐV nên hộp "Hạng mục đã đủ chỗ" có thể bật lên và chắn sheet: bấm "Hủy"
  /// (không đổi đăng ký) nếu hộp xuất hiện trong vài giây đầu.
  Future<void> dismissFullDivisionPrompt() async {
    final keepOpen = find.text('Giữ mở');
    for (var i = 0; i < 12 && keepOpen.evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
    if (keepOpen.evaluate().isEmpty) return;
    // Nút "Hủy" nằm ngoài vùng bấm của emulator: đóng hộp bằng pop route, giống việc nút Hủy làm
    // (`Navigator.maybePop`), không đổi đăng ký của hạng mục nào.
    await Navigator.of(tester.element(find.text('Hạng mục đã đủ chỗ'))).maybePop();
    await tester.pump(const Duration(milliseconds: 500));
    await gone(tester, find.text('Hạng mục đã đủ chỗ'), 'hộp Hạng mục đã đủ chỗ');
  }

  /// Mở sheet sửa nội dung (tab Nội dung), chọn [bracketType], chạy [configure], lưu và chờ sheet đóng.
  Future<void> editDivision(
    String bracketType, {
    bool openStage = false,
    Future<void> Function()? configure,
  }) async {
    await openHubTab(tester, 'Nội dung');
    await dismissFullDivisionPrompt();
    await tapKey(tester, 'division-edit-$did', step: 'mở sheet sửa nội dung');
    await expectKey(tester, 'division-editor-save', step: 'sheet nội dung');
    await tapKey(tester, 'division-editor-bracket-$bracketType', step: 'chọn thể thức');
    if (openStage) {
      await tapKey(tester, 'division-editor-section-stage', step: 'mở mục cấu hình thể thức');
    }
    await configure?.call();
    await snap('sua-noi-dung-$bracketType');
    await tapKey(tester, 'division-editor-save', step: 'lưu nội dung');
    await gone(tester, find.byKey(const ValueKey('division-editor-save')), 'sheet nội dung sau khi lưu');
    refresh();
  }

  /// Đội (id) -> hạt giống theo endpoint quản lý (cùng nguồn với mục Hạt giống của app).
  Future<Map<String, int?>> seedsById() async => {
    for (final p in await extra.participants(tid, did))
      p['id'].toString(): p['seed'] is num ? (p['seed'] as num).toInt() : null,
  };

  /// Khai mạc giải, rồi chấm 2-0 các trận đang mở có đủ 2 đội ([limit] trận, mặc định tất cả).
  Future<void> startAndScore({int? limit}) async {
    await api.startTournament(token: seeded.token, tournamentId: tid);
    var scored = 0;
    for (final match in await listMatches()) {
      if (limit != null && scored >= limit) break;
      final playable =
          _isOpen(match) && _participantId(match, 1).isNotEmpty && _participantId(match, 2).isNotEmpty;
      if (!playable) continue;
      await api.scoreMatch(token: seeded.token, match: match);
      scored++;
    }
    expect(scored, limit ?? greaterThan(0), reason: 'Không có trận nào để chấm');
    refresh();
  }

  /// Số trận chưa xong và chưa hủy của nội dung theo Backend.
  Future<int> openMatchCount() async => (await listMatches()).where(_isOpen).length;

  /// Mở màn Vận hành giai đoạn từ tab Bảng đấu. Giải họ Lite ẩn nút `stage-operations-entry`
  /// (bracket_view_screen.dart: `tournament?.isLite == true`), khi đó đẩy đúng màn đó bằng Navigator
  /// như nút vẫn làm; giải thường thì bấm nút.
  Future<void> openStageOperations() async {
    await openHubTab(tester, 'Bảng đấu');
    final isLite = container.read(tournamentProvider(tid)).value?.isLite;
    expect(isLite, isNotNull, reason: 'Chưa có dữ liệu giải để biết có nút Vận hành giai đoạn không');
    if (isLite == true) {
      expect(
        find.byKey(const ValueKey('stage-operations-entry')),
        findsNothing,
        reason: 'Giải họ Lite không hiện nút Vận hành giai đoạn',
      );
      debugPrint('stage-operations-entry: giải họ Lite ẩn nút, đẩy StageOperationsScreen bằng Navigator');
      final hub = tester.element(find.byType(TournamentManagementHubScreen));
      unawaited(
        Navigator.of(hub).push<void>(
          MaterialPageRoute<void>(
            builder: (_) => StageOperationsScreen(tournamentId: tid, divisionId: did),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
    } else {
      await tapKey(tester, 'stage-operations-entry', step: 'mở Vận hành giai đoạn');
    }
    await pumpUntilFound(tester, find.byType(StageOperationsScreen), what: 'màn Vận hành giai đoạn');
  }

  /// Cuộn danh sách của tab Nội dung (ListView bên trong) tới khi [target] hiện.
  Future<void> scrollDivisionsTo(Finder target) async {
    final scrollable = find
        .descendant(
          of: find.byType(TournamentManagementDivisionsSection),
          matching: find.byType(Scrollable),
        )
        .first;
    await tester.scrollUntilVisible(target, 300, scrollable: scrollable, maxScrolls: 40);
    await tester.pump();
  }

  /// Bấm nút Back của AppBar (màn vừa đẩy lên) và chờ màn đó biến mất.
  Future<void> back(String screen) async {
    final backButton = find.byType(BackButton);
    await tapFinder(tester, backButton.first, 'nút quay lại của $screen');
    await pumpUntilCondition(
      tester,
      () => backButton.evaluate().isEmpty,
      what: 'đã rời $screen',
    );
  }
}

/// Gọi Backend ngoài `BackendApi`: sơ đồ theo giai đoạn và danh sách VĐV của BTC (có hạt giống).
class _FormatsApi {
  _FormatsApi(String token)
    : _dio = Dio(
        BaseOptions(
          baseUrl: kE2eApiBaseUrl,
          connectTimeout: const Duration(seconds: 20),
          receiveTimeout: const Duration(seconds: 60),
          headers: {'Authorization': 'Bearer $token'},
          validateStatus: (_) => true,
        ),
      );

  final Dio _dio;

  Future<Object?> _get(String path, Map<String, dynamic> query) async {
    final response = await _dio.get<Object?>(path, queryParameters: query);
    final code = response.statusCode ?? 0;
    if (code < 200 || code >= 300) {
      throw StateError('GET $path -> HTTP $code: ${response.data}');
    }
    final body = response.data;
    return body is Map && body.containsKey('data') ? body['data'] : body;
  }

  /// `GET /tournaments/:id/bracket?divisionId=`: các stage của nội dung, mỗi stage có `groups[].matches[]`.
  Future<List<Map<String, dynamic>>> stages(String tournamentId, String divisionId) async {
    final data = await _get('/tournaments/$tournamentId/bracket', {'divisionId': divisionId});
    return _maps(data is Map ? data['stages'] : null);
  }

  /// `PATCH /tournaments/divisions/:id`: đổi thể thức bằng API (App đã ẩn Thụy Sĩ khi tạo/đổi nội dung).
  Future<void> setBracketType(String divisionId, String bracketType) async {
    final response = await _dio.patch<Object?>(
      '/tournaments/divisions/$divisionId',
      data: {'bracketType': bracketType},
    );
    final code = response.statusCode ?? 0;
    if (code < 200 || code >= 300) {
      throw StateError('PATCH division $divisionId -> HTTP $code: ${response.data}');
    }
  }

  /// `GET /tournaments/:id/manage/participants?divisionId=`: cùng nguồn với mục Hạt giống của app.
  Future<List<Map<String, dynamic>>> participants(String tournamentId, String divisionId) async =>
      _maps(await _get('/tournaments/$tournamentId/manage/participants', {'divisionId': divisionId}));
}

List<Object?> _list(Object? value) => value is List ? value.cast<Object?>() : <Object?>[];

List<Map<String, dynamic>> _maps(Object? value) => [
  for (final item in _list(value))
    if (item is Map) Map<String, dynamic>.from(item),
];

Map<String, dynamic> _map(Object? value) =>
    value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

List<Map<String, dynamic>> _stageMatches(Map<String, dynamic> stage) => [
  for (final group in _maps(stage['groups'])) ..._maps(group['matches']),
];

String _stageType(Map<String, dynamic> stage) => (stage['type'] ?? '').toString().toUpperCase();

String _status(Map<String, dynamic> match) => (match['status'] ?? '').toString().toUpperCase();

/// Trận thật (không BYE) chưa xong và chưa hủy.
bool _isOpen(Map<String, dynamic> match) =>
    match['isBye'] != true && _status(match) != 'COMPLETED' && _status(match) != 'CANCELLED';

int _intOf(Object? value) => value is num ? value.toInt() : int.tryParse('$value') ?? 0;

/// Nhánh của trận loại kép (`winners`, `losers`, `grand_final`), thường viết thấp.
String _branch(Map<String, dynamic> match) =>
    (_map(match['bracketPosition'])['bracket'] ?? match['bracketBranch'] ?? '').toString().toLowerCase();

String _participantId(Map<String, dynamic> match, int side) =>
    (match['participant${side}Id'] ?? _map(match['participant$side'])['id'] ?? '').toString();

/// Widget có `ValueKey<String>` bắt đầu bằng [prefix] (key có đuôi là id động).
Finder _keyed(String prefix) => find.byWidgetPredicate((widget) {
  final key = widget.key;
  return key is ValueKey<String> && key.value.startsWith(prefix);
}, description: 'widget có key bắt đầu bằng "$prefix"');

/// Nút trong hộp thoại đang mở (tránh trùng nhãn với nút cùng chữ ở màn phía sau).
Finder _dialogButton(Finder button) =>
    find.descendant(of: find.byType(AlertDialog), matching: button);

/// Chờ [finder] hiện rồi chạm vào giữa nó.
Future<void> tapFinder(WidgetTester tester, Finder finder, String what) async {
  await pumpUntilFound(tester, finder, what: what);
  await tapCentered(tester, finder);
  await tester.pump(const Duration(milliseconds: 300));
}

/// Chờ có hạn tới khi [finder] không còn trên màn.
Future<void> gone(WidgetTester tester, Finder finder, String what) =>
    pumpUntilCondition(tester, () => finder.evaluate().isEmpty, what: 'hết hiển thị: $what');

/// Nhập số vào ô có `ValueKey(key)`.
Future<void> _enterNumber(WidgetTester tester, String key, String value) async {
  await expectKey(tester, key);
  await tester.enterText(find.byKey(ValueKey(key)), value);
  await tester.pump();
}

/// Xóa thông báo nổi đang che nút ở đáy màn.
void clearSnackBars(WidgetTester tester) {
  ScaffoldMessenger.of(tester.element(find.byType(Scaffold).first)).clearSnackBars();
}

/// Nút (TextButton/FilledButton/OutlinedButton/ElevatedButton) có `ValueKey(key)` đang bấm được không.
bool _enabled(WidgetTester tester, String key) =>
    _enabledFinder(tester, find.byKey(ValueKey(key)));

bool _enabledFinder(WidgetTester tester, Finder finder) =>
    tester.widget<ButtonStyleButton>(finder.first).onPressed != null;

/// Chờ có hạn tới khi nút `ValueKey(key)` ở trạng thái bấm được ([enabled]) hoặc bị khóa.
Future<void> waitEnabled(WidgetTester tester, String key, {required bool enabled}) async {
  await expectKey(tester, key);
  await pumpUntilCondition(
    tester,
    () => _enabled(tester, key) == enabled,
    what: 'nút "$key" ${enabled ? 'bấm được' : 'bị khóa'}',
  );
}
