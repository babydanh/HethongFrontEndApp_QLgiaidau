import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final root = Directory.current.path;
  String source(String relative) =>
      File('$root/${relative.replaceAll('/', Platform.pathSeparator)}').readAsStringSync();

  test('social screen wires profile and membership authorization to post card', () {
    final screen = source('lib/features/community/social/community_social_screen.dart');
    expect(screen, contains('userProfileProvider'));
    expect(screen, contains('myCommunityMembershipProvider'));
    expect(screen, contains('onDelete:'));
    expect(screen, contains('deletePost'));
    expect(screen, contains('showDialog<bool>'));
  });

  test('edit club exposes exact-name guarded deletion through community route', () {
    final screen = source('lib/features/community/screens/edit_club_screen.dart');
    expect(screen, contains('Vùng nguy hiểm'));
    expect(screen, contains('deleteCommunity'));
    expect(screen, contains('Tên CLB hiện tại'));
    expect(screen, contains("context.go('/club/"));
  });
}
