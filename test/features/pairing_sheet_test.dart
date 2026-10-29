import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/domain/entities/pairing.dart';
import 'package:app_quanly_giaidau/domain/repositories/tournament_management_repository.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/pairing_sheet.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fake repository: trả danh sách VĐV chờ ghép, ghi lại lần POST
/// pairing/batch và lần POST pairing/generate để khẳng định đúng payload.
class _Repo implements TournamentManagementRepository {
  _Repo(this.candidates);

  final List<PairingCandidate> candidates;
  final batchCalls = <List<PairInput>>[];
  final generateCalls = <({PairingStrategy strategy, String? divisionId})>[];
  PairGenerateResult generateResult = const PairGenerateResult(
    pairedCount: 0,
    unpairedCount: 0,
  );

  @override
  Future<List<PairingCandidate>> getPairingParticipants(String id) async =>
      candidates;

  @override
  Future<void> pairBatch(String id, List<PairInput> pairs) async {
    batchCalls.add(List.of(pairs));
  }

  @override
  Future<PairGenerateResult> pairGenerate(
    String id, {
    required PairingStrategy strategy,
    String? divisionId,
  }) async {
    generateCalls.add((strategy: strategy, divisionId: divisionId));
    return generateResult;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

PairingCandidate _candidate(String id, String name) => PairingCandidate(
  // Người chờ ghép chuẩn của Backend: PENDING_PARTNER, không token, 1 VĐV.
  id: id,
  name: name,
  divisionId: 'div-1',
  teamStatus: 'PENDING_PARTNER',
);

/// Trang chủ có nút mở sheet: sheet chạy trong modal route thật nên đóng
/// được bằng Navigator.pop (pump trực tiếp vào home thì route gốc không pop
/// được).
Widget _app(
  _Repo repo,
  Future<void> Function(BuildContext context) openSheet,
) => ProviderScope(
  overrides: [
    tournamentManagementRepositoryProvider.overrideWith((ref) => repo),
  ],
  child: MaterialApp(
    theme: AppTheme.darkTheme,
    locale: const Locale('vi'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: Builder(
        builder: (context) => Center(
          child: TextButton(
            key: const ValueKey('open-sheet'),
            onPressed: () => openSheet(context),
            child: const Text('Mở sheet'),
          ),
        ),
      ),
    ),
  ),
);

Future<void> _open(WidgetTester tester, Widget app) async {
  await tester.pumpWidget(app);
  await tester.tap(find.byKey(const ValueKey('open-sheet')));
  await tester.pumpAndSettle();
}

FilledButton _submitButton(WidgetTester tester) =>
    tester.widget<FilledButton>(find.byKey(const ValueKey('pairing-submit')));

Future<void> _toggleRow(WidgetTester tester, String id) async {
  await tester.tap(find.byKey(ValueKey('pairing-row-$id')));
  await tester.pump();
}

void main() {
  testWidgets(
    'TC-WP-03-09: ghép thủ công 2 người — tìm không dấu, chọn 2, đặt tên cặp, gửi batch đúng payload rồi tự đóng',
    (tester) async {
      tester.view.physicalSize = const Size(400, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final l10n = await AppLocalizations.delegate.load(const Locale('vi'));
      final repo = _Repo([
        _candidate('p-a', 'Nguyễn A'),
        _candidate('p-b', 'Trần B'),
        _candidate('p-c', 'Lê C'),
      ]);
      await _open(
        tester,
        _app(
          repo,
          (context) => PairingSheet.show(
            context,
            tournamentId: 't1',
            divisionId: 'div-1',
            divisionName: 'Đôi nam',
          ),
        ),
      );

      // Danh sách chờ của hạng mục: đủ 3 VĐV, chưa chọn thì nút gửi khoá.
      expect(find.text('Nguyễn A'), findsOneWidget);
      expect(find.text('Trần B'), findsOneWidget);
      expect(find.text('Lê C'), findsOneWidget);
      expect(_submitButton(tester).enabled, isFalse);

      // Tìm kiếm không dấu: "nguyen a" vẫn khớp "Nguyễn A".
      await tester.enterText(
        find.byKey(const ValueKey('pairing-search')),
        'nguyen a',
      );
      await tester.pumpAndSettle();
      expect(find.text('Nguyễn A'), findsOneWidget);
      expect(find.text('Trần B'), findsNothing);

      // Xoá tìm kiếm rồi chọn 2 người liên tiếp: badge "Đôi 1" cho cả hai.
      await tester.enterText(find.byKey(const ValueKey('pairing-search')), '');
      await tester.pumpAndSettle();
      await _toggleRow(tester, 'p-a');
      await _toggleRow(tester, 'p-b');
      await tester.pumpAndSettle();
      expect(find.text(l10n.pairingPairBadge(1)), findsNWidgets(2));
      expect(find.text(l10n.pairingSubmitPairs(1)), findsOneWidget);
      expect(_submitButton(tester).enabled, isTrue);

      // Đặt tên cặp rồi gửi: một lần POST batch đúng payload, sheet đóng.
      await tester.enterText(
        find.byKey(const ValueKey('pairing-name-p-a|p-b')),
        'Chim Én',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('pairing-submit')));
      await tester.pumpAndSettle();

      expect(repo.batchCalls, hasLength(1));
      expect(repo.batchCalls.single, hasLength(1));
      expect(repo.batchCalls.single.single.participant1Id, 'p-a');
      expect(repo.batchCalls.single.single.participant2Id, 'p-b');
      expect(repo.batchCalls.single.single.teamName, 'Chim Én');
      expect(find.byType(PairingSheet), findsNothing);
    },
  );

  testWidgets(
    'TC-WP-03-09c: danh sách chờ chỉ gồm VĐV PENDING_PARTNER, không giữ link mời và giữ đúng 1 VĐV (filter của Web)',
    (tester) async {
      tester.view.physicalSize = const Size(400, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repo = _Repo([
        // Chờ ghép chuẩn: hiện.
        _candidate('p-ok', 'Nguyễn Chờ'),
        // Đã có cặp: ẩn.
        const PairingCandidate(
          id: 'p-paired',
          name: 'Trần Đã Ghép',
          divisionId: 'div-1',
          teamStatus: 'COMPLETE',
        ),
        // Chờ duyệt: ẩn.
        const PairingCandidate(
          id: 'p-pending',
          name: 'Lê Chờ Duyệt',
          divisionId: 'div-1',
          teamStatus: 'PENDING',
        ),
        // Đang giữ link mời đồng đội: ẩn.
        PairingCandidate(
          id: 'p-invited',
          name: 'Phạm Giữ Link',
          divisionId: 'div-1',
          teamStatus: 'PENDING_PARTNER',
          teamInviteToken: 'invite-token',
        ),
        // PENDING_PARTNER nhưng entry import ghi sẵn VĐV 2: ẩn.
        const PairingCandidate(
          id: 'p-named-pair',
          name: 'Đôi Ghi Sẵn',
          divisionId: 'div-1',
          teamStatus: 'PENDING_PARTNER',
          holdsSingleAthlete: false,
        ),
      ]);
      await _open(
        tester,
        _app(
          repo,
          (context) => PairingSheet.show(
            context,
            tournamentId: 't1',
            divisionId: 'div-1',
            divisionName: 'Đôi nam',
          ),
        ),
      );

      expect(find.text('Nguyễn Chờ'), findsOneWidget);
      expect(find.text('Trần Đã Ghép'), findsNothing);
      expect(find.text('Lê Chờ Duyệt'), findsNothing);
      expect(find.text('Phạm Giữ Link'), findsNothing);
      expect(find.text('Đôi Ghi Sẵn'), findsNothing);
      expect(find.byKey(const ValueKey('pairing-empty')), findsNothing);
    },
  );

  testWidgets(
    'TC-WP-03-10: kéo-thả long-press thả lên người khác để thành cặp, hoàn tác bằng chạm',
    (tester) async {
      tester.view.physicalSize = const Size(400, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final l10n = await AppLocalizations.delegate.load(const Locale('vi'));
      final repo = _Repo([
        _candidate('p-a', 'Nguyễn A'),
        _candidate('p-b', 'Trần B'),
        _candidate('p-c', 'Lê C'),
      ]);
      await _open(
        tester,
        _app(
          repo,
          (context) => PairingSheet.show(
            context,
            tournamentId: 't1',
            divisionId: 'div-1',
            divisionName: 'Đôi nam',
          ),
        ),
      );

      // Long-press "Lê C" rồi thả lên "Nguyễn A": hai người thành Đôi 1.
      final gesture = await tester.startGesture(
        tester.getCenter(find.byKey(const ValueKey('pairing-row-p-c'))),
      );
      await tester.pump(const Duration(milliseconds: 700));
      await gesture.moveTo(
        tester.getCenter(find.byKey(const ValueKey('pairing-row-p-a'))),
      );
      await tester.pump(const Duration(milliseconds: 50));
      await gesture.up();
      await tester.pumpAndSettle();

      expect(find.text(l10n.pairingPairBadge(1)), findsNWidgets(2));
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('pairing-row-p-a')),
          matching: find.text(l10n.pairingPairBadge(1)),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('pairing-row-p-c')),
          matching: find.text(l10n.pairingPairBadge(1)),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('pairing-row-p-b')),
          matching: find.text(l10n.pairingWaitingBadge),
        ),
        findsNothing,
      );

      // Hoàn tác trước khi gửi: chạm một người trong cặp, cả hai rời cặp.
      await _toggleRow(tester, 'p-a');
      await tester.pumpAndSettle();
      expect(find.text(l10n.pairingPairBadge(1)), findsNothing);
      expect(_submitButton(tester).enabled, isFalse);

      // Đổi bạn: bỏ chọn nốt "Lê C" rồi chọn lại đủ 3 theo thứ tự, thả
      // "Lê C" (đang chờ) lên "Trần B" (cùng cặp với A) — cặp cũ tan, thành
      // cặp mới (Trần B + Lê C), Nguyễn A về hàng chờ.
      await _toggleRow(tester, 'p-c');
      await _toggleRow(tester, 'p-a');
      await _toggleRow(tester, 'p-b');
      await _toggleRow(tester, 'p-c');
      await tester.pumpAndSettle();
      expect(find.text(l10n.pairingWaitingBadge), findsOneWidget);

      final swapGesture = await tester.startGesture(
        tester.getCenter(find.byKey(const ValueKey('pairing-row-p-c'))),
      );
      await tester.pump(const Duration(milliseconds: 700));
      await swapGesture.moveTo(
        tester.getCenter(find.byKey(const ValueKey('pairing-row-p-b'))),
      );
      await tester.pump(const Duration(milliseconds: 50));
      await swapGesture.up();
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byKey(const ValueKey('pairing-row-p-b')),
          matching: find.text(l10n.pairingPairBadge(1)),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('pairing-row-p-c')),
          matching: find.text(l10n.pairingPairBadge(1)),
        ),
        findsOneWidget,
      );
      // Nguyễn A rời danh sách chọn (không badge nào trên dòng của A).
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('pairing-row-p-a')),
          matching: find.text(l10n.pairingPairBadge(1)),
        ),
        findsNothing,
      );
      expect(find.text(l10n.pairingSubmitPairs(1)), findsOneWidget);
      expect(repo.batchCalls, isEmpty);
    },
  );

  testWidgets(
    'TC-WP-03-11: tối đa 24 VĐV mỗi lần ghép — chọn VĐV thứ 25 bị từ chối và thông báo',
    (tester) async {
      tester.view.physicalSize = const Size(400, 2800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final l10n = await AppLocalizations.delegate.load(const Locale('vi'));
      final repo = _Repo([
        for (var i = 1; i <= 26; i++)
          _candidate('p-${i.toString().padLeft(2, '0')}', 'VĐV $i'),
      ]);
      await _open(
        tester,
        _app(
          repo,
          (context) => PairingSheet.show(
            context,
            tournamentId: 't1',
            divisionId: 'div-1',
            divisionName: 'Đôi nam',
          ),
        ),
      );

      // Chọn 24 VĐV đầu: 12 cặp.
      for (var i = 1; i <= 24; i++) {
        await _toggleRow(tester, 'p-${i.toString().padLeft(2, '0')}');
      }
      await tester.pumpAndSettle();
      expect(find.text(l10n.pairingSubmitPairs(12)), findsOneWidget);
      expect(_submitButton(tester).enabled, isTrue);

      // VĐV thứ 25: bị từ chối chọn, có thông báo giới hạn; payload không đổi.
      await _toggleRow(tester, 'p-25');
      await tester.pump();
      expect(find.text(l10n.pairingSelectionLimit), findsOneWidget);
      expect(find.text(l10n.pairingSubmitPairs(12)), findsOneWidget);

      // Đường kéo cũng chặn giới hạn như Web (`next.length > MAX`): đã đủ 24
      // người chọn rồi kéo 2 VĐV CHƯA chọn thả lên nhau (p-25 → p-26) sẽ ra
      // 26 người > 24 — phải bị bỏ qua, danh sách chọn giữ nguyên.
      final dragGesture = await tester.startGesture(
        tester.getCenter(find.byKey(const ValueKey('pairing-row-p-25'))),
      );
      await tester.pump(const Duration(milliseconds: 700));
      await dragGesture.moveTo(
        tester.getCenter(find.byKey(const ValueKey('pairing-row-p-26'))),
      );
      await tester.pump(const Duration(milliseconds: 50));
      await dragGesture.up();
      await tester.pumpAndSettle();
      // Danh sách chọn giữ nguyên: submit vẫn 12 cặp, cặp cuối p-23+p-24
      // (khẳng định bên dưới qua payload — snackbar giới hạn cũ vẫn còn treo
      // nên không assert theo text).
      expect(find.text(l10n.pairingSubmitPairs(12)), findsOneWidget);

      // Vẫn gửi được batch 12 cặp theo thứ tự đã chọn.
      await tester.tap(find.byKey(const ValueKey('pairing-submit')));
      await tester.pumpAndSettle();
      expect(repo.batchCalls, hasLength(1));
      expect(repo.batchCalls.single, hasLength(12));
      expect(repo.batchCalls.single.first.participant1Id, 'p-01');
      expect(repo.batchCalls.single.first.participant2Id, 'p-02');
      expect(repo.batchCalls.single.last.participant1Id, 'p-23');
      expect(repo.batchCalls.single.last.participant2Id, 'p-24');
    },
  );

  testWidgets(
    'TC-WP-03-12: ghép tự động — 3 chiến lược, mặc định RANDOM, đổi ELO_BALANCED, 0 cặp là thông báo giữ sheet, thành công báo số cặp và đóng',
    (tester) async {
      tester.view.physicalSize = const Size(400, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final l10n = await AppLocalizations.delegate.load(const Locale('vi'));
      final repo = _Repo([
        for (var i = 1; i <= 5; i++) _candidate('p-$i', 'VĐV $i'),
      ]);
      await _open(
        tester,
        _app(
          repo,
          (context) => PairingSheet.show(
            context,
            tournamentId: 't1',
            divisionId: 'div-1',
            divisionName: 'Đôi nam',
          ),
        ),
      );

      // Chuyển tab tự động: đủ 3 chiến lược với mô tả như Web.
      await tester.tap(find.byKey(const ValueKey('pairing-tab-auto')));
      await tester.pumpAndSettle();
      expect(find.text(l10n.pairingStrategyRandomLabel), findsOneWidget);
      expect(find.text(l10n.pairingStrategyEloBalancedLabel), findsOneWidget);
      expect(find.text(l10n.pairingStrategySameLevelLabel), findsOneWidget);

      // Mặc định RANDOM: chạy ra 0 cặp thì chỉ là thông báo, sheet giữ nguyên
      // để thử chiến lược khác (Web: 'none' không phải lỗi).
      await tester.tap(find.byKey(const ValueKey('pairing-generate')));
      await tester.pumpAndSettle();
      expect(repo.generateCalls.single.strategy, PairingStrategy.random);
      expect(repo.generateCalls.single.divisionId, 'div-1');
      expect(find.text(l10n.pairingNoPairsFormed), findsOneWidget);
      expect(find.byType(PairingSheet), findsOneWidget);

      // Đổi sang "Cân bằng mạnh–yếu" và chạy lại: báo số cặp + số chờ, đóng.
      repo.generateResult = const PairGenerateResult(
        pairedCount: 2,
        unpairedCount: 1,
      );
      await tester.tap(
        find.byKey(const ValueKey('pairing-strategy-eloBalanced')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('pairing-generate')));
      await tester.pumpAndSettle();

      expect(repo.generateCalls, hasLength(2));
      expect(repo.generateCalls.last.strategy, PairingStrategy.eloBalanced);
      expect(find.text(l10n.pairingSuccessWithUnpaired(2, 1)), findsOneWidget);
      expect(find.byType(PairingSheet), findsNothing);
    },
  );

  testWidgets(
    'TC-WP-03-10b: xáo trộn Fisher-Yates giữ nguyên số người chọn, xoá tên cặp đã đặt',
    (tester) async {
      tester.view.physicalSize = const Size(400, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final l10n = await AppLocalizations.delegate.load(const Locale('vi'));
      final repo = _Repo([
        _candidate('p-a', 'Nguyễn A'),
        _candidate('p-b', 'Trần B'),
        _candidate('p-c', 'Lê C'),
        _candidate('p-d', 'Phạm D'),
      ]);
      await _open(
        tester,
        _app(
          repo,
          (context) => PairingSheet.show(
            context,
            tournamentId: 't1',
            divisionId: 'div-1',
            divisionName: 'Đôi nam',
          ),
        ),
      );

      await _toggleRow(tester, 'p-a');
      await _toggleRow(tester, 'p-b');
      await _toggleRow(tester, 'p-c');
      await _toggleRow(tester, 'p-d');
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('pairing-name-p-a|p-b')),
        'Cặp 1',
      );
      await tester.pumpAndSettle();

      // Chưa đủ 2 người chọn thì nút xáo trộn khoá — đã có 4 người nên bật.
      await tester.tap(find.byKey(const ValueKey('pairing-shuffle')));
      await tester.pumpAndSettle();

      // Vẫn 4 người đã chọn (2 cặp); xáo trộn có thể ra đúng thứ tự cũ
      // (Fisher-Yates) nên khẳng định tên cặp đã xoá qua payload gửi lên:
      // mọi cặp đều không còn teamName.
      expect(find.text(l10n.pairingSubmitPairs(2)), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('pairing-submit')));
      await tester.pumpAndSettle();
      expect(repo.batchCalls, hasLength(1));
      expect(repo.batchCalls.single, hasLength(2));
      expect(
        repo.batchCalls.single.every((pair) => pair.teamName == null),
        isTrue,
      );
    },
  );

  testWidgets('gọn chữ: không mô tả, chân một hàng hai nút, không nút Hủy', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repo = _Repo([for (var i = 1; i <= 3; i++) _candidate('p-$i', 'VĐV $i')]);
    await _open(
      tester,
      _app(
        repo,
        (context) => PairingSheet.show(
          context,
          tournamentId: 't1',
          divisionId: 'div-1',
          divisionName: 'Đôi nam',
        ),
      ),
    );

    expect(find.textContaining('Chọn VĐV theo thứ tự'), findsNothing);
    expect(find.text('Đang chờ ghép'), findsNothing);
    expect(find.text('Hủy'), findsNothing);
    final submit = tester.getCenter(find.byKey(const ValueKey('pairing-submit')));
    final shuffle = tester.getCenter(find.byKey(const ValueKey('pairing-shuffle')));
    expect(shuffle.dy, submit.dy);
    expect(shuffle.dx, lessThan(submit.dx));
    expect(
      tester.getSize(find.byKey(const ValueKey('pairing-submit'))).height,
      greaterThanOrEqualTo(44),
    );
  });

  testWidgets('tab tự động chỉ còn nhãn ngắn, không câu hướng dẫn', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repo = _Repo([for (var i = 1; i <= 3; i++) _candidate('p-$i', 'VĐV $i')]);
    await _open(
      tester,
      _app(
        repo,
        (context) => PairingSheet.show(
          context,
          tournamentId: 't1',
          divisionId: 'div-1',
          divisionName: 'Đôi nam',
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('pairing-tab-auto')));
    await tester.pumpAndSettle();

    expect(find.text('Ngẫu nhiên'), findsOneWidget);
    expect(find.text('Cân bằng'), findsOneWidget);
    expect(find.text('Cùng trình'), findsOneWidget);
    expect(find.text('Chọn cách ghép cho nội dung đang xem.'), findsNothing);
    expect(find.textContaining('Xáo trộn rồi ghép'), findsNothing);
    expect(find.text('Hủy'), findsNothing);
    expect(find.byKey(const ValueKey('pairing-generate')), findsOneWidget);
  });
}
