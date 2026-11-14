import 'package:app_quanly_giaidau/core/router/app_router.dart';
import 'package:app_quanly_giaidau/core/widgets/province_picker.dart';
import 'package:app_quanly_giaidau/domain/entities/ranking.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/actors.dart';
import 'support/app_driver.dart';
import 'support/backend_api.dart';
import 'support/social_journey.dart';

/// Chuỗi G (task 2.7): khám phá và xem. TC-MULTI-G-01..15.
/// Khách (chưa đăng nhập), VĐV và BTC cùng xem dữ liệu công khai: tìm và lọc giải, địa điểm, trang giải
/// (loại trực tiếp, vòng tròn, vòng bảng), xem lại trận đã xong, bảng xếp hạng seed, hồ sơ VĐV và ELO,
/// rồi phân quyền âm. Giải dựng bằng API (BTC `admin1`, ADMIN duyệt); xếp hạng lấy từ dữ liệu seed trên cloud.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(initializeAppForTests);

  const testTimeout = Timeout(Duration(minutes: 6));

  testWidgets(
    'TC-MULTI-G-01 khách tìm giải theo tên: ra đúng giải cần tìm, không lẫn giải khác',
    (tester) async {
      _tolerateOverflow();
      final a = await _tourA;
      final d = await _tourD;
      final shooter = SocialShooter(tester, binding, 'TC-MULTI-G-01');
      final container = await _asGuest(tester);
      await _openTournamentSearch(tester, container);
      await shooter.snap('o-tim-kiem-giai');

      await _typeQuery(tester, a.tag);
      await _until(tester, _result(a.tag));
      expect(
        _result(d.tag),
        findsNothing,
        reason: 'Tìm "${a.tag}" không được ra giải ${d.tag}',
      );
      await shooter.snap('tim-theo-ten-giai-a');

      await _typeQuery(tester, d.tag);
      await _until(tester, _result(d.tag));
      expect(
        _result(a.tag),
        findsNothing,
        reason: 'Tìm "${d.tag}" không được ra giải ${a.tag}',
      );
      await shooter.snap('tim-theo-ten-giai-d');
      await leaveSocialSession(tester, container);
    },
    timeout: testTimeout,
  );

  testWidgets(
    'TC-MULTI-G-02 khách lọc giải theo trạng thái: Hoàn thành chỉ ra giải đã kết thúc, Đăng ký chỉ ra giải mở đăng ký',
    (tester) async {
      _tolerateOverflow();
      final a = await _tourA;
      final d = await _tourD;
      final shooter = SocialShooter(tester, binding, 'TC-MULTI-G-02');
      final container = await _asGuest(tester);
      await _openTournamentSearch(tester, container);
      await _typeQuery(tester, _base);
      await _until(tester, _result(_base));

      await _applyFilter(tester, status: 'Hoàn thành');
      await _until(tester, _result(a.tag));
      expect(
        _result(d.tag),
        findsNothing,
        reason: 'Lọc Hoàn thành không được ra giải đang đăng ký',
      );
      await shooter.snap('loc-hoan-thanh');

      await _applyFilter(tester, status: 'Đăng ký');
      await _until(tester, _result(d.tag));
      expect(
        _result(a.tag),
        findsNothing,
        reason: 'Lọc Đăng ký không được ra giải đã hoàn thành',
      );
      await shooter.snap('loc-dang-ky');
      await leaveSocialSession(tester, container);
    },
    timeout: testTimeout,
  );

  testWidgets(
    'TC-MULTI-G-03 khách lọc giải theo môn: đúng môn thì thấy giải, môn khác thì rỗng',
    (tester) async {
      _tolerateOverflow();
      final a = await _tourA;
      final sports = await _publicApi.categoryNames();
      final other = sports.where((s) => s.slug != 'pickleball').toList();
      expect(
        sports.any((s) => s.slug == 'pickleball'),
        isTrue,
        reason: 'Cloud phải có môn pickleball: $sports',
      );
      expect(
        other,
        isNotEmpty,
        reason: 'Cần ít nhất một môn khác pickleball để kiểm lọc rỗng',
      );
      final pickle = sports.firstWhere((s) => s.slug == 'pickleball');
      final shooter = SocialShooter(tester, binding, 'TC-MULTI-G-03');
      final container = await _asGuest(tester);
      await _openTournamentSearch(tester, container);
      await _typeQuery(tester, a.tag);
      await _until(tester, _result(a.tag));

      await _applyFilter(tester, sport: pickle.name);
      await _until(tester, _result(a.tag));
      await shooter.snap('loc-dung-mon');

      await _applyFilter(tester, sport: other.first.name);
      await _until(tester, _emptyTournamentResult);
      expect(
        _result(a.tag),
        findsNothing,
        reason: 'Môn ${other.first.name} không được ra giải pickleball',
      );
      await shooter.snap('loc-mon-khac-rong');
      await leaveSocialSession(tester, container);
    },
    timeout: testTimeout,
  );

  testWidgets(
    'TC-MULTI-G-04 khách lọc giải theo tỉnh: giải không có tỉnh bị loại, bỏ lọc thì hiện lại',
    (tester) async {
      _tolerateOverflow();
      final a = await _tourA;
      final province = ProvinceData.all.first.name;
      final shooter = SocialShooter(tester, binding, 'TC-MULTI-G-04');
      final container = await _asGuest(tester);
      await _openTournamentSearch(tester, container);
      await _typeQuery(tester, a.tag);
      await _until(tester, _result(a.tag));

      await _applyFilter(tester, province: province);
      await _until(tester, _emptyTournamentResult);
      expect(
        _result(a.tag),
        findsNothing,
        reason: 'Giải dựng bằng API không có tỉnh, lọc $province phải loại nó',
      );
      await shooter.snap('loc-tinh-rong');

      await _applyFilter(tester, clear: true);
      await _until(tester, _result(a.tag));
      await shooter.snap('bo-loc-hien-lai');
      await leaveSocialSession(tester, container);
    },
    timeout: testTimeout,
  );

  testWidgets(
    'TC-MULTI-G-05 khách mở tìm địa điểm: có ghi chú nguồn dữ liệu, truy vấn lạ ra màn rỗng, không báo lỗi tải',
    (tester) async {
      _tolerateOverflow();
      final a = await _tourA;
      final shooter = SocialShooter(tester, binding, 'TC-MULTI-G-05');
      final container = await _asGuest(tester);
      await _openTournamentSearch(tester, container);
      final venueChip = find.widgetWithText(ChoiceChip, 'Địa điểm');
      // Hàng chip phạm vi cuộn ngang: cuộn tới chip Địa điểm rồi mới bấm.
      await tester.scrollUntilVisible(
        venueChip,
        120,
        scrollable: find
            .ancestor(
              of: find.widgetWithText(ChoiceChip, 'Kèo'),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.tap(venueChip);
      await tester.pump();
      await _until(
        tester,
        find.textContaining('Địa điểm được tổng hợp từ các trận đấu công khai'),
      );
      await shooter.snap('pham-vi-dia-diem');

      await _typeQuery(tester, a.tag);
      await _until(tester, find.text('Không tìm thấy kết quả phù hợp'));
      expect(
        find.text('Không thể tải kết quả. Vui lòng thử lại.'),
        findsNothing,
      );
      await shooter.snap('dia-diem-rong');
      await leaveSocialSession(tester, container);
    },
    timeout: testTimeout,
  );

  testWidgets(
    'TC-MULTI-G-06 khách mở trang giải đã kết thúc: đủ 6 tab công khai và nhà vô địch trên bục',
    (tester) async {
      _tolerateOverflow();
      final a = await _tourA;
      final shooter = SocialShooter(tester, binding, 'TC-MULTI-G-06');
      final container = await _asGuest(tester);
      container.read(routerProvider).go('/tournament/${a.id}');
      for (final label in [
        'Tổng quan',
        'Giới thiệu',
        'Danh sách đội',
        'Bảng đấu',
        'Lịch thi đấu',
        'Kết quả',
      ]) {
        await _until(
          tester,
          find.text(label),
          timeout: const Duration(seconds: 45),
        );
        expect(
          find.text(label),
          findsWidgets,
          reason: 'Khách phải thấy tab "$label"',
        );
      }
      await shooter.snap('du-tab-cong-khai');
      expect(
        find.byTooltip('QUẢN LÝ'),
        findsNothing,
        reason: 'Khách không được thấy nút quản lý giải',
      );

      await tapCentered(tester, find.text('Kết quả').first);
      final podium = find.byKey(const ValueKey('results-podium-null'));
      await _until(tester, podium);
      await _until(
        tester,
        find.descendant(of: podium, matching: find.text(a.champion)),
      );
      await shooter.snap('nha-vo-dich');
      await leaveSocialSession(tester, container);
    },
    timeout: testTimeout,
  );

  testWidgets(
    'TC-MULTI-G-07 khách xem bracket loại trực tiếp: thấy tên VĐV của giải, không báo lỗi tải',
    (tester) async {
      _tolerateOverflow();
      final a = await _tourA;
      final shooter = SocialShooter(tester, binding, 'TC-MULTI-G-07');
      final container = await _asGuest(tester);
      await _openTournamentTab(tester, container, a.id, 'Bảng đấu');
      await _until(tester, find.textContaining('${a.tag} VDV'));
      _expectBracketLoaded();
      await shooter.snap('bracket-loai-truc-tiep');
      await leaveSocialSession(tester, container);
    },
    timeout: testTimeout,
  );

  testWidgets(
    'TC-MULTI-G-08 khách xem giải vòng tròn đang đấu: bảng có đủ tên VĐV, tab Kết quả hiện vì giải đã thi đấu',
    (tester) async {
      _tolerateOverflow();
      final b = await _tourB;
      final shooter = SocialShooter(tester, binding, 'TC-MULTI-G-08');
      final container = await _asGuest(tester);
      await _openTournamentTab(tester, container, b.id, 'Bảng đấu');
      await _until(tester, find.textContaining('${b.tag} VDV'));
      _expectBracketLoaded();
      await shooter.snap('bang-vong-tron');

      expect(
        find.text('Kết quả'),
        findsWidgets,
        reason: 'Giải đang thi đấu phải có tab Kết quả cho khách',
      );
      await tapCentered(tester, find.text('Kết quả').first);
      await _until(
        tester,
        find.byKey(ValueKey('results-row-${b.scoredMatchId}')),
      );
      await shooter.snap('vong-tron-ket-qua');
      await leaveSocialSession(tester, container);
    },
    timeout: testTimeout,
  );

  testWidgets(
    'TC-MULTI-G-09 khách xem giải vòng bảng: sơ đồ có tên VĐV, không báo lỗi tải',
    (tester) async {
      _tolerateOverflow();
      final c = await _tourC;
      final shooter = SocialShooter(tester, binding, 'TC-MULTI-G-09');
      final container = await _asGuest(tester);
      await _openTournamentTab(tester, container, c.id, 'Bảng đấu');
      await _until(tester, find.textContaining('${c.tag} VDV'));
      _expectBracketLoaded();
      await shooter.snap('vong-bang');
      await leaveSocialSession(tester, container);
    },
    timeout: testTimeout,
  );

  testWidgets(
    'TC-MULTI-G-10 khách xem lại trận đã xong: lọc "Đã xong" và tìm theo tên thì ra trận chung kết',
    (tester) async {
      _tolerateOverflow();
      final a = await _tourA;
      final shooter = SocialShooter(tester, binding, 'TC-MULTI-G-10');
      final container = await _asGuest(tester);
      await _openTournamentTab(tester, container, a.id, 'Kết quả');
      await _until(tester, find.byKey(const ValueKey('results-podium-null')));
      await shooter.snap('bang-ket-qua');

      await tapFinder(
        tester,
        find.textContaining('Đã xong'),
        what: 'chip lọc Đã xong',
      );
      await tester.enterText(
        find.byKey(const ValueKey('results-search')),
        a.tag,
      );
      await tester.pump();
      await _until(
        tester,
        find.byKey(ValueKey('results-row-${a.finalMatchId}')),
      );
      expect(
        find.descendant(
          of: find.byKey(ValueKey('results-row-${a.finalMatchId}')),
          matching: find.textContaining(a.tag),
        ),
        findsWidgets,
        reason: 'Dòng trận chung kết phải ghi tên VĐV của giải',
      );
      await shooter.snap('xem-lai-tran-chung-ket');

      await tester.enterText(
        find.byKey(const ValueKey('results-search')),
        'khong-co-vdv-nay-zzz',
      );
      await tester.pump();
      await socialWait(tester, const Duration(seconds: 2));
      expect(
        find.byKey(ValueKey('results-row-${a.finalMatchId}')),
        findsNothing,
        reason: 'Tìm tên lạ phải ẩn trận chung kết',
      );
      await shooter.snap('tim-ten-la-rong');
      await leaveSocialSession(tester, container);
    },
    timeout: testTimeout,
  );

  testWidgets(
    'TC-MULTI-G-11 khách xem bảng xếp hạng /rankings: khớp dữ liệu API (có VĐV thì hiện tên và ELO, chưa có thì hiện màn rỗng)',
    (tester) async {
      _tolerateOverflow();
      final pickle = (await _publicApi.categoryNames()).firstWhere(
        (s) => s.slug == 'pickleball',
      );
      final ranked = await _publicApi.rankings(pickle.id, 'MALE');
      debugPrint('G-11: bảng pickleball nam trả về ${ranked.length} dòng');
      final shooter = SocialShooter(tester, binding, 'TC-MULTI-G-11');
      final container = await _asGuest(tester);
      container.read(routerProvider).go('/rankings?sport=pickleball');
      await _until(tester, find.text('Đơn'));
      if (ranked.isEmpty) {
        await _until(tester, find.text('Chưa có dữ liệu xếp hạng'));
        expect(
          find.text('Điểm'),
          findsNothing,
          reason: 'Bảng rỗng không có tiêu đề cột Điểm',
        );
      } else {
        await _until(tester, find.text(ranked.first.displayName));
        expect(find.text('${ranked.first.eloPoints}'), findsWidgets);
      }
      expect(find.text('Không thể tải bảng xếp hạng'), findsNothing);
      await shooter.snap('xep-hang-pickleball-nam');

      await tapCentered(tester, find.text('Nữ').first);
      await socialWait(tester, const Duration(seconds: 2));
      await shooter.snap('xep-hang-pickleball-nu');
      await leaveSocialSession(tester, container);
    },
    timeout: testTimeout,
  );

  testWidgets(
    'TC-MULTI-G-12 khách mở hồ sơ VĐV: 3 tab, mục xếp hạng theo môn; VĐV mở lịch sử ELO của mình',
    (tester) async {
      _tolerateOverflow();
      final actors = await _actors;
      final player = actors['player']!;
      final snapshot = await _publicApi.rankingSnapshot();
      expect(
        snapshot.any((row) => row.endsWith(player.userId)),
        isFalse,
        reason: 'VĐV mới tạo chưa đấu trận nào nên chưa có dòng xếp hạng',
      );
      final shooter = SocialShooter(tester, binding, 'TC-MULTI-G-12');
      var container = await _asGuest(tester);
      container.read(routerProvider).go('/user/${player.userId}');
      for (final label in ['Tổng quan', 'Trận đấu', 'Danh hiệu']) {
        await _until(
          tester,
          find.widgetWithText(Tab, label),
          timeout: const Duration(seconds: 45),
        );
      }
      await _until(tester, find.text('Xếp hạng theo bộ môn'));
      expect(
        find.text(player.fullName),
        findsWidgets,
        reason: 'Hồ sơ phải ghi tên ${player.fullName}',
      );
      await _until(tester, find.text('Chưa có dữ liệu xếp hạng'));
      await shooter.snap('ho-so-vdv-khach');

      await tapCentered(tester, find.widgetWithText(Tab, 'Trận đấu'));
      await _until(tester, find.text('Chưa có trận đấu công khai'));
      await shooter.snap('ho-so-vdv-tab-tran');
      await leaveSocialSession(tester, container);

      container = await signInAs(tester, player);
      await _openRoute(
        tester,
        container,
        '/profile/elo',
        find.textContaining('Lịch sử ELO'),
      );
      await _until(
        tester,
        find.text('Chưa có trận xếp hạng đã hoàn thành'),
        timeout: const Duration(seconds: 45),
      );
      await shooter.snap('lich-su-elo-vdv');
      await leaveSocialSession(tester, container);
    },
    timeout: testTimeout,
  );

  testWidgets(
    'TC-MULTI-G-13 khách và VĐV thấy cùng dữ liệu công khai: giải, xếp hạng, bracket và nhà vô địch',
    (tester) async {
      _tolerateOverflow();
      final a = await _tourA;
      final actors = await _actors;
      final player = actors['player']!;

      // Qua API: cùng một giải và cùng các bảng xếp hạng với hoặc không có token.
      final guestTour = await _publicApi.get('/tournaments/${a.id}');
      final playerTour = await _publicApi.get(
        '/tournaments/${a.id}',
        token: player.token,
      );
      expect(guestTour.status, 200, reason: 'Khách đọc giải công khai');
      expect(playerTour.status, 200, reason: 'VĐV đọc giải công khai');
      expect(_dataOf(guestTour.body)['id'], _dataOf(playerTour.body)['id']);
      expect(_dataOf(guestTour.body)['name'], _dataOf(playerTour.body)['name']);
      expect(
        await _publicApi.rankingSnapshot(token: player.token),
        await _publicApi.rankingSnapshot(),
        reason: 'Bảng xếp hạng công khai phải như nhau với khách và VĐV',
      );

      // Qua giao diện: khách rồi VĐV thấy cùng tên VĐV ở bracket và cùng nhà vô địch ở tab Kết quả.
      final shooter = SocialShooter(tester, binding, 'TC-MULTI-G-13');
      var container = await _asGuest(tester);
      await _openTournamentTab(tester, container, a.id, 'Bảng đấu');
      await _until(tester, find.textContaining('${a.tag} VDV'));
      final guestNames = _visibleNames(a.tag);
      await shooter.snap('khach-thay-bracket');
      await _openTournamentTab(tester, container, a.id, 'Kết quả');
      await _until(
        tester,
        find.descendant(
          of: find.byKey(const ValueKey('results-podium-null')),
          matching: find.text(a.champion),
        ),
      );
      await leaveSocialSession(tester, container);

      container = await signInAs(tester, player);
      await _openTournamentTab(tester, container, a.id, 'Bảng đấu');
      await _until(tester, find.textContaining('${a.tag} VDV'));
      expect(
        _visibleNames(a.tag),
        guestNames,
        reason: 'VĐV phải thấy đúng các tên VĐV mà khách thấy ở bracket',
      );
      await shooter.snap('vdv-thay-bracket');
      await _openTournamentTab(tester, container, a.id, 'Kết quả');
      await _until(
        tester,
        find.descendant(
          of: find.byKey(const ValueKey('results-podium-null')),
          matching: find.text(a.champion),
        ),
      );
      await shooter.snap('vdv-thay-vo-dich');
      await leaveSocialSession(tester, container);
    },
    timeout: testTimeout,
  );

  testWidgets(
    'TC-MULTI-G-14 phân quyền âm: khách và VĐV không thấy tab Kết quả hay nút quản lý của giải chưa thi đấu, BTC thấy; khách bị chặn khỏi màn quản lý',
    (tester) async {
      _tolerateOverflow();
      final d = await _tourD;
      final actors = await _actors;
      final shooter = SocialShooter(tester, binding, 'TC-MULTI-G-14');
      final scheduleTab = find.text('Lịch thi đấu');

      var container = await _asGuest(tester);
      await _openRoute(tester, container, '/tournament/${d.id}', scheduleTab);
      expect(
        find.text('Kết quả'),
        findsNothing,
        reason: 'Khách không được thấy tab Kết quả của giải chưa có trận',
      );
      expect(
        find.byTooltip('QUẢN LÝ'),
        findsNothing,
        reason: 'Khách không được thấy nút quản lý',
      );
      await shooter.snap('khach-khong-thay-ket-qua-quan-ly');
      await expectBlocked(tester, '/organizer/tournaments/${d.id}/manage');
      await expectBlocked(tester, '/admin');
      await shooter.snap('khach-bi-chan-man-quan-ly');
      await leaveSocialSession(tester, container);

      container = await signInAs(tester, actors['player']!);
      await _openRoute(tester, container, '/tournament/${d.id}', scheduleTab);
      await socialWait(tester, const Duration(seconds: 3));
      expect(
        find.text('Kết quả'),
        findsNothing,
        reason:
            'VĐV không phải BTC không được thấy tab Kết quả của giải chưa có trận',
      );
      expect(
        find.byTooltip('QUẢN LÝ'),
        findsNothing,
        reason: 'VĐV không phải BTC không được thấy nút quản lý',
      );
      await shooter.snap('vdv-khong-thay-ket-qua-quan-ly');
      await leaveSocialSession(tester, container);

      // Đối chứng: BTC của giải thấy cả hai.
      container = await signInAs(tester, actors['organizer']!);
      await _openRoute(tester, container, '/tournament/${d.id}', scheduleTab);
      await _until(
        tester,
        find.byTooltip('QUẢN LÝ'),
        timeout: const Duration(seconds: 45),
      );
      await _until(tester, find.text('Kết quả'));
      await shooter.snap('btc-thay-ket-qua-quan-ly');
      await leaveSocialSession(tester, container);
    },
    timeout: testTimeout,
  );

  testWidgets(
    'TC-MULTI-G-15 phân quyền âm: VĐV không phải BTC mở màn quản lý giải thì bị chặn, API sửa giải bị từ chối',
    (tester) async {
      _tolerateOverflow();
      final d = await _tourD;
      final actors = await _actors;
      final shooter = SocialShooter(tester, binding, 'TC-MULTI-G-15');
      final container = await signInAs(tester, actors['player']!);
      // Chờ app ổn định ở trang giải (đăng nhập xong còn điều hướng về /home) rồi mới thử vào màn quản lý.
      await _openRoute(
        tester,
        container,
        '/tournament/${d.id}',
        find.text('Lịch thi đấu'),
      );
      await expectBlocked(tester, '/organizer/tournaments/${d.id}/manage');
      await shooter.snap('vdv-bi-chan-man-quan-ly');
      expect(
        await _publicApi.statusOf(
          'PATCH',
          '/tournaments/${d.id}',
          token: actors['player']!.token,
          data: {'name': '${d.tag} bi-sua'},
        ),
        anyOf(401, 403),
        reason: 'API sửa giải của VĐV không phải BTC phải bị từ chối',
      );
      await leaveSocialSession(tester, container);
    },
    timeout: testTimeout,
  );
}

// ---------------------------------------------------------------------------
// Dữ liệu dùng chung (dựng lười, mỗi giải một Future nên lỗi dựng chỉ làm đỏ ca dùng nó)
// ---------------------------------------------------------------------------

final BackendApi _api = BackendApi();
final _PublicApi _publicApi = _PublicApi();

/// Tiền tố chung của mọi giải trong file; mỗi giải thêm một chữ cái (A..D) để tìm riêng từng giải.
final String _base = 'E2E${DateTime.now().millisecondsSinceEpoch}G';

final Future<Map<String, E2eActor>> _actors = createActors(
  _api,
  chain: 'G',
  roles: const ['organizer', 'player', 'viewer'],
);

/// A: loại trực tiếp, đã chấm hết và kết thúc (COMPLETED).
final Future<_Tour> _tourA = _buildTour('A', 'Loại trực tiếp', (t) async {
  await _api.generateBracket(
    token: t.token,
    tournamentId: t.id,
    divisionId: t.divisionId,
  );
  await _api.startTournament(token: t.token, tournamentId: t.id);
  final champion = await _api.playOutSingleElimination(
    token: t.token,
    tournamentId: t.id,
    divisionId: t.divisionId,
  );
  final matches = await _api.listMatches(
    token: t.token,
    tournamentId: t.id,
    divisionId: t.divisionId,
  );
  final finals = matches
      .where((m) => m['status'] == 'COMPLETED' && m['nextMatchId'] == null)
      .toList();
  await _api.completeTournament(token: t.token, tournamentId: t.id);
  return t.copyWith(
    champion: champion,
    finalMatchId: finals.first['id'] as String,
  );
});

/// B: vòng tròn 4 VĐV, đã khai mạc và chấm một trận.
final Future<_Tour> _tourB = _buildTour('B', 'Vòng tròn', (t) async {
  await _publicApi.patchDivision(t.token, t.divisionId, {
    'bracketType': 'ROUND_ROBIN',
  });
  await _api.generateBracket(
    token: t.token,
    tournamentId: t.id,
    divisionId: t.divisionId,
  );
  await _api.startTournament(token: t.token, tournamentId: t.id);
  final matches = await _api.listMatches(
    token: t.token,
    tournamentId: t.id,
    divisionId: t.divisionId,
  );
  final playable = matches.firstWhere(
    (m) =>
        m['isBye'] != true &&
        m['participant1Id'] is String &&
        m['participant2Id'] is String,
  );
  await _api.scoreMatch(token: t.token, match: playable);
  return t.copyWith(scoredMatchId: playable['id'] as String);
});

/// C: vòng bảng (2 bảng x 4 đội) + playoff, mới tạo sơ đồ.
final Future<_Tour> _tourC = _buildTour('C', 'Vòng bảng', (t) async {
  await _publicApi.patchDivision(t.token, t.divisionId, {
    'bracketType': 'GROUP_STAGE_KNOCKOUT',
    'roundConfig': {
      'groupsConfig': {'numGroups': 2, 'teamsPerGroup': 4, 'roundsToPlay': 1},
      'advancementConfig': {'teamsAdvancing': 2},
      'playoffConfig': {'type': 'SINGLE_ELIMINATION', 'seedingType': 'RANDOM'},
    },
  });
  await _api.generateBracket(
    token: t.token,
    tournamentId: t.id,
    divisionId: t.divisionId,
  );
  return t;
}, players: 8);

/// D: mở đăng ký, có VĐV, chưa tạo sơ đồ.
final Future<_Tour> _tourD = _buildTour('D', 'Đăng ký', (t) async => t);

class _Tour {
  const _Tour({
    required this.token,
    required this.id,
    required this.divisionId,
    required this.tag,
    this.champion = '',
    this.finalMatchId = '',
    this.scoredMatchId = '',
  });

  final String token;
  final String id;
  final String divisionId;
  final String tag;
  final String champion;
  final String finalMatchId;
  final String scoredMatchId;

  _Tour copyWith({
    String? champion,
    String? finalMatchId,
    String? scoredMatchId,
  }) => _Tour(
    token: token,
    id: id,
    divisionId: divisionId,
    tag: tag,
    champion: champion ?? this.champion,
    finalMatchId: finalMatchId ?? this.finalMatchId,
    scoredMatchId: scoredMatchId ?? this.scoredMatchId,
  );
}

Future<_Tour> _buildTour(
  String suffix,
  String label,
  Future<_Tour> Function(_Tour) prepare, {
  int players = 4,
}) async {
  final tag = '$_base$suffix';
  final token = await _api.login(kOrganizerEmail, kE2ePassword);
  final created = await _api.createLiteTournament(
    token: token,
    name: '$tag $label',
    matchType: 'SINGLES',
    maxParticipants: 8,
  );
  await _api.approveTournamentAsAdmin(created.tournamentId);
  await _api.importRoster(
    token: token,
    tournamentId: created.tournamentId,
    divisionId: created.divisionId,
    tag: tag,
    count: players,
    singles: true,
  );
  return prepare(
    _Tour(
      token: token,
      id: created.tournamentId,
      divisionId: created.divisionId,
      tag: tag,
    ),
  );
}

class _Sport {
  const _Sport(this.slug, this.name, this.id);

  final String slug;
  final String name;
  final String id;

  @override
  String toString() => '$slug/$name';
}

class _Reply {
  const _Reply(this.status, this.body);

  final int status;
  final Object? body;
}

/// Gọi API công khai bằng Dio riêng (không ném lỗi theo mã HTTP), dùng cho phần BackendApi chưa có.
class _PublicApi {
  _PublicApi()
    : _dio = Dio(
        BaseOptions(
          baseUrl: kE2eApiBaseUrl,
          connectTimeout: const Duration(seconds: 20),
          receiveTimeout: const Duration(seconds: 60),
          contentType: Headers.jsonContentType,
          validateStatus: (_) => true,
        ),
      );

  final Dio _dio;

  Future<_Reply> get(
    String path, {
    String? token,
    Map<String, dynamic>? query,
  }) async {
    final response = await _dio.get<Object?>(
      path,
      queryParameters: query,
      options: Options(
        headers: token == null ? null : {'Authorization': 'Bearer $token'},
      ),
    );
    return _Reply(response.statusCode ?? 0, response.data);
  }

  Future<int> statusOf(
    String method,
    String path, {
    String? token,
    Object? data,
  }) async {
    final response = await _dio.request<Object?>(
      path,
      data: data,
      options: Options(
        method: method,
        headers: token == null ? null : {'Authorization': 'Bearer $token'},
      ),
    );
    return response.statusCode ?? 0;
  }

  /// `PATCH /tournaments/divisions/:id` (BTC): đổi thể thức và cấu hình nội dung.
  Future<void> patchDivision(
    String token,
    String divisionId,
    Map<String, Object?> body,
  ) async {
    final code = await statusOf(
      'PATCH',
      '/tournaments/divisions/$divisionId',
      token: token,
      data: body,
    );
    if (code < 200 || code >= 300) {
      throw StateError(
        'PATCH /tournaments/divisions/$divisionId -> HTTP $code (body: $body)',
      );
    }
  }

  Future<List<_Sport>> categoryNames() async {
    final reply = await get('/categories');
    expect(reply.status, 200, reason: 'GET /categories');
    return [
      for (final item in _listOf(_unwrapBody(reply.body)))
        _Sport(
          '${item['slug']}'.toLowerCase(),
          '${item['name']}',
          '${item['id']}',
        ),
    ];
  }

  /// `GET /rankings` công khai như màn Xếp hạng gọi (không gửi matchType khi rỗng).
  Future<List<PlayerRanking>> rankings(
    String categoryId,
    String gender, {
    String matchType = '',
    String? token,
  }) async {
    final reply = await get(
      '/rankings',
      token: token,
      query: {
        'scope': 'PUBLIC',
        'limit': 100,
        'categoryId': categoryId,
        'genderRestriction': gender,
        if (matchType.isNotEmpty) 'matchType': matchType,
      },
    );
    expect(
      reply.status,
      200,
      reason: 'GET /rankings (categoryId=$categoryId, gender=$gender)',
    );
    return [
      for (final item in _listOf(_unwrapBody(reply.body)))
        PlayerRanking.fromJson(item),
    ];
  }

  /// Mọi dòng xếp hạng công khai theo từng môn và giới (chuỗi `môn:giới:userId`), để so khách với VĐV.
  Future<List<String>> rankingSnapshot({String? token}) async {
    final rows = <String>[];
    for (final sport in await categoryNames()) {
      for (final gender in const ['MALE', 'FEMALE']) {
        for (final r in await rankings(sport.id, gender, token: token)) {
          rows.add('${sport.slug}:$gender:${r.userId}');
        }
      }
    }
    return rows;
  }
}

Object? _unwrapBody(Object? body) =>
    body is Map && body.containsKey('data') ? body['data'] : body;

Map<String, dynamic> _dataOf(Object? body) {
  final data = _unwrapBody(body);
  return data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};
}

