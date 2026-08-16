import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('community post card exposes author profile navigation hook', () {
    final card = File(
      'lib/features/community/social/widgets/community_post_card.dart',
    ).readAsStringSync();
    final screen = File(
      'lib/features/community/social/community_social_screen.dart',
    ).readAsStringSync();

    expect(card, contains('onAuthorTap'));
    expect(card, contains('onAuthorTap'));
    expect(screen, contains('post.authorId'));
    expect(screen, contains("onAuthorTap: post.authorId.isEmpty"));
  });
}
