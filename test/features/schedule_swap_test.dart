import 'package:app_quanly_giaidau/domain/entities/match_schedule.dart';
import 'package:app_quanly_giaidau/features/tournament/utils/schedule_actions.dart';
import 'package:flutter_test/flutter_test.dart';

/// Ghi lại mọi lần ghi lịch theo thứ tự gọi. [failOnCalls] là số thứ tự lần
/// gọi (từ 1) sẽ thất bại; mặc định server echo lại đúng lịch đã yêu cầu.
class _Writer {
  _Writer({this.failOnCalls = const {}, this.reflowed = const {}});

  final Set<int> failOnCalls;

  /// matchId → lịch server giữ lại thay vì lịch đã yêu cầu (mô phỏng server dời).
  final Map<String, MatchScheduleSnapshot> reflowed;
  final List<String> log = [];

  Future<MatchScheduleSnapshot?> call(String matchId, ScheduleSlot? slot) async {
    log.add(_describe(matchId, slot));
    if (failOnCalls.contains(log.length)) return null;
    if (slot == null) return (scheduledAt: null, courtId: null, courtName: null);
    final forced = reflowed[matchId];
    if (forced != null) return forced;
    return (
      scheduledAt: slot.scheduledAt,
      courtId: slot.courtId,
      courtName: slot.courtName,
    );
  }
}

String _describe(String matchId, ScheduleSlot? slot) {
  if (slot == null) return '$matchId:gỡ';
  final hh = slot.scheduledAt.hour.toString().padLeft(2, '0');
  final mm = slot.scheduledAt.minute.toString().padLeft(2, '0');
  return '$matchId:${slot.courtId}@$hh:$mm';
}

final _slotA = ScheduleSlot(
  courtId: 'court-1',
  courtName: 'Sân 1',
  scheduledAt: DateTime(2026, 5, 20, 7, 30),
);
final _slotB = ScheduleSlot(
  courtId: 'court-2',
  courtName: 'Sân 2',
  scheduledAt: DateTime(2026, 5, 20, 9, 0),
);

void main() {
  group('runScheduleSwap', () {
    test('a tray match dropped on a placed card takes its cell and the card goes back to the tray', () async {
      final writer = _Writer();

      final report = await runScheduleSwap(
        draggedId: 'tray',
        draggedSlot: null,
        targetId: 'b',
        targetSlot: _slotB,
        write: writer.call,
      );

      expect(writer.log, ['b:gỡ', 'tray:court-2@09:00']);
      expect(report.result, ScheduleSwapResult.swapped);
      expect(report.movedMatchIds, isEmpty);
    });

    test('two placed matches trade cells in unschedule, place, place order', () async {
      final writer = _Writer();

      final report = await runScheduleSwap(
        draggedId: 'a',
        draggedSlot: _slotA,
        targetId: 'b',
        targetSlot: _slotB,
        write: writer.call,
      );

      expect(writer.log, [
        'b:gỡ',
        'a:court-2@09:00',
        'b:court-1@07:30',
      ]);
      expect(report.result, ScheduleSwapResult.swapped);
    });

    test('aborts without touching the dragged match when the target cannot be unscheduled', () async {
      final writer = _Writer(failOnCalls: {1});

      final report = await runScheduleSwap(
        draggedId: 'a',
        draggedSlot: _slotA,
        targetId: 'b',
        targetSlot: _slotB,
        write: writer.call,
      );

      expect(writer.log, ['b:gỡ']);
      expect(report.result, ScheduleSwapResult.aborted);
    });

    test('rolls the target back into its cell when the dragged match cannot be placed', () async {
      final writer = _Writer(failOnCalls: {2});

      final report = await runScheduleSwap(
        draggedId: 'a',
        draggedSlot: _slotA,
        targetId: 'b',
        targetSlot: _slotB,
        write: writer.call,
      );

      expect(writer.log, ['b:gỡ', 'a:court-2@09:00', 'b:court-2@09:00']);
      expect(report.result, ScheduleSwapResult.rolledBack);
    });

    test('restores both matches to their original cells when the second placement fails', () async {
      final writer = _Writer(failOnCalls: {3});

      final report = await runScheduleSwap(
        draggedId: 'a',
        draggedSlot: _slotA,
        targetId: 'b',
        targetSlot: _slotB,
        write: writer.call,
      );

      expect(writer.log, [
        'b:gỡ',
        'a:court-2@09:00',
        'b:court-1@07:30',
        'a:court-1@07:30',
        'b:court-2@09:00',
      ]);
      expect(report.result, ScheduleSwapResult.rolledBack);
    });

    test('reports partial when the rollback itself fails so the screen can ask for a reload', () async {
      final writer = _Writer(failOnCalls: {2, 3});

      final report = await runScheduleSwap(
        draggedId: 'a',
        draggedSlot: _slotA,
        targetId: 'b',
        targetSlot: _slotB,
        write: writer.call,
      );

      expect(report.result, ScheduleSwapResult.partial);
    });

    test('lists a match the server placed somewhere other than requested', () async {
      final writer = _Writer(
        reflowed: {
          'a': (
            scheduledAt: DateTime(2026, 5, 20, 9, 30),
            courtId: 'court-2',
            courtName: 'Sân 2',
          ),
        },
      );

      final report = await runScheduleSwap(
        draggedId: 'a',
        draggedSlot: _slotA,
        targetId: 'b',
        targetSlot: _slotB,
        write: writer.call,
      );

      expect(report.result, ScheduleSwapResult.swapped);
      expect(report.movedMatchIds, ['a']);
    });
  });

  group('quickScheduleMinutes', () {
    test('lists every 15-minute start inside the operating hours', () {
      final minutes = quickScheduleMinutes(startHour: 7, endHour: 9);

      expect(minutes, [420, 435, 450, 465, 480, 495, 510, 525]);
    });
  });
}
