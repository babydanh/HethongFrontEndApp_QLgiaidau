import 'package:app_quanly_giaidau/domain/entities/user.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UserProfile.fromJson', () {
    test('merges the nested profile; top-level fields win', () {
      final profile = UserProfile.fromJson({
        'id': 'top',
        'email': 'a@b.vn',
        'fullName': 'Top-level',
        'profile': {
          'id': 'nested',
          'fullName': 'Nested',
          'bio': 'từ profile',
          'provinceCode': '79',
        },
      });

      expect(profile.id, 'top');
      expect(profile.fullName, 'Top-level');
      expect(profile.bio, 'từ profile');
      expect(profile.provinceCode, '79');
    });

    test('a flat body works and missing id becomes empty', () {
      final profile = UserProfile.fromJson({'fullName': 'Phẳng'});

      expect(profile.id, '');
      expect(profile.fullName, 'Phẳng');
      expect(profile.roles, isEmpty);
      expect(profile.isEmailVerified, isNull);
    });

    test('booleans accept bool, 0/1 and true/1 strings; junk becomes null',
        () {
      bool? flag(Object? value) =>
          UserProfile.fromJson({'isEmailVerified': value}).isEmailVerified;

      expect(flag(true), isTrue);
      expect(flag(false), isFalse);
      expect(flag(1), isTrue);
      expect(flag(0), isFalse);
      expect(flag('TRUE'), isTrue);
      expect(flag('1'), isTrue);
      expect(flag('no'), isFalse);
      expect(flag(null), isNull);
      expect(flag(const <String>[]), isNull);
    });

    test('elo points accept int, double and numeric strings', () {
      int? elo(Object? value) =>
          UserProfile.fromJson({'eloPoints': value}).eloPoints;

      expect(elo(1500), 1500);
      expect(elo(1499.9), 1499);
      expect(elo('1200'), 1200);
      expect(elo('abc'), isNull);
      expect(elo(null), isNull);
    });

    test('roles are stringified and the single role is kept', () {
      final profile = UserProfile.fromJson({
        'role': 'admin',
        'roles': ['ORGANIZER', 7],
      });

      expect(profile.role, 'admin');
      expect(profile.roles, ['ORGANIZER', '7']);
    });
  });

  group('UserProfile behaviour', () {
    test('hasRole is case/space insensitive over role and roles', () {
      final profile = UserProfile.fromJson({
        'role': ' Admin ',
        'roles': ['organizer'],
      });

      expect(profile.hasRole('ADMIN'), isTrue);
      expect(profile.hasRole(' Organizer '), isTrue);
      expect(profile.hasRole('REFEREE'), isFalse);
      expect(const UserProfile(id: 'x').hasRole('ADMIN'), isFalse);
    });

    test('toJson omits null fields and copyWith overrides only given ones',
        () {
      const profile = UserProfile(id: 'u1', fullName: 'An', bio: 'hi');

      final json = profile.toJson();
      final copy = profile.copyWith(bio: 'mới', provinceCode: '01');

      expect(json, {'id': 'u1', 'fullName': 'An', 'bio': 'hi'});
      expect(copy.bio, 'mới');
      expect(copy.provinceCode, '01');
      expect(copy.fullName, 'An');
      expect(copy.id, 'u1');
      expect(profile.toString(), contains('u1'));
    });
  });

  group('UserPublicProfile.fromJson', () {
    test('defaults, systemRole fallback and verified flag', () {
      final profile = UserPublicProfile.fromJson({
        'id': 'u1',
        'fullName': 'Công khai',
        'systemRole': 'PLAYER',
        'isVerified': true,
      });
      final bare = UserPublicProfile.fromJson({});

      expect(profile.role, 'PLAYER');
      expect(profile.isVerified, isTrue);
      expect(bare.id, '');
      expect(bare.isVerified, isFalse);
      expect(bare.ranks, isEmpty);
      expect(bare.achievements, isEmpty);
    });

    test('pair ranks join the singles ranks and default to DOUBLES', () {
      final profile = UserPublicProfile.fromJson({
        'ranks': [
          {'categoryId': 'c1', 'matchType': 'singles', 'eloPoints': 1200},
        ],
        'pairRanks': [
          {'categoryId': 'c1', 'eloPoints': 1300, 'partnerName': 'Bình'},
        ],
      });

      expect(profile.ranks.map((r) => r.matchType), ['SINGLES', 'DOUBLES']);
      expect(profile.ranks.last.isDoubles, isTrue);
      expect(profile.ranks.last.partnerName, 'Bình');
    });

    test('achievements parse with defaults', () {
      final profile = UserPublicProfile.fromJson({
        'achievements': [
          {'tournamentId': 't1', 'tournamentName': 'Cúp A', 'rank': 1},
          <String, dynamic>{},
        ],
      });

      expect(profile.achievements.first.rank, 1);
      expect(profile.achievements.last.tournamentName, 'Giải đấu');
      expect(profile.achievements.last.tournamentId, '');
    });
  });

  group('UserPublicRank', () {
    test('reads nested category/tier and snake_case aliases', () {
      final rank = UserPublicRank.fromJson({
        'category': {'id': 'c9', 'name': 'Pickleball'},
        'tier': {'name': 'Vàng'},
        'elo_points': '1750',
        'totalMatches': 10,
        'wins': 6,
        'match_type': 'mixed_doubles',
        'gender_restriction': 'mixed',
        'peak_elo': 1800,
        'shield_active': true,
        'current_streak_type': 'win',
        'current_streak_count': 3,
      });

      expect(rank.categoryId, 'c9');
      expect(rank.categoryName, 'Pickleball');
      expect(rank.tierName, 'Vàng');
      expect(rank.eloPoints, 1750);
      expect(rank.matchesPlayed, 10);
      expect(rank.matchesWon, 6);
      expect(rank.matchType, 'MIXED_DOUBLES');
      expect(rank.genderRestriction, 'MIXED');
      expect(rank.peakElo, 1800);
      expect(rank.shieldActive, isTrue);
      expect(rank.currentStreakType, 'WIN');
      expect(rank.currentStreakCount, 3);
      expect(rank.tierSource, 'ELO');
      expect(rank.isDoubles, isTrue);
    });

    test('leaderboard eligibility needs a played match or the admin flag in '
        'any accepted spelling', () {
      bool eligible(Map<String, dynamic> json) =>
          UserPublicRank.fromJson(json).isLeaderboardEligible;

      expect(eligible({}), isFalse);
      expect(eligible({'matchesPlayed': 1}), isTrue);
      expect(eligible({'adminLeaderboardEligible': true}), isTrue);
      expect(eligible({'admin_leaderboard_eligible': 1}), isTrue);
      expect(eligible({'adminLeaderboardEligible': 'TRUE'}), isTrue);
      expect(eligible({'adminLeaderboardEligible': 'no'}), isFalse);
    });

    test('peak elo stays null when absent, and singles are not doubles', () {
      final rank = UserPublicRank.fromJson({'matchType': 'singles'});

      expect(rank.peakElo, isNull);
      expect(rank.isDoubles, isFalse);
      expect(rank.hasPlayed, isFalse);
    });
  });

  group('UserSearchResult.fromJson', () {
    test('accepts id/userId and fullName/name', () {
      final a = UserSearchResult.fromJson({'id': 'u1', 'fullName': 'An'});
      final b = UserSearchResult.fromJson({
        'userId': 'u2',
        'name': 'Bình',
        'avatarUrl': 'a.png',
      });
      final c = UserSearchResult.fromJson({});

      expect((a.id, a.fullName), ('u1', 'An'));
      expect((b.id, b.fullName, b.avatarUrl), ('u2', 'Bình', 'a.png'));
      expect((c.id, c.fullName), ('', ''));
    });
  });
}
