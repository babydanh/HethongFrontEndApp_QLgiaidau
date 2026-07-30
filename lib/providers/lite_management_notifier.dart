import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:app_quanly_giaidau/core/di/core_di_providers.dart';
import 'package:app_quanly_giaidau/core/services/app_logger.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';

// ──────────────────────────────────────────────
// Data models (shared with LitePairingScreen)
// ──────────────────────────────────────────────

class LiteParticipant {
  final String id;
  final String status;
  final String teamName;
  final List<LiteMember> members;

  const LiteParticipant({
    required this.id,
    required this.status,
    this.teamName = '',
    this.members = const [],
  });

  factory LiteParticipant.fromJson(Map<String, dynamic> json) {
    final membersList =
        (json['rosters'] as List<dynamic>?)
            ?.map(
              (m) => LiteMember.fromRosterJson(
                Map<String, dynamic>.from(m as Map),
              ),
            )
            .toList() ??
        [];
    return LiteParticipant(
      id: json['id']?.toString() ?? '',
      status: (json['teamStatus']?.toString() ?? '').toUpperCase(),
      teamName: json['teamName']?.toString() ?? '',
      members: membersList,
    );
  }

  bool get isPending => status == 'PENDING_PARTNER';
  bool get isComplete => status == 'COMPLETE' || status == 'PENDING_APPROVAL';

  String get displayName => teamName.isNotEmpty
      ? teamName
      : members.map((m) => m.fullName).join(' & ');
}

class LiteMember {
  final String id;
  final String fullName;
  final String avatarUrl;

  const LiteMember({required this.id, this.fullName = '', this.avatarUrl = ''});

  factory LiteMember.fromRosterJson(Map<String, dynamic> json) {
    final profile = json['profile'] is Map
        ? Map<String, dynamic>.from(json['profile'] as Map)
        : const <String, dynamic>{};
    return LiteMember(
      id: json['userId']?.toString() ?? '',
      fullName: profile['fullName']?.toString() ?? '',
      avatarUrl: profile['avatarUrl']?.toString() ?? '',
    );
  }
}

// ──────────────────────────────────────────────
// State
// ──────────────────────────────────────────────

class LiteManagementState {
  final bool loading;
  final String? error;
  final Tournament? tournament;
  final List<LiteParticipant> participants;
  final Set<String> selectedIds;
  final bool pairing;
  final bool generating;
  final String? generatingStrategy;
  final bool creatingBracket;
  final bool mockLoading;
  final String? matchType;
  final String? tournamentName;
  final String? inviteCode;
  final bool hasBracket;

  const LiteManagementState({
    this.loading = true,
    this.error,
    this.tournament,
    this.participants = const [],
    this.selectedIds = const {},
    this.pairing = false,
    this.generating = false,
    this.generatingStrategy,
    this.creatingBracket = false,
    this.mockLoading = false,
    this.matchType,
    this.tournamentName,
    this.inviteCode,
    this.hasBracket = false,
  });

  LiteManagementState copyWith({
    bool? loading,
    String? error,
    bool? clearError,
    Tournament? tournament,
    bool? clearTournament,
    List<LiteParticipant>? participants,
    Set<String>? selectedIds,
    bool? pairing,
    bool? generating,
    String? generatingStrategy,
    bool? creatingBracket,
    bool? mockLoading,
    String? matchType,
    String? tournamentName,
    String? inviteCode,
    bool? hasBracket,
  }) {
    return LiteManagementState(
      loading: loading ?? this.loading,
      error: clearError == true ? null : (error ?? this.error),
      tournament: clearTournament == true
          ? null
          : (tournament ?? this.tournament),
      participants: participants ?? this.participants,
      selectedIds: selectedIds ?? this.selectedIds,
      pairing: pairing ?? this.pairing,
      generating: generating ?? this.generating,
      generatingStrategy: generatingStrategy ?? this.generatingStrategy,
      creatingBracket: creatingBracket ?? this.creatingBracket,
      mockLoading: mockLoading ?? this.mockLoading,
      matchType: matchType ?? this.matchType,
      tournamentName: tournamentName ?? this.tournamentName,
      inviteCode: inviteCode ?? this.inviteCode,
      hasBracket: hasBracket ?? this.hasBracket,
    );
  }

  // Derived
  List<LiteParticipant> get pendingParticipants =>
      participants.where((p) => p.isPending).toList();

  List<LiteParticipant> get completeParticipants =>
      participants.where((p) => p.isComplete).toList();

  bool get isDoubles =>
      matchType?.toUpperCase() == 'DOUBLES' ||
      matchType?.toUpperCase() == 'DOUBLE';
}

// ──────────────────────────────────────────────
// Provider
// ──────────────────────────────────────────────

