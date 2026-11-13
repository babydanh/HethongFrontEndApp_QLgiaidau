import 'package:app_quanly_giaidau/core/utils/tournament_location_formatter.dart';
import 'package:app_quanly_giaidau/data/models/community_tournament_model.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:flutter_test/flutter_test.dart';

const _address = '18A Đường Phan Văn Trị, Phường 10, Phường Gò Vấp, Thành phố Hồ Chí Minh';
const _city = 'Thành phố Hồ Chí Minh';

// Hình dạng như API Backend: `venue` là {id, name, locationAddress} hoặc null.
Map<String, dynamic> _json({
  Object? venue,
  String? locationAddress,
  String? city,
  Map<String, dynamic>? location,
}) => {
  'name': 'Giải thử',
  'sport': 'tennis',
  'format': 'single_elimination',
  'venue': venue,
  if (locationAddress != null) 'locationAddress': locationAddress,
  if (city != null) 'city': city,
  if (location != null) 'tournamentConfig': {'location': location},
};

Tournament _parse(Map<String, dynamic> json) => Tournament.fromJson(json, 't1');

const _staleLocation = <String, dynamic>{
  'venueName': 'Sân tạm',
  'address': 'ádasd',
  'province': 'ádasd',
};

void main() {
  group('Tournament.fromJson địa điểm', () {
    test('TC-LOC-APP-09 venue đủ tên + địa chỉ: lấy của venue, bỏ địa chỉ riêng và snapshot', () {
      final t = _parse(_json(
        venue: {'id': 'v1', 'name': 'Sân Khang An', 'locationAddress': _address},
        locationAddress: 'địa chỉ riêng cũ',
        city: _city,
        location: _staleLocation,
      ));
      expect(t.venueName, 'Sân Khang An');
      expect(t.locationAddress, _address);
      expect(TournamentLocationFormatter.tournamentFullLocation(t), 'Sân Khang An, $_address');
    });

    test('TC-LOC-APP-10 venue null: dùng địa chỉ riêng + thành phố', () {
      final t = _parse(_json(locationAddress: _address, city: _city, location: _staleLocation));
      expect(t.venueName, isNull);
      expect(TournamentLocationFormatter.tournamentFullLocation(t), _address);
    });

    test('TC-LOC-APP-11 venue chỉ có tên: không lấy địa chỉ riêng lẫn vào, thêm thành phố', () {
      final t = _parse(_json(
        venue: {'id': 'v1', 'name': 'Sân A'},
        locationAddress: 'địa chỉ riêng cũ',
        city: 'Hà Nội',
      ));
      expect(t.locationAddress, isNull);
      expect(TournamentLocationFormatter.tournamentFullLocation(t), 'Sân A, Hà Nội');
    });

    test('TC-LOC-APP-12 venue rỗng/khoảng trắng coi như không có sân', () {
      final t = _parse(_json(
        venue: {'id': 'v1', 'name': '  ', 'locationAddress': ''},
        locationAddress: '  12 Lê Lợi ',
        city: 'Hà Nội',
      ));
      expect(t.venueName, isNull);
      expect(t.locationAddress, '12 Lê Lợi');
      expect(TournamentLocationFormatter.tournamentFullLocation(t), '12 Lê Lợi, Hà Nội');
    });

    test('TC-LOC-APP-13 city trùng đoạn cuối địa chỉ (khác cách viết): không lặp', () {
      final t = _parse(_json(locationAddress: '12 Lê Lợi, Phường 1, TP. Hồ Chí Minh', city: _city));
      expect(TournamentLocationFormatter.tournamentFullLocation(t), '12 Lê Lợi, Phường 1, TP. Hồ Chí Minh');
    });

    test('TC-LOC-APP-14 không có venue/địa chỉ/city: chỉ khi đó dùng snapshot, thứ tự như Web', () {
      final t = _parse(_json(location: {
        'display': 'Cụm sân X',
        'venueName': 'Sân X',
        'address': '5 Trần Phú',
        'province': 'Đà Nẵng',
      }));
      expect(TournamentLocationFormatter.tournamentFullLocation(t), 'Sân X, 5 Trần Phú, Đà Nẵng, Cụm sân X');
    });
  });

  group('TournamentLocationFormatter rút gọn và trận', () {
    test('TC-LOC-APP-15 rút gọn lấy 2 phần cuối của danh sách đã chuẩn hoá, không lấy snapshot', () {
      final t = _parse(_json(
        venue: {'id': 'v1', 'name': 'Sân Khang An', 'locationAddress': _address},
        city: _city,
        location: _staleLocation,
      ));
      expect(TournamentLocationFormatter.tournamentShortLocation(t), 'Phường Gò Vấp, Thành phố Hồ Chí Minh');
    });

    test('TC-LOC-APP-16 trận: sân + địa chỉ sân, không trộn snapshot khi đã có sân', () {
      final t = _parse(_json(
        venue: {'id': 'v1', 'name': 'Sân A', 'locationAddress': '1 Lê Lợi'},
        location: _staleLocation,
      ));
      expect(
        TournamentLocationFormatter.matchFullLocation(tournament: t, courtName: 'Sân 2', courtAddress: '1 Lê Lợi'),
        'Sân 2, 1 Lê Lợi, Sân A',
      );
      expect(
        TournamentLocationFormatter.matchFullLocationFromConfig(
          courtName: 'Sân 2',
          courtAddress: '1 Lê Lợi',
          tournamentConfig: {'location': _staleLocation},
        ),
        'Sân 2, 1 Lê Lợi',
      );
    });

    test('TC-LOC-APP-17 trận không có sân nào: mới dùng snapshot cũ', () {
      expect(
        TournamentLocationFormatter.matchFullLocationFromConfig(
          courtName: '',
          courtAddress: null,
          tournamentConfig: {
            'location': {'address': '5 Trần Phú', 'province': 'Đà Nẵng'},
          },
        ),
        '5 Trần Phú, Đà Nẵng',
      );
    });
  });

  group('CommunityTournamentModel địa điểm', () {
    test('TC-LOC-APP-18 thẻ giải CLB hiện tên sân + địa chỉ sân như Web, bỏ địa chỉ riêng', () {
      final m = CommunityTournamentModel.fromJson({
        'id': 't1',
        'name': 'Giải CLB',
        'venue': {'id': 'v1', 'name': 'Sân Khang An', 'locationAddress': _address},
        'locationAddress': 'địa chỉ riêng cũ',
        'city': _city,
      });
      expect(m.fullLocation, 'Sân Khang An, $_address');
    });

    test('TC-LOC-APP-19 thẻ giải CLB không gắn sân: địa chỉ riêng + city; venue null an toàn', () {
      final m = CommunityTournamentModel.fromJson({
        'id': 't1',
        'name': 'Giải CLB',
        'venue': null,
        'locationAddress': '12 Lê Lợi',
        'city': 'Hà Nội',
      });
      expect(m.fullLocation, '12 Lê Lợi, Hà Nội');
    });
  });
}
