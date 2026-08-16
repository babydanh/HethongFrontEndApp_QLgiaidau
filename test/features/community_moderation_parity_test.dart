import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final root = Directory.current.path;
  String source(String relative) =>
      File('$root/${relative.replaceAll('/', Platform.pathSeparator)}').readAsStringSync();

  test('community repository exposes pending-post moderation contract', () {
    final contract = source('lib/domain/repositories/community_social_repository.dart');
    final api = source('lib/data/repositories/api/api_community_social_repository.dart');
    expect(contract, contains('getPendingPosts'));
    expect(contract, contains('moderatePost'));
    expect(contract, contains('reportPost'));
    expect(api, contains("/communities/\$communityId/moderation/posts"));
    expect(api, contains("/communities/\$communityId/posts/\$postId/moderation"));
    expect(api, contains("/communities/\$communityId/posts/\$postId/report"));
  });

  test('club management screen renders pending-post moderation actions', () {
    final screen = source('lib/features/community/screens/club_management_screen.dart');
    expect(screen, contains('getPendingPosts'));
    expect(screen, contains('moderatePost'));
    expect(screen, contains('Bài viết chờ duyệt'));
    expect(screen, contains('Duyệt'));
    expect(screen, contains('Từ chối'));
  });
}

// The source assertions intentionally fail until the real contract and UI are wired.
// They protect the Web moderation parity slice without mocking Dio.
void _keepAnalyzerQuiet() {}