List<Map<String, dynamic>> _listOf(Object? value) => value is List
    ? [
        for (final item in value)
          if (item is Map) Map<String, dynamic>.from(item),
      ]
    : <Map<String, dynamic>>[];

// ---------------------------------------------------------------------------
// Thao tác giao diện
// ---------------------------------------------------------------------------

/// Chỉ bỏ qua lỗi tràn layout vài px đã biết ở nhiều màn của sản phẩm, vẫn ghi log; lỗi khác làm ca đỏ.
void _tolerateOverflow() {
  final previous = FlutterError.onError;
  FlutterError.onError = (details) {
    if (details.toString().contains('A RenderFlex overflowed by')) {
      debugPrint(
        '[BUG-OVERFLOW-G] ${details.exceptionAsString().split('\n').first}',
      );
      return;
    }
    previous?.call(details);
  };
  addTearDown(() => FlutterError.onError = previous);
}

/// Dựng app ở trạng thái khách: đăng nhập tài khoản xem rồi đăng xuất (tài khoản của ca trước có thể còn phiên).
Future<ProviderContainer> _asGuest(WidgetTester tester) async {
  final viewer = (await _actors)['viewer']!;
  final container = await signInWithEmail(tester, email: viewer.email);
  await ensureSignedOut(tester, container);
  await socialWait(tester, const Duration(seconds: 2));
  drainKnownProductErrors(tester);
  return container;
}

