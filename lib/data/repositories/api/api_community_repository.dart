import 'package:app_quanly_giaidau/core/services/app_logger.dart';
import 'package:app_quanly_giaidau/core/services/dio_client.dart';
import 'package:app_quanly_giaidau/domain/entities/community.dart';
import 'package:app_quanly_giaidau/domain/repositories/community_repository.dart';
import 'package:app_quanly_giaidau/data/models/community_member_model.dart';
import 'package:app_quanly_giaidau/data/models/community_tournament_model.dart';
import 'package:app_quanly_giaidau/data/models/gallery_image_model.dart';
import 'package:app_quanly_giaidau/data/models/community_ranking_model.dart';
import 'package:app_quanly_giaidau/data/models/community_invite_model.dart';

class ApiCommunityRepository implements ICommunityRepository {
  static const _log = AppLogger('ApiCommunityRepo');
  final DioClient _dioClient;

  ApiCommunityRepository(this._dioClient);

  @override
  Future<List<Community>> getCommunities({String? search, int page = 1, int limit = 20}) async {
    _log.info('Lấy danh sách CLB: search=$search, page=$page');
    try {
      final params = <String, dynamic>{'page': page, 'limit': limit};
      if (search != null && search.isNotEmpty) params['search'] = search;

      final response = await _dioClient.dio.get('/communities', queryParameters: params);
      if (response.statusCode == 200) {
        final data = response.data['data'] as List<dynamic>? ?? [];
        return data.map((e) => Community.fromJson(e as Map<String, dynamic>)).toList();
      }
      _log.warning('getCommunities status=${response.statusCode}');
      return [];
    } catch (e, stack) {
      _log.error('Lỗi lấy danh sách CLB', e, stack);
      return [];
    }
  }

  @override
  Future<List<Community>> getMyCommunities() async {
    _log.info('Lấy CLB của tôi');
    try {
      final response = await _dioClient.dio.get('/communities/my');
      if (response.statusCode == 200) {
        final data = response.data['data'] as List<dynamic>? ?? [];
        return data.map((e) => Community.fromJson(e as Map<String, dynamic>)).toList();
      }
      _log.warning('getMyCommunities status=${response.statusCode}');
      return [];
    } catch (e, stack) {
      _log.error('Lỗi lấy CLB của tôi', e, stack);
      return [];
    }
  }

  @override
  Future<Community?> getCommunityById(String id) async {
    _log.info('Lấy chi tiết CLB: $id');
    try {
      final response = await _dioClient.dio.get('/communities/$id');
      if (response.statusCode == 200) {
        final data = response.data['data'] as Map<String, dynamic>? ?? response.data as Map<String, dynamic>?;
        if (data != null) return Community.fromJson(data);
      }
      _log.warning('getCommunityById status=${response.statusCode}');
      return null;
    } catch (e, stack) {
      _log.error('Lỗi lấy chi tiết CLB', e, stack);
      return null;
    }
  }

  @override
  Future<List<CommunityMemberModel>> getMembers(String communityId, {int page = 1, int limit = 50}) async {
    _log.info('Lấy thành viên CLB: $communityId');
    try {
      final response = await _dioClient.dio.get(
        '/communities/$communityId/members',
        queryParameters: {'page': page, 'limit': limit},
      );
      if (response.statusCode == 200) {
        final raw = response.data;
        final data = raw is Map ? (raw['data'] as List<dynamic>? ?? []) : (raw as List<dynamic>? ?? []);
        return data.map((e) => CommunityMemberModel.fromJson(e as Map<String, dynamic>)).toList();
      }
      _log.warning('getMembers status=${response.statusCode}');
      return [];
    } catch (e, stack) {
      _log.error('Lỗi lấy thành viên CLB', e, stack);
      return [];
    }
  }

  @override
  Future<bool> joinCommunity(String communityId, {Map<String, dynamic>? answers}) async {
    _log.info('Tham gia CLB: $communityId');
    try {
      await _dioClient.dio.post('/communities/$communityId/join', data: answers ?? {});
      _log.success('Tham gia CLB $communityId thành công');
      return true;
    } catch (e, stack) {
      _log.error('Lỗi tham gia CLB', e, stack);
      return false;
    }
  }

