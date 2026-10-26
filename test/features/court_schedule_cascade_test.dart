import 'package:app_quanly_giaidau/features/tournament/utils/court_schedule_cascade.dart';
import 'package:flutter_test/flutter_test.dart';

DateTime _at(String hhmm) {
  final parts = hhmm.split(':');
  return DateTime(2026, 10, 26, int.parse(parts[0]), int.parse(parts[1]));
}

int _ms(String hhmm) => _at(hhmm).millisecondsSinceEpoch;

CascadeCourtMatch _match(
  String id,
  String start, {
  int? durationMinutes,
  String? status,
}) => CascadeCourtMatch(
  id: id,
  startMs: _ms(start),
  durationMinutes: durationMinutes,
  status: status,
);

void main() {
  group(
    'planDurationCascade (port court-schedule-cascade.test.ts của Web)',
    () {
      test(
        '15 phút liền nhau: trận sau dời xuống khi trận đầu tăng lên 20 phút',
        () {
          final plan = planDurationCascade('m1', 20, [
            _match('m1', '08:00', durationMinutes: 15),
            _match('m2', '08:15', durationMinutes: 15),
            _match('m3', '08:30', durationMinutes: 15),
            _match('m4', '08:45', durationMinutes: 15),
          ]);

          expect(plan, isA<CascadePlanOk>());
          final moves = (plan as CascadePlanOk).moves;
          expect(moves, hasLength(3));
          expect(moves[0].id, 'm2');
          expect(moves[0].fromMs, _ms('08:15'));
          expect(moves[0].toMs, _ms('08:20'));
          expect(moves[1].id, 'm3');
          expect(moves[1].toMs, _ms('08:35'));
          expect(moves[2].id, 'm4');
          expect(moves[2].toMs, _ms('08:50'));
        },
      );

      test('có khoảng trống thì dây chuyền dừng', () {
        final plan = planDurationCascade('m1', 20, [
          _match('m1', '08:00', durationMinutes: 15),
          _match('m2', '08:15', durationMinutes: 15),
          _match('m3', '08:45', durationMinutes: 15),
        ]);

        final moves = (plan as CascadePlanOk).moves;
        expect(moves, hasLength(1));
        expect(moves.single.id, 'm2');
      });

      test('không trận nào phía sau bị đè: không dời gì', () {
        final plan = planDurationCascade('m1', 20, [
          _match('m1', '08:00', durationMinutes: 15),
          _match('m2', '08:30', durationMinutes: 15),
        ]);

        expect((plan as CascadePlanOk).moves, isEmpty);
      });

      test('trận đã/đang đấu chặn toàn bộ thay đổi', () {
        for (final status in ['ONGOING', 'COMPLETED', 'DISPUTED']) {
          final plan = planDurationCascade('m1', 20, [
            _match('m1', '08:00', durationMinutes: 15),
            _match('m2', '08:15', durationMinutes: 15, status: 'SCHEDULED'),
            _match('m3', '08:30', durationMinutes: 15, status: status),
          ]);
          expect(plan, isA<CascadePlanBlocked>(), reason: status);
          expect(
            (plan as CascadePlanBlocked).blockedById,
            'm3',
            reason: status,
          );
        }
      });

      test('trận đã hủy không chiếm sân', () {
        final plan = planDurationCascade('m1', 20, [
          _match('m1', '08:00', durationMinutes: 15),
          _match('m2', '08:15', durationMinutes: 15, status: 'CANCELLED'),
        ]);

        expect((plan as CascadePlanOk).moves, isEmpty);
      });

      test('thời lượng theo luật server: thiếu là 30, dưới 15 là 15', () {
        final plan = planDurationCascade('m1', 20, [
          _match('m1', '08:00', durationMinutes: 15),
          _match('m2', '08:15'),
          _match('m3', '08:45', durationMinutes: 10),
          _match('m4', '09:05', durationMinutes: 15),
        ]);

        // m2 (30) dời tới 08:20 và hết 08:50; m3 (15 phía server) dời tới 08:50
        // và hết 09:05.
        final moves = (plan as CascadePlanOk).moves;
        expect(moves, hasLength(2));
        expect(moves[0].id, 'm2');
        expect(moves[0].toMs, _ms('08:20'));
        expect(moves[1].id, 'm3');
        expect(moves[1].toMs, _ms('08:50'));
      });

      test('trận cũ trùng giờ bắt đầu không nằm trong dây chuyền', () {
        final plan = planDurationCascade('m1', 20, [
          _match('m1', '08:00', durationMinutes: 15),
          _match('m0', '08:00', durationMinutes: 15),
          _match('m2', '08:15', durationMinutes: 15),
        ]);

        final moves = (plan as CascadePlanOk).moves;
        expect(moves, hasLength(1));
        expect(moves.single.id, 'm2');
      });

      test('không tìm thấy trận đích: không dời gì', () {
        final plan = planDurationCascade('missing', 20, [
          _match('m1', '08:00', durationMinutes: 15),
        ]);
        expect((plan as CascadePlanOk).moves, isEmpty);
      });
    },
  );

  group('serverEffectiveDurationMinutes', () {
    test('thiếu là 30, dưới 15 nâng 15, giá trị thường giữ nguyên', () {
      expect(serverEffectiveDurationMinutes(null), 30);
      expect(serverEffectiveDurationMinutes(0), 30);
      expect(serverEffectiveDurationMinutes(-5), 30);
      expect(serverEffectiveDurationMinutes(10), 15);
      expect(serverEffectiveDurationMinutes(15), 15);
      expect(serverEffectiveDurationMinutes(45), 45);
    });
  });

  group('cascadeStartTimes', () {
    test('3 trận 30/45/30 từ 08:00: bắt đầu 08:00, 08:30, 09:15 (spec)', () {
      final starts = cascadeStartTimes(_at('08:00'), [30, 45, 30]);
      expect(starts, [_at('08:00'), _at('08:30'), _at('09:15')]);
    });

    test('khoảng nghỉ gapMinutes xen giữa hai trận', () {
      final starts = cascadeStartTimes(_at('08:00'), [30, 30], gapMinutes: 5);
      expect(starts, [_at('08:00'), _at('08:35')]);
    });

    test('thời lượng dưới 15 được nâng lên theo luật server', () {
      final starts = cascadeStartTimes(_at('08:00'), [10, 10]);
      expect(starts, [_at('08:00'), _at('08:15')]);
    });

    test('danh sách rỗng trả về rỗng, không đụng giờ bắt đầu', () {
      expect(cascadeStartTimes(_at('08:00'), const []), isEmpty);
    });
  });
}