final liteManagementProvider =
    NotifierProvider<LiteManagementNotifier, LiteManagementState>(
      LiteManagementNotifier.new,
    );

class LiteManagementNotifier extends Notifier<LiteManagementState> {
  static const _log = AppLogger('LiteManage');

  @override
  LiteManagementState build() => const LiteManagementState();

  void markLoadFailed(String message) {
    state = state.copyWith(loading: false, error: message);
  }

  Dio get _dio => ref.read(dioClientProvider).dio;

  String _apiError(DioException error, String fallback) {
    final data = error.response?.data;
    if (data is Map && data['message'] != null) {
      return data['message'].toString();
    }
    if (error.response?.statusCode == 401) {
      return 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.';
    }
    if (error.response?.statusCode == 403) {
      return 'Bạn không có quyền quản lý giải Lite này.';
    }
    return fallback;
  }

  // ─── Initialize with tournament ID (called from screen) ───

  Future<void> init(String tournamentId) async {
    state = const LiteManagementState(loading: true);
    try {
      await Future.wait([
        _fetchTournament(tournamentId),
        _fetchParticipants(tournamentId),
        _fetchBracket(tournamentId),
      ]).timeout(const Duration(seconds: 15));
    } on TimeoutException {
      state = state.copyWith(
        loading: false,
        error: 'Tải dữ liệu giải Lite quá lâu. Vui lòng thử lại.',
      );
    } catch (e, stack) {
      _log.error('Lỗi khởi tạo quản lý Lite', e, stack);
      state = state.copyWith(
        loading: false,
        error: 'Không thể tải dữ liệu giải Lite. Vui lòng thử lại.',
      );
    }
  }

  // ─── Fetch tournament details ───

  Future<void> _fetchTournament(String tournamentId) async {
    try {
      final res = await _dio
          .get('/tournaments/$tournamentId')
          .timeout(const Duration(seconds: 12));
      final envelope = res.data;
      final payload = envelope is Map ? envelope['data'] : envelope;
      if (payload is Map) {
        final config = payload['tournamentConfig'];
        final mode = config is Map ? config['mode']?.toString().toUpperCase() : null;
        if (mode != null && mode != 'LITE') {
          state = state.copyWith(
            loading: false,
            error: 'Đây là giải Nâng Cao. App chỉ hỗ trợ quản lý giải Lite.',
          );
          return;
        }
        final rawMatchType =
            payload['matchType']?.toString().toUpperCase() ?? 'SINGLES';
        final rawName = payload['name']?.toString() ?? '';
        final rawInviteCode = payload['inviteCode']?.toString() ?? '';

        // Check for bracket existence
        final hasBracket =
            payload['hasBracket'] == true ||
            payload['bracketGenerated'] == true;

        Tournament? tournament;
        if (payload['id'] != null) {
          tournament = Tournament.fromJson(
            Map<String, dynamic>.from(payload),
            payload['id'].toString(),
          );
        }

        state = state.copyWith(
          tournament: tournament,
          matchType: rawMatchType,
          tournamentName: rawName,
          inviteCode: rawInviteCode,
          hasBracket: hasBracket,
        );
      }
    } catch (e, stack) {
      _log.error('Lỗi tải thông tin giải', e, stack);
      state = state.copyWith(
        loading: false,
        error: e is DioException
            ? _apiError(e, 'Không thể tải thông tin giải đấu')
            : 'Không thể tải thông tin giải đấu',
      );
    }
  }

  // ─── Fetch participants ───

