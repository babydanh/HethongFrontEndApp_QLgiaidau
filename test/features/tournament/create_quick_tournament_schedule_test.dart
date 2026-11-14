import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

import 'create_quick_tournament_harness.dart';

const _start = ValueKey('quick-schedule-start');
const _end = ValueKey('quick-schedule-end');
const _regStart = ValueKey('quick-schedule-reg-start');
const _regEnd = ValueKey('quick-schedule-reg-end');
const _rowHeight = 44.0; // CupertinoPicker itemExtent in the date sheet.

/// Text shown on a schedule field, "dd/MM/yyyy · HH:mm" or the placeholder.
String _shown(WidgetTester tester, Key key) {
  final button = find.byKey(key);
  return tester
      .widget<Text>(
        find.descendant(of: button, matching: find.byType(Text)).first,
      )
      .data!;
}

DateTime _parse(String shown) => DateFormat('dd/MM/yyyy · HH:mm').parse(shown);

Future<void> _open(WidgetTester tester, Key key) async {
  await tester.ensureVisible(find.byKey(key));
  await tester.tap(find.byKey(key));
  await tester.pumpAndSettle();
}

/// Drags the date wheel of the open sheet by [days] (negative = earlier).
Future<void> _scrollDate(WidgetTester tester, int days) async {
  await tester.drag(
    find.byType(CupertinoPicker).first,
    Offset(0, -_rowHeight * days),
  );
  await tester.pumpAndSettle();
}

Future<void> _confirm(WidgetTester tester) async {
  await tester.tap(find.text('Xác nhận'));
  await tester.pumpAndSettle();
}

Future<void> _shiftField(WidgetTester tester, Key key, int days) async {
  await _open(tester, key);
  await _scrollDate(tester, days);
  await _confirm(tester);
}

DateTime _bodyDate(Harness h, String key) =>
    DateTime.parse(h.lastBody[key] as String).toLocal();

