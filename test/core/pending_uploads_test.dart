import 'package:app_quanly_giaidau/core/utils/pending_uploads.dart';
import 'package:flutter_test/flutter_test.dart';

(PendingUploads, List<String>) _setup({Set<String> failing = const {}}) {
  final removed = <String>[];
  final pending = PendingUploads((url) async {
    removed.add(url);
    if (failing.contains(url)) throw StateError('boom');
  });
  return (pending, removed);
}

void main() {
  group('PendingUploads', () {
    test(
      'TC-UPLOAD-CLEAN-APP-01 forget removes the tracked url once',
      () async {
        final (pending, removed) = _setup();

        pending.track('logo', 'u1');
        pending.forget('logo');
        pending.forget('logo');
        await pending.discardExcept(const []);

        expect(removed, ['u1']);
      },
    );

    test('TC-UPLOAD-CLEAN-APP-02 a new upload in the same slot removes the '
        'previous one and keeps the new one', () async {
      final (pending, removed) = _setup();

      pending.track('logo', 'a');
      pending.track('logo', 'b');
      expect(removed, ['a']);

      await pending.discardExcept(['b']);
      expect(removed, ['a']);
    });

    test('TC-UPLOAD-CLEAN-APP-03 discardExcept without keep removes every '
        'tracked url and then does nothing', () async {
      final (pending, removed) = _setup();

      pending.track('logo', 'a');
      pending.track('banner', 'b');
      await pending.discardExcept(const []);
      await pending.discardExcept(const []);

      expect(removed, unorderedEquals(['a', 'b']));
    });

    test('TC-UPLOAD-CLEAN-APP-04 discardExcept removes only urls outside '
        'keep', () async {
      final (pending, removed) = _setup();

      pending.track('logo', 'a');
      pending.track('banner', 'b');
      pending.track('gallery-1', 'c');
      await pending.discardExcept(['a', 'c']);

      expect(removed, ['b']);
    });

    test('TC-UPLOAD-CLEAN-APP-05 removal errors are swallowed and the rest '
        'is still removed', () async {
      final (pending, removed) = _setup(failing: {'a'});

      pending.track('logo', 'a');
      pending.track('banner', 'b');
      pending.forget('logo');
      await pending.discardExcept(const []);

      expect(removed, unorderedEquals(['a', 'b']));
    });

    test('TC-UPLOAD-CLEAN-APP-06 never removes untracked urls or the same '
        'url twice', () async {
      final (pending, removed) = _setup();

      pending.forget('logo');
      await pending.discardExcept(['saved']);
      expect(removed, isEmpty);

      pending.track('logo', 'a');
      pending.track('banner', 'a');
      await pending.discardExcept(const []);

      expect(removed, ['a']);
    });
  });
}