  Future<void> _fetchParticipants(String tournamentId) async {
    state = state.copyWith(loading: true, error: null, clearError: true);
    try {
      final res = await _dio
          .get('/tournaments/lite/$tournamentId/participants')
          .timeout(const Duration(seconds: 12));
      final envelope = res.data;
      final payload = envelope is Map ? envelope['data'] : envelope;
      final rawParticipants = payload is List ? payload : const <dynamic>[];

      final parsed = rawParticipants
          .map(
            (e) =>
                LiteParticipant.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList();

      state = state.copyWith(
        loading: false,
        participants: parsed,
        selectedIds: {},
      );
    } catch (e, stack) {
      _log.error('Lỗi tải danh sách người tham gia', e, stack);
      state = state.copyWith(
        loading: false,
        error: e is DioException
            ? _apiError(e, 'Không thể tải danh sách người tham gia')
            : 'Không thể tải danh sách người tham gia',
      );
    }
  }

  Future<void> _fetchBracket(String tournamentId) async {
    try {
      final res = await _dio
          .get('/tournaments/$tournamentId/bracket')
          .timeout(const Duration(seconds: 12));
      final envelope = res.data;
      final payload = envelope is Map ? envelope['data'] : envelope;
      final stages = payload is Map ? payload['stages'] : null;
      state = state.copyWith(hasBracket: stages is List && stages.isNotEmpty);
    } catch (e) {
      _log.debug('Chưa có bracket Lite hoặc chưa tải được bracket: $e');
      state = state.copyWith(hasBracket: false);
    }
  }

  // ─── Public methods ───

  Future<void> refresh(String tournamentId) async {
    state = const LiteManagementState(loading: true);
    try {
      await Future.wait([
        _fetchTournament(tournamentId),
        _fetchParticipants(tournamentId),
        _fetchBracket(tournamentId),
      ]).timeout(const Duration(seconds: 15));
    } on TimeoutException {
      state = state.copyWith(
        loading: false,
        error: 'Tải dữ liệu giải Lite quá lâu. Vui lòng thử lại.',
      );
    }
  }

  void toggleSelection(String id) {
    final ids = Set<String>.from(state.selectedIds);
    if (ids.contains(id)) {
      ids.remove(id);
    } else {
      if (ids.length >= 2) {
        ids.remove(ids.first);
      }
      ids.add(id);
    }
    state = state.copyWith(selectedIds: ids);
  }

  Future<void> manualPair(String tournamentId) async {
    if (state.selectedIds.length != 2) return;
    final ids = state.selectedIds.toList();
    state = state.copyWith(pairing: true);
    try {
      await _dio.post(
        '/tournaments/lite/$tournamentId/pairs',
        data: {'participant1Id': ids[0], 'participant2Id': ids[1]},
      );
      _log.success('Ghép cặp thủ công thành công');
      await _fetchParticipants(tournamentId);
    } on DioException catch (e) {
      _log.error('Lỗi ghép cặp', e);
      rethrow;
    } finally {
      state = state.copyWith(pairing: false);
    }
  }

  Future<void> generatePairs(String tournamentId, String strategy) async {
    state = state.copyWith(generating: true, generatingStrategy: strategy);
    try {
      final res = await _dio.post(
        '/tournaments/lite/$tournamentId/pairs/generate',
        data: {'strategy': strategy},
      );
      final data = res.data is Map ? (res.data as Map)['data'] as Map? : null;
      final unpairedIds =
          (data?['unpairedParticipantIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [];

      _log.success(
        'Sinh cặp $strategy: ${unpairedIds.isEmpty ? 'toàn bộ' : '${unpairedIds.length} người lẻ'}',
      );
      await _fetchParticipants(tournamentId);
    } on DioException catch (e) {
      _log.error('Lỗi sinh cặp $strategy', e);
      rethrow;
    } finally {
      state = state.copyWith(generating: false, generatingStrategy: null);
    }
  }

  Future<void> unpair(String tournamentId, String participantId) async {
    try {
      await _dio.post(
        '/tournaments/lite/$tournamentId/pairs/$participantId/unpair',
      );
      _log.success('Đã hủy ghép cặp: $participantId');
      await _fetchParticipants(tournamentId);
    } on DioException catch (e) {
      _log.error('Lỗi hủy cặp', e);
      rethrow;
    }
  }

  Future<void> createBracket(String tournamentId) async {
    state = state.copyWith(creatingBracket: true);
    try {
      // Lite has its own guarded endpoint, backed by the same persisted generator.
      await _dio.post(
        '/tournaments/lite/$tournamentId/bracket',
        data: {'seedingType': 'RANDOM'},
      );
      _log.success('Tạo bracket thành công');
      state = state.copyWith(creatingBracket: false, hasBracket: true);
      await _fetchBracket(tournamentId);
    } on DioException catch (e) {
      _log.error('Lỗi tạo bracket', e);
      state = state.copyWith(creatingBracket: false);
      rethrow;
    }
  }

  Future<void> resetBracket(String tournamentId) async {
    state = state.copyWith(creatingBracket: true);
    try {
      await _dio.post('/tournaments/lite/$tournamentId/bracket/reset');
      await _fetchBracket(tournamentId);
      _log.success('Đã reset bracket Lite');
    } on DioException catch (e) {
      _log.error('Lỗi reset bracket', e);
      rethrow;
    } finally {
      state = state.copyWith(creatingBracket: false);
    }
  }

  Future<void> seedMock(String tournamentId, int count) async {
    state = state.copyWith(mockLoading: true);
    try {
      final names = List.generate(count, (i) => 'VĐV ảo ${i + 1}');
      await _dio.post(
        '/tournaments/$tournamentId/mock-participants',
        data: {'names': names},
      );
      _log.success('Đã tạo $count VĐV ảo');
      await _fetchParticipants(tournamentId);
    } on DioException catch (e) {
      _log.error('Lỗi tạo VĐV ảo', e);
      rethrow;
    } finally {
      state = state.copyWith(mockLoading: false);
    }
  }
}