  @override
  Future<bool> leaveCommunity(String communityId, String userId) async {
    _log.info('Rời CLB: $communityId');
    try {
      await _dioClient.dio.delete('/communities/$communityId/members/$userId');
      _log.success('Rời CLB $communityId thành công');
      return true;
    } catch (e, stack) {
      _log.error('Lỗi rời CLB', e, stack);
      return false;
    }
  }

  @override
  Future<List<CommunityTournamentModel>> getTournaments(String communityId) async {
    _log.info('Lấy giải đấu của CLB: $communityId');
    try {
      final response = await _dioClient.dio.get('/communities/$communityId/tournaments');
      if (response.statusCode == 200) {
        final raw = response.data;
        final data = raw is Map ? (raw['data'] as List<dynamic>? ?? []) : (raw as List<dynamic>? ?? []);
        return data.map((e) => CommunityTournamentModel.fromJson(e as Map<String, dynamic>)).toList();
      }
      _log.warning('getTournaments status=${response.statusCode}');
      return [];
    } catch (e, stack) {
      _log.error('Lỗi lấy giải đấu của CLB', e, stack);
      return [];
    }
  }

  @override
  Future<CommunityTournamentModel?> createTournament(String communityId, Map<String, dynamic> data) async {
    _log.info('Tạo giải đấu trong CLB: $communityId');
    try {
      final response = await _dioClient.dio.post('/tournaments', data: {
        ...data,
        'communityId': communityId,
      });
      if (response.statusCode == 201) {
        final d = response.data['data'] as Map<String, dynamic>? ?? response.data as Map<String, dynamic>?;
        if (d != null) {
          _log.success('Tạo giải đấu trong CLB thành công');
          return CommunityTournamentModel.fromJson(d);
        }
      }
      return null;
    } catch (e, stack) {
      _log.error('Lỗi tạo giải đấu trong CLB', e, stack);
      return null;
    }
  }

  @override
  Future<Community?> createCommunity(Map<String, dynamic> data) async {
    _log.info('Tạo CLB mới');
    try {
      final response = await _dioClient.dio.post('/communities', data: data);
      if (response.statusCode == 201) {
        final d = response.data['data'] as Map<String, dynamic>? ?? response.data as Map<String, dynamic>?;
        if (d != null) {
          _log.success('Tạo CLB mới thành công');
          return Community.fromJson(d);
        }
      }
      _log.warning('createCommunity status=${response.statusCode}');
      return null;
    } catch (e, stack) {
      _log.error('Lỗi tạo CLB', e, stack);
      return null;
    }
  }

