import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/features/organizer_ops/screens/multi_match_schedule_sheet.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Lần ghi lịch: trận, giờ bắt đầu, thời lượng gửi đi.
typedef _WriteCall = ({
  String matchId,
  DateTime scheduledAt,
  int durationMinutes,
});

/// Trang chủ có nút mở sheet: sheet chạy trong modal route thật nên đóng
/// được bằng Navigator.pop (pump trực tiếp vào home thì route gốc không pop
/// được).
Widget _app(
  DateTime at,
  List<MatchModel> waiting,
  Future<bool> Function(MatchModel, DateTime, int) onWrite,
) => MaterialApp(
  theme: AppTheme.darkTheme,
  locale: const Locale('vi'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(
    body: Builder(
      builder: (context) => Center(
        child: TextButton(
          key: const ValueKey('open-sheet'),
          onPressed: () => MultiMatchScheduleSheet.show(
            context,
            courtName: 'Sân 2',
            at: at,
            waiting: waiting,
            minutesPerSet: 15,
            onWrite: onWrite,
          ),
          child: const Text('Mở sheet'),
        ),
      ),
    ),
  ),
);

/// Trận chờ xếp lịch: không có sân, không có giờ, thời lượng mặc định theo
/// minutesPerSet (15 phút, 1 set).
MatchModel _waitingMatch(
  String id,
  int round,
  String team1,
  String team2, {
  String? matchCode,
}) => MatchModel.fromJson({
  'id': id,
  'tournamentId': 't-1',
  'divisionId': 'd-1',
  'round': round,
  'matchNumber': 1,
  'status': 'SCHEDULED',
  'team1Name': team1,
  'team2Name': team2,
  'matchCode': ?matchCode,
}, id);

Future<void> _open(WidgetTester tester, Widget app) async {
  await tester.pumpWidget(app);
  await tester.tap(find.byKey(const ValueKey('open-sheet')));
  await tester.pumpAndSettle();
}

/// Nhập thời lượng cho một trận rồi tắt bàn phím.
Future<void> _enterDuration(
  WidgetTester tester,
  String matchId,
  String text,
) async {
  await tester.enterText(
    find.byKey(ValueKey('schedule-multi-duration-$matchId')),
    text,
  );
  await tester.pump();
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pump();
}

bool _submitEnabled(WidgetTester tester) =>
    tester
        .widget<FilledButton>(
          find.byKey(const ValueKey('schedule-multi-submit')),
        )
        .onPressed !=
    null;

void main() {
  testWidgets(
    'TC-WP-04-01: xếp 3 trận nối tiếp từ ô 08:00 sân 2, thời lượng 30/45/30 → ghi 08:00, 08:30, 09:15',
    (tester) async {
      tester.view.physicalSize = const Size(420, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final calls = <_WriteCall>[];
      final at = DateTime(2026, 10, 26, 8);
      final waiting = [
        _waitingMatch('m-1', 1, 'Đội A', 'Đội B'),
        _waitingMatch('m-2', 1, 'Đội C', 'Đội D'),
        _waitingMatch('m-3', 2, 'Đội E', 'Đội F'),
      ];
      await _open(
        tester,
        _app(at, waiting, (match, scheduledAt, durationMinutes) async {
          calls.add((
            matchId: match.id,
            scheduledAt: scheduledAt,
            durationMinutes: durationMinutes,
          ));
          return true;
        }),
      );

      // Lọc vòng: có 2 vòng khác nhau mới hiện bộ lọc; chọn "Vòng 1" còn 2 dòng.
      expect(
        find.byKey(const ValueKey('schedule-multi-round-filter')),
        findsOneWidget,
      );
      await tester.tap(
        find.byKey(const ValueKey('schedule-multi-round-filter')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Vòng 1 (2)').last);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('schedule-picker-m-3')), findsNothing);

      // Tìm theo tên đội không dấu: "doi b" khớp "Đội B" của m-1.
      await tester.enterText(
        find.byKey(const ValueKey('schedule-multi-search')),
        'doi b',
      );
      await tester.pump();
      expect(find.byKey(const ValueKey('schedule-picker-m-1')), findsOneWidget);
      expect(find.byKey(const ValueKey('schedule-picker-m-2')), findsNothing);
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();

      // Xoá tìm kiếm và lọc về tất cả, chọn đủ 3 trận theo thứ tự bấm.
      await tester.enterText(
        find.byKey(const ValueKey('schedule-multi-search')),
        '',
      );
      await tester.pump();
      await tester.tap(
        find.byKey(const ValueKey('schedule-multi-round-filter')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tất cả vòng (3)').last);
      await tester.pumpAndSettle();
      for (final id in ['m-1', 'm-2', 'm-3']) {
        await tester.tap(find.byKey(ValueKey('schedule-picker-$id')));
        await tester.pump();
      }

      // Thời lượng từng trận 30/45/30 (mặc định 15 vì trận chưa khai thời lượng).
      await _enterDuration(tester, 'm-1', '30');
      await _enterDuration(tester, 'm-2', '45');
      await _enterDuration(tester, 'm-3', '30');

      // Giờ dự kiến từng trận hiện ngay tại dòng: 08:00, 08:30, 09:15.
      expect(
        find.byKey(const ValueKey('schedule-multi-start-m-1')),
        findsOneWidget,
      );
      expect(find.text('→ 08:00'), findsOneWidget);
      expect(find.text('→ 08:30'), findsOneWidget);
      expect(find.text('→ 09:15'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('schedule-multi-submit')));
      await tester.pumpAndSettle();

      // Ba lần ghi tuần tự đúng dây chuyền; sheet đóng và báo "đã xếp 3/3".
      expect(calls, hasLength(3));
      expect(calls[0].matchId, 'm-1');
      expect(calls[0].scheduledAt, at);
      expect(calls[0].durationMinutes, 30);
      expect(calls[1].matchId, 'm-2');
      expect(calls[1].scheduledAt, at.add(const Duration(minutes: 30)));
      expect(calls[1].durationMinutes, 45);
      expect(calls[2].matchId, 'm-3');
      expect(calls[2].scheduledAt, at.add(const Duration(minutes: 75)));
      expect(calls[2].durationMinutes, 30);
      expect(find.byType(MultiMatchScheduleSheet), findsNothing);
      expect(find.text('Đã xếp 3/3 trận nối tiếp.'), findsOneWidget);
    },
  );

  testWidgets(
    'TC-MC-SHEET-01: mã trận không tách vòng; bộ lọc vẫn gom cả vòng và tìm được theo mã',
    (tester) async {
      tester.view.physicalSize = const Size(420, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final waiting = [
        _waitingMatch('m-1', 1, 'Đội A', 'Đội B', matchCode: 'DNTB-R1-T1'),
        _waitingMatch('m-2', 1, 'Đội C', 'Đội D', matchCode: 'DNTB-R1-T2'),
        _waitingMatch('m-3', 2, 'Đội E', 'Đội F', matchCode: 'DNTB-R2-T1'),
      ];
      await _open(
        tester,
        _app(DateTime(2026, 10, 26, 8), waiting, (_, _, _) async => true),
      );

      await tester.tap(
        find.byKey(const ValueKey('schedule-multi-round-filter')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Vòng 1 (2)'), findsWidgets);
      await tester.tap(find.text('Vòng 1 (2)').last);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('schedule-picker-m-1')), findsOneWidget);
      expect(find.byKey(const ValueKey('schedule-picker-m-2')), findsOneWidget);
      expect(find.byKey(const ValueKey('schedule-picker-m-3')), findsNothing);

      await tester.tap(
        find.byKey(const ValueKey('schedule-multi-round-filter')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tất cả vòng (3)').last);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('schedule-multi-search')),
        '#dntb-r2-t1',
      );
      await tester.pump();
      expect(find.byKey(const ValueKey('schedule-picker-m-3')), findsOneWidget);
      expect(find.byKey(const ValueKey('schedule-picker-m-1')), findsNothing);
    },
  );

  testWidgets(
    'TC-WP-04-02: thời lượng 33 phút báo lỗi tại dòng và chặn xác nhận tới khi sửa',
    (tester) async {
      tester.view.physicalSize = const Size(420, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final calls = <_WriteCall>[];
      final at = DateTime(2026, 10, 26, 8);
      final waiting = [_waitingMatch('m-1', 1, 'Đội A', 'Đội B')];
      await _open(
        tester,
        _app(at, waiting, (match, scheduledAt, durationMinutes) async {
          calls.add((
            matchId: match.id,
            scheduledAt: scheduledAt,
            durationMinutes: durationMinutes,
          ));
          return true;
        }),
      );

      await tester.tap(find.byKey(const ValueKey('schedule-picker-m-1')));
      await tester.pump();
      await _enterDuration(tester, 'm-1', '33');

      // Báo lỗi tại dòng đó và nút xác nhận bị khoá: bấm cũng không ghi.
      expect(
        find.byKey(const ValueKey('schedule-multi-duration-error-m-1')),
        findsOneWidget,
      );
      expect(_submitEnabled(tester), isFalse);
      await tester.tap(find.byKey(const ValueKey('schedule-multi-submit')));
      await tester.pump();
      expect(calls, isEmpty);

      // Sửa lại 35 phút (bội 5 trong 15–240): hết lỗi, xác nhận được.
      await _enterDuration(tester, 'm-1', '35');
      expect(
        find.byKey(const ValueKey('schedule-multi-duration-error-m-1')),
        findsNothing,
      );
      expect(_submitEnabled(tester), isTrue);
      await tester.tap(find.byKey(const ValueKey('schedule-multi-submit')));
      await tester.pumpAndSettle();
      expect(calls, hasLength(1));
      expect(calls.single.durationMinutes, 35);
      expect(calls.single.scheduledAt, at);
    },
  );

  testWidgets(
    'TC-WP-04-03: ghi tuần tự lỗi giữa chừng thì dừng và báo "đã xếp i/N"',
    (tester) async {
      tester.view.physicalSize = const Size(420, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final calls = <String>[];
      var secondMatchAttempts = 0;
      final at = DateTime(2026, 10, 26, 8);
      final waiting = [
        _waitingMatch('m-1', 1, 'Đội A', 'Đội B'),
        _waitingMatch('m-2', 1, 'Đội C', 'Đội D'),
        _waitingMatch('m-3', 1, 'Đội E', 'Đội F'),
      ];
      await _open(
        tester,
        _app(at, waiting, (match, scheduledAt, durationMinutes) async {
          // Lần thử đầu của trận 2 ghi lỗi: dây chuyền dừng ngay, không gọi
          // trận 3. Lần thử sau ghi được như thường.
          if (match.id == 'm-2' && secondMatchAttempts++ == 0) return false;
          calls.add(match.id);
          return true;
        }),
      );

      // Chọn tất cả các dòng đang thấy bằng nút "Chọn tất cả".
      await tester.tap(
        find.byKey(const ValueKey('schedule-multi-toggle-visible')),
      );
      await tester.pump();
      expect(find.text('Xếp 3 trận'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('schedule-multi-submit')));
      await tester.pumpAndSettle();

      // Chỉ trận đầu được ghi; sheet giữ mở với báo "đã xếp 1/3".
      expect(calls, ['m-1']);
      expect(find.byType(MultiMatchScheduleSheet), findsOneWidget);
      expect(
        find.text('Đã xếp 1/3 trận rồi dừng vì có trận chưa xếp được.'),
        findsOneWidget,
      );

      // Ghi lại: cả 3 trận còn chọn được xếp lại theo dây chuyền từ ô 08:00
      // (trận 1 được ghi đè cùng sân cùng giờ, như dây chuyền chạy lại từ đầu).
      await tester.tap(find.byKey(const ValueKey('schedule-multi-submit')));
      await tester.pumpAndSettle();
      expect(calls, ['m-1', 'm-1', 'm-2', 'm-3']);
      expect(find.byType(MultiMatchScheduleSheet), findsNothing);
      expect(find.text('Đã xếp 3/3 trận nối tiếp.'), findsOneWidget);
    },
  );
}