/// Mở tab Giải đấu của trang chủ rồi mở màn tìm kiếm (phạm vi Giải đấu).
Future<void> _openTournamentSearch(
  WidgetTester tester,
  ProviderContainer container,
) async {
  container.read(routerProvider).go('/home?tab=1');
  final searchButton = find.byTooltip('Tìm kiếm thể thao');
  await _until(tester, searchButton, timeout: const Duration(seconds: 45));
  await tester.tap(searchButton.first);
  await _until(
    tester,
    find.byType(TextField),
    timeout: const Duration(seconds: 30),
  );
  await socialWait(tester, const Duration(milliseconds: 800));
}

Future<void> _typeQuery(WidgetTester tester, String query) async {
  await tester.enterText(find.byType(TextField).first, query);
  await tester.pump();
  // Màn tìm kiếm chờ 350ms rồi mới gọi API.
  await socialWait(tester, const Duration(milliseconds: 1200));
}

final Finder _filterButton = find.byWidgetPredicate(
  (w) => w is Tooltip && (w.message ?? '').startsWith('Bộ lọc nâng cao'),
  description: 'nút Bộ lọc nâng cao',
);

/// Chữ màn rỗng của phạm vi Giải đấu.
final Finder _emptyTournamentResult = find.text(
  'Không tìm thấy kết quả mong muốn?',
);