void main() {
  setUpAll(setUpEnv);

  group('CreatePublicQuickTournamentScreen thời gian: mặc định', () {
    testWidgets('hiện đủ bốn mốc thời gian, mốc bắt đầu có dấu *', (
      tester,
    ) async {
      await pumpCreateScreen(tester);
      expect(find.text('Thời gian bắt đầu *'), findsOneWidget);
      expect(find.text('Thời gian kết thúc (dự kiến)'), findsOneWidget);
      expect(find.text('Mở đăng ký'), findsOneWidget);
      expect(find.text('Hạn chót đăng ký (Đóng)'), findsOneWidget);
    });

    testWidgets('cả bốn mốc đã có giá trị mặc định, không còn placeholder', (
      tester,
    ) async {
      await pumpCreateScreen(tester);
      for (final key in [_start, _end, _regStart, _regEnd]) {
        expect(_shown(tester, key), isNot(vi.tournamentManagementChooseDate));
      }
    });

    testWidgets(
      'bắt đầu mặc định: 06:00 hôm nay nếu còn sớm, nếu không thì 00:00 mai',
      (tester) async {
        await pumpCreateScreen(tester);
        final now = DateTime.now();
        final expected = now.isBefore(DateTime(now.year, now.month, now.day, 6))
            ? DateTime(now.year, now.month, now.day, 6)
            : DateTime(now.year, now.month, now.day + 1);
        expect(_parse(_shown(tester, _start)), expected);
      },
    );

    testWidgets('kết thúc mặc định là 00:00 ngày kế tiếp sau ngày bắt đầu', (
      tester,
    ) async {
      await pumpCreateScreen(tester);
      final start = _parse(_shown(tester, _start));
      expect(
        _parse(_shown(tester, _end)),
        DateTime(start.year, start.month, start.day + 1),
      );
    });

    testWidgets('mở đăng ký mặc định là 00:00 hôm nay', (tester) async {
      await pumpCreateScreen(tester);
      final now = DateTime.now();
      expect(
        _parse(_shown(tester, _regStart)),
        DateTime(now.year, now.month, now.day),
      );
    });

    testWidgets('hạn chót đăng ký mặc định nằm trước giờ bắt đầu', (
      tester,
    ) async {
      await pumpCreateScreen(tester);
      expect(
        _parse(
          _shown(tester, _regEnd),
        ).isBefore(_parse(_shown(tester, _start))),
        isTrue,
      );
    });

    testWidgets(
      'gửi đi các mốc đúng thứ tự: mở ĐK < hạn ĐK < bắt đầu < kết thúc',
      (tester) async {
        final h = await pumpCreateScreen(tester);
        await enterName(tester, 'Giải lịch');
        await tapSubmit(tester);
        final regStart = _bodyDate(h, 'registrationStartDate');
        final regEnd = _bodyDate(h, 'registrationEndDate');
        final start = _bodyDate(h, 'startDate');
        final end = _bodyDate(h, 'endDate');
        expect(regStart.isBefore(regEnd), isTrue);
        expect(regEnd.isBefore(start), isTrue);
        expect(start.isBefore(end), isTrue);
      },
    );

    testWidgets('thời lượng gửi đi khớp hiệu giữa kết thúc và bắt đầu', (
      tester,
    ) async {
      final h = await pumpCreateScreen(tester);
      await enterName(tester, 'Giải lịch');
      await tapSubmit(tester);
      final minutes = _bodyDate(
        h,
        'endDate',
      ).difference(_bodyDate(h, 'startDate')).inMinutes;
      expect(h.lastBody['durationMinutes'], minutes);
      expect(h.lastBody['durationHours'], minutes / 60.0);
    });

    testWidgets('mốc thời gian gửi dạng UTC và không gửi startTime riêng', (
      tester,
    ) async {
      final h = await pumpCreateScreen(tester);
      await enterName(tester, 'Giải lịch');
      await tapSubmit(tester);
      expect(h.lastBody['startDate'], endsWith('Z'));
      expect(h.lastBody['endDate'], endsWith('Z'));
      expect(h.lastBody.containsKey('startTime'), isFalse);
    });
  });

  group('CreatePublicQuickTournamentScreen thời gian: chọn mốc', () {
    testWidgets('chạm mốc kết thúc mở bảng chọn với tiêu đề của mốc đó', (
      tester,
    ) async {
      await pumpCreateScreen(tester);
      await _open(tester, _end);
      expect(find.text('Chọn ngày và giờ'), findsOneWidget);
      expect(find.text('Thời gian kết thúc'), findsOneWidget);
    });

    testWidgets('hủy bảng chọn thì giữ nguyên giá trị cũ', (tester) async {
      await pumpCreateScreen(tester);
      final before = _shown(tester, _end);
      await _open(tester, _end);
      await _scrollDate(tester, 2);
      await tester.tap(find.text('Hủy'));
      await tester.pumpAndSettle();
      expect(_shown(tester, _end), before);
    });

    testWidgets('dời ngày bắt đầu sang 3 ngày sau thì hiện ngày mới', (
      tester,
    ) async {
      await pumpCreateScreen(tester);
      final before = _parse(_shown(tester, _start));
      await _shiftField(tester, _start, 3);
      expect(
        _parse(_shown(tester, _start)),
        DateTime(before.year, before.month, before.day + 3, before.hour),
      );
    });

    testWidgets(
      'dời ngày bắt đầu thì kết thúc tự dời theo khi chưa chỉnh tay',
      (tester) async {
        await pumpCreateScreen(tester);
        await _shiftField(tester, _start, 3);
        final start = _parse(_shown(tester, _start));
        expect(
          _parse(_shown(tester, _end)),
          DateTime(start.year, start.month, start.day + 1),
        );
      },
    );

    testWidgets('kết thúc đã chỉnh tay thì không bị dời theo ngày bắt đầu', (
      tester,
    ) async {
      await pumpCreateScreen(tester);
      await _shiftField(tester, _end, 2);
      final chosen = _shown(tester, _end);
      await _shiftField(tester, _start, 1);
      expect(_shown(tester, _end), chosen);
    });

    testWidgets('mốc đăng ký tự dời theo giờ bắt đầu khi chưa chỉnh tay', (
      tester,
    ) async {
      await pumpCreateScreen(tester);
      await _shiftField(tester, _start, 3);
      final start = _parse(_shown(tester, _start));
      final regEnd = _parse(_shown(tester, _regEnd));
      expect(regEnd.isBefore(start), isTrue);
    });
  });

  group('CreatePublicQuickTournamentScreen thời gian: ca biên khi gửi', () {
    testWidgets(
      'kết thúc trước ngày bắt đầu bị chặn kèm thông báo, không gửi',
      (tester) async {
        final h = await pumpCreateScreen(tester);
        await _shiftField(tester, _end, -1);
        await enterName(tester, 'Giải sai lịch');
        await tapSubmit(tester);
        expect(
          find.text('Thời gian kết thúc phải sau thời gian bắt đầu'),
          findsOneWidget,
        );
        expect(h.submitCount, 0);
      },
    );

    testWidgets('sửa lại kết thúc hợp lệ thì gửi được', (tester) async {
      final h = await pumpCreateScreen(tester);
      await _shiftField(tester, _end, -1);
      await enterName(tester, 'Giải sửa lịch');
      await tapSubmit(tester);
      expect(h.submitCount, 0);
      await _shiftField(tester, _end, 2);
      await tapSubmit(tester);
      expect(h.submitCount, 1);
    });

    testWidgets('mở đăng ký sau hạn đăng ký bị chặn kèm thông báo', (
      tester,
    ) async {
      final h = await pumpCreateScreen(tester);
      await _shiftField(tester, _start, 3);
      await _shiftField(tester, _regStart, 2);
      await enterName(tester, 'Giải đăng ký sai');
      await tapSubmit(tester);
      expect(
        find.text('Thời gian đóng đăng ký phải sau thời gian mở đăng ký'),
        findsOneWidget,
      );
      expect(h.submitCount, 0);
    });

    testWidgets(
      'hạn đăng ký 23:59 đúng ngày bắt đầu bị chặn vì không trước giờ bắt đầu',
      (tester) async {
        final h = await pumpCreateScreen(tester);
        await _shiftField(tester, _start, 3);
        final start = _parse(_shown(tester, _start));
        final regEnd = _parse(_shown(tester, _regEnd));
        final days = DateUtils.dateOnly(
          start,
        ).difference(DateUtils.dateOnly(regEnd)).inDays;
        await _open(tester, _regEnd);
        await _scrollDate(tester, days);
        await tester.tap(find.text('23:59'));
        await tester.pumpAndSettle();
        await _confirm(tester);
        await enterName(tester, 'Giải hạn muộn');
        await tapSubmit(tester);
        expect(
          find.text('Hạn đăng ký phải trước giờ bắt đầu giải'),
          findsOneWidget,
        );
        expect(h.submitCount, 0);
      },
    );
  });
}
