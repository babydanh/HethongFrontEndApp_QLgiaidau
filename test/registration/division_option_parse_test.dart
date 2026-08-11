import 'package:app_quanly_giaidau/domain/entities/tournament_registration.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TournamentDivisionOption.fromJson', () {
    // Payload thật từ GET /tournaments/:id/divisions — backend trả entryFee
    // dưới dạng chuỗi ("0.00"), maxParticipants là số. Trước đây ép
    // `as num?` ném TypeError → cả danh sách division bị bỏ qua.
    final realPayload = [
      {
        'id': 'db7b9ff1-4d6d-4b1a-b264-95b141bfac98',
        'name': 'Đôi Nam',
        'matchType': 'DOUBLES',
        'genderRestriction': 'MALE',
        'maxParticipants': 8,
        'entryFee': '0.00',
        'bracketType': 'SINGLE_ELIMINATION',
        'minElo': null,
        'maxElo': null,
        '_count': {'participants': 0},
      },
      {
        'id': 'e6a27959-cf55-4296-bbd6-eec1f50aafd4',
        'name': 'Đôi Nam Nữ',
        'matchType': 'MIXED_DOUBLES',
        'genderRestriction': 'MIXED',
        'maxParticipants': 8,
        'entryFee': '0.00',
        'bracketType': 'SINGLE_ELIMINATION',
        'minElo': null,
        'maxElo': null,
        '_count': {'participants': 0},
      },
    ];

    test('parse không vỡ khi entryFee là chuỗi, trả về đủ mọi division', () {
      final divisions = realPayload
          .map((item) => TournamentDivisionOption.fromJson(item))
          .toList();

      expect(divisions, hasLength(2));
      expect(divisions[0].id, 'db7b9ff1-4d6d-4b1a-b264-95b141bfac98');
      expect(divisions[0].name, 'Đôi Nam');
      expect(divisions[0].matchType, 'DOUBLES');
      expect(divisions[0].genderRestriction, 'MALE');
      expect(divisions[0].entryFee, 0.0);
      expect(divisions[0].maxParticipants, 8);
      expect(divisions[0].participantCount, 0);

      expect(divisions[1].name, 'Đôi Nam Nữ');
      expect(divisions[1].matchType, 'MIXED_DOUBLES');
      expect(divisions[1].entryFee, 0.0);
    });

    test('entryFee số với dấu phẩy và lệ phí thật vẫn parse đúng', () {
      final division = TournamentDivisionOption.fromJson({
        'id': 'div-1',
        'name': 'Đơn Nam',
        'matchType': 'SINGLES',
        'genderRestriction': 'MALE',
        'maxParticipants': 16,
        'entryFee': '150000',
        'minElo': '800',
        'maxElo': '1800',
        '_count': {'participants': 12},
      });

      expect(division.entryFee, 150000.0);
      expect(division.minElo, 800.0);
      expect(division.maxElo, 1800.0);
      expect(division.maxParticipants, 16);
      expect(division.participantCount, 12);
    });

    test('trường rỗng/thiếu vẫn parse an toàn', () {
      final division = TournamentDivisionOption.fromJson({
        'id': 'div-2',
        'name': '',
        'matchType': 'DOUBLES',
      });

      expect(division.id, 'div-2');
      expect(division.entryFee, isNull);
      expect(division.maxParticipants, isNull);
      expect(division.participantCount, isNull);
    });
  });
}