/// Mở sheet bộ lọc của phạm vi Giải đấu, chọn các mục (hoặc [clear] để xoá hết) rồi bấm Áp dụng.
Future<void> _applyFilter(
  WidgetTester tester, {
  String? sport,
  String? status,
  String? province,
  bool clear = false,
}) async {
  await tapFinder(tester, _filterButton, what: 'nút Bộ lọc nâng cao');
  await _until(tester, find.text('Áp dụng'));
  await socialWait(tester, const Duration(milliseconds: 600));
  final dropdowns = find.byType(DropdownButtonFormField<String>);
  Future<void> pick(int index, String label) async {
    await tester.ensureVisible(dropdowns.at(index));
    await tester.tap(dropdowns.at(index));
    await socialWait(tester, const Duration(milliseconds: 600));
    final item = find.widgetWithText(DropdownMenuItem<String>, label).last;
    expect(
      item,
      findsOneWidget,
      reason: 'Lựa chọn "$label" phải có trong danh sách thả xuống',
    );
    await tester.tap(item);
    await socialWait(tester, const Duration(milliseconds: 600));
  }

  if (clear) await tapText(tester, 'Xóa bộ lọc');
  if (sport != null) await pick(0, sport);
  if (status != null) await pick(1, status);
  if (province != null) await pick(2, province);
  await tester.tap(find.text('Áp dụng'));
  await socialWait(tester, const Duration(seconds: 1));
}

