import 'package:app_quanly_giaidau/core/utils/tournament_location_formatter.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:flutter_test/flutter_test.dart';

const _address = '18A Đường Phan Văn Trị, Phường 10, Phường Gò Vấp, Thành phố Hồ Chí Minh';
const _city = 'Thành phố Hồ Chí Minh';

Tournament _tournament({
  String? venueName,
  String? locationAddress,
  String? city,
  Map<String, dynamic>? locationConfig,
}) => Tournament(
  id: 't1',
  name: 'Giải thử',
  sport: 'tennis',
  format: 'single_elimination',
  bracketType: 'SINGLE_ELIMINATION',
  adminToken: '',
  refereeToken: '',
  viewerToken: '',
  creatorId: 'u1',
  createdAt: DateTime.utc(2026, 1, 1),
  updatedAt: DateTime.utc(2026, 1, 1),
  venueName: venueName,
  locationAddress: locationAddress,
  city: city,
  locationConfig: locationConfig,
);

// Snapshot typed before a saved venue was picked: it must not leak into the shown address.
const _staleConfig = <String, dynamic>{
  'venueName': 'Sân tạm',
  'address': 'ádasd',
  'province': 'ádasd',
};

void main() {
  group('TournamentLocationFormatter.tournamentFullLocation', () {
    test('TC-LOC-APP-01 giải gắn sân: tên sân + địa chỉ sân + thành phố, bỏ snapshot cũ', () {
      final t = _tournament(
        venueName: 'Câu Lạc Bộ Tennis Khang An',
        locationAddress: _address,
        city: _city,
        locationConfig: _staleConfig,
      );
      expect(
        TournamentLocationFormatter.tournamentFullLocation(t),
        'Câu Lạc Bộ Tennis Khang An, $_address',
      );
    });

    test('TC-LOC-APP-02 giải không gắn sân: địa chỉ + thành phố, bỏ snapshot cũ', () {
      final t = _tournament(
        locationAddress: '12 Lê Lợi, Quận 1',
        city: _city,
        locationConfig: _staleConfig,
      );
      expect(
        TournamentLocationFormatter.tournamentFullLocation(t),
        '12 Lê Lợi, Quận 1, $_city',
      );
    });

    test('TC-LOC-APP-03 giải cũ chỉ có locationConfig: vẫn dùng locationConfig', () {
      final t = _tournament(
        locationConfig: const {'venueName': 'Sân cũ', 'address': '5 Hai Bà Trưng', 'province': 'Hà Nội'},
      );
      expect(
        TournamentLocationFormatter.tournamentFullLocation(t),
        'Sân cũ, 5 Hai Bà Trưng, Hà Nội',
      );
    });

    test('TC-LOC-APP-04 không có dữ liệu địa điểm: chuỗi rỗng', () {
      expect(TournamentLocationFormatter.tournamentFullLocation(_tournament()), '');
    });
  });

  group('TournamentLocationFormatter.tournamentLocationLines', () {
    test('TC-LOC-APP-05 dòng phụ là địa chỉ đầy đủ, không phải đoạn cuối', () {
      final t = _tournament(
        venueName: 'Câu Lạc Bộ Tennis Khang An',
        locationAddress: _address,
        city: _city,
        locationConfig: _staleConfig,
      );
      final lines = TournamentLocationFormatter.tournamentLocationLines(t);
      expect(lines.title, 'Câu Lạc Bộ Tennis Khang An');
      expect(lines.subtitle, _address);
    });

    test('TC-LOC-APP-06 không có tên sân: đoạn đầu làm tiêu đề, phần còn lại làm dòng phụ', () {
      final t = _tournament(locationAddress: '12 Lê Lợi, Quận 1', city: _city);
      final lines = TournamentLocationFormatter.tournamentLocationLines(t);
      expect(lines.title, '12 Lê Lợi');
      expect(lines.subtitle, 'Quận 1, $_city');
    });

    test('TC-LOC-APP-07 chỉ có tên sân: dòng phụ rỗng, không lặp lại tên sân', () {
      final lines = TournamentLocationFormatter.tournamentLocationLines(_tournament(venueName: 'Sân A'));
      expect(lines.title, 'Sân A');
      expect(lines.subtitle, '');
    });

    test('TC-LOC-APP-08 không có địa điểm: cả hai dòng rỗng', () {
      final lines = TournamentLocationFormatter.tournamentLocationLines(_tournament());
      expect(lines.title, '');
      expect(lines.subtitle, '');
    });
  });
}
