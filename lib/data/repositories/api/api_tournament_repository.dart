import 'package:app_quanly_giaidau/core/services/app_logger.dart';
import 'package:app_quanly_giaidau/core/services/dio_client.dart';
import 'package:app_quanly_giaidau/data/models/tournament_model.dart';
import 'package:app_quanly_giaidau/domain/repositories/tournament_repository.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament_workspace.dart';

class ApiTournamentRepository implements ITournamentRepository {
  static const _log = AppLogger('ApiTournamentRepo');
  final DioClient _dioClient;

  ApiTournamentRepository(this._dioClient);

  @override
  Future<Tournament> create(Tournament tournament) async {
    _log.info('Creating tournament via API: ${tournament.name}');
    final payload = {
      'name': tournament.name,
      'categoryId': tournament.category ?? 'badminton',
      'tournamentType': 'PUBLIC',
      'matchType': tournament.format == 'Doubles' ? 'DOUBLES' : 'SINGLES',
      'description': tournament.description,
      'entryFee': 0,
      'sportRules': {
        'sets': 3,
        'pointsPerSet': 21,
      },
      'tournamentConfig': {
        'bracketType': tournament.bracketType,
        'maxTeams': tournament.maxTeams,
        'roundRobinLegs': tournament.roundCount,
      },
    };
    final response = await _dioClient.dio.post('/tournaments', data: payload);
    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = response.data['data'];
      return Tournament.fromJson(data, data['id']);
    }
    throw Exception('Failed to create tournament via API');
  }

  @override
  Future<Tournament?> getById(String id) async {
    _log.debug('Fetching tournament by id via API: $id');
    try {
      final response = await _dioClient.dio.get('/tournaments/$id');
      if (response.statusCode == 200) {
        final data = response.data['data'];
        if (data != null) {
          return Tournament.fromJson(data, id);
        }
      }
      return null;
    } catch (e, stack) {
      _log.error('Error fetching tournament by id', e, stack);
      return null;
    }
  }

  @override
  Future<TournamentWorkspace> getMyWorkspace() async {
    _log.debug('Fetching tournament workspace for current user');
    try {
      final response = await _dioClient.dio.get('/tournaments/workspace/me');
      final raw = response.data;
      final data = raw is Map<String, dynamic>
          ? (raw['data'] as Map<String, dynamic>? ?? raw)
          : <String, dynamic>{};
      return TournamentWorkspace.fromJson(data);
    } catch (e, stack) {
      _log.error('Error fetching tournament workspace', e, stack);
      rethrow;
    }
  }

  @override
  Future<void> respondToRefereeInvite({
    required String tournamentId,
    required String refereeId,
    required String action,
  }) async {
    _log.info('Responding referee invite: $tournamentId / $refereeId -> $action');
    await _dioClient.dio.patch(
      '/tournaments/$tournamentId/referees/$refereeId/respond',
      data: {'action': action},
    );
  }

  @override
  Stream<Tournament?> watch(String id) async* {
    yield await getById(id);
    yield* Stream.periodic(const Duration(seconds: 10))
        .asyncMap((_) => getById(id));
  }

  @override
  Stream<List<Tournament>> watchAll() async* {
    try {
      final response = await _dioClient.dio.get('/tournaments/public');
      if (response.statusCode == 200) {
        final List<dynamic> list = response.data['data'] ?? [];
        yield list.map((json) => Tournament.fromJson(json, json['id'])).toList();
      } else {
        yield <Tournament>[];
      }
    } catch (e, stack) {
      _log.error('Error fetching initial public tournaments', e, stack);
      yield <Tournament>[];
    }

    yield* Stream.periodic(const Duration(seconds: 15))
        .asyncMap((_) async {
          try {
            final response = await _dioClient.dio.get('/tournaments/public');
            if (response.statusCode == 200) {
              final List<dynamic> list = response.data['data'] ?? [];
              return list.map((json) => Tournament.fromJson(json, json['id'])).toList();
            }
          } catch (e, stack) {
            _log.error('Error polling public tournaments', e, stack);
          }
          return <Tournament>[];
        });
  }

  @override
  Future<void> update(String id, Map<String, dynamic> data) async {
    _log.info('Updating tournament $id via API: $data');
    await _dioClient.dio.patch('/tournaments/$id', data: data);
  }

  @override
  Future<void> updateStatus(String id, String status) async {
    _log.info('Updating tournament status $id → $status');
    await _dioClient.dio.patch('/tournaments/$id', data: {'status': status});
  }

  @override
  Future<void> updateToken(String id, String role, String newToken) async {
    // Thường được Web Admin quản lý
    _log.warning('updateToken not supported/required directly from mobile API client.');
  }

  @override
  Future<void> delete(String id) async {
    _log.info('Deleting tournament $id via API');
    await _dioClient.dio.delete('/tournaments/$id');
  }

  // ─── Follow / Unfollow ──────────────────────────────────

  @override
  Future<void> followTournament(String id) async {
    _log.info('Following tournament $id');
    await _dioClient.dio.post('/tournaments/$id/follow');
  }

  @override
  Future<void> unfollowTournament(String id) async {
    _log.info('Unfollowing tournament $id');
    await _dioClient.dio.delete('/tournaments/$id/follow');
  }

  @override
  Future<bool> isFollowing(String id) async {
    try {
      final followed = await getFollowedTournaments();
      return followed.any((t) => t.id == id);
    } catch (_) {
      return false;
    }
  }

  @override
  Future<List<Tournament>> getFollowedTournaments() async {
    try {
      final response = await _dioClient.dio.get('/tournaments/my/followed');
      if (response.statusCode == 200) {
        final data = response.data['data'] as List<dynamic>? ?? [];
        return data.map((json) => Tournament.fromJson(json as Map<String, dynamic>, json['id'])).toList();
      }
      return [];
    } catch (e, stack) {
      _log.error('Lỗi lấy danh sách theo dõi', e, stack);
      return [];
    }
  }
}
