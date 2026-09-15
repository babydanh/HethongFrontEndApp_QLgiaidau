import 'package:flutter_test/flutter_test.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';

Map<String, dynamic> _tournamentJson({
  bool? isLite,
  Map<String, dynamic>? tournamentConfig,
}) {
  final json = <String, dynamic>{
    'name': 'Test tournament',
    'createdAt': '2026-01-01T00:00:00Z',
    'updatedAt': '2026-01-01T00:00:00Z',
  };
  if (isLite != null) json['isLite'] = isLite;
  if (tournamentConfig != null) json['tournamentConfig'] = tournamentConfig;
  return json;
}

void main() {
  test('classifies Super Lite only with the compact marker', () {
    final tournament = Tournament.fromJson(
      _tournamentJson(
        isLite: true,
        tournamentConfig: {
          'isLite': true,
          'mode': 'LITE',
          'hideAdvancedSettings': true,
        },
      ),
      'super-lite',
    );

    expect(tournament.isLite, isTrue);
    expect(tournament.isSuperLite, isTrue);
  });

  test('keeps configured Lite/Quick out of the compact product', () {
    final tournament = Tournament.fromJson(
      _tournamentJson(
        isLite: true,
        tournamentConfig: {
          'isLite': true,
          'mode': 'LITE',
          'hideAdvancedSettings': false,
        },
      ),
      'configured-lite',
    );

    expect(tournament.isLite, isTrue);
    expect(tournament.isSuperLite, isFalse);
  });

  test('does not infer Lite product from scoring mode alone', () {
    final tournament = Tournament.fromJson(
      _tournamentJson(
        tournamentConfig: {'mode': 'LITE', 'hideAdvancedSettings': false},
      ),
      'advanced',
    );

    expect(tournament.isLite, isFalse);
    expect(tournament.isSuperLite, isFalse);
  });

  test(
    'fails closed when an explicit false flag conflicts with legacy data',
    () {
      final tournament = Tournament.fromJson(
        _tournamentJson(
          isLite: false,
          tournamentConfig: {'mode': 'LITE', 'hideAdvancedSettings': true},
        ),
        'conflicting-product',
      );

      expect(tournament.isLite, isFalse);
      expect(tournament.isSuperLite, isFalse);
    },
  );
}
