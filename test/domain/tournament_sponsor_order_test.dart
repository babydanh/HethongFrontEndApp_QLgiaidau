import 'package:app_quanly_giaidau/domain/entities/tournament_sponsor.dart';
import 'package:flutter_test/flutter_test.dart';

TournamentSponsor _sponsor(
  String id, {
  int order = 0,
  String status = 'PUBLISHED',
  bool? isPublic,
}) => TournamentSponsor(
  id: id,
  displayName: id,
  tier: 'GOLD',
  logoUrl: 'https://cdn.example.test/$id.png',
  displayOrder: order,
  status: status,
  isPublic: isPublic,
);

void main() {
  group('sponsorOrderChanges', () {
    test('returns nothing when positions already match displayOrder', () {
      final list = [_sponsor('a', order: 0), _sponsor('b', order: 1)];
      expect(sponsorOrderChanges(list), isEmpty);
    });

    test('returns only the sponsors whose position changed', () {
      // b was dragged above a; c did not move.
      final list = [
        _sponsor('b', order: 1),
        _sponsor('a', order: 0),
        _sponsor('c', order: 2),
      ];
      expect(sponsorOrderChanges(list), {'b': 0, 'a': 1});
    });

    test('renumbers sponsors that all share the default order 0', () {
      final list = [_sponsor('a'), _sponsor('b'), _sponsor('c')];
      expect(sponsorOrderChanges(list), {'b': 1, 'c': 2});
    });
  });

  group('visibility getters', () {
    test('published and public sponsor is shown publicly', () {
      expect(_sponsor('a').isShownPublicly, isTrue);
      expect(_sponsor('a', isPublic: true).isShownPublicly, isTrue);
    });

    test('draft, hidden flag and archived sponsors are not shown', () {
      expect(_sponsor('a', status: 'DRAFT').isShownPublicly, isFalse);
      expect(_sponsor('a', isPublic: false).isShownPublicly, isFalse);
      final archived = _sponsor('a', status: 'ARCHIVED');
      expect(archived.isArchived, isTrue);
      expect(archived.isShownPublicly, isFalse);
    });
  });
}
