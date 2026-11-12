import 'package:app_quanly_giaidau/data/models/social_place.dart';
import 'package:app_quanly_giaidau/data/models/social_session_model.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _base([Map<String, dynamic> extra = const {}]) => {
  'id': 's1',
  'title': 'Kèo tối',
  'startAt': '2026-06-01T10:00:00',
  ...extra,
};

void main() {
  group('SocialParticipantModel', () {
    test('a guest is identified by guestName and addressed by row id', () {
      final guest = SocialParticipantModel.fromJson({
        'id': 'row-1',
        'guest_name': '  Khách A  ',
      });

      expect(guest.isGuest, isTrue);
      expect(guest.name, 'Khách A');
      expect(guest.userId, 'row-1'); // userId falls back to the row id
      expect(guest.apiIdentifier, 'row-1');
    });

    test('a member is addressed by userId and shows the full name', () {
      final member = SocialParticipantModel.fromJson({
        'id': 'row-2',
        'userId': 'u-2',
        'fullName': ' Nguyễn Văn An ',
        'role': 'host',
        'paymentStatus': 'paid',
        'ticketCount': 2,
        'status': 'requested',
      });

      expect(member.isGuest, isFalse);
      expect(member.apiIdentifier, 'u-2');
      expect(member.isHost, isTrue);
      expect(member.paymentStatus, 'PAID');
      expect(member.ticketCount, 2);
      expect(member.isRequested, isTrue);
      expect(member.initials, 'NA');
    });

    test(
      'defaults: name "Thành viên", initials from one word, skill level',
      () {
        final anon = SocialParticipantModel.fromJson({'id': 'x'});
        final single = SocialParticipantModel.fromJson({
          'id': 'y',
          'name': 'an',
          'skillLevel': '3.5',
        });

        expect(anon.name, 'Thành viên');
        expect(anon.role, 'PLAYER');
        expect(anon.status, 'JOINED');
        expect(anon.paymentStatus, 'UNPAID');
        expect(anon.skillLevel, 'Tất cả trình độ');
        expect(single.initials, 'A');
        expect(single.skillLevel, '3.5');
      },
    );

    test('isHost flag in JSON promotes the role when none is given', () {
      expect(
        SocialParticipantModel.fromJson({'id': 'h', 'isHost': true}).isHost,
        isTrue,
      );
    });

    test('toJson omits null optionals and copyWith overrides only given '
        'fields', () {
      final p = SocialParticipantModel.fromJson({
        'id': 'p1',
        'userId': 'u1',
        'joinedAt': '2026-05-01T00:00:00Z',
      });

      final json = p.toJson();
      final copy = p.copyWith(paymentStatus: 'PAID');

      expect(json.containsKey('guestName'), isFalse);
      expect(json.containsKey('avatarUrl'), isFalse);
      expect(json['joinedAt'], '2026-05-01T00:00:00.000Z');
      expect(copy.paymentStatus, 'PAID');
      expect(copy.userId, 'u1');
    });
  });

  group('SocialChatMessageModel.fromJson', () {
    test('derives initials from the nested sender and reads aliases', () {
      final m = SocialChatMessageModel.fromJson({
        'id': 'm1',
        'sender': {'fullName': 'Lê Thị Bình', 'avatarUrl': 'https://a/b.png'},
        'content': 'chào',
        'createdAt': '2026-06-01T09:00:00Z',
        'isHost': true,
      });

      expect(m.senderName, 'Lê Thị Bình');
      expect(m.senderInitials, 'LB');
      expect(m.senderAvatar, 'https://a/b.png');
      expect(m.message, 'chào');
      expect(m.time, DateTime.utc(2026, 6, 1, 9));
      expect(m.isHost, isTrue);
      expect(m.isMe, isFalse);
    });

    test('falls back to "Thành viên"/TM initials and an embedded session', () {
      final m = SocialChatMessageModel.fromJson({
        'id': 'm2',
        'message': 'xem kèo',
        'sharedSession': _base(),
      });

      expect(m.senderName, 'Thành viên');
      expect(m.senderInitials, 'TV'); // "Thành viên" has two words → T + V
      expect(m.sharedSession?.id, 's1');
      expect(m.toJson()['sharedSession'], isA<Map>());
    });

    test('a single-word sender gets one initial; blank gets TV', () {
      expect(
        SocialChatMessageModel.fromJson({
          'id': 'a',
          'senderName': 'minh',
        }).senderInitials,
        'M',
      );
      expect(
        SocialChatMessageModel.fromJson({
          'id': 'b',
          'senderName': '   ',
        }).senderInitials,
        'TV',
      );
    });
  });

  group('SocialMatchModel.fromJson', () {
    test('uses documented defaults for missing fields', () {
      final m = SocialMatchModel.fromJson({'id': 'm'});

      expect(m.courtName, 'Sân 1');
      expect(m.matchType, 'Đánh đôi');
      expect(m.status, 'Chưa diễn ra');
      expect(m.score, isNull);
    });
  });

  group('SocialSessionModel.fromJson', () {
    test('applies defaults and derives the sport display name', () {
      final s = SocialSessionModel.fromJson(_base());

      expect(s.sport, 'pickleball');
      expect(s.sportName, 'Pickleball');
      expect(s.maxSlots, 6);
      expect(s.durationMinutes, 120);
      expect(s.status, 'OPEN');
      expect(s.visibility, 'PUBLIC');
      expect(s.levelRequirement, 'ALL');
      expect(s.skillLevel, 'Tất cả trình độ');
      expect(s.isLocationDeferred, isFalse);
    });

    test('maps sport keys to names and keeps unknown keys verbatim', () {
      String nameFor(String sport) =>
          SocialSessionModel.fromJson(_base({'sport': sport})).sportName;

      expect(nameFor('TENNIS'), 'Tennis');
      expect(nameFor('badminton'), 'Cầu lông');
      expect(nameFor('padel'), 'padel');
      expect(
        SocialSessionModel.fromJson(
          _base({'sport': 'tennis', 'sportName': 'Quần vợt'}),
        ).sportName,
        'Quần vợt',
      );
    });

    test('reads legacy aliases for slots, fee, duration and host', () {
      final s = SocialSessionModel.fromJson(
        _base({
          'maxParticipants': 8,
          'currentParticipants': 3,
          'pricePerSlot': 50000,
          'durationHours': 1.5,
          'creatorId': 'host-1',
          'notes': 'mang vợt',
          'skillLevel': '3.0',
          'hostPhone': '0900',
        }),
      );

      expect(s.maxSlots, 8);
      expect(s.currentSlots, 3);
      expect(s.feePerSlot, 50000);
      expect(s.durationMinutes, 90);
      expect(s.hostUserId, 'host-1');
      expect(s.description, 'mang vợt');
      expect(s.levelRequirement, '3.0');
      expect(s.contactPhone, '0900');
    });

    test('currentSlots sums tickets of JOINED participants when absent', () {
      final s = SocialSessionModel.fromJson(
        _base({
          'participants': [
            {'id': 'a', 'status': 'JOINED', 'ticketCount': 2},
            {'id': 'b', 'status': 'JOINED'},
            {'id': 'c', 'status': 'REQUESTED', 'ticketCount': 5},
          ],
        }),
      );

      expect(s.currentSlots, 3);
      expect(s.participants.map((p) => p.id), ['a', 'b']);
      expect(s.requestedParticipants.map((p) => p.id), ['c']);
    });

    test('merges requested rows from every source, deduped by id', () {
      final s = SocialSessionModel.fromJson(
        _base({
          'requests': [
            {'id': 'r1', 'status': 'REQUESTED'},
            {'id': 'jx', 'status': 'JOINED'},
          ],
          'participants': [
            {'id': 'r1', 'status': 'PENDING'},
            {'id': 'r2', 'status': 'PENDING'},
          ],
        }),
      );

      expect(s.requestedParticipants.map((p) => p.id).toSet(), {'r1', 'r2'});
      expect(s.requestedParticipants, hasLength(2));
    });

    test(
      'isPending follows joinRequestStatus when present, else isPending',
      () {
        bool pending(Map<String, dynamic> extra) =>
            SocialSessionModel.fromJson(_base(extra)).isPending;

        expect(pending({'joinRequestStatus': 'requested'}), isTrue);
        expect(pending({'joinRequestStatus': 'REJECTED'}), isFalse);
        expect(
          pending({'joinRequestStatus': null, 'isPending': true}),
          isFalse,
        );
        expect(pending({'isPending': true}), isTrue);
        // A joined viewer is never "pending".
        expect(
          pending({'isJoined': true, 'joinRequestStatus': 'REQUESTED'}),
          isFalse,
        );
      },
    );

    test('distance prefers meters, falls back to km, and formats both', () {
      final meters = SocialSessionModel.fromJson(
        _base({'distanceMeters': 420}),
      );
      final far = SocialSessionModel.fromJson(_base({'distance_m': '1500'}));
      final km = SocialSessionModel.fromJson(_base({'distanceKm': 0.5}));
      final none = SocialSessionModel.fromJson(_base());

      expect(meters.distanceDisplay, '420 m');
      expect(meters.distanceKm, closeTo(0.42, 1e-9));
      expect(far.distanceDisplay, '1.5 km');
      expect(km.distanceDisplay, '500 m');
      expect(
        SocialSessionModel.fromJson(
          _base({'distanceKm': 2.34}),
        ).distanceDisplay,
        '2.3 km',
      );
      expect(none.distanceDisplay, '');
    });

    test('coordinates accept numbers and numeric strings', () {
      final s = SocialSessionModel.fromJson(
        _base({'latitude': '10.5', 'longitude': 106.7}),
      );
      final bad = SocialSessionModel.fromJson(_base({'latitude': 'abc'}));

      expect(s.latitude, 10.5);
      expect(s.longitude, 106.7);
      expect(bad.latitude, isNull);
    });

    test('community comes from the nested object and supplies the club id', () {
      final s = SocialSessionModel.fromJson(
        _base({
          'community': {'id': 'c9', 'name': 'CLB Chín', 'logoUrl': 'l.png'},
        }),
      );

      expect(s.communityId, 'c9');
      expect(s.clubId, 'c9');
      expect(s.hostClubName, 'CLB Chín');
      expect(s.hostClubAvatar, 'l.png');
    });

    test('hostClubName falls back to the host participant, then "Host"', () {
      final withHost = SocialSessionModel.fromJson(
        _base({
          'participants': [
            {'id': 'h', 'role': 'HOST', 'fullName': 'Chủ kèo'},
          ],
        }),
      );

      expect(withHost.hostClubName, 'Chủ kèo');
      expect(SocialSessionModel.fromJson(_base()).hostClubName, 'Host');
    });

    test('shareUrl only exists for a well-formed short code', () {
      String? urlFor(String? code) =>
          SocialSessionModel.fromJson(_base({'shortCode': code})).shareUrl;

      expect(urlFor('AbCd1234'), 'https://sporto.asia/s/AbCd1234');
      expect(urlFor(' AbCd1234 '), 'https://sporto.asia/s/AbCd1234');
      expect(urlFor('short'), isNull);
      expect(urlFor('has space in it'), isNull);
      expect(urlFor(null), isNull);
    });

    test('payments derive the amount from tickets × fee per slot', () {
      final s = SocialSessionModel.fromJson(
        _base({
          'feePerSlot': 40000,
          'participants': [
            {
              'id': 'p1',
              'userId': 'u1',
              'ticketCount': 3,
              'paymentStatus': 'PAID',
              'fullName': 'An',
            },
          ],
        }),
      );

      final payment = s.payments.single;

      expect(payment.id, 'pay_p1');
      expect(payment.participantId, 'u1');
      expect(payment.totalAmount, 120000);
      expect(payment.status, 'PAID');
    });

    test('Vietnamese weekday and date labels follow the local start time', () {
      // 2026-06-01 is a Monday.
      final s = SocialSessionModel.fromJson(
        _base(),
      ).copyWith(startAt: DateTime(2026, 6, 1, 7, 5));

      expect(s.timeSlot, '07:05');
      expect(s.dateDisplay, '07:05 T2, 1/6');
      expect(s.fullDateTimeDisplay, 'Thứ hai 01/06/2026 vào lúc 07:05');
      expect(s.dayOfWeek, 'T2');
      expect(s.dayOfMonth, 1);
    });

    test('a deferred location is recognised only with no coordinates', () {
      final deferred = SocialSessionModel.fromJson(
        _base({
          'venueName': SocialPlace.deferredLabel,
          'venueAddress': SocialPlace.deferredLabel,
        }),
      );
      final pinned = deferred.copyWith(latitude: 1, longitude: 2);

      expect(deferred.isLocationDeferred, isTrue);
      expect(pinned.isLocationDeferred, isFalse);
    });

    test('toJson round-trips the fields the UI re-reads', () {
      final s = SocialSessionModel.fromJson(
        _base({
          'shortCode': 'AbCd1234',
          'feePerSlot': 10000,
          'latitude': 1.5,
          'longitude': 2.5,
          'distanceKm': 3,
          'bracketTournamentId': 't1',
          'isHost': true,
        }),
      );

      final again = SocialSessionModel.fromJson(s.toJson());

      expect(again.shortCode, 'AbCd1234');
      expect(again.feePerSlot, 10000);
      expect(again.latitude, 1.5);
      expect(again.distanceKm, 3);
      expect(again.bracketTournamentId, 't1');
      expect(again.isHost, isTrue);
    });

    test('copyWith keeps untouched fields', () {
      final s = SocialSessionModel.fromJson(_base({'maxSlots': 9}));

      final copy = s.copyWith(title: 'Mới');

      expect(copy.title, 'Mới');
      expect(copy.maxSlots, 9);
      expect(copy.id, 's1');
    });
  });

  group('CreateSocialSessionRequest.toJson', () {
    CreateSocialSessionRequest build({
      bool deferred = false,
      String? venueId,
      String? description,
      String? phone,
      String? zalo,
      String? communityId,
    }) => CreateSocialSessionRequest(
      sport: 'pickleball',
      title: 'Kèo',
      description: description,
      startAt: DateTime.utc(2026, 6, 1, 10),
      venueName: 'Sân A',
      venueAddress: '1 Lê Lợi',
      latitude: 10.1,
      longitude: 106.2,
      locationDeferred: deferred,
      venueId: venueId,
      contactPhone: phone,
      zaloGroupUrl: zalo,
      communityId: communityId,
    );

    test('a new pinned venue is sent as newVenue with the start offset', () {
      final json = build().toJson();

      expect(json['startAt'], '2026-06-01T10:00:00+00:00');
      expect(json['newVenue'], {
        'name': 'Sân A',
        'locationAddress': '1 Lê Lợi',
        'latitude': 10.1,
        'longitude': 106.2,
      });
      expect(json.containsKey('venueId'), isFalse);
      expect(json.containsKey('locationDeferred'), isFalse);
    });

    test('a saved venue sends venueId and no newVenue', () {
      final json = build(venueId: 'v1').toJson();

      expect(json['venueId'], 'v1');
      expect(json['venueName'], 'Sân A');
      expect(json.containsKey('newVenue'), isFalse);
    });

    test('a deferred location sends only the flag, even with a venueId', () {
      final json = build(deferred: true, venueId: 'v1').toJson();

      expect(json['locationDeferred'], isTrue);
      expect(json.containsKey('venueId'), isFalse);
      expect(json.containsKey('newVenue'), isFalse);
    });

    test('blank optional strings are omitted', () {
      final json = build(
        description: '',
        phone: '',
        zalo: '',
        communityId: '',
      ).toJson();

      for (final key in [
        'description',
        'contactPhone',
        'zaloGroupUrl',
        'communityId',
      ]) {
        expect(json.containsKey(key), isFalse, reason: key);
      }
      expect(
        build(
          description: 'd',
          phone: '09',
          zalo: 'z',
          communityId: 'c',
        ).toJson()['communityId'],
        'c',
      );
    });
  });

  group('response wrappers', () {
    test('NearbySocialSessionsResponse reads nested data and hasMore', () {
      final r = NearbySocialSessionsResponse.fromJson({
        'data': {
          'items': [_base()],
          'meta': {'page': 1, 'limit': 1, 'total': 2},
        },
      });
      final flat = NearbySocialSessionsResponse.fromJson({
        'items': [
          _base(),
          _base({'id': 's2'}),
        ],
      });

      expect(r.items, hasLength(1));
      expect(r.hasMore, isTrue);
      expect(flat.total, 2);
      expect(flat.limit, 2);
      expect(flat.hasMore, isFalse);
    });

    test('SocialSessionListResponse tolerates a missing list and meta', () {
      final r = SocialSessionListResponse.fromJson({});

      expect(r.items, isEmpty);
      expect(r.page, 1);
      expect(r.limit, 20);
      expect(r.total, 0);
    });

    test('SocialSessionListResponse falls back to data and item count', () {
      final r = SocialSessionListResponse.fromJson({
        'data': [_base(), 'junk'],
      });

      expect(r.items, hasLength(1));
      expect(r.total, 1);
    });
  });
}
