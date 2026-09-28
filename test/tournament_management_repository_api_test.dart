import 'package:app_quanly_giaidau/core/services/dio_client.dart';
import 'package:app_quanly_giaidau/core/services/token_manager.dart';
import 'package:app_quanly_giaidau/data/repositories/api/api_tournament_management_repository.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament_sponsor.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _NoTokenManager extends TokenManager {
  @override
  Future<String?> getAccessToken() async => null;
}

/// Envelope every management endpoint answers with.
Map<String, dynamic> _envelope(Object? data) => <String, dynamic>{
  'statusCode': 200,
  'message': 'Success',
  'data': data,
  'meta': <String, dynamic>{'timestamp': '2026-01-01T00:00:00.000Z'},
};

/// Records the [RequestOptions] the repository really builds and answers only
/// the routes a test registered, keyed by method *and* path. A call that drifts
/// to another verb or another URL finds no fixture and fails loudly instead of
/// receiving a catch-all body, and the collection route `/venues` never
/// swallows the item route `/venues/:venueId` (or its POST sibling).
class _FakeBackend {
  _FakeBackend(this._dio);

  final Dio _dio;
  final List<RequestOptions> requests = <RequestOptions>[];
  final Map<String, Object?> _routes = <String, Object?>{};

  void onGet(String path, Object? data) =>
      _routes['GET $path'] = _envelope(data);

  void onPost(String path, Object? data) =>
      _routes['POST $path'] = _envelope(data);

  void onPatch(String path, Object? data) =>
      _routes['PATCH $path'] = _envelope(data);

  void onDelete(String path, Object? data) =>
      _routes['DELETE $path'] = _envelope(data);

  /// Answers [path] with [body] verbatim, without the response envelope.
  void onRawResponse(String method, String path, Object? body) =>
      _routes['${method.toUpperCase()} $path'] = body;

  /// The one request the repository issued.
  RequestOptions get only {
    if (requests.length != 1) {
      throw StateError(
        'Expected exactly 1 request, got ${requests.length}: '
        '${requests.map((r) => '${r.method} ${r.path}').join(', ')}',
      );
    }
    return requests.single;
  }

