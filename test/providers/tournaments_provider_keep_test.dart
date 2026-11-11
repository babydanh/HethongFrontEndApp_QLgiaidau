import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // TC-EXPLORE-KEEP-01: leaving the Explore tab removes the last listener of
  // `tournamentsProvider`. The list must survive that, otherwise coming back
  // shows an empty "new tournaments" block until every page is fetched again.
  test('TC-EXPLORE-KEEP-01 keeps the list after the last listener leaves', () async {
    final container = ProviderContainer(
      overrides: [
        tournamentsProvider.overrideWith(
          (ref) => Stream.value(const <Tournament>[]),
        ),
      ],
    );
    addTearDown(container.dispose);

    final subscription = container.listen(tournamentsProvider, (_, _) {});
    await container.read(tournamentsProvider.future);
    subscription.close();
    await Future<void>.delayed(Duration.zero);

    expect(container.read(tournamentsProvider).hasValue, isTrue);
  });
}