/// Mở trang giải rồi bấm tab [label] (đưa tab vào giữa màn trước khi bấm).
Future<void> _openTournamentTab(
  WidgetTester tester,
  ProviderContainer container,
  String tournamentId,
  String label,
) async {
  await _openRoute(
    tester,
    container,
    '/tournament/$tournamentId',
    find.text(label),
  );
  await tapCentered(tester, find.text(label).first);
  await socialWait(tester, const Duration(seconds: 1));
}

void _expectBracketLoaded() {
  expect(
    find.text('Không thể tải dữ liệu bảng thi đấu.'),
    findsNothing,
    reason: 'Bảng đấu công khai không được báo lỗi tải',
  );
  expect(
    find.text('Chưa có trận đấu nào'),
    findsNothing,
    reason: 'Giải đã tạo sơ đồ không được báo chưa có trận',
  );
}

/// Tập tên (Text) có chứa [tag] đang hiện trên màn.
Set<String> _visibleNames(String tag) => {
  for (final text
      in find
          .textContaining(tag)
          .evaluate()
          .map((e) => e.widget)
          .whereType<Text>())
    if (text.data != null) text.data!,
};

/// Chờ [finder] hiện, chịu được lỗi tạm của finder khi cây widget đang đổi (element đã gỡ).
Future<void> _until(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 30),
}) => pumpUntilCondition(
  tester,
  () {
    try {
      return finder.evaluate().isNotEmpty;
    } catch (_) {
      return false;
    }
  },
  timeout: timeout,
  what: finder.describeMatch(Plurality.zero),
);

/// Chữ (Text) có chứa [tag], không tính nội dung ô nhập tìm kiếm.
Finder _result(String tag) => find.byWidgetPredicate(
  (w) => w is Text && (w.data ?? '').contains(tag),
  description: 'Text chứa "$tag"',
);

/// Vào [route] và chờ [ready] ở lại trên màn: sau đăng nhập app còn điều hướng về /home và đẩy trang đi,
/// nên thấy [ready] mất thì vào lại.
Future<void> _openRoute(
  WidgetTester tester,
  ProviderContainer container,
  String route,
  Finder ready,
) async {
  final deadline = DateTime.now().add(const Duration(seconds: 60));
  while (true) {
    container.read(routerProvider).go(route);
    await socialWait(tester, const Duration(seconds: 2));
    var present = false;
    try {
      present = ready.evaluate().isNotEmpty;
    } catch (_) {}
    if (present) {
      await socialWait(tester, const Duration(seconds: 2));
      try {
        if (ready.evaluate().isNotEmpty) return;
      } catch (_) {}
    }
    if (DateTime.now().isAfter(deadline)) {
      fail(
        'Hết 60s mà $route không ở lại trên màn (${ready.describeMatch(Plurality.zero)})',
      );
    }
  }
}
