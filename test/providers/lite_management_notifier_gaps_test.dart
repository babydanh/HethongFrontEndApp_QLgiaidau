import 'package:app_quanly_giaidau/core/di/core_di_providers.dart';
import 'package:app_quanly_giaidau/providers/lite_management_notifier.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_api_adapter.dart';

const _id = 't1';
const _lite = '/tournaments/lite/t1';
const _oneDivision = [
  {'id': 'd1', 'matchType': 'DOUBLES'},
];

Map<String, dynamic> _complete(String id, {String name = 'Đội'}) => {
  'id': id,
  'teamStatus': 'COMPLETE',
  'teamName': '$name $id',
  'rosters': <Object>[],
};

Map<String, dynamic> _pending(String id) => {
  'id': id,
  'teamStatus': 'PENDING_PARTNER',
  'teamName': 'Chờ $id',
  'customResponses': {'importedFrom': 'ORGANIZER_DIRECT', 'player1Name': id},
  'rosters': <Object>[],
};

FakeApiAdapter _adapter({
  Map<String, dynamic> tournament = const {},
  List<Map<String, dynamic>> participants = const [],
  List<Map<String, dynamic>> divisions = _oneDivision,
  Map<String, FakeReply> routes = const {},
}) {
  return FakeApiAdapter({
    'GET /tournaments/$_id': FakeReply(200, {
      'data': {
        'id': _id,
        'name': 'Giải Lite',
        'matchType': 'DOUBLES',
        'status': 'REGISTRATION',
        'tournamentConfig': {'isLite': true},
        'divisions': divisions,
        ...tournament,
      },
    }),
    'GET $_lite/participants': FakeReply(200, {'data': participants}),
    ...routes,
  });
}

ProviderContainer _container(FakeApiAdapter adapter) {
  final container = ProviderContainer(
    overrides: [dioClientProvider.overrideWithValue(fakeDioClient(adapter))],
  );
  addTearDown(container.dispose);
  return container;
}

Future<(ProviderContainer, LiteManagementNotifier)> _loaded(
  FakeApiAdapter adapter,
) async {
  final container = _container(adapter);
  final notifier = container.read(liteManagementProvider.notifier);
  await notifier.init(_id);
  return (container, notifier);
}

LiteManagementState _state(ProviderContainer c) =>
    c.read(liteManagementProvider);

