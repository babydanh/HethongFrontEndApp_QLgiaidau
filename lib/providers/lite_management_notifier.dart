import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:app_quanly_giaidau/core/di/core_di_providers.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/core/services/app_logger.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/core/utils/date_parser.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/locale_provider.dart';

// ──────────────────────────────────────────────
// Data models (shared with LitePairingScreen)
// ──────────────────────────────────────────────

class LiteParticipant {
  final String id;
  final String status;
  final String teamName;
  final String? footballTeamId;
  final String? footballTeamLogoUrl;
  final List<LiteMember> members;

  const LiteParticipant({
    required this.id,
    required this.status,
    this.teamName = '',
    this.footballTeamId,
    this.footballTeamLogoUrl,
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
      footballTeamId: json['footballTeamId']?.toString(),
      footballTeamLogoUrl: json['footballTeamLogoUrl']?.toString(),
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
  final String role;

  const LiteMember({
    required this.id,
    this.fullName = '',
    this.avatarUrl = '',
    this.role = '',
  });

  factory LiteMember.fromRosterJson(Map<String, dynamic> json) {
    final profile = json['profile'] is Map
        ? Map<String, dynamic>.from(json['profile'] as Map)
        : const <String, dynamic>{};
    return LiteMember(
      id: json['userId']?.toString() ?? '',
      fullName: profile['fullName']?.toString() ?? '',
      avatarUrl: profile['avatarUrl']?.toString() ?? '',
      role: json['role']?.toString().toUpperCase() ?? '',
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
  final bool formatSaving;
  final String? matchType;
  final String? tournamentName;
  final String? inviteCode;
  final bool hasBracket;
  final bool rosterConfirmed;
  final List<MatchModel> matches;
  final String? matchesError;
  final DateTime? startDate;
  final int? durationMinutes;
  final int? maxParticipants;
  final String? venueName;
  final String? locationAddress;
  final String? description;
  final String detailsSaveStatus; // 'idle', 'saving', 'saved'

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
    this.formatSaving = false,
    this.matchType,
    this.tournamentName,
    this.inviteCode,
    this.hasBracket = false,
    this.rosterConfirmed = false,
    this.matches = const [],
    this.matchesError,
    this.startDate,
    this.durationMinutes,
    this.maxParticipants,
    this.venueName,
    this.locationAddress,
    this.description,
    this.detailsSaveStatus = 'idle',
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
    bool? formatSaving,
    String? matchType,
    String? tournamentName,
    String? inviteCode,
    bool? hasBracket,
    bool? rosterConfirmed,
    List<MatchModel>? matches,
    String? matchesError,
    bool? clearMatchesError,
    DateTime? startDate,
    int? durationMinutes,
    int? maxParticipants,
    String? venueName,
    String? locationAddress,
    String? description,
    String? detailsSaveStatus,
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
      formatSaving: formatSaving ?? this.formatSaving,
      matchType: matchType ?? this.matchType,
      tournamentName: tournamentName ?? this.tournamentName,
      inviteCode: inviteCode ?? this.inviteCode,
      hasBracket: hasBracket ?? this.hasBracket,
      rosterConfirmed: rosterConfirmed ?? this.rosterConfirmed,
      matches: matches ?? this.matches,
      matchesError: clearMatchesError == true
          ? null
          : (matchesError ?? this.matchesError),
      startDate: startDate ?? this.startDate,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      venueName: venueName ?? this.venueName,
      locationAddress: locationAddress ?? this.locationAddress,
      description: description ?? this.description,
      detailsSaveStatus: detailsSaveStatus ?? this.detailsSaveStatus,
    );
  }

  // Derived
  List<LiteParticipant> get pendingParticipants =>
      participants.where((p) => p.isPending).toList();

  List<LiteParticipant> get completeParticipants =>
      participants.where((p) => p.isComplete).toList();

  // Backend bracket generators only seed COMPLETE records (or mock records).
  // Keep PENDING_APPROVAL visible in the roster, but never count it as
  // bracket-eligible until the registration is approved.
  List<LiteParticipant> get bracketEligibleParticipants =>
      participants.where((p) => p.status == 'COMPLETE').toList();

  /// Total eligible units (singles players or doubles pairs).
  /// For doubles: paired count + auto-pairable pairs from pending pool.
  int get bracketEligibleCount {
    if (isDoubles) {
      return completeParticipants.length + (pendingParticipants.length ~/ 2);
    }
    return participants.length;
  }

  bool get isDoubles {
    // Football uses the generic SINGLES match type for team-vs-team.
    // Legacy football divisions may still carry DOUBLES, so football must
    // take precedence and never enter the partner-pairing flow.
    if (isFootball) return false;
    final normalized = matchType?.toUpperCase();
    return normalized == 'DOUBLES' ||
        normalized == 'DOUBLE' ||
        normalized == 'MIXED_DOUBLES' ||
        normalized == 'MIXED-DOUBLES';
  }

  bool get isFootball {
    final tournamentSport = tournament?.sport.toLowerCase() ?? '';
    final tournamentCategory = tournament?.category?.toLowerCase() ?? '';
    return tournamentSport.contains('football') ||
        tournamentSport.contains('soccer') ||
        tournamentCategory.contains('bóng đá') ||
        tournamentCategory.contains('football') ||
        participants.any((participant) => participant.footballTeamId != null);
  }
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
  bool _loadInFlight = false;

  @override
  LiteManagementState build() => const LiteManagementState();

  void markLoadFailed(String message) {
    state = state.copyWith(loading: false, error: message);
  }

  Dio get _dio => ref.read(dioClientProvider).dio;

  AppLocalizations get _l10n =>
      lookupAppLocalizations(ref.read(localeProvider));

  String _apiError(DioException error, String fallback) {
    final data = error.response?.data;
    if (data is Map && data['message'] != null) {
      return data['message'].toString();
    }
    if (error.response?.statusCode == 401) {
      return _l10n.lite_apiSessionExpired;
    }
    if (error.response?.statusCode == 403) {
      return _l10n.lite_apiForbidden;
    }
    if (error.response?.statusCode == 429) {
      return _l10n.lite_apiRateLimited;
    }
    if ((error.response?.statusCode ?? 0) >= 500) {
      return _l10n.lite_apiServerBusy;
    }
    return fallback;
  }

  String _canonicalMatchType(Map<String, dynamic> payload) {
    final divisions = payload['divisions'];
    if (divisions is List && divisions.isNotEmpty && divisions.first is Map) {
      final division = Map<String, dynamic>.from(divisions.first as Map);
      final divisionMatchType = division['matchType']?.toString().toUpperCase();
      final divisionGender = division['genderRestriction']
          ?.toString()
          .toUpperCase();
      if (divisionMatchType == 'MIXED_DOUBLES' ||
          (divisionMatchType == 'DOUBLES' && divisionGender == 'MIXED')) {
        return 'MIXED_DOUBLES';
      }
      if (divisionMatchType != null && divisionMatchType.isNotEmpty) {
        return divisionMatchType;
      }
    }
    return payload['matchType']?.toString().toUpperCase() ?? 'SINGLES';
  }

  // ─── Initialize with tournament ID (called from screen) ───

  Future<void> init(String tournamentId) async {
    if (_loadInFlight) return;
    _loadInFlight = true;
    state = const LiteManagementState(loading: true);
    try {
      await Future.wait([
        _fetchTournament(tournamentId),
        _fetchParticipants(tournamentId),
      ]).timeout(const Duration(seconds: 15));
      await _fetchBracket(tournamentId, divisionId: _liteDivisionId);
      _loadInFlight = false;
    } on TimeoutException {
      _loadInFlight = false;
      state = state.copyWith(loading: false, error: _l10n.lite_loadTimeout);
    } catch (e, stack) {
      _loadInFlight = false;
      _log.error('Lỗi khởi tạo quản lý Lite', e, stack);
      state = state.copyWith(loading: false, error: _l10n.lite_loadError);
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
        final cfgMap = config is Map ? config : const <String, dynamic>{};
        final mode = cfgMap['mode']?.toString().toUpperCase();
        // isLite = LOẠI GIẢI lite. Fallback an toàn cho giải lite cũ
        // (mode='LITE' + hideAdvancedSettings=true) trước migration.
        final isLite =
            cfgMap['isLite'] == true ||
            (mode == 'LITE' && cfgMap['hideAdvancedSettings'] == true);
        if (!isLite) {
          state = state.copyWith(
            loading: false,
            error: _l10n.lite_tournamentTypeAdvanced,
          );
          return;
        }
        final rawMatchType = _canonicalMatchType(
          Map<String, dynamic>.from(payload),
        );

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

        final locConfig = cfgMap['location'] is Map
            ? Map<String, dynamic>.from(cfgMap['location'] as Map)
            : payload['location'] is Map
            ? Map<String, dynamic>.from(payload['location'] as Map)
            : const <String, dynamic>{};
        final initialVenue = locConfig['venueName']?.toString() ??
            (payload['venue'] is Map ? (payload['venue'] as Map)['name']?.toString() : null) ??
            '';
        final initialAddress = payload['locationAddress']?.toString() ??
            locConfig['address']?.toString() ??
            '';
        final initialDesc = payload['description']?.toString() ?? '';
        final initialMaxPart = int.tryParse(payload['maxParticipants']?.toString() ?? '') ??
            tournament?.maxTeams ??
            16;

        DateTime? parsedStartDate;
        int? parsedDurationMinutes;
        if (payload['startDate'] != null) {
          parsedStartDate = DateParser.parseDate(payload['startDate']);
          if (payload['endDate'] != null) {
            final parsedEndDate = DateParser.parseDate(payload['endDate']);
            if (parsedEndDate.isAfter(parsedStartDate)) {
              parsedDurationMinutes = parsedEndDate.difference(parsedStartDate).inMinutes;
            }
          } else if (cfgMap['durationMinutes'] != null) {
            parsedDurationMinutes = int.tryParse(cfgMap['durationMinutes'].toString());
          } else if (cfgMap['durationHours'] != null) {
            final dh = double.tryParse(cfgMap['durationHours'].toString()) ?? 1.5;
            parsedDurationMinutes = (dh * 60).round();
          }
        }

        state = state.copyWith(
          tournament: tournament,
          matchType: rawMatchType,
          tournamentName: rawName,
          inviteCode: rawInviteCode,
          hasBracket: hasBracket,
          rosterConfirmed: payload['isRegistrationLocked'] == true,
          startDate: parsedStartDate,
          durationMinutes: parsedDurationMinutes ?? 90,
          maxParticipants: initialMaxPart,
          venueName: initialVenue,
          locationAddress: initialAddress,
          description: initialDesc,
        );
      }
    } catch (e, stack) {
      _log.error('Lỗi tải thông tin giải', e, stack);
      state = state.copyWith(
        loading: false,
        error: e is DioException
            ? _apiError(e, _l10n.lite_tournamentLoadError)
            : _l10n.lite_tournamentLoadError,
      );
    }
  }

  // ─── Fetch participants ───

  Future<void> _fetchParticipants(String tournamentId) async {
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
            ? _apiError(e, _l10n.lite_participantsLoadError)
            : _l10n.lite_participantsLoadError,
      );
    }
  }

  String? get _liteDivisionId {
    final divisions =
        state.tournament?.divisions ?? const <TournamentDivision>[];
    final divisionId = divisions.isNotEmpty ? divisions.first.id.trim() : '';
    return divisionId.isEmpty ? null : divisionId;
  }

  Future<void> _fetchBracket(String tournamentId, {String? divisionId}) async {
    try {
      final res = await _dio
          .get(
            '/tournaments/$tournamentId/bracket',
            queryParameters: divisionId == null
                ? null
                : {'divisionId': divisionId},
          )
          .timeout(const Duration(seconds: 12));
      final envelope = res.data;
      final payload = envelope is Map ? envelope['data'] : envelope;
      final stages = payload is Map ? payload['stages'] : null;
      state = state.copyWith(hasBracket: stages is List && stages.isNotEmpty);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        state = state.copyWith(hasBracket: false);
      } else {
        _log.debug('Không tải được bracket Lite, giữ snapshot hiện tại: $e');
      }
    } catch (e) {
      _log.debug('Không tải được bracket Lite, giữ snapshot hiện tại: $e');
    }
  }

  Future<void> _fetchMatches(String tournamentId) async {
    try {
      final matches = await ref
          .read(matchRepositoryProvider)
          .getAllByTournament(tournamentId);
      state = state.copyWith(matches: matches, clearMatchesError: true);
    } catch (e, stack) {
      _log.error('Lỗi tải danh sách trận Lite', e, stack);
      final message = e is DioException
          ? _apiError(e, _l10n.lite_matchesLoadError)
          : _l10n.lite_matchesLoadError;
      // Preserve the last good snapshot. A transient 429/5xx must not look
      // like the tournament has no matches.
      state = state.copyWith(matchesError: message);
    }
  }

  // ─── Public methods ───

  Future<void> refresh(String tournamentId) async {
    if (_loadInFlight) return;
    _loadInFlight = true;
    state = state.copyWith(loading: true, clearError: true);
    try {
      await Future.wait([
        _fetchTournament(tournamentId),
        _fetchParticipants(tournamentId),
      ]).timeout(const Duration(seconds: 15));
      await _fetchBracket(tournamentId, divisionId: _liteDivisionId);
      _loadInFlight = false;
    } on TimeoutException {
      _loadInFlight = false;
      state = state.copyWith(loading: false, error: _l10n.lite_loadTimeout);
    }
  }

  Future<void> refreshMatches(String tournamentId) =>
      _fetchMatches(tournamentId);

  Future<bool> updateMatchType(String tournamentId, String matchType) async {
    final tournament = state.tournament;
    final division = tournament?.divisions.isNotEmpty == true
        ? tournament!.divisions.first
        : null;
    final normalized = matchType.trim().toUpperCase();
    final isFootball = state.isFootball;
    final lifecycleLocked =
        tournament == null ||
        division == null ||
        division.id.isEmpty ||
        state.hasBracket ||
        state.rosterConfirmed ||
        state.participants.isNotEmpty ||
        division.participantCount > 0 ||
        {
          'IN_PROGRESS',
          'ONGOING',
          'COMPLETED',
          'CANCELLED',
        }.contains(tournament.status.toUpperCase());

    if (lifecycleLocked ||
        (isFootball && normalized != 'SINGLES') ||
        !{'SINGLES', 'DOUBLES', 'MIXED_DOUBLES'}.contains(normalized)) {
      return false;
    }
    final currentMatchType =
        division.matchType.toUpperCase() == 'DOUBLES' &&
            division.genderRestriction?.trim().toUpperCase() == 'MIXED'
        ? 'MIXED_DOUBLES'
        : division.matchType.toUpperCase();
    if (normalized == currentMatchType) return true;

    state = state.copyWith(formatSaving: true);
    try {
      final participantsResponse = await _dio
          .get('/tournaments/lite/$tournamentId/participants')
          .timeout(const Duration(seconds: 12));
      final envelope = participantsResponse.data;
      final payload = envelope is Map ? envelope['data'] : envelope;
      if (payload is List && payload.isNotEmpty) return false;

      await _dio.patch(
        '/tournaments/$tournamentId/divisions/${division.id}/config',
        data: {
          'matchType': normalized,
          'genderRestriction': normalized == 'MIXED_DOUBLES' ? 'MIXED' : null,
        },
      );
      await _fetchTournament(tournamentId);
      return true;
    } catch (e, stack) {
      _log.error('Lỗi cập nhật thể thức giải Lite', e, stack);
      return false;
    } finally {
      state = state.copyWith(formatSaving: false);
    }
  }

  Future<bool> updateSchedule(
    String tournamentId, {
    required DateTime startDate,
    required int durationMinutes,
  }) async {
    final tournament = state.tournament;
    if (tournament == null ||
        {'IN_PROGRESS', 'ONGOING', 'COMPLETED', 'CANCELLED'}
            .contains(tournament.status.toUpperCase())) {
      return false;
    }
    state = state.copyWith(detailsSaveStatus: 'saving');
    try {
      final startIso = startDate.toIso8601String();
      final endIso = startDate.add(Duration(minutes: durationMinutes)).toIso8601String();
      final totalMinutes = durationMinutes;

      final nextTournamentConfig = {
        ...(tournament.locationConfig ?? {}),
        'durationHours': (totalMinutes / 60.0),
        'durationMinutes': totalMinutes,
      };

      await _dio.patch('/tournaments/$tournamentId', data: {
        'startDate': startIso,
        'endDate': endIso,
        'tournamentConfig': nextTournamentConfig,
      });

      state = state.copyWith(
        startDate: startDate,
        durationMinutes: durationMinutes,
        detailsSaveStatus: 'saved',
      );
      Future.delayed(const Duration(milliseconds: 2500), () {
        state = state.copyWith(detailsSaveStatus: 'idle');
      });
      return true;
    } catch (e, stack) {
      _log.error('Lỗi cập nhật lịch thi đấu Lite', e, stack);
      state = state.copyWith(detailsSaveStatus: 'idle');
      return false;
    }
  }

  Future<bool> updateMaxParticipants(
    String tournamentId,
    int maxParticipants,
  ) async {
    final tournament = state.tournament;
    if (tournament == null ||
        state.hasBracket ||
        {'IN_PROGRESS', 'ONGOING', 'COMPLETED', 'CANCELLED'}
            .contains(tournament.status.toUpperCase())) {
      return false;
    }
    state = state.copyWith(detailsSaveStatus: 'saving');
    try {
      final divisionId = _liteDivisionId;
      await _dio.patch('/tournaments/$tournamentId', data: {
        'maxParticipants': maxParticipants,
      });
      if (divisionId != null) {
        try {
          await _dio.patch(
            '/tournaments/$tournamentId/divisions/$divisionId/config',
            data: {'maxParticipants': maxParticipants},
          );
        } catch (_) {}
      }

      state = state.copyWith(
        maxParticipants: maxParticipants,
        detailsSaveStatus: 'saved',
      );
      Future.delayed(const Duration(milliseconds: 2500), () {
        state = state.copyWith(detailsSaveStatus: 'idle');
      });
      return true;
    } catch (e, stack) {
      _log.error('Lỗi cập nhật số lượng người tham gia Lite', e, stack);
      state = state.copyWith(detailsSaveStatus: 'idle');
      return false;
    }
  }

  Future<bool> updateLocation(
    String tournamentId, {
    required String venueName,
    required String locationAddress,
  }) async {
    final tournament = state.tournament;
    if (tournament == null ||
        {'IN_PROGRESS', 'ONGOING', 'COMPLETED', 'CANCELLED'}
            .contains(tournament.status.toUpperCase())) {
      return false;
    }
    state = state.copyWith(detailsSaveStatus: 'saving');
    try {
      final nextTournamentConfig = {
        ...(tournament.locationConfig ?? {}),
        'location': {
          if (venueName.trim().isNotEmpty) 'venueName': venueName.trim(),
          if (locationAddress.trim().isNotEmpty) 'address': locationAddress.trim(),
        },
      };

      await _dio.patch('/tournaments/$tournamentId', data: {
        'locationAddress': locationAddress.trim(),
        'tournamentConfig': nextTournamentConfig,
      });

      if (venueName.trim().isNotEmpty || locationAddress.trim().isNotEmpty) {
        try {
          await _dio.post('/tournaments/$tournamentId/venues', data: {
            'name': venueName.trim().isNotEmpty ? venueName.trim() : 'Sân thi đấu',
            'locationAddress': locationAddress.trim(),
          });
        } catch (_) {}
      }

      state = state.copyWith(
        venueName: venueName.trim(),
        locationAddress: locationAddress.trim(),
        detailsSaveStatus: 'saved',
      );
      Future.delayed(const Duration(milliseconds: 2500), () {
        state = state.copyWith(detailsSaveStatus: 'idle');
      });
      return true;
    } catch (e, stack) {
      _log.error('Lỗi cập nhật địa điểm Lite', e, stack);
      state = state.copyWith(detailsSaveStatus: 'idle');
      return false;
    }
  }

  Future<bool> updateLiteDetails(
    String tournamentId, {
    required String description,
    required String locationAddress,
    String? venueName,
  }) async {
    final tournament = state.tournament;
    if (tournament == null ||
        {'IN_PROGRESS', 'ONGOING', 'COMPLETED', 'CANCELLED'}
            .contains(tournament.status.toUpperCase())) {
      return false;
    }
    state = state.copyWith(detailsSaveStatus: 'saving');
    try {
      final nextTournamentConfig = {
        ...(tournament.locationConfig ?? {}),
        if (venueName != null && venueName.trim().isNotEmpty)
          'location': {
            'venueName': venueName.trim(),
            if (locationAddress.trim().isNotEmpty) 'address': locationAddress.trim(),
          },
      };

      await _dio.patch('/tournaments/$tournamentId', data: {
        'description': description.trim(),
        'locationAddress': locationAddress.trim(),
        'tournamentConfig': nextTournamentConfig,
      });

      state = state.copyWith(
        description: description.trim(),
        locationAddress: locationAddress.trim(),
        venueName: venueName?.trim() ?? state.venueName,
        detailsSaveStatus: 'saved',
      );
      Future.delayed(const Duration(milliseconds: 2500), () {
        state = state.copyWith(detailsSaveStatus: 'idle');
      });
      return true;
    } catch (e, stack) {
      _log.error('Lỗi cập nhật thông tin giải Lite', e, stack);
      state = state.copyWith(detailsSaveStatus: 'idle');
      return false;
    }
  }

  Future<void> startMatch(String tournamentId, String matchId) async {
    await ref.read(matchRepositoryProvider).startMatch(tournamentId, matchId);
    await _fetchMatches(tournamentId);
  }

  Future<void> applyMatchOperation(
    String tournamentId,
    String matchId, {
    required String action,
    required String reason,
    String? winnerId,
  }) async {
    await ref
        .read(matchRepositoryProvider)
        .matchOperation(
          matchId,
          action: action,
          reason: reason,
          winnerId: winnerId,
        );
    await _fetchMatches(tournamentId);
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

  Future<void> confirmRoster(String tournamentId) async {
    try {
      final response = await _dio.post(
        '/tournaments/$tournamentId/confirm-roster',
      );
      final envelope = response.data;
      final payload = envelope is Map && envelope['data'] is Map
          ? Map<String, dynamic>.from(envelope['data'] as Map)
          : envelope is Map
          ? Map<String, dynamic>.from(envelope)
          : null;
      state = state.copyWith(rosterConfirmed: true);
      await _fetchTournament(tournamentId);
      if (payload != null) {
        final current = state.tournament;
        if (current != null) {
          state = state.copyWith(
            tournament: Tournament.fromJson(
              payload,
              payload['id']?.toString() ?? current.id,
            ),
          );
        }
      }
    } on DioException catch (e) {
      _log.error('Lỗi chốt danh sách Lite', e);
      rethrow;
    }
  }

  Future<void> kickParticipant(
    String tournamentId,
    String participantId,
    String reason,
  ) async {
    try {
      await _dio.post(
        '/tournaments/$tournamentId/participants/$participantId/kick',
        data: {'reason': reason},
      );
      _log.success('Đã loại participant khỏi giải: $participantId');
      await _fetchParticipants(tournamentId);
    } on DioException catch (e) {
      _log.error('Lỗi loại participant khỏi giải', e);
      rethrow;
    }
  }

  Future<void> createBracket(String tournamentId) async {
    if (state.bracketEligibleCount < 2) {
      throw StateError(_l10n.lite_bracketMinimumParticipants(2));
    }
    state = state.copyWith(creatingBracket: true);
    final bType =
        state.tournament?.bracketType.toUpperCase() ?? 'SINGLE_ELIMINATION';
    try {
      // If tournament is Doubles format and has 2+ unpaired participants,
      // automatically auto-pair them (RANDOM) before creating bracket (matching Web behavior).
      if (state.isDoubles && state.pendingParticipants.length >= 2) {
        try {
          await _dio.post(
            '/tournaments/lite/$tournamentId/pairs/generate',
            data: {'strategy': 'RANDOM'},
          );
          await _fetchParticipants(tournamentId);
        } catch (pairErr) {
          _log.warning('Tự động ghép cặp trước khi tạo bracket bỏ qua lỗi: $pairErr');
        }
      }

      try {
        await _dio.post(
          '/tournaments/lite/$tournamentId/bracket',
          data: {
            if (_liteDivisionId != null) 'divisionId': _liteDivisionId,
            'seedingType': 'RANDOM',
            'bracketType': bType.contains('DOUBLE')
                ? 'DOUBLE_ELIMINATION'
                : 'SINGLE_ELIMINATION',
          },
        );
      } on DioException catch (e) {
        if (e.response?.statusCode == 400 || e.response?.statusCode == 404) {
          // Fallback to standard bracket generation endpoint
          await _dio.post(
            '/tournaments/$tournamentId/bracket/generate',
            data: {
              if (_liteDivisionId != null) 'divisionId': _liteDivisionId,
              'bracketType': bType.contains('DOUBLE')
                  ? 'DOUBLE_ELIMINATION'
                  : 'SINGLE_ELIMINATION',
              'seedingType': 'RANDOM',
            },
          );
        } else {
          rethrow;
        }
      }
      _log.success('Tạo bracket thành công');
      state = state.copyWith(creatingBracket: false, hasBracket: true);
      await _fetchBracket(tournamentId, divisionId: _liteDivisionId);
      await _fetchParticipants(tournamentId);
    } on DioException catch (e) {
      _log.error('Lỗi tạo bracket', e);
      state = state.copyWith(creatingBracket: false);
      rethrow;
    }
  }

  Future<void> resetBracket(String tournamentId) async {
    state = state.copyWith(creatingBracket: true);
    try {
      await _dio.post(
        '/tournaments/lite/$tournamentId/bracket/reset',
        data: {if (_liteDivisionId != null) 'divisionId': _liteDivisionId},
      );
      await _fetchBracket(tournamentId, divisionId: _liteDivisionId);
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