  @override
  Future<List<GalleryImageModel>> getGallery(String communityId) async {
    _log.info('Lấy gallery CLB: $communityId');
    try {
      final response = await _dioClient.dio.get('/communities/$communityId/gallery');
      if (response.statusCode == 200) {
        final raw = response.data;
        final data = raw is Map ? (raw['data'] as List<dynamic>? ?? []) : (raw as List<dynamic>? ?? []);
        return data.map((e) => GalleryImageModel.fromJson(e as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (e, stack) {
      _log.error('Lỗi lấy gallery CLB', e, stack);
      return [];
    }
  }

  @override
  Future<List<CommunityRankingModel>> getRankings(String communityId, {int limit = 50}) async {
    _log.info('Lấy bảng xếp hạng CLB: $communityId');
    try {
      final response = await _dioClient.dio.get('/communities/$communityId/rankings', queryParameters: {'limit': limit});
      if (response.statusCode == 200) {
        final raw = response.data;
        final data = raw is Map ? (raw['data'] as List<dynamic>? ?? []) : (raw as List<dynamic>? ?? []);
        return data.map((e) => CommunityRankingModel.fromJson(e as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (e, stack) {
      _log.error('Lỗi lấy bảng xếp hạng CLB', e, stack);
      return [];
    }
  }

  // ─── Join Requests ─────────────────────────────────────────────

  @override
  Future<List<CommunityMemberModel>> getJoinRequests(String communityId) async {
    _log.info('Lấy yêu cầu tham gia CLB: $communityId');
    try {
      final response = await _dioClient.dio.get('/communities/$communityId/join-requests');
      if (response.statusCode == 200) {
        final raw = response.data;
        final data = raw is Map ? (raw['data'] as List<dynamic>? ?? []) : (raw as List<dynamic>? ?? []);
        return data.map((e) => CommunityMemberModel.fromJson(e as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (e, stack) {
      _log.error('Lỗi lấy yêu cầu tham gia', e, stack);
      return [];
    }
  }

  @override
  Future<void> reviewJoinRequest(String communityId, String memberId, String action) async {
    _log.info('$action yêu cầu tham gia: $memberId');
    await _dioClient.dio.patch(
      '/communities/$communityId/join-requests/$memberId',
      data: {'action': action},
    );
  }

  // ─── Admin: Pending Clubs ───────────────────────────────────────

  @override
  Future<List<Community>> getPendingCommunities() async {
    _log.info('Lấy danh sách CLB chờ duyệt');
    try {
      final response = await _dioClient.dio.get('/communities', queryParameters: {'status': 'PENDING'});
      if (response.statusCode == 200) {
        final data = response.data['data'] as List<dynamic>? ?? [];
        return data.map((e) => Community.fromJson(e as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (e, stack) {
      _log.error('Lỗi lấy CLB chờ duyệt', e, stack);
      return [];
    }
  }

  @override
  Future<void> reviewCommunity(String communityId, String status, {String? rejectedReason}) async {
    _log.info('$status CLB: $communityId');
    final body = <String, dynamic>{'status': status};
    if (rejectedReason != null) body['rejectedReason'] = rejectedReason;
    await _dioClient.dio.patch('/communities/$communityId/review', data: body);
  }

  // ─── Member Management ──────────────────────────────────────────

  @override
  Future<void> updateMemberRole(String communityId, String memberId, String role) async {
    _log.info('Cập nhật role thành viên: $memberId → $role');
    await _dioClient.dio.patch(
      '/communities/$communityId/members/$memberId/role',
      data: {'role': role},
    );
  }

  @override
  @override
  Future<void> removeMember(String communityId, String userId) async {
    _log.info('Xoá thành viên: $userId khỏi CLB $communityId');
    await _dioClient.dio.delete('/communities/$communityId/members/$userId');
  }

  @override
  Future<void> inviteMember(String communityId, String userId, {String role = 'MEMBER'}) async {
    _log.info('Mời thành viên $userId vào CLB $communityId với role $role');
    await _dioClient.dio.post('/communities/$communityId/invite', data: {
      'userId': userId,
      'role': role,
    });
  }

  @override
  Future<void> respondToInvite(String communityId, String action) async {
    _log.info('$action lời mời từ CLB $communityId');
    await _dioClient.dio.post('/communities/$communityId/invite/$action');
  }

  @override
  Future<void> unbanMember(String communityId, String userId) async {
    _log.info('Gỡ cấm $userId khỏi CLB $communityId');
    await _dioClient.dio.post('/communities/$communityId/unban/$userId');
  }

  @override
  Future<List<CommunityInviteModel>> getMyInvites() async {
    _log.info('Lấy danh sách lời mời CLB của tôi');
    try {
      final response = await _dioClient.dio.get('/communities/my/invites');
      if (response.statusCode == 200) {
        final raw = response.data;
        final data = raw is Map ? (raw['data'] as List<dynamic>? ?? []) : (raw as List<dynamic>? ?? []);
        return data.map((e) => CommunityInviteModel.fromJson(e as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (e, stack) {
      _log.error('Lỗi lấy lời mời CLB', e, stack);
      return [];
    }
  }

  @override
  Future<Community> updateCommunity(String communityId, Map<String, dynamic> data) async {
    _log.info('Cập nhật thông tin CLB: $communityId');
    try {
      final response = await _dioClient.dio.patch(
        '/communities/$communityId',
        data: data,
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final result = response.data['data'] as Map<String, dynamic>? ?? response.data;
        return Community.fromJson(result);
      }
      throw Exception('Cập nhật CLB thất bại');
    } catch (e, stack) {
      _log.error('Lỗi cập nhật CLB', e, stack);
      rethrow;
    }
  }
}
