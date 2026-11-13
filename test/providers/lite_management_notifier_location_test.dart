import 'package:app_quanly_giaidau/core/di/core_di_providers.dart';
import 'package:app_quanly_giaidau/providers/lite_management_notifier.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_api_adapter.dart';

const _id = 't1';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  dotenv.loadFromString(
    envString: 'API_BASE_URL=https://api.example.test/api/v1',
  );

  // TC-VENUE-TEXT-APP-01
  test('saving the location twice upserts one venue instead of creating '
      'a new venue row each time', () async {
    final adapter = FakeApiAdapter({
      'GET /tournaments/$_id': const FakeReply(200, {
        'data': {
          'id': _id,
          'name': 'Giải Lite',
          'matchType': 'DOUBLES',
          'status': 'REGISTRATION',
          'tournamentConfig': {'isLite': true},
          'divisions': [
            {'id': 'd1', 'matchType': 'DOUBLES'},
          ],
        },
      }),
      'GET /tournaments/lite/$_id/participants': const FakeReply(200, {
        'data': [],
      }),
      'PATCH /tournaments/$_id': const FakeReply(200, {}),
      'PATCH /tournaments/$_id/venue': const FakeReply(200, {}),
      'POST /tournaments/$_id/venues': const FakeReply(201, {}),
    });
    final container = ProviderContainer(
      overrides: [dioClientProvider.overrideWithValue(fakeDioClient(adapter))],
    );
    addTearDown(container.dispose);
    final notifier = container.read(liteManagementProvider.notifier);
    await notifier.init(_id);

    expect(
      await notifier.updateLocation(
        _id,
        venueName: ' Sân A ',
        locationAddress: ' 1 Lê Lợi ',
      ),
      isTrue,
    );
    expect(
      await notifier.updateLocation(
        _id,
        venueName: 'Sân A',
        locationAddress: '1 Lê Lợi, Q.1',
      ),
      isTrue,
    );

    final venueCalls = adapter.requests
        .where((r) => r.path.startsWith('/tournaments/$_id/venue'))
        .toList();
    expect(venueCalls.map((r) => '${r.method} ${r.path}'), [
      'PATCH /tournaments/$_id/venue',
      'PATCH /tournaments/$_id/venue',
    ]);
    expect(adapter.postsTo('/tournaments/$_id/venues'), isEmpty);
    expect(venueCalls.first.body, {
      'name': 'Sân A',
      'locationAddress': '1 Lê Lợi',
    });
    expect(venueCalls.last.body, {
      'name': 'Sân A',
      'locationAddress': '1 Lê Lợi, Q.1',
    });

    // The save badge resets after 2.5 s; wait so no timer outlives the test.
    await Future<void>.delayed(const Duration(milliseconds: 2600));
  });
}