/// Detail-saving methods reset `detailsSaveStatus` to idle after 2.5 s; wait
/// for it so no timer fires after the container is disposed.
Future<void> _settleSaveStatus() =>
    Future<void>.delayed(const Duration(milliseconds: 2600));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  dotenv.loadFromString(
    envString: 'API_BASE_URL=https://api.example.test/api/v1',
  );

  group('init', () {
    test(
      'reads schedule, venue, capacity, match type and invite code',
      () async {
        final (c, _) = await _loaded(
          _adapter(
            tournament: {
              'inviteCode': 'INV123',
              'startDate': '2026-06-01T08:00:00Z',
              'endDate': '2026-06-01T10:00:00Z',
              'maxParticipants': '12',
              'locationAddress': '1 Lê Lợi',
              'city': 'TP.HCM',
              'description': 'Giải vui',
              'isRegistrationLocked': true,
              'tournamentConfig': {
                'isLite': true,
                'location': {'venueName': 'Sân A', 'ward': 'Bến Nghé'},
              },
            },
            participants: [_complete('p1'), _complete('p2')],
          ),
        );

        final s = _state(c);
        expect(s.loading, isFalse);
        expect(s.error, isNull);
        expect(s.tournamentName, 'Giải Lite');
        expect(s.inviteCode, 'INV123');
        expect(s.matchType, 'DOUBLES');
        expect(s.durationMinutes, 120); // derived from end - start
        expect(s.maxParticipants, 12);
        expect(s.venueName, 'Sân A');
        expect(s.locationAddress, '1 Lê Lợi');
        expect(s.province, 'TP.HCM');
        expect(s.ward, 'Bến Nghé');
        expect(s.description, 'Giải vui');
        expect(s.rosterConfirmed, isTrue);
        expect(s.participants.map((p) => p.id), ['p1', 'p2']);
      },
    );

    test('the division match type decides MIXED_DOUBLES', () async {
      final (viaGender, _) = await _loaded(
        _adapter(
          divisions: [
            {'id': 'd1', 'matchType': 'DOUBLES', 'genderRestriction': 'mixed'},
          ],
        ),
      );
      final (viaType, _) = await _loaded(
        _adapter(
          divisions: [
            {'id': 'd1', 'matchType': 'MIXED_DOUBLES'},
          ],
        ),
      );
      final (fallback, _) = await _loaded(
        _adapter(tournament: {'matchType': 'singles'}, divisions: const []),
      );

      expect(_state(viaGender).matchType, 'MIXED_DOUBLES');
      expect(_state(viaType).matchType, 'MIXED_DOUBLES');
      expect(_state(fallback).matchType, 'SINGLES');
    });

    test(
      'duration prefers config minutes, then config hours, else 90',
      () async {
        Future<int?> durationFor(Map<String, dynamic> config) async {
          final (c, _) = await _loaded(
            _adapter(
              tournament: {
                'tournamentConfig': {'isLite': true, ...config},
              },
            ),
          );
          return _state(c).durationMinutes;
        }

        expect(await durationFor({'durationMinutes': 45}), 45);
        expect(await durationFor({'durationHours': 1.5}), 90);
        expect(
          await durationFor({
            'schedule': {'durationMinutes': 30},
          }),
          30,
        );
        expect(await durationFor({}), 90);
      },
    );

    test('a legacy LITE-mode config is still treated as Lite', () async {
      final (c, _) = await _loaded(
        _adapter(
          tournament: {
            'tournamentConfig': {'mode': 'lite', 'hideAdvancedSettings': true},
          },
        ),
      );

      expect(_state(c).error, isNull);
      expect(_state(c).tournament, isNotNull);
    });

    test(
      'an advanced (non-Lite) tournament is rejected with an error',
      () async {
        final (c, _) = await _loaded(
          _adapter(
            tournament: {
              'tournamentConfig': {'isLite': false},
            },
          ),
        );

        expect(_state(c).error, isNotNull);
        expect(_state(c).loading, isFalse);
        expect(_state(c).tournamentName, isNull); // nothing was applied
      },
    );

    test(
      'a server message from the tournament request becomes the error',
      () async {
        final (c, _) = await _loaded(
          _adapter(
            routes: {
              'GET /tournaments/$_id': const FakeReply(403, {
                'message': 'Không có quyền',
              }),
            },
          ),
        );

        expect(_state(c).error, 'Không có quyền');
        expect(_state(c).loading, isFalse);
      },
    );

    test('hasBracket follows the bracket stages; a 404 means none', () async {
      final (withStages, _) = await _loaded(
        _adapter(
          routes: {
            'GET /tournaments/$_id/bracket': const FakeReply(200, {
              'data': {
                'stages': [
                  {'id': 's1'},
                ],
              },
            }),
          },
        ),
      );
      final (none, _) = await _loaded(_adapter());

      expect(_state(withStages).hasBracket, isTrue);
      expect(_state(none).hasBracket, isFalse);
    });

    test('markLoadFailed stops loading and keeps the message', () async {
      final c = _container(_adapter());

      c.read(liteManagementProvider.notifier).markLoadFailed('hỏng');

      expect(_state(c).loading, isFalse);
      expect(_state(c).error, 'hỏng');
    });

    test('refresh clears the previous error and reloads', () async {
      final adapter = _adapter(
        routes: {
          'GET /tournaments/$_id': const FakeReply(500, <String, dynamic>{}),
        },
      );
      final (c, notifier) = await _loaded(adapter);
      expect(_state(c).error, isNotNull);

      adapter.routes['GET /tournaments/$_id'] = const FakeReply(200, {
        'data': {
          'id': _id,
          'name': 'Giải Lite',
          'tournamentConfig': {'isLite': true},
        },
      });
      await notifier.refresh(_id);

      expect(_state(c).tournamentName, 'Giải Lite');
      expect(_state(c).loading, isFalse);
    });
  });

  group('selection and pairing', () {
    test(
      'toggleSelection keeps at most two ids, evicting the oldest',
      () async {
        final c = _container(_adapter());
        final notifier = c.read(liteManagementProvider.notifier);

        notifier.toggleSelection('a');
        notifier.toggleSelection('b');
        notifier.toggleSelection('c');
        expect(_state(c).selectedIds, {'b', 'c'});

        notifier.toggleSelection('b'); // toggling again deselects
        expect(_state(c).selectedIds, {'c'});
      },
    );

    test('manualPair needs exactly two selected, posts both ids, then '
        'refreshes', () async {
      final adapter = _adapter(
        participants: [_pending('a'), _pending('b')],
        routes: {'POST $_lite/pairs': const FakeReply(201, {})},
      );
      final (c, notifier) = await _loaded(adapter);

      await notifier.manualPair(_id); // nothing selected → no request
      expect(adapter.postsTo('$_lite/pairs'), isEmpty);

      notifier.toggleSelection('a');
      notifier.toggleSelection('b');
      await notifier.manualPair(_id);

      expect(adapter.postsTo('$_lite/pairs').single.body, {
        'participant1Id': 'a',
        'participant2Id': 'b',
      });
      expect(_state(c).pairing, isFalse);
      expect(_state(c).selectedIds, isEmpty); // participants reload clears it
    });

    test(
      'a failed manualPair rethrows and releases the pairing flag',
      () async {
        final (c, notifier) = await _loaded(_adapter());
        notifier.toggleSelection('a');
        notifier.toggleSelection('b');

        await expectLater(
          notifier.manualPair(_id),
          throwsA(isA<DioException>()),
        );

        expect(_state(c).pairing, isFalse);
        expect(_state(c).selectedIds, {'a', 'b'}); // selection kept for a retry
      },
    );

    test(
      'generatePairs returns the response body and clears generating',
      () async {
        final adapter = _adapter(
          routes: {
            'POST $_lite/pairs/generate': const FakeReply(200, {
              'data': {
                'unpairedParticipantIds': ['x'],
              },
            }),
          },
        );
        final (c, notifier) = await _loaded(adapter);

        final body = await notifier.generatePairs(
          _id,
          'SKILL',
          divisionId: 'dz',
        );

        expect(body, isA<Map>());
        expect(adapter.postsTo('$_lite/pairs/generate').single.body, {
          'strategy': 'SKILL',
          'divisionId': 'dz',
        });
        expect(_state(c).generating, isFalse);
        // generatingStrategy is deliberately not asserted: see findings.md F2.
      },
    );

    test('generatePairs failures rethrow and still reset the flags', () async {
      final (c, notifier) = await _loaded(_adapter());

      await expectLater(
        notifier.generatePairs(_id, 'RANDOM'),
        throwsA(isA<DioException>()),
      );

      expect(_state(c).generating, isFalse);
    });

    test('unpair posts to the participant and surfaces errors', () async {
      final adapter = _adapter(
        routes: {'POST $_lite/pairs/p1/unpair': const FakeReply(200, {})},
      );
      final (_, notifier) = await _loaded(adapter);

      await notifier.unpair(_id, 'p1');

      expect(adapter.postsTo('$_lite/pairs/p1/unpair'), hasLength(1));
      await expectLater(
        notifier.unpair(_id, 'missing'),
        throwsA(isA<DioException>()),
      );
    });
  });

  group('roster actions', () {
    test('addClubMember only sends a non-blank trimmed division', () async {
      final adapter = _adapter(
        routes: {'POST $_lite/club-members': const FakeReply(201, {})},
      );
      final (_, notifier) = await _loaded(adapter);

      await notifier.addClubMember(_id, 'u1', divisionId: '  d9  ');
      await notifier.addClubMember(_id, 'u2', divisionId: '   ');
      await notifier.addClubMember(_id, 'u3');

      final bodies = adapter.postsTo('$_lite/club-members').map((r) => r.body);
      expect(bodies.toList(), [
        {'userId': 'u1', 'divisionId': 'd9'},
        {'userId': 'u2'},
        {'userId': 'u3'},
      ]);
    });

    test('kickParticipant posts the reason and rethrows failures', () async {
      final adapter = _adapter(
        routes: {
          'POST /tournaments/$_id/participants/p1/kick': const FakeReply(
            200,
            {},
          ),
        },
      );
      final (_, notifier) = await _loaded(adapter);

      await notifier.kickParticipant(_id, 'p1', 'vắng');

      expect(
        adapter.postsTo('/tournaments/$_id/participants/p1/kick').single.body,
        {'reason': 'vắng'},
      );
      await expectLater(
        notifier.kickParticipant(_id, 'p2', 'x'),
        throwsA(isA<DioException>()),
      );
    });

    test(
      'confirmRoster locks the roster and adopts the returned tournament',
      () async {
        final adapter = _adapter(
          routes: {
            'POST /tournaments/$_id/confirm-roster': const FakeReply(200, {
              'data': {
                'id': _id,
                'name': 'Giải đã chốt',
                'tournamentConfig': {'isLite': true},
              },
            }),
          },
        );
        final (c, notifier) = await _loaded(adapter);
        // After the confirm the server reports the registration as locked.
        adapter.routes['GET /tournaments/$_id'] = const FakeReply(200, {
          'data': {
            'id': _id,
            'name': 'Giải Lite',
            'isRegistrationLocked': true,
            'tournamentConfig': {'isLite': true},
          },
        });

        await notifier.confirmRoster(_id);

        expect(_state(c).rosterConfirmed, isTrue);
        expect(_state(c).tournament?.name, 'Giải đã chốt');
      },
    );

    test(
      'confirmRoster surfaces a backend refusal and keeps the roster open',
      () async {
        final (c, notifier) = await _loaded(_adapter());

        await expectLater(
          notifier.confirmRoster(_id),
          throwsA(isA<DioException>()),
        );
        expect(_state(c).rosterConfirmed, isFalse);
      },
    );

    test('seedMock sends N numbered names and the write division; clearMock '
        'deletes them', () async {
      final adapter = _adapter(
        routes: {
          'POST /tournaments/$_id/mock-participants': const FakeReply(201, {}),
          'DELETE /tournaments/$_id/mock-participants': const FakeReply(
            200,
            {},
          ),
        },
      );
      final (c, notifier) = await _loaded(adapter);

      await notifier.seedMock(_id, 3);
      await notifier.clearMock(_id);

      expect(
        adapter.postsTo('/tournaments/$_id/mock-participants').single.body,
        {
          'names': ['VĐV ảo 1', 'VĐV ảo 2', 'VĐV ảo 3'],
          'divisionId': 'd1',
        },
      );
      final delete = adapter.requests.firstWhere((r) => r.method == 'DELETE');
      expect(delete.query, {'divisionId': 'd1'});
      expect(_state(c).mockLoading, isFalse);
    });

    test('mock actions rethrow errors and release the loading flag', () async {
      final (c, notifier) = await _loaded(_adapter());

      await expectLater(
        notifier.seedMock(_id, 1),
        throwsA(isA<DioException>()),
      );
      await expectLater(notifier.clearMock(_id), throwsA(isA<DioException>()));

      expect(_state(c).mockLoading, isFalse);
    });
  });

  group('bracket', () {
    test(
      'createBracket refuses fewer than two eligible participants',
      () async {
        final adapter = _adapter(participants: [_complete('p1')]);
        final (c, notifier) = await _loaded(adapter);

        await expectLater(
          notifier.createBracket(_id),
          throwsA(isA<StateError>()),
        );

        expect(adapter.postsTo('$_lite/bracket'), isEmpty);
        expect(_state(c).creatingBracket, isFalse);
      },
    );

    test('createBracket posts a random seeding with the division and marks '
        'the bracket as present', () async {
      final adapter = _adapter(
        participants: [_complete('p1'), _complete('p2')],
        routes: {
          'POST $_lite/bracket': const FakeReply(201, {
            'data': {'autoPaired': 0},
          }),
        },
      );
      final (c, notifier) = await _loaded(adapter);
      // Once created, the bracket endpoint reports a stage.
      adapter.routes['GET /tournaments/$_id/bracket'] = const FakeReply(200, {
        'data': {
          'stages': [
            {'id': 's1'},
          ],
        },
      });

      final body = await notifier.createBracket(_id);

      expect(body, isA<Map>());
      expect(adapter.postsTo('$_lite/bracket').single.body, {
        'divisionId': 'd1',
        'seedingType': 'RANDOM',
        'bracketType': 'SINGLE_ELIMINATION',
      });
      expect(_state(c).hasBracket, isTrue);
      expect(_state(c).creatingBracket, isFalse);
    });

    test(
      'a backend failure on createBracket is rethrown, not swallowed',
      () async {
        final (c, notifier) = await _loaded(
          _adapter(participants: [_complete('p1'), _complete('p2')]),
        );

        await expectLater(
          notifier.createBracket(_id),
          throwsA(isA<DioException>()),
        );

        expect(_state(c).creatingBracket, isFalse);
        expect(_state(c).hasBracket, isFalse);
      },
    );

    test('resetBracket posts the division and reloads', () async {
      final adapter = _adapter(
        routes: {'POST $_lite/bracket/reset': const FakeReply(200, {})},
      );
      final (c, notifier) = await _loaded(adapter);

      await notifier.resetBracket(_id);

      expect(adapter.postsTo('$_lite/bracket/reset').single.body, {
        'divisionId': 'd1',
      });
      expect(_state(c).creatingBracket, isFalse);
    });

    test('resetBracket failure rethrows and releases the flag', () async {
      final (c, notifier) = await _loaded(_adapter());

      await expectLater(
        notifier.resetBracket(_id),
        throwsA(isA<DioException>()),
      );

      expect(_state(c).creatingBracket, isFalse);
    });
  });

  group('details editing', () {
    test('updateSchedule sends UTC dates and a config with duration', () async {
      final adapter = _adapter(
        routes: {'PATCH /tournaments/$_id': const FakeReply(200, {})},
      );
      final (c, notifier) = await _loaded(adapter);
      final start = DateTime.utc(2026, 6, 1, 8);

      final ok = await notifier.updateSchedule(
        _id,
        startDate: start,
        durationMinutes: 150,
      );

      final patch = adapter.requests.last.body!;
      expect(ok, isTrue);
      expect(patch['startDate'], '2026-06-01T08:00:00.000Z');
      expect(patch['endDate'], '2026-06-01T10:30:00.000Z');
      final config = patch['tournamentConfig'] as Map;
      expect(config['durationMinutes'], 150);
      expect(config['durationHours'], 2.5);
      expect(config['isLite'], isTrue);
      expect(_state(c).durationMinutes, 150);
      expect(_state(c).detailsSaveStatus, 'saved');
      await _settleSaveStatus();
      expect(_state(c).detailsSaveStatus, 'idle');
    });

    test(
      'a started or finished tournament refuses every details edit',
      () async {
        for (final status in [
          'IN_PROGRESS',
          'ongoing',
          'COMPLETED',
          'CANCELLED',
        ]) {
          final adapter = _adapter(tournament: {'status': status});
          final (_, notifier) = await _loaded(adapter);
          final before = adapter.requests.length;

          expect(
            await notifier.updateSchedule(
              _id,
              startDate: DateTime.utc(2026),
              durationMinutes: 60,
            ),
            isFalse,
            reason: status,
          );
          expect(await notifier.updateMaxParticipants(_id, 8), isFalse);
          expect(
            await notifier.updateLocation(
              _id,
              venueName: 'A',
              locationAddress: 'B',
            ),
            isFalse,
          );
          expect(
            await notifier.updateLiteDetails(
              _id,
              description: 'd',
              locationAddress: 'l',
            ),
            isFalse,
          );
          expect(adapter.requests.skip(before), isEmpty, reason: status);
        }
      },
    );

    test(
      'details edits are refused before the tournament has loaded',
      () async {
        final adapter = _adapter();
        final c = _container(adapter);
        final notifier = c.read(liteManagementProvider.notifier);

        expect(await notifier.updateMaxParticipants(_id, 8), isFalse);
        expect(adapter.requests, isEmpty);
      },
    );

    test(
      'updateSchedule failure resets the saving status and returns false',
      () async {
        final (c, notifier) = await _loaded(_adapter());

        final ok = await notifier.updateSchedule(
          _id,
          startDate: DateTime.utc(2026),
          durationMinutes: 60,
        );

        expect(ok, isFalse);
        expect(_state(c).detailsSaveStatus, 'idle');
      },
    );

    test('updateMaxParticipants patches the tournament and the division, and '
        'tolerates a division failure', () async {
      final adapter = _adapter(
        routes: {'PATCH /tournaments/$_id': const FakeReply(200, {})},
      );
      final (c, notifier) = await _loaded(adapter);

      final ok = await notifier.updateMaxParticipants(_id, 24);

      expect(ok, isTrue); // the division PATCH 404s but is best-effort
      final patches = adapter.requests.where((r) => r.method == 'PATCH');
      expect(patches.map((r) => r.path), [
        '/tournaments/$_id',
        '/tournaments/$_id/divisions/d1/config',
      ]);
      expect(patches.first.body, {'maxParticipants': 24});
      expect(_state(c).maxParticipants, 24);
      await _settleSaveStatus();
    });

    test('updateMaxParticipants is refused once a bracket exists', () async {
      final adapter = _adapter(
        routes: {
          'GET /tournaments/$_id/bracket': const FakeReply(200, {
            'data': {
              'stages': [
                {'id': 's'},
              ],
            },
          }),
        },
      );
      final (_, notifier) = await _loaded(adapter);
      final before = adapter.requests.length;

      expect(await notifier.updateMaxParticipants(_id, 8), isFalse);
      expect(adapter.requests.skip(before), isEmpty);
    });

    test('updateLocation builds a display string, registers a venue and keeps '
        'fallbacks', () async {
      final adapter = _adapter(
        tournament: {
          'city': 'TP.HCM',
          'tournamentConfig': {
            'isLite': true,
            'location': {'ward': 'Bến Nghé'},
          },
        },
        routes: {
          'PATCH /tournaments/$_id': const FakeReply(200, {}),
          'POST /tournaments/$_id/venues': const FakeReply(201, {}),
        },
      );
      final (c, notifier) = await _loaded(adapter);

      final ok = await notifier.updateLocation(
        _id,
        venueName: '  Sân A ',
        locationAddress: ' 1 Lê Lợi ',
      );

      expect(ok, isTrue);
      final patch = adapter.requests
          .firstWhere((r) => r.method == 'PATCH')
          .body!;
      expect(patch['locationAddress'], '1 Lê Lợi');
      expect(patch['city'], 'TP.HCM'); // falls back to the loaded province
      final location = (patch['tournamentConfig'] as Map)['location'] as Map;
      expect(location['display'], 'Sân A, 1 Lê Lợi, Bến Nghé, TP.HCM');
      expect(adapter.postsTo('/tournaments/$_id/venues').single.body, {
        'name': 'Sân A',
        'locationAddress': '1 Lê Lợi',
      });
      expect(_state(c).venueName, 'Sân A');
      await _settleSaveStatus();
    });

    test('updateLocation without a venue name still saves; no venue call '
        'when both are blank', () async {
      final adapter = _adapter(
        routes: {'PATCH /tournaments/$_id': const FakeReply(200, {})},
      );
      final (_, notifier) = await _loaded(adapter);

      final ok = await notifier.updateLocation(
        _id,
        venueName: '  ',
        locationAddress: '',
      );

      expect(ok, isTrue);
      expect(
        adapter.requests.where((r) => r.path.endsWith('/venues')),
        isEmpty,
      );
      await _settleSaveStatus();
    });

    test('updateLiteDetails trims the text and only rewrites the location '
        'when a venue is given', () async {
      final adapter = _adapter(
        routes: {'PATCH /tournaments/$_id': const FakeReply(200, {})},
      );
      final (c, notifier) = await _loaded(adapter);

      await notifier.updateLiteDetails(
        _id,
        description: '  mô tả  ',
        locationAddress: ' địa chỉ ',
      );
      await notifier.updateLiteDetails(
        _id,
        description: 'd',
        locationAddress: 'a',
        venueName: ' Sân B ',
      );

      final patches = adapter.requests
          .where((r) => r.method == 'PATCH')
          .map((r) => r.body!)
          .toList();
      expect(patches[0]['description'], 'mô tả');
      expect(patches[0]['locationAddress'], 'địa chỉ');
      expect(
        (patches[0]['tournamentConfig'] as Map).containsKey('location'),
        isFalse,
      );
      expect(
        ((patches[1]['tournamentConfig'] as Map)['location']
            as Map)['venueName'],
        'Sân B',
      );
      expect(_state(c).venueName, 'Sân B');
      await _settleSaveStatus();
    });

    test('updateMatchType is blocked while players are registered', () async {
      final adapter = _adapter(participants: [_complete('p1')]);
      final (c, notifier) = await _loaded(adapter);
      final before = adapter.requests.length;

      final ok = await notifier.updateMatchType(_id, 'SINGLES');

      expect(ok, isFalse);
      expect(adapter.requests.skip(before), isEmpty);
      expect(_state(c).formatSaving, isFalse);
    });

    test(
      'updateMatchType patches the division config for a valid change',
      () async {
        final adapter = _adapter(
          routes: {
            'PATCH /tournaments/$_id/divisions/d1/config': const FakeReply(
              200,
              {},
            ),
          },
        );
        final (c, notifier) = await _loaded(adapter);

        final changed = await notifier.updateMatchType(_id, ' mixed_doubles ');
        final same = await notifier.updateMatchType(_id, 'doubles');
        final invalid = await notifier.updateMatchType(_id, 'TRIPLES');

        expect(changed, isTrue);
        expect(same, isTrue); // already DOUBLES: no request needed
        expect(invalid, isFalse);
        final patches = adapter.requests.where((r) => r.method == 'PATCH');
        expect(patches.single.body, {
          'matchType': 'MIXED_DOUBLES',
          'genderRestriction': 'MIXED',
        });
        expect(_state(c).formatSaving, isFalse);
      },
    );

    test('football tournaments only accept SINGLES', () async {
      final adapter = _adapter(
        tournament: {'sport': 'football'},
        divisions: const [
          {'id': 'd1', 'matchType': 'DOUBLES'},
        ],
      );
      final (_, notifier) = await _loaded(adapter);

      expect(await notifier.updateMatchType(_id, 'MIXED_DOUBLES'), isFalse);
    });
  });
}
