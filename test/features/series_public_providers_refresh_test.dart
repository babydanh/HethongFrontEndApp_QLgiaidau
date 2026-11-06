import 'package:app_quanly_giaidau/core/di/core_di_providers.dart';
import 'package:app_quanly_giaidau/features/series/screens/series_detail_screen.dart';
import 'package:app_quanly_giaidau/features/series/screens/series_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_api_adapter.dart';

ProviderContainer _container(FakeApiAdapter adapter) {
  final container = ProviderContainer(
    overrides: [dioClientProvider.overrideWithValue(fakeDioClient(adapter))],
  );
  addTearDown(container.dispose);
  return container;
}

int _gets(FakeApiAdapter adapter, String path) =>
    adapter.requests.where((r) => r.method == 'GET' && r.path == path).length;

void main() {
  setUpAll(() {
    dotenv.loadFromString(envString: 'API_BASE_URL=https://api.example.test');
  });

  group('public series providers do not serve stale data', () {
    test('TC-SERIESFRESH-01 the list is fetched again after it was left', () async {
      final adapter = FakeApiAdapter({
        'GET /series': const FakeReply(200, {'data': []}),
      });
      final container = _container(adapter);

      final first = container.listen(seriesListProvider, (_, _) {});
      await container.read(seriesListProvider.future);
      first.close();
      await Future<void>.delayed(Duration.zero);

      container.listen(seriesListProvider, (_, _) {});
      await container.read(seriesListProvider.future);

      expect(_gets(adapter, '/series'), 2);
    });

    test('TC-SERIESFRESH-02 the detail is fetched again after it was left', () async {
      final adapter = FakeApiAdapter({
        'GET /series/demo': const FakeReply(200, {
          'data': {
            'series': {'id': 's-1', 'name': 'Demo', 'slug': 'demo'},
          },
        }),
      });
      final container = _container(adapter);

      final first = container.listen(seriesDetailProvider('demo'), (_, _) {});
      await container.read(seriesDetailProvider('demo').future);
      first.close();
      await Future<void>.delayed(Duration.zero);

      container.listen(seriesDetailProvider('demo'), (_, _) {});
      await container.read(seriesDetailProvider('demo').future);

      expect(_gets(adapter, '/series/demo'), 2);
    });

    test('TC-SERIESFRESH-03 invalidating the family reloads every open detail', () async {
      final adapter = FakeApiAdapter({
        'GET /series/demo': const FakeReply(200, {
          'data': {
            'series': {'id': 's-1', 'name': 'Demo', 'slug': 'demo'},
          },
        }),
      });
      final container = _container(adapter);

      container.listen(seriesDetailProvider('demo'), (_, _) {});
      await container.read(seriesDetailProvider('demo').future);
      container.invalidate(seriesDetailProvider);
      await container.read(seriesDetailProvider('demo').future);

      expect(_gets(adapter, '/series/demo'), 2);
    });
  });
}
