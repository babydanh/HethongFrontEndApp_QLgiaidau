import 'package:app_quanly_giaidau/core/participants/participant_display.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/domain/entities/match.dart';
import 'package:app_quanly_giaidau/features/organizer_ops/screens/schedule_conflicts_sheet.dart';
import 'package:app_quanly_giaidau/features/tournament/utils/schedule_conflicts.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

DateTime _at(String hhmm) {
  final parts = hhmm.split(':');
  return DateTime(2026, 10, 26, int.parse(parts[0]), int.parse(parts[1]));
}

MatchModel _match(
  String id,
  String courtId, {
  required String scheduledAt,
  String team1Id = 'p1',
  String team2Id = 'p2',
  String team1Name = 'TBD',
  String team2Name = 'TBD',
  List<ParticipantPlayer> team1Players = const [],
  List<ParticipantPlayer> team2Players = const [],
  String? courtName,
  int? durationMinutes,
  String status = 'scheduled',
}) => MatchModel(
  id: id,
  round: 1,
  matchNumber: 1,
  team1Id: team1Id,
  team2Id: team2Id,
  team1Name: team1Name,
  team2Name: team2Name,
  team1Players: team1Players,
  team2Players: team2Players,
  status: status,
  courtId: courtId,
  courtName: courtName,
  scheduledTime: _at(scheduledAt),
  durationMinutes: durationMinutes,
  bracketPosition: const BracketPosition(round: 1, position: 0),
  updatedAt: DateTime.utc(2026),
);

