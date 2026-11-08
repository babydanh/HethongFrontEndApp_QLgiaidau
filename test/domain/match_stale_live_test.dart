import 'package:app_quanly_giaidau/domain/entities/match.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _json({Map<String, dynamic> extra = const {}}) => {
  'status': 'ONGOING',
  'updatedAt': '2026-11-01T10:00:00.000Z',
  ...extra,
};

void main() {
  test('TC-SLM-APP-01 fromJson reads isStaleLive and lastActivityAt', () {
    final m = MatchModel.fromJson(
      _json(
        extra: {
          'isStaleLive': true,
          'lastActivityAt': '2026-11-01T08:00:00.000Z',
        },
      ),
      'm1',
    );

    expect(m.isStaleLive, isTrue);
    expect(
      m.lastActivityAt!.isAtSameMomentAs(DateTime.utc(2026, 11, 1, 8)),
      isTrue,
    );
    expect(m.isLive, isTrue);
  });

  test('TC-SLM-APP-02 missing keys (old backend) mean not stale', () {
    final m = MatchModel.fromJson(_json(), 'm1');

    expect(m.isStaleLive, isFalse);
    expect(m.lastActivityAt, isNull);
  });

  test('TC-SLM-APP-02b toJson and copyWith keep the stale fields', () {
    final m = MatchModel.fromJson(
      _json(
        extra: {
          'isStaleLive': true,
          'lastActivityAt': '2026-11-01T08:00:00.000Z',
        },
      ),
      'm1',
    );

    final again = MatchModel.fromJson(m.toJson(), 'm1');
    expect(again.isStaleLive, isTrue);
    expect(again.lastActivityAt!.isAtSameMomentAs(m.lastActivityAt!), isTrue);
    expect(m.copyWith(isStaleLive: false).isStaleLive, isFalse);
    expect(m.copyWith(status: 'COMPLETED').isStaleLive, isTrue);
  });
}