  void install() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          requests.add(options);
          final key = '${options.method.toUpperCase()} ${options.path}';
          if (!_routes.containsKey(key)) {
            handler.reject(
              DioException(
                requestOptions: options,
                type: DioExceptionType.badResponse,
                error: 'No fixture registered for $key',
                response: Response<dynamic>(
                  requestOptions: options,
                  statusCode: 404,
                  data: _envelope(<String, dynamic>{
                    'message': 'No fixture: $key',
                  }),
                ),
              ),
            );
            return;
          }
          handler.resolve(
            Response<dynamic>(
              requestOptions: options,
              statusCode: 200,
              data: _routes[key],
            ),
          );
        },
      ),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const baseUrl = 'https://api.example.test/api/v1';
  const tournamentId = 'tournament-1';

  late _FakeBackend backend;
  late ApiTournamentManagementRepository repository;

  setUpAll(() {
    dotenv.loadFromString(envString: 'API_BASE_URL=$baseUrl');
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    final dio = Dio(BaseOptions(baseUrl: baseUrl));
    repository = ApiTournamentManagementRepository(
      DioClient(tokenManager: _NoTokenManager(), dio: dio),
    );
    // Installed after the client so the fake observes the request as the
    // client finally emitted it.
    backend = _FakeBackend(dio)..install();
  });

  group('venues', () {
    test(
      'collection read unwraps the envelope on the canonical route',
      () async {
        backend.onGet('/tournaments/$tournamentId/venues', [
          {'id': 'venue-1', 'name': 'Court Hall'},
          {'id': 'venue-2', 'name': 'Annex', 'courts': []},
        ]);

        final venues = await repository.getVenues(tournamentId);

        expect(venues, [
          {'id': 'venue-1', 'name': 'Court Hall'},
          {'id': 'venue-2', 'name': 'Annex', 'courts': []},
        ]);
        expect(backend.only.method, 'GET');
        expect(backend.only.path, '/tournaments/$tournamentId/venues');
        expect(backend.only.queryParameters, isEmpty);
      },
    );

    test('creation posts the required keys to the collection route', () async {
      backend.onPost('/tournaments/$tournamentId/venues', {'id': 'venue-3'});

      final venue = await repository.createVenue(
        tournamentId,
        name: 'Court Hall',
        locationAddress: '12 Le Loi',
      );

      expect(venue, {'id': 'venue-3'});
      expect(backend.only.method, 'POST');
      expect(backend.only.path, '/tournaments/$tournamentId/venues');
      expect(backend.only.data, {
        'name': 'Court Hall',
        'locationAddress': '12 Le Loi',
      });
    });

    test(
      'creation sends every optional key, including isDefault false',
      () async {
        backend.onPost('/tournaments/$tournamentId/venues', {'id': 'venue-4'});

        await repository.createVenue(
          tournamentId,
          name: 'Annex',
          locationAddress: '9 Nguyen Trai',
          venueId: 'venue-4',
          isDefault: false,
          initialCourtCount: 6,
          courtPrefix: 'A',
        );

        expect(backend.only.data, {
          'name': 'Annex',
          'locationAddress': '9 Nguyen Trai',
          'venueId': 'venue-4',
          'isDefault': false,
          'initialCourtCount': 6,
          'courtPrefix': 'A',
        });
      },
    );

    test(
      'update patches the venue item route with only the changed field',
      () async {
        backend.onPatch('/tournaments/$tournamentId/venues/venue-1', {
          'id': 'venue-1',
        });

        final venue = await repository.updateVenue(
          tournamentId,
          'venue-1',
          name: 'Court Hall B',
        );

        expect(venue, {'id': 'venue-1'});
        expect(backend.only.method, 'PATCH');
        expect(backend.only.path, '/tournaments/$tournamentId/venues/venue-1');
        expect(backend.only.data, {'name': 'Court Hall B'});
      },
    );

    test(
      'default selection patches the default sub-route without a body',
      () async {
        backend.onPatch('/tournaments/$tournamentId/venues/venue-1/default', {
          'success': true,
          'defaultVenueId': 'venue-1',
        });

        await repository.setDefaultVenue(tournamentId, 'venue-1');

        expect(backend.only.method, 'PATCH');
        expect(
          backend.only.path,
          '/tournaments/$tournamentId/venues/venue-1/default',
        );
        expect(backend.only.data, isNull);
      },
    );

    test(
      'removal deletes the venue item route and returns the payload',
      () async {
        backend.onDelete('/tournaments/$tournamentId/venues/venue-1', {
          'id': 'venue-1',
          'deleted': true,
        });

        final result = await repository.removeVenue(tournamentId, 'venue-1');

        expect(result, {'id': 'venue-1', 'deleted': true});
        expect(backend.only.method, 'DELETE');
        expect(backend.only.path, '/tournaments/$tournamentId/venues/venue-1');
      },
    );

    test('court creation posts courtName and omits an unset status', () async {
      backend.onPost('/tournaments/$tournamentId/venues/venue-1/courts', {
        'id': 'court-1',
      });

      await repository.addCourt(tournamentId, 'venue-1', courtName: 'Court 1');
      await repository.addCourt(
        tournamentId,
        'venue-1',
        courtName: 'Court 2',
        status: 'MAINTENANCE',
      );

      expect(
        backend.requests.map((r) => '${r.method} ${r.path}'),
        everyElement('POST /tournaments/$tournamentId/venues/venue-1/courts'),
      );
      expect(backend.requests.map((r) => r.data), [
        {'courtName': 'Court 1'},
        {'courtName': 'Court 2', 'status': 'MAINTENANCE'},
      ]);
    });

    test('court removal deletes the court item route', () async {
      backend.onDelete(
        '/tournaments/$tournamentId/venues/venue-1/courts/court-1',
        <String, dynamic>{},
      );

      await repository.removeCourt(tournamentId, 'venue-1', 'court-1');

      expect(backend.only.method, 'DELETE');
      expect(
        backend.only.path,
        '/tournaments/$tournamentId/venues/venue-1/courts/court-1',
      );
    });
  });

  group('sponsors', () {
    test(
      'manage read maps camelCase and snake_case rows to entities',
      () async {
        backend.onGet('/tournaments/$tournamentId/sponsors/manage', [
          {
            'id': 'sponsor-1',
            'displayName': 'Alpha',
            'tier': 'GOLD',
            'logoUrl': 'https://cdn.test/alpha.png',
            'displayOrder': 1,
            'status': 'PUBLISHED',
          },
          {
            'id': 'sponsor-2',
            'display_name': 'Beta',
            'tier': 'SILVER',
            'logo_url': 'https://cdn.test/beta.png',
            'display_order': 2,
            'status': 'DRAFT',
            'is_public': false,
          },
        ]);

        final List<TournamentSponsor> sponsors = await repository.getSponsors(
          tournamentId,
        );

        expect(backend.only.method, 'GET');
        expect(backend.only.path, '/tournaments/$tournamentId/sponsors/manage');
        expect(
          sponsors
              .map(
                (s) => (s.id, s.displayName, s.tier, s.displayOrder, s.status),
              )
              .toList(),
          [
            ('sponsor-1', 'Alpha', 'GOLD', 1, 'PUBLISHED'),
            ('sponsor-2', 'Beta', 'SILVER', 2, 'DRAFT'),
          ],
        );
        expect(sponsors.first.logoUrl, 'https://cdn.test/alpha.png');
        expect(sponsors.last.isPublic, isFalse);
      },
    );

    test('creation posts the payload and returns the mapped entity', () async {
      backend.onPost('/tournaments/$tournamentId/sponsors', {
        'id': 'sponsor-3',
        'displayName': 'Gamma',
        'tier': 'SILVER',
      });

      final TournamentSponsor sponsor = await repository.createSponsor(
        tournamentId,
        {'displayName': 'Gamma', 'tier': 'BRONZE'},
      );

      expect(sponsor.id, 'sponsor-3');
      expect(sponsor.displayName, 'Gamma');
      // The entity is built from the server response, not the request payload.
      expect(sponsor.tier, 'SILVER');
      expect(backend.only.method, 'POST');
      expect(backend.only.path, '/tournaments/$tournamentId/sponsors');
      expect(backend.only.data, {'displayName': 'Gamma', 'tier': 'BRONZE'});
    });

    test('update patches the sponsor item route', () async {
      backend.onPatch('/tournaments/$tournamentId/sponsors/sponsor-1', {
        'id': 'sponsor-1',
        'displayName': 'Alpha 2',
      });

      final TournamentSponsor sponsor = await repository.updateSponsor(
        tournamentId,
        'sponsor-1',
        {'displayName': 'Alpha 2'},
      );

      expect(sponsor.displayName, 'Alpha 2');
      expect(backend.only.method, 'PATCH');
      expect(
        backend.only.path,
        '/tournaments/$tournamentId/sponsors/sponsor-1',
      );
      expect(backend.only.data, {'displayName': 'Alpha 2'});
    });

    test(
      'archiving deletes the sponsor item route and returns the entity',
      () async {
        backend.onDelete('/tournaments/$tournamentId/sponsors/sponsor-1', {
          'id': 'sponsor-1',
          'status': 'ARCHIVED',
        });

        final TournamentSponsor sponsor = await repository.archiveSponsor(
          tournamentId,
          'sponsor-1',
        );

        expect(sponsor.status, 'ARCHIVED');
        expect(backend.only.method, 'DELETE');
        expect(
          backend.only.path,
          '/tournaments/$tournamentId/sponsors/sponsor-1',
        );
      },
    );
  });

  group('staff and referees', () {
    test('reads hit their own collection routes', () async {
      backend.onGet('/tournaments/$tournamentId/staff', [
        {'id': 'user-1', 'role': 'REFEREE'},
      ]);
      backend.onGet('/tournaments/$tournamentId/referees', [
        {'id': 'ref-1'},
      ]);

      expect(await repository.getStaff(tournamentId), [
        {'id': 'user-1', 'role': 'REFEREE'},
      ]);
      expect(await repository.getReferees(tournamentId), [
        {'id': 'ref-1'},
      ]);

      expect(backend.requests.map((r) => '${r.method} ${r.path}'), [
        'GET /tournaments/$tournamentId/staff',
        'GET /tournaments/$tournamentId/referees',
      ]);
    });

    test('staff invitation posts email and role to the staff route', () async {
      backend.onPost('/tournaments/$tournamentId/staff', {
        'id': 'user-2',
        'role': 'REFEREE',
      });

      final member = await repository.addStaff(
        tournamentId,
        'referee@example.test',
        'REFEREE',
      );

      expect(member, {'id': 'user-2', 'role': 'REFEREE'});
      expect(backend.only.method, 'POST');
      expect(backend.only.path, '/tournaments/$tournamentId/staff');
      expect(backend.only.data, {
        'email': 'referee@example.test',
        'role': 'REFEREE',
      });
    });

    test('staff removal deletes the member route', () async {
      backend.onDelete(
        '/tournaments/$tournamentId/staff/user-1',
        <String, dynamic>{},
      );

      await repository.removeStaff(tournamentId, 'user-1');

      expect(backend.only.method, 'DELETE');
      expect(backend.only.path, '/tournaments/$tournamentId/staff/user-1');
    });

    test('referee invitation posts only the email key', () async {
      backend.onPost(
        '/tournaments/$tournamentId/referees',
        <String, dynamic>{},
      );

      await repository.addReferee(tournamentId, 'referee@example.test');

      expect(backend.only.method, 'POST');
      expect(backend.only.path, '/tournaments/$tournamentId/referees');
      expect(backend.only.data, {'email': 'referee@example.test'});
    });

    test('referee removal deletes the referee route', () async {
      backend.onDelete(
        '/tournaments/$tournamentId/referees/ref-1',
        <String, dynamic>{},
      );

      await repository.removeReferee(tournamentId, 'ref-1');

      expect(backend.only.method, 'DELETE');
      expect(backend.only.path, '/tournaments/$tournamentId/referees/ref-1');
    });
  });

  group('finance', () {
    test('fee config reads the shared route with no tournament id', () async {
      backend.onGet('/tournaments/fees', {
        'currency': 'VND',
        'payoutEnabled': true,
      });

      final config = await repository.getFeesConfig();

      expect(config, {'currency': 'VND', 'payoutEnabled': true});
      expect(backend.only.method, 'GET');
      expect(backend.only.path, '/tournaments/fees');
      expect(backend.only.queryParameters, isEmpty);
    });

    test(
      'payout request posts the exact backend keys and no query filters',
      () async {
        backend.onPost('/payments/payout', {'success': true});

        await repository.requestPayout(
          tournamentId: tournamentId,
          bankName: 'Example Bank',
          bankAccountNumber: 'sensitive-account-number',
          bankAccountName: 'Sensitive Account Name',
          amountRequested: 25000,
        );

        expect(backend.only.method, 'POST');
        expect(backend.only.path, '/payments/payout');
        expect(backend.only.queryParameters, isEmpty);
        expect(backend.only.data, {
          'tournamentId': tournamentId,
          'bankName': 'Example Bank',
          'bankAccountNumber': 'sensitive-account-number',
          'bankAccountName': 'Sensitive Account Name',
          'amountRequested': 25000,
        });
      },
    );

    test(
      'payout list flattens nested rows and leaves flat rows untouched',
      () async {
        backend.onGet('/payments/payouts', [
          {
            'payout': {
              'id': 'payout-1',
              'amountRequested': 25000,
              'status': 'PENDING',
            },
            'tournament': {'id': tournamentId, 'name': 'Open Cup'},
          },
          {'id': 'payout-2', 'amountRequested': 9000, 'status': 'PAID'},
        ]);

        final payouts = await repository.getMyPayouts();

        expect(backend.only.method, 'GET');
        expect(backend.only.path, '/payments/payouts');
        expect(payouts, [
          {
            'id': 'payout-1',
            'amountRequested': 25000,
            'status': 'PENDING',
            'tournament': {'id': tournamentId, 'name': 'Open Cup'},
          },
          {'id': 'payout-2', 'amountRequested': 9000, 'status': 'PAID'},
        ]);
        expect(payouts.last.containsKey('tournament'), isFalse);
      },
    );
  });

  group('participants and gallery', () {
    test(
      'status change patches the participant route with the status key',
      () async {
        backend.onPatch(
          '/tournaments/$tournamentId/participants/participant-1',
          <String, dynamic>{},
        );

        await repository.updateParticipantStatus(
          tournamentId,
          'participant-1',
          'COMPLETE',
        );

        expect(backend.only.method, 'PATCH');
        expect(
          backend.only.path,
          '/tournaments/$tournamentId/participants/participant-1',
        );
        expect(backend.only.data, {'status': 'COMPLETE'});
      },
    );

    test('gallery read unwraps the URL list', () async {
      backend.onGet('/tournaments/$tournamentId/gallery', [
        'https://cdn.test/a.jpg',
        'https://cdn.test/b.jpg',
      ]);

      expect(await repository.getGallery(tournamentId), [
        'https://cdn.test/a.jpg',
        'https://cdn.test/b.jpg',
      ]);
      expect(backend.only.method, 'GET');
      expect(backend.only.path, '/tournaments/$tournamentId/gallery');
    });

    test('gallery creation posts the url key', () async {
      backend.onPost('/tournaments/$tournamentId/gallery', <String, dynamic>{});

      await repository.addGalleryImage(tournamentId, 'https://cdn.test/c.jpg');

      expect(backend.only.method, 'POST');
      expect(backend.only.path, '/tournaments/$tournamentId/gallery');
      expect(backend.only.data, {'url': 'https://cdn.test/c.jpg'});
    });

    test('gallery removal deletes by index in the path', () async {
      backend.onDelete(
        '/tournaments/$tournamentId/gallery/2',
        <String, dynamic>{},
      );

      await repository.removeGalleryImage(tournamentId, 2);

      expect(backend.only.method, 'DELETE');
      expect(backend.only.path, '/tournaments/$tournamentId/gallery/2');
      expect(backend.only.data, isNull);
    });
  });

  group('divisions and seeding', () {
    test('division read hits the tournament divisions route', () async {
      backend.onGet('/tournaments/$tournamentId/divisions', [
        {'id': 'division-1', 'name': 'Open Doubles'},
      ]);

      expect(await repository.getManageDivisions(tournamentId), [
        {'id': 'division-1', 'name': 'Open Doubles'},
      ]);
      expect(backend.only.method, 'GET');
      expect(backend.only.path, '/tournaments/$tournamentId/divisions');
    });

    test(
      'creation drops endDate without mutating the caller payload',
      () async {
        backend.onPost('/tournaments/$tournamentId/divisions', {
          'id': 'division-1',
        });
        final payload = <String, dynamic>{
          'name': 'Open Doubles',
          'matchType': 'DOUBLES',
          'endDate': '2026-12-31',
        };

        final division = await repository.createDivision(tournamentId, payload);

        expect(division, {'id': 'division-1'});
        expect(backend.only.method, 'POST');
        expect(backend.only.path, '/tournaments/$tournamentId/divisions');
        expect(backend.only.data, {
          'name': 'Open Doubles',
          'matchType': 'DOUBLES',
        });
        expect(
          payload.containsKey('endDate'),
          isTrue,
          reason: 'the caller keeps its own endDate for a later retry',
        );
      },
    );

    test('division update patches the division-only route', () async {
      backend.onPatch('/tournaments/divisions/division-1', {
        'id': 'division-1',
      });

      await repository.updateDivision('division-1', {'name': 'A'});

      expect(backend.only.method, 'PATCH');
      expect(backend.only.path, '/tournaments/divisions/division-1');
      expect(backend.only.data, {'name': 'A'});
    });

    test('config update patches the tournament-scoped config route', () async {
      backend.onPatch(
        '/tournaments/$tournamentId/divisions/division-1/config',
        {'id': 'division-1'},
      );

      await repository.updateDivisionConfig(tournamentId, 'division-1', {
        'status': 'ONGOING',
      });

      expect(backend.only.method, 'PATCH');
      expect(
        backend.only.path,
        '/tournaments/$tournamentId/divisions/division-1/config',
      );
      expect(backend.only.data, {'status': 'ONGOING'});
    });

    test('division deletion deletes the division-only route', () async {
      backend.onDelete(
        '/tournaments/divisions/division-1',
        <String, dynamic>{},
      );

      await repository.deleteDivision('division-1');

      expect(backend.only.method, 'DELETE');
      expect(backend.only.path, '/tournaments/divisions/division-1');
    });

    test('seed update wraps the list under the seeds key', () async {
      backend.onPatch('/tournaments/$tournamentId/seeds', <String, dynamic>{});
      final seeds = [
        {'participantId': 'p-1', 'seed': 1},
      ];

      await repository.updateTournamentSeeds(tournamentId, seeds);

      expect(backend.only.method, 'PATCH');
      expect(backend.only.path, '/tournaments/$tournamentId/seeds');
      expect(backend.only.data, {'seeds': seeds});
    });

    test('auto seed omits divisionId unless one is supplied', () async {
      backend.onPost('/tournaments/$tournamentId/auto-seed', [
        {'participantId': 'p-1', 'seed': 1},
      ]);

      final seeded = await repository.autoSeedParticipants(tournamentId);
      await repository.autoSeedParticipants(
        tournamentId,
        divisionId: 'division-1',
      );

      expect(seeded, [
        {'participantId': 'p-1', 'seed': 1},
      ]);
      expect(backend.requests.map((r) => r.method), everyElement('POST'));
      expect(backend.requests.map((r) => r.data), [
        <String, dynamic>{},
        {'divisionId': 'division-1'},
      ]);
    });
  });

  group('lifecycle', () {
    test(
      'publish, reopen, lock and invite regen post distinct routes',
      () async {
        backend.onPost('/tournaments/$tournamentId/publish', {
          'status': 'PUBLISHED',
        });
        backend.onPost('/tournaments/$tournamentId/reopen-registration', {
          'status': 'REGISTRATION_REOPENED',
        });
        backend.onPost('/tournaments/$tournamentId/lock', {'status': 'LOCKED'});
        backend.onPost('/tournaments/$tournamentId/regenerate-invite', {
          'inviteCode': 'ABC123',
        });

        expect(
          (await repository.publishTournament(tournamentId))['status'],
          'PUBLISHED',
        );
        expect(
          (await repository.reopenRegistration(tournamentId))['status'],
          'REGISTRATION_REOPENED',
        );
        expect(
          (await repository.lockTournament(tournamentId))['status'],
          'LOCKED',
        );
        expect(
          (await repository.regenerateInviteCode(tournamentId))['inviteCode'],
          'ABC123',
        );

        expect(backend.requests.map((r) => r.method), everyElement('POST'));
        expect(backend.requests.map((r) => r.path), [
          '/tournaments/$tournamentId/publish',
          '/tournaments/$tournamentId/reopen-registration',
          '/tournaments/$tournamentId/lock',
          '/tournaments/$tournamentId/regenerate-invite',
        ]);
      },
    );
  });

  group('response envelope', () {
    test('a body without the data envelope fails the read', () async {
      backend.onRawResponse('GET', '/tournaments/fees', {
        'statusCode': 200,
        'message': 'Success',
      });

      await expectLater(
        repository.getFeesConfig(),
        throwsA(isA<FormatException>()),
      );
    });

    test('a list read rejects an object payload', () async {
      backend.onGet('/tournaments/$tournamentId/venues', <String, dynamic>{
        'items': <dynamic>[],
      });

      await expectLater(
        repository.getVenues(tournamentId),
        throwsA(isA<FormatException>()),
      );
    });

    test('a list read rejects non-object rows', () async {
      backend.onGet('/tournaments/$tournamentId/staff', ['user-1']);

      await expectLater(
        repository.getStaff(tournamentId),
        throwsA(isA<FormatException>()),
      );
    });

    test('a map read rejects a list payload', () async {
      backend.onGet('/tournaments/fees', <dynamic>[]);

      await expectLater(
        repository.getFeesConfig(),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
