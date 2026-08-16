import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('community widgets expose poll, tournament and delete hooks', () {
    final card = File('lib/features/community/social/widgets/community_post_card.dart').readAsStringSync();
    final poll = File('lib/features/community/social/widgets/community_poll_widget.dart').readAsStringSync();
    final tournament = File('lib/features/community/social/widgets/community_tournament_preview.dart').readAsStringSync();
    expect(card, contains('onDelete'));
    expect(card, contains('CommunityPollWidget'));
    expect(poll, contains('votePoll'));
    expect(poll, contains('addPollOption'));
    expect(tournament, contains('/intro/'));

  });
}
