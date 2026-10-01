import 'package:flutter_test/flutter_test.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament_registration.dart';

void main() {
  group('TournamentDivisionOption capacity', () {
    test('reads fractional team slots from the server capacity projection', () {
      final division = TournamentDivisionOption.fromJson({
        'id': 'division-1',
        'name': 'Doubles A',
        'maxParticipants': 4,
        '_count': {'participants': 4},
        'capacity': {'occupiedTeamSlots': 0.5, 'maxTeamSlots': 4},
      });

      expect(division.occupiedTeamSlots, 0.5);
      expect(division.effectiveMaxTeamSlots, 4);
    });

    test('keeps half capacity while only four unpaired members registered', () {
      final division = TournamentDivisionOption.fromJson({
        'id': 'division-1',
        'name': 'Doubles A',
        '_count': {'participants': 4},
        'capacity': {'occupiedTeamSlots': 2.0, 'maxTeamSlots': 4},
      });

      expect(division.isFull, isFalse);
    });

    test('reports full only at four team slots', () {
      final division = TournamentDivisionOption.fromJson({
        'id': 'division-1',
        'name': 'Doubles A',
        'capacity': {'occupiedTeamSlots': 3.5, 'maxTeamSlots': 4},
      });
      final full = TournamentDivisionOption.fromJson({
        'id': 'division-2',
        'name': 'Doubles B',
        'capacity': {'occupiedTeamSlots': 4.0, 'maxTeamSlots': 4},
      });

      expect(division.isFull, isFalse);
      expect(full.isFull, isTrue);
    });

    test('does not report an uncapped division as full', () {
      final division = TournamentDivisionOption.fromJson({
        'id': 'division-1',
        'name': 'Open',
        'capacity': {'occupiedTeamSlots': 40.0, 'maxTeamSlots': null},
      });

      expect(division.isFull, isFalse);
    });

    test('falls back to participant row count for non-doubles formats', () {
      final division = TournamentDivisionOption.fromJson({
        'id': 'division-1',
        'name': 'Singles',
        'matchType': 'SINGLES',
        'maxParticipants': 4,
        '_count': {'participants': 3},
      });

      expect(division.occupiedTeamSlots, 3.0);
      expect(division.isFull, isFalse);
    });

    test('leaves doubles occupancy unknown instead of counting rows', () {
      // 4 hồ sơ ở nội dung đôi có thể chỉ là 2 suất, nên số bản ghi KHÔNG
      // được dùng làm sức chứa khi thiếu projection của server.
      final division = TournamentDivisionOption.fromJson({
        'id': 'division-1',
        'name': 'Doubles A',
        'matchType': 'DOUBLES',
        'maxParticipants': 4,
        '_count': {'participants': 4},
      });

      expect(division.occupiedTeamSlots, isNull);
      expect(division.teamSlotsLabel, isNull);
      expect(division.isFull, isFalse);
    });

    test('leaves mixed doubles occupancy unknown too', () {
      final division = TournamentDivisionOption.fromJson({
        'id': 'division-1',
        'name': 'Đôi Nam Nữ',
        'matchType': 'MIXED_DOUBLES',
        'maxParticipants': 4,
        '_count': {'participants': 4},
      });

      expect(division.occupiedTeamSlots, isNull);
      expect(division.isFull, isFalse);
    });

    test('leaves an unrecognised format unknown instead of counting rows', () {
      // matchType ngoài danh sách app biết (chưa có quy ước nào map về đôi/đơn)
      // thì 4 hồ sơ KHÔNG được đo thành 4 suất rồi báo đầy nhầm. Thiếu
      // projection của server thì sức chứa CHƯA BIẾT, không phải bằng số dòng.
      final division = TournamentDivisionOption.fromJson({
        'id': 'division-1',
        'name': 'Four on four',
        'matchType': 'FOURS',
        'maxParticipants': 4,
        '_count': {'participants': 4},
      });

      expect(division.occupiedTeamSlots, isNull);
      expect(division.teamSlotsLabel, isNull);
      expect(division.isFull, isFalse);
    });

    test('leaves a missing match format unknown instead of counting rows', () {
      // Backend chưa gán matchType (nội dung tạo tay) — null KHÔNG phải là
      // "đơn", nên cũng không được phép suy ra sức chứa từ số bản ghi.
      final division = TournamentDivisionOption.fromJson({
        'id': 'division-1',
        'name': 'Chưa cấu hình',
        'maxParticipants': 4,
        '_count': {'participants': 4},
      });

      expect(division.occupiedTeamSlots, isNull);
      expect(division.teamSlotsLabel, isNull);
      expect(division.isFull, isFalse);
    });

    test('still shows the server projection for an unrecognised format', () {
      // Projection là nguồn chân lý bất kể format: nếu backend đã gửi thì
      // phải hiện đúng con số, không phải vì "không đọc được format" mà bỏ trống.
      final division = TournamentDivisionOption.fromJson({
        'id': 'division-1',
        'name': 'Four on four',
        'matchType': 'FOURS',
        'maxParticipants': 4,
        '_count': {'participants': 4},
        'capacity': {
          'occupiedTeamSlots': 2,
          'maxTeamSlots': 4,
          'isFull': false,
        },
      });

      expect(division.occupiedTeamSlots, 2.0);
      expect(division.teamSlotsLabel, '2/4');
      expect(division.isFull, isFalse);
    });
  });

  group('TournamentDivisionOption.teamSlotsLabel', () {
    test('shows 2 / 4 team slots for four unpaired doubles athletes', () {
      final division = TournamentDivisionOption.fromJson({
        'id': 'division-1',
        'name': 'Doubles A',
        'matchType': 'DOUBLES',
        'maxParticipants': 4,
        '_count': {'participants': 4},
        'capacity': {'occupiedTeamSlots': 2, 'maxTeamSlots': 4},
      });

      expect(division.teamSlotsLabel, '2/4');
      expect(division.isFull, isFalse);
    });

    test('keeps the half slot visible for one unpaired athlete', () {
      final division = TournamentDivisionOption.fromJson({
        'id': 'division-1',
        'name': 'Doubles A',
        'matchType': 'DOUBLES',
        'maxParticipants': 4,
        'capacity': {'occupiedTeamSlots': 0.5, 'maxTeamSlots': 4},
      });

      expect(division.teamSlotsLabel, '0.5/4');
      expect(division.isFull, isFalse);
    });

    test('shows 4 / 4 and reports full once every team slot is taken', () {
      final division = TournamentDivisionOption.fromJson({
        'id': 'division-1',
        'name': 'Doubles A',
        'matchType': 'DOUBLES',
        'maxParticipants': 4,
        '_count': {'participants': 8},
        'capacity': {'occupiedTeamSlots': 4, 'maxTeamSlots': 4},
      });

      expect(division.teamSlotsLabel, '4/4');
      expect(division.isFull, isTrue);
    });

    test('keeps whole-team units for singles', () {
      final division = TournamentDivisionOption.fromJson({
        'id': 'division-1',
        'name': 'Singles A',
        'matchType': 'SINGLES',
        'maxParticipants': 4,
        '_count': {'participants': 3},
      });

      expect(division.teamSlotsLabel, '3/4');
      expect(division.isFull, isFalse);
    });

    test('drops the cap for a division without a team limit', () {
      final division = TournamentDivisionOption.fromJson({
        'id': 'division-1',
        'name': 'Open',
        'capacity': {'occupiedTeamSlots': 40, 'maxTeamSlots': null},
      });

      expect(division.teamSlotsLabel, '40');
    });
  });
}