void main() {
  group('scheduleStatusActive (port isActiveScheduleStatus)', () {
    test('thiếu, SCHEDULED và ONGOING là còn hiệu lực', () {
      expect(scheduleStatusActive(null), isTrue);
      expect(scheduleStatusActive(''), isTrue);
      expect(scheduleStatusActive('scheduled'), isTrue);
      expect(scheduleStatusActive(' ONGOING '), isTrue);
    });

    test('trận đã xong, hủy, đấu trực tiếp không còn hiệu lực', () {
      expect(scheduleStatusActive('COMPLETED'), isFalse);
      expect(scheduleStatusActive('CANCELLED'), isFalse);
      expect(scheduleStatusActive('LIVE'), isFalse);
      expect(scheduleStatusActive('BYE'), isFalse);
    });
  });

  group('scheduleConflictDuration', () {
    test('thiếu hoặc <= 0 tính bằng bước ô, luôn tối thiểu 15', () {
      // Web: Math.max(15, Number(m.durationMinutes) || defaultStepMinutes).
      expect(scheduleConflictDuration(null, 30), 30);
      expect(scheduleConflictDuration(0, 10), 15);
      expect(scheduleConflictDuration(-5, 10), 15);
      expect(scheduleConflictDuration(5, 30), 15);
      expect(scheduleConflictDuration(45, 30), 45);
    });
  });

  group('scheduleCompetitorOf (khoá nhận diện port identityKeysOf)', () {
    test('id participant và user/name từng VĐV', () {
      final match = _match(
        'm1',
        'court-1',
        scheduledAt: '08:00',
        team1Players: const [
          ParticipantPlayer(slot: 0, userId: 'u1', fullName: 'Nguyễn Văn A'),
        ],
      );
      final competitor = scheduleCompetitorOf(match, 1);
      expect(competitor.keys, contains('id:p1'));
      expect(competitor.keys, contains('user:u1'));
      expect(competitor.label, 'Nguyễn Văn A');
    });

    test('VĐV khách theo tên, đội theo team khi bên không có id', () {
      final match = _match(
        'm1',
        'court-1',
        scheduledAt: '08:00',
        team1Id: '',
        team1Name: 'Đội Phoenix',
        team1Players: const [
          ParticipantPlayer(slot: 0, fullName: 'Trần Thị B'),
        ],
      );
      final competitor = scheduleCompetitorOf(match, 1);
      expect(competitor.keys, contains('name:trần thị b'));
      expect(competitor.keys, contains('team:đội phoenix'));
      // Nhãn hiện tên đội (quy ước participantLabel của thẻ lịch).
      expect(competitor.label, 'Đội Phoenix');
    });
  });

  group('scheduleConflictGroups (port scheduleConflicts)', () {
    test(
      'một VĐV hai trận cùng giờ hai sân: cả hai trận đều có dòng cảnh báo',
      () {
        final conflicts = scheduleConflictGroups([
          _match(
            'm1',
            'court-1',
            scheduledAt: '08:00',
            team1Players: const [
              ParticipantPlayer(
                slot: 0,
                userId: 'u1',
                fullName: 'Nguyễn Văn A',
              ),
            ],
            courtName: 'Sân 1',
            durationMinutes: 30,
          ),
          _match(
            'm2',
            'court-2',
            scheduledAt: '08:15',
            team2Players: const [
              ParticipantPlayer(
                slot: 0,
                userId: 'u1',
                fullName: 'Nguyễn Văn A',
              ),
            ],
            courtName: 'Sân 2',
            durationMinutes: 30,
          ),
        ], defaultStepMinutes: 30);

        expect(conflicts, hasLength(2));
        final m1 = conflicts.firstWhere((group) => group.match.id == 'm1');
        expect(m1.conflicts.single.otherMatchId, 'm2');
        expect(m1.conflicts.single.otherCourtName, 'Sân 2');
        expect(m1.conflicts.single.otherTimeStr, '08:15');
        expect(m1.conflicts.single.competitorName, 'Nguyễn Văn A');
        final m2 = conflicts.firstWhere((group) => group.match.id == 'm2');
        expect(m2.conflicts.single.otherCourtName, 'Sân 1');
      },
    );

    test('kết thúc đúng lúc trận khác bắt đầu không tính trùng', () {
      final conflicts = scheduleConflictGroups([
        _match('m1', 'court-1', scheduledAt: '08:00', durationMinutes: 30),
        _match(
          'm2',
          'court-2',
          scheduledAt: '08:30',
          team2Id: 'p1',
          durationMinutes: 30,
        ),
      ], defaultStepMinutes: 30);
      expect(conflicts, isEmpty);
    });

    test('trùng sân cùng giờ không báo (server đã chặn trùng sân)', () {
      final conflicts = scheduleConflictGroups([
        _match('m1', 'court-1', scheduledAt: '08:00', durationMinutes: 30),
        _match(
          'm2',
          'court-1',
          scheduledAt: '08:00',
          team2Id: 'p1',
          durationMinutes: 30,
        ),
      ], defaultStepMinutes: 30);
      expect(conflicts, isEmpty);
    });

    test('trận đã kết thúc không tham gia phát hiện', () {
      final conflicts = scheduleConflictGroups([
        _match(
          'm1',
          'court-1',
          scheduledAt: '08:00',
          durationMinutes: 30,
          status: 'completed',
        ),
        _match(
          'm2',
          'court-2',
          scheduledAt: '08:00',
          team2Id: 'p1',
          durationMinutes: 30,
        ),
      ], defaultStepMinutes: 30);
      expect(conflicts, isEmpty);
    });

    test('khớp VĐV theo tên khách không dấu hoa thường và khoảng trắng', () {
      final conflicts = scheduleConflictGroups([
        _match(
          'm1',
          'court-1',
          scheduledAt: '09:00',
          team1Id: '',
          team1Players: const [
            ParticipantPlayer(slot: 0, fullName: 'NGUYEN   Van A'),
          ],
          durationMinutes: 30,
        ),
        _match(
          'm2',
          'court-2',
          scheduledAt: '09:00',
          team2Id: '',
          team2Players: const [
            ParticipantPlayer(slot: 0, fullName: 'Nguyen van a'),
          ],
          durationMinutes: 30,
        ),
      ], defaultStepMinutes: 30);
      expect(conflicts, hasLength(2));
      // Nhãn hiển thị tên VĐV nguyên văn từ dữ liệu server.
      expect(conflicts.first.conflicts.single.competitorName, 'NGUYEN   Van A');
    });

    test('khớp theo tên đội khi hai bên chưa có id', () {
      final conflicts = scheduleConflictGroups([
        _match(
          'm1',
          'court-1',
          scheduledAt: '10:00',
          team1Id: '',
          team1Name: 'Đội Phoenix',
          durationMinutes: 30,
        ),
        _match(
          'm2',
          'court-2',
          scheduledAt: '10:00',
          team2Id: '',
          team2Name: 'đội phoenix',
          durationMinutes: 30,
        ),
      ], defaultStepMinutes: 30);
      expect(conflicts, hasLength(2));
    });

    test('bên chưa xác định (TBD, không VĐV) không tạo xung đột ảo', () {
      // Cả hai trận chưa có participant: không id, không VĐV, không tên đội —
      // chỗ TBD mặc định không là khoá nhận diện.
      final conflicts = scheduleConflictGroups([
        _match(
          'm1',
          'court-1',
          scheduledAt: '11:00',
          team1Id: '',
          team2Id: '',
          durationMinutes: 30,
        ),
        _match(
          'm2',
          'court-2',
          scheduledAt: '11:00',
          team1Id: '',
          team2Id: '',
          durationMinutes: 30,
        ),
      ], defaultStepMinutes: 30);
      expect(conflicts, isEmpty);
    });

    test('sân thiếu tên để trống, giao diện tự dịch nhãn "Sân khác"', () {
      final conflicts = scheduleConflictGroups([
        _match('m1', 'court-1', scheduledAt: '13:00', durationMinutes: 30),
        _match(
          'm2',
          'court-2',
          scheduledAt: '13:00',
          team2Id: 'p1',
          durationMinutes: 30,
          courtName: '   ',
        ),
      ], defaultStepMinutes: 30);
      expect(conflicts.first.conflicts.single.otherCourtName, isEmpty);
    });

    for (final (code, label) in [('vi', 'Sân khác'), ('en', 'Another court')]) {
      testWidgets('sheet shows the translated label for a nameless court '
          '($code)', (tester) async {
        final groups = scheduleConflictGroups([
          _match('m1', 'court-1', scheduledAt: '13:00', durationMinutes: 30),
          _match(
            'm2',
            'court-2',
            scheduledAt: '13:00',
            team2Id: 'p1',
            durationMinutes: 30,
            courtName: '   ',
          ),
        ], defaultStepMinutes: 30);
        await tester.pumpWidget(
          MaterialApp(
            locale: Locale(code),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: ScheduleConflictsSheet(groups: groups)),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.textContaining(label), findsWidgets);
      });
    }

    test('thời lượng thiếu lấy bước ô làm mặc định', () {
      // m1 thiếu durationMinutes → 15 phút (max(15, step 15)); m2 bắt đầu 08:10
      // sau khi m1 kết thúc 08:15 thì không trùng, nhưng bắt đầu 08:05 thì trùng.
      final noClash = scheduleConflictGroups([
        _match('m1', 'court-1', scheduledAt: '08:00'),
        _match('m2', 'court-2', scheduledAt: '08:15', team2Id: 'p1'),
      ], defaultStepMinutes: 15);
      final clash = scheduleConflictGroups([
        _match('m1', 'court-1', scheduledAt: '08:00'),
        _match('m2', 'court-2', scheduledAt: '08:05', team2Id: 'p1'),
      ], defaultStepMinutes: 15);
      expect(noClash, isEmpty);
      expect(clash, hasLength(2));
    });

    test('trận chưa có sân hoặc chưa có giờ bị bỏ qua', () {
      final conflicts = scheduleConflictGroups([
        _match('m1', '', scheduledAt: '08:00', durationMinutes: 30),
        _match(
          'm2',
          'court-2',
          scheduledAt: '08:00',
          team2Id: 'p1',
          durationMinutes: 30,
        ),
      ], defaultStepMinutes: 30);
      expect(conflicts, isEmpty);
    });

    test('hai cặp xung đột cùng trận xếp thành hai dòng cảnh báo', () {
      final conflicts = scheduleConflictGroups([
        _match(
          'm1',
          'court-1',
          scheduledAt: '14:00',
          team1Players: const [
            ParticipantPlayer(slot: 0, userId: 'u1', fullName: 'VĐV Một'),
            ParticipantPlayer(slot: 1, userId: 'u2', fullName: 'VĐV Hai'),
          ],
          durationMinutes: 30,
        ),
        _match(
          'm2',
          'court-2',
          scheduledAt: '14:00',
          team1Id: 'p3',
          team2Id: 'u1',
          team2Players: const [
            ParticipantPlayer(slot: 0, userId: 'u1', fullName: 'VĐV Một'),
          ],
          durationMinutes: 30,
        ),
        _match(
          'm3',
          'court-3',
          scheduledAt: '14:10',
          team1Id: 'p5',
          team2Id: 'u2',
          team2Players: const [
            ParticipantPlayer(slot: 0, userId: 'u2', fullName: 'VĐV Hai'),
          ],
          durationMinutes: 30,
        ),
      ], defaultStepMinutes: 30);

      final m1 = conflicts.firstWhere((group) => group.match.id == 'm1');
      expect(m1.conflicts, hasLength(2));
      final otherIds = [for (final c in m1.conflicts) c.otherMatchId]..sort();
      expect(otherIds, ['m2', 'm3']);
    });
  });
}
