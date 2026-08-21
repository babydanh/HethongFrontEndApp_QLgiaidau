import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament_registration.dart';
import 'package:app_quanly_giaidau/domain/entities/user.dart';
import 'package:app_quanly_giaidau/providers/app_providers.dart';
import 'package:app_quanly_giaidau/providers/user_provider.dart';
import 'package:app_quanly_giaidau/providers/my_tournament_workspace_provider.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/core/utils/error_parser.dart';
import 'package:intl/intl.dart';
import 'package:app_quanly_giaidau/shared/widgets/withdraw_sheet.dart';
import 'package:app_quanly_giaidau/core/widgets/app_share_modal.dart';

class DoublesRegistrationFlow extends ConsumerStatefulWidget {
  final String tournamentId;
  final TournamentDivisionOption division;
  final String? inviteCode;

  const DoublesRegistrationFlow({
    super.key,
    required this.tournamentId,
    required this.division,
    this.inviteCode,
  });

  @override
  ConsumerState<DoublesRegistrationFlow> createState() =>
      _DoublesRegistrationFlowState();
}

class _DoublesRegistrationFlowState
    extends ConsumerState<DoublesRegistrationFlow> {
  int _step = 1;
  bool _submitting = false;
  bool _success = false;

  // Step 1
  final _teamNameCtrl = TextEditingController();
  final _partnerSearchCtrl = TextEditingController();
  final Map<String, dynamic> _customResponses = {};
  List<UserSearchResult> _searchResults = [];
  UserSearchResult? _selectedPartner;
  bool _searching = false;
  bool _inviteLater = false;
  Timer? _searchDebounce;
  String? _genderError;
  String? _eloError;
  bool _eloChecking = false;

  List<Map<String, dynamic>> _activeRegistrationFields(Tournament tournament) {
    final divisionId = widget.division.id;
    if (tournament.registrationFormDivisionIds.isNotEmpty &&
        !tournament.registrationFormDivisionIds.contains(divisionId)) {
      return const [];
    }
    return tournament.registrationFields;
  }

  String? _validateCustomResponses(Tournament tournament) {
    final l10n = AppLocalizations.of(context)!;
    for (final field in _activeRegistrationFields(tournament)) {
      final id = field['id']?.toString() ?? '';
      final value = _customResponses[id];
      final empty =
          value == null ||
          value.toString().trim().isEmpty ||
          (value is List && value.isEmpty);
      final label = field['label']?.toString() ?? id;
      if (field['required'] == true) {
        if (empty) return l10n.registerCustomFieldRequired(label);
      }
      if (empty) continue;
      if (field['type'] == 'EMAIL' &&
          !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value.toString())) {
        return l10n.registerCustomFieldEmailInvalid(label);
      }

      if (field['type'] == 'NUMBER') {
        final number = num.tryParse(value.toString());
        if (number == null) return l10n.registerCustomFieldNumberInvalid(label);
        final min = num.tryParse(field['min']?.toString() ?? '');
        final max = num.tryParse(field['max']?.toString() ?? '');
        if (min != null && number < min) {
          return l10n.registerCustomFieldMin(label, min);
        }
        if (max != null && number > max) {
          return l10n.registerCustomFieldMax(label, max);
        }
      }
      if (field['type'] == 'SELECT' &&
          field['options'] is List &&
          !(field['options'] as List).contains(value)) {
        return l10n.registerCustomFieldSelectInvalid(label);
      }
      if (field['type'] == 'CHECKBOX' && value != true) {
        return l10n.registerCustomFieldCheckboxRequired(label);
      }
    }
    return null;
  }

  Widget _buildCustomFields(Tournament tournament) {
    final l10n = AppLocalizations.of(context)!;
    final fields = _activeRegistrationFields(tournament);
    if (fields.isEmpty) return const SizedBox.shrink();

    // Tự động điền sẵn Email và Số điện thoại từ profile nếu trường chưa có giá trị
    final userProfileAsync = ref.watch(userProfileProvider);
    final userProfile = userProfileAsync.asData?.value;
    if (userProfile != null) {
      for (final field in fields) {
        final id = field['id']?.toString() ?? '';
        if (id.isEmpty) continue;
        if (!_customResponses.containsKey(id) ||
            _customResponses[id] == null ||
            _customResponses[id].toString().trim().isEmpty) {
          final label = (field['label']?.toString() ?? '').toLowerCase();
          final type = field['type']?.toString();
          final isEmailField =
              type == 'EMAIL' ||
              label.contains('email') ||
              label.contains('gmail');
          final isPhoneField =
              type == 'PHONE' ||
              label.contains('điện thoại') ||
              label.contains('sđt') ||
              label.contains('phone');

          if (isEmailField &&
              userProfile.email != null &&
              userProfile.email!.isNotEmpty) {
            _customResponses[id] = userProfile.email;
          } else if (isPhoneField &&
              userProfile.phoneNumber != null &&
              userProfile.phoneNumber!.isNotEmpty) {
            _customResponses[id] = userProfile.phoneNumber;
          }
        }
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.colors.bgSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.registerAdditionalInfoTitle,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.registerAdditionalInfoDescription,
            style: TextStyle(fontSize: 12, color: context.colors.textSecondary),
          ),
          const SizedBox(height: 12),
          ...fields.map((field) {
            final id = field['id']?.toString() ?? '';
            final label = field['label']?.toString() ?? id;
            final required = field['required'] == true;
            final type = field['type']?.toString();
            final help = field['helpText']?.toString();
            if (type == 'CHECKBOX') {
              return CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _customResponses[id] == true,
                onChanged: (value) =>
                    setState(() => _customResponses[id] = value == true),
                title: Text(
                  '$label${required ? ' *' : ''}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              );
            }
            if (type == 'SELECT') {
              return DropdownButtonFormField<String>(
                initialValue: _customResponses[id]?.toString(),
                decoration: InputDecoration(
                  labelText: '$label${required ? ' *' : ''}',
                  helperText: help,
                ),
                items: [
                  DropdownMenuItem(
                    value: '',
                    child: Text(l10n.registerSelectOption),
                  ),
                  ...((field['options'] as List? ?? const []).map(
                    (option) => DropdownMenuItem(
                      value: option.toString(),
                      child: Text(option.toString()),
                    ),
                  )),
                ],
                onChanged: (value) =>
                    setState(() => _customResponses[id] = value),
              );
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: TextFormField(
                initialValue: _customResponses[id]?.toString() ?? '',
                keyboardType: type == 'NUMBER'
                    ? TextInputType.number
                    : type == 'EMAIL'
                    ? TextInputType.emailAddress
                    : type == 'PHONE'
                    ? TextInputType.phone
                    : TextInputType.text,
                maxLines: type == 'TEXTAREA' ? 3 : 1,
                decoration: InputDecoration(
                  labelText: '$label${required ? ' *' : ''}',
                  helperText: help,
                ),
                onChanged: (value) => _customResponses[id] = value,
              ),
            );
          }),
        ],
      ),
    );
  }

  // Step 2
  String? _teamInviteToken;
  String? _teamInviteLink;
  String? _participantId;
  Timer? _pollTimer;
  int _pollElapsed = 0;
  DateTime? _partnerInviteExpiresAt;
  bool _gatesChecked = false;

  // Step 3
  double? _entryFee;
  bool _isPaid = false;
  String _teamStatus = '';
  String? _partnerContact;

  @override
  void initState() {
    super.initState();
    _checkExistingRegistration();
  }

  Future<void> _checkExistingRegistration() async {
    try {
      final dio = ref.read(dioClientProvider);
      final regResp = await dio.dio.get(
        '/tournaments/${widget.tournamentId}/my-registration',
        queryParameters: {
          'divisionId': widget.division.id,
          '_t': DateTime.now().millisecondsSinceEpoch.toString(),
        },
      );
      final body = regResp.data;
      final regData = body is Map && body['data'] is Map
          ? body['data'] as Map
          : body is Map
          ? body
          : null;
      if (mounted && regData != null) {
        if (regData['registered'] == true && regData['participant'] is Map) {
          final participant = regData['participant'] as Map;
          final status = participant['teamStatus']?.toString() ?? '';
          final token = participant['teamInviteToken']?.toString();
          final link = participant['teamInviteLink']?.toString();
          final pId = participant['id']?.toString();
          final name = participant['teamName']?.toString();
          final fee =
              double.tryParse(participant['entryFee']?.toString() ?? '') ??
              widget.division.entryFee ??
              0;

          if (name != null && name.isNotEmpty) {
            _teamNameCtrl.text = name;
          }

          if (status == 'PENDING_PARTNER') {
            setState(() {
              _participantId = pId;
              _teamInviteToken = token;
              _teamInviteLink = link;
              _entryFee = fee;
              _isPaid = participant['isPaid'] == true;
              _teamStatus = status;
              _step = 2;
            });
            _startPolling();
          } else if (status == 'COMPLETE' ||
              status == 'PENDING_APPROVAL' ||
              status == 'WAITLISTED') {
            setState(() {
              _participantId = pId;
              _teamInviteToken = token;
              _teamInviteLink = link;
              _entryFee = fee;
              _isPaid = participant['isPaid'] == true;
              _teamStatus = status;
              _step = 3;
            });
          }
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _teamNameCtrl.dispose();
    _partnerSearchCtrl.dispose();
    _searchDebounce?.cancel();
    _pollTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    if (value.trim().length < 3) {
      setState(() => _searchResults = []);
      return;
    }
    _searchDebounce = Timer(
      const Duration(milliseconds: 500),
      () => _searchUsers(value.trim()),
    );
  }

  Future<void> _searchUsers(String query) async {
    setState(() => _searching = true);
    try {
      final repo = ref.read(userRepositoryProvider);
      final results = await repo.searchUsers(query);
      if (mounted) setState(() => _searchResults = results);
    } catch (_) {
      // Silently fail
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  void _checkGenderAndElo() {
    final div = widget.division;
    setState(() {
      _genderError = null;
      _eloError = null;
    });

    // Check gender restriction
    final userAsync = ref.read(userProfileProvider);
    final user = userAsync.asData?.value;
    // Chuẩn hoá cả 2 phía: profile lưu giới tính tiếng Việt ('Nữ') còn
    // division lưu 'FEMALE'/'MALE'. So sánh raw (toUpperCase) là 'NỮ' !=
    // 'FEMALE' → báo sai "chỉ dành cho Nữ" kể cả khi đúng giới tính.
    if (user != null) {
      final userGender = _normalizeGender(user.gender);
      final divGender = _normalizeGender(div.genderRestriction);
      if (userGender != null &&
          divGender != null &&
          divGender != 'MIXED' &&
          userGender != divGender) {
        setState(() {
          _genderError = divGender == 'MALE'
              ? AppLocalizations.of(context)!.registerGenderErrorMale
              : AppLocalizations.of(context)!.registerGenderErrorFemale;
        });
      }
    }

    // Check ELO
    if (div.categoryId != null && user != null) {
      _checkElo(user.id, div.categoryId!, div.minElo, div.maxElo);
    }
  }

  /// Chuẩn hoá giá trị giới tính ('Nữ'/'nu'/'FEMALE' → 'FEMALE'; 'Nam'/'nam'/
  /// 'MALE' → 'MALE'; 'MIXED'/'Nam Nữ' → 'MIXED'; không nhận biết → null).
  String? _normalizeGender(String? value) {
    final normalized = value
        ?.trim()
        .toUpperCase()
        .replaceAll('-', '_')
        .replaceAll(' ', '_');
    return switch (normalized) {
      'MALE' || 'MEN' || 'NAM' => 'MALE',
      'FEMALE' || 'WOMEN' || 'NU' || 'NỮ' => 'FEMALE',
      'MIXED' || 'MIXED_GENDER' || 'NAM_NU' => 'MIXED',
      _ => null,
    };
  }

  Future<void> _checkElo(
    String userId,
    String categoryId,
    double? minElo,
    double? maxElo,
  ) async {
    setState(() => _eloChecking = true);
    try {
      final repo = ref.read(rankingRepositoryProvider);
      final response = await repo.getUserRank(userId, categoryId);
      final elo = response.eloPoints ?? 1000;
      if (minElo != null && elo < minElo) {
        setState(
          () => _eloError = AppLocalizations.of(
            context,
          )!.registerEloTooLow(elo, minElo.toInt()),
        );
      } else if (maxElo != null && elo > maxElo) {
        setState(
          () => _eloError = AppLocalizations.of(
            context,
          )!.registerEloTooHigh(elo, maxElo.toInt()),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _eloError = AppLocalizations.of(context)!.registerEloCheckError,
        );
      }
    } finally {
      if (mounted) setState(() => _eloChecking = false);
    }
  }

  Future<bool> _recoverRegistrationAfterSubmitFailure() async {
    try {
      final response = await ref
          .read(dioClientProvider)
          .dio
          .get(
            '/tournaments/${widget.tournamentId}/my-registration',
            queryParameters: {
              'divisionId': widget.division.id,
              '_t': DateTime.now().millisecondsSinceEpoch.toString(),
            },
          );
      final body = response.data;
      final raw = body is Map && body['data'] is Map
          ? body['data'] as Map
          : body;
      if (raw is! Map ||
          raw['registered'] != true ||
          raw['participant'] is! Map) {
        return false;
      }

      final participant = raw['participant'] as Map;
      final status = participant['teamStatus']?.toString() ?? '';
      final participantId = participant['id']?.toString();
      if (participantId == null || participantId.isEmpty) return false;

      _participantId = participantId;
      _teamStatus = status;
      _teamInviteToken = participant['teamInviteToken']?.toString();
      _teamInviteLink = participant['teamInviteLink']?.toString();
      _entryFee =
          double.tryParse(participant['entryFee']?.toString() ?? '') ?? 0;
      _isPaid = participant['isPaid'] == true;

      if (!mounted) return true;
      if (status == 'PENDING_PARTNER') {
        setState(() => _step = 2);
        _startPolling();
      } else if (status == 'COMPLETE' ||
          status == 'PENDING_APPROVAL' ||
          status == 'WAITLISTED') {
        setState(() => _step = 3);
      }
      return status.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<void> _handleStep1Submit() async {
    final l10n = AppLocalizations.of(context)!;
    if (_teamNameCtrl.text.trim().length < 3) {
      _showError(l10n.doublesRegTeamNameTooShort);
      return;
    }
    // Gender gate
    if (_genderError != null || _eloError != null) {
      _showError(_genderError ?? _eloError!);
      return;
    }
    // Đồng ý ELO/ranking đã được thu thập ở màn đăng ký ngoài (checkbox bắt
    // buộc với giải có xếp hạng trước khi vào đây). Màn ghép đôi không hỏi
    // lại — chỉ truyền đúng trạng thái giải để backend ghi ELO hợp lệ.
    final tournament = ref
        .read(
          registerTournamentProvider((
            id: widget.tournamentId,
            invite: widget.inviteCode,
          )),
        )
        .asData
        ?.value;

    if (tournament != null) {
      final customError = _validateCustomResponses(tournament);
      if (customError != null) {
        _showError(customError);
        return;
      }
    }

    setState(() => _submitting = true);
    try {
      _partnerContact =
          _selectedPartner?.email ??
          (_inviteLater ? null : _partnerSearchCtrl.text.trim());
      final result = await ref
          .read(tournamentRepositoryProvider)
          .registerParticipant(
            tournamentId: widget.tournamentId,
            teamName: _teamNameCtrl.text.trim(),
            divisionId: widget.division.id,
            inviteCode: widget.inviteCode,
            partnerEmailOrPhone:
                _selectedPartner?.email ??
                (_inviteLater ? null : _partnerSearchCtrl.text.trim()),
            rankingConsent: tournament?.isRanked == true,
            customResponses: _customResponses.isNotEmpty
                ? _customResponses
                : null,
          );
      if (!mounted) return;
      _participantId = result.participantId;
      _teamStatus = result.teamStatus;
      _entryFee = result.entryFee;
      _isPaid = result.entryFee <= 0;

      // Fetch registration details to get invite token/link
      try {
        final dio = ref.read(dioClientProvider);
        final regResp = await dio.dio.get(
          '/tournaments/${widget.tournamentId}/my-registration',
          queryParameters: {
            'divisionId': widget.division.id,
            '_t': DateTime.now().millisecondsSinceEpoch.toString(),
          },
        );
        if (mounted && regResp.data['data'] is Map) {
          final regData = regResp.data['data'] as Map;
          final participant = regData['participant'];
          if (participant is Map) {
            _teamInviteToken = participant['teamInviteToken']?.toString();
            _teamInviteLink = participant['teamInviteLink']?.toString();
            final expires = participant['partnerInviteExpiresAt']?.toString();
            if (expires != null) {
              _partnerInviteExpiresAt = DateTime.tryParse(expires);
            }
          }
        }
      } catch (_) {}

      if (mounted) {
        // Keep tournament/slot views in sync immediately after the backend
        // creates the participant. The registration screen itself uses a
        // direct endpoint, while home/detail screens read Riverpod streams.
        ref.invalidate(tournamentProvider(widget.tournamentId));
        ref.invalidate(tournamentIntroProvider(widget.tournamentId));
        ref.invalidate(myTournamentWorkspaceProvider);
        if (result.isWaitlisted ||
            result.teamStatus == 'COMPLETE' ||
            result.teamStatus == 'PENDING_APPROVAL') {
          setState(() => _step = 3);
        } else {
          setState(() => _step = 2);
          _startPolling();
        }
      }
    } catch (e) {
      final recovered = await _recoverRegistrationAfterSubmitFailure();
      if (!recovered && mounted) {
        _showError(
          ErrorParser.parse(
            e,
            AppLocalizations.of(context)!.doublesRegCreateError,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _partnerInviteExpiresAt ??= DateTime.now().add(const Duration(minutes: 60));
    _pollElapsed = 0;
    _pollTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final remaining = _partnerInviteExpiresAt!
          .difference(DateTime.now())
          .inSeconds;
      if (remaining <= 0) {
        _pollTimer?.cancel();
        if (mounted) {
          _showError('Lời mời ghép đôi đã hết hạn hoặc giải đã đóng đăng ký.');
          setState(() {
            _step = 1;
          });
        }
        return;
      }

      setState(() {}); // Update countdown UI

      _pollElapsed++;
      // Check backend every 5 seconds to avoid spamming
      if (_pollElapsed % 5 == 0) {
        _checkPartnerJoined();
      }
    });
  }

  Future<void> _checkPartnerJoined() async {
    try {
      final dio = ref.read(dioClientProvider);
      final resp = await dio.dio.get(
        '/tournaments/${widget.tournamentId}/my-registration',
        queryParameters: {
          'divisionId': widget.division.id,
          '_t': DateTime.now().millisecondsSinceEpoch.toString(),
        },
      );
      if (!mounted || resp.data['data'] is! Map) return;
      final regData = resp.data['data'] as Map;
      final participant = regData['participant'];
      if (participant is! Map) return;
      final teamStatus = participant['teamStatus']?.toString() ?? '';
      if (teamStatus == 'COMPLETE' ||
          teamStatus == 'PENDING_APPROVAL' ||
          teamStatus == 'WAITLISTED') {
        _pollTimer?.cancel();
        if (mounted) {
          ref.invalidate(tournamentProvider(widget.tournamentId));
          ref.invalidate(tournamentIntroProvider(widget.tournamentId));
          ref.invalidate(myTournamentWorkspaceProvider);
          setState(() {
            _teamStatus = teamStatus;
            _step = 3;
          });
        }
      } else if (teamStatus == 'EXPIRED') {
        _pollTimer?.cancel();
        if (mounted) {
          _showError('Lời mời ghép đôi đã hết hạn hoặc giải đã đóng đăng ký.');
          setState(() {
            _step = 1;
          });
        }
      }
    } catch (_) {}
  }

  void _showError(dynamic msg) {
    if (mounted) {
      final text = msg is String ? msg : ErrorParser.parse(msg);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Tải kèm mã mời để đọc được giải PRIVATE (backend yêu cầu `?invite=`).
    final tAsync = ref.watch(
      registerTournamentProvider((
        id: widget.tournamentId,
        invite: widget.inviteCode,
      )),
    );
    final colors = context.colors;

    if (_success) return _buildSuccess(colors);
    return Scaffold(
      backgroundColor: colors.bgDark,
      appBar: AppBar(title: Text(l10n.doublesRegTitle), centerTitle: true),
      body: tAsync.when(
        data: (t) {
          if (t == null) {
            return Center(child: Text(l10n.registerTournamentNotFound));
          }
          // Check gender/ELO gates once when entering Step 1
          if (_step == 1 && !_gatesChecked) {
            _gatesChecked = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _checkGenderAndElo();
            });
          }
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStepIndicator(colors),
                const SizedBox(height: 24),
                if (_step == 1) _buildStep1(t, colors),
                if (_step == 2) _buildStep2(t, colors),
                if (_step == 3) _buildStep3(t, colors),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) =>
            Center(child: Text('${l10n.registerTournamentNotFound}: $e')),
      ),
    );
  }

  Widget _buildStepIndicator(AppColorsExtension colors) {
    return Row(
      children: [1, 2, 3].map((i) {
        final active = _step >= i;
        final done = _step > i;
        return Expanded(
          child: Row(
            children: [
              if (i > 1)
                Expanded(
                  child: Container(
                    height: 2,
                    color: done || _step > i ? AppTheme.primary : colors.border,
                  ),
                ),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: active ? AppTheme.primary : colors.bgCard,
                  border: Border.all(
                    color: active ? AppTheme.primary : colors.border,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: done
                      ? const Icon(Icons.check, size: 18, color: Colors.white)
                      : Text(
                          '$i',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: active ? Colors.white : colors.textMuted,
                          ),
                        ),
                ),
              ),
              if (i < 3)
                Expanded(
                  child: Container(
                    height: 2,
                    color: done ? AppTheme.primary : colors.border,
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStep1(Tournament t, AppColorsExtension colors) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.doublesRegStep1,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: AppTheme.primary,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.doublesRegCreateTeam,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 20),
        _buildCustomFields(t),
        TextField(
          controller: _teamNameCtrl,
          style: TextStyle(color: colors.textPrimary),
          decoration: InputDecoration(
            labelText: l10n.doublesRegTeamName,
            hintText: l10n.doublesRegTeamNameHint,
            prefixIcon: const Icon(Icons.group_rounded),
            filled: true,
            fillColor: colors.bgCard,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 20),
        if (_genderError != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: colors.error.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: colors.error.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    size: 16,
                    color: colors.error,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _genderError!,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: colors.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (_eloError != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: colors.error.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: colors.error.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.trending_up_rounded,
                    size: 16,
                    color: colors.error,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _eloError!,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: colors.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (_eloChecking)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.registerEloCheckError,
                  style: TextStyle(fontSize: 13, color: colors.textSecondary),
                ),
              ],
            ),
          ),
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.doublesRegSearchPartner,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: colors.textMuted,
                  letterSpacing: 1,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: () => setState(() => _inviteLater = !_inviteLater),
              icon: Icon(
                _inviteLater
                    ? Icons.check_box_rounded
                    : Icons.check_box_outline_blank_rounded,
                size: 18,
              ),
              label: Text(
                l10n.doublesRegInviteLater,
                style: TextStyle(fontSize: 12, color: colors.textSecondary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (!_inviteLater) ...[
          TextField(
            controller: _partnerSearchCtrl,
            style: TextStyle(color: colors.textPrimary),
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: l10n.doublesRegPartnerHint,
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _searching
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : null,
              filled: true,
              fillColor: colors.bgCard,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          if (_searchResults.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: colors.bgCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.border),
              ),
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _searchResults.length,
                separatorBuilder: (_, index) =>
                    Divider(color: colors.border, height: 1),
                itemBuilder: (_, i) {
                  final u = _searchResults[i];
                  final sel = _selectedPartner?.id == u.id;
                  return ListTile(
                    dense: true,
                    leading: CircleAvatar(
                      radius: 16,
                      backgroundImage: u.avatarUrl != null
                          ? NetworkImage(u.avatarUrl!)
                          : null,
                      child: u.avatarUrl == null
                          ? Text(
                              u.fullName.isNotEmpty
                                  ? u.fullName[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(fontSize: 12),
                            )
                          : null,
                    ),
                    title: Text(
                      u.fullName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      u.email ?? '',
                      style: TextStyle(fontSize: 11, color: colors.textMuted),
                    ),
                    trailing: sel
                        ? Icon(Icons.check_circle, color: AppTheme.primary)
                        : null,
                    onTap: () =>
                        setState(() => _selectedPartner = sel ? null : u),
                  );
                },
              ),
            ),
          ],
        ],
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: FilledButton.icon(
            onPressed: _submitting ? null : _handleStep1Submit,
            icon: _submitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.arrow_forward_rounded),
            label: Text(
              _submitting
                  ? l10n.doublesRegProcessing
                  : l10n.doublesRegSubmitNext,
            ),
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildStep2(Tournament t, AppColorsExtension colors) {
    final l10n = AppLocalizations.of(context)!;
    final rawInviteLink =
        _teamInviteLink ??
        (_teamInviteToken != null
            ? '/tournaments/${widget.tournamentId}/join-team?pid=$_participantId&token=$_teamInviteToken'
            : null);
    final inviteLink = rawInviteLink == null
        ? null
        : rawInviteLink.startsWith('http://') ||
              rawInviteLink.startsWith('https://')
        ? rawInviteLink
        : 'https://sporto.asia${rawInviteLink.startsWith('/') ? '' : '/'}$rawInviteLink';
    final showInvite = inviteLink != null || _teamInviteToken != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.doublesRegStep2,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: AppTheme.primary,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.doublesRegInviteTitle,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.doublesRegInviteDesc,
          style: TextStyle(fontSize: 13, color: colors.textSecondary),
        ),
        const SizedBox(height: 24),
        if (showInvite) ...[
          Center(
            child: QrImageView(
              data: inviteLink ?? _teamInviteToken!,
              version: QrVersions.auto,
              size: 200,
              backgroundColor: Colors.white,
              padding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.bgCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.doublesRegInviteLink,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: colors.textMuted,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  inviteLink ?? _teamInviteToken!,
                  style: TextStyle(fontSize: 12, color: AppTheme.primary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Clipboard.setData(
                      ClipboardData(text: inviteLink ?? _teamInviteToken!),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l10n.doublesRegCopied),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  label: Text(
                    l10n.doublesRegCopyLink,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    AppShareModal.show(
                      context: context,
                      title: l10n.doublesRegInviteTeamTitle(_teamNameCtrl.text),
                      subtitle: l10n.doublesRegTournamentSubtitle(t.name),
                      webUrl: inviteLink ?? _teamInviteToken!,
                      imageUrl: t.logoUrl,
                      badgeText: l10n.doublesRegInviteBadge,
                    );
                  },
                  icon: const Icon(Icons.share_rounded, size: 16),
                  label: Text(
                    l10n.doublesRegShareToTeam,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ] else ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  size: 48,
                  color: Colors.blue,
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.doublesRegInviteSentTitle,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Colors.blue.shade900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.doublesRegInviteSentDescription,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue.shade700,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            Text(
              l10n.doublesRegWaiting,
              style: TextStyle(fontSize: 13, color: colors.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildCountdownBadge(colors),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: () {
              _pollTimer?.cancel();
              context.go('/intro/${widget.tournamentId}');
            },
            child: Text(l10n.doublesRegContinueLater),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: TextButton.icon(
            onPressed: () async {
              final withdrew = await WithdrawSheet.show(
                context,
                tournamentId: widget.tournamentId,
                divisionId: widget.division.id,
                hasPaid: false,
              );
              if (!mounted || !withdrew) return;
              context.go('/intro/${widget.tournamentId}');
            },
            icon: Icon(
              Icons.exit_to_app_rounded,
              size: 16,
              color: colors.error,
            ),
            label: Text(
              l10n.registerWithdraw,
              style: TextStyle(color: colors.error, fontSize: 13),
            ),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 300.ms);
  }

  /// Countdown badge for partner invitation — shows HH:MM:SS or MM:SS, pulsing red when ≤30s
  Widget _buildCountdownBadge(AppColorsExtension colors) {
    final l10n = AppLocalizations.of(context)!;
    int remaining = 0;
    if (_partnerInviteExpiresAt != null) {
      remaining = _partnerInviteExpiresAt!.difference(DateTime.now()).inSeconds;
      if (remaining < 0) remaining = 0;
    }
    final hours = remaining ~/ 3600;
    final minutes = (remaining % 3600) ~/ 60;
    final seconds = remaining % 60;
    final isUrgent = remaining <= 30;
    final badgeColor = isUrgent ? colors.error : const Color(0xFF2979FF);

    final timeStr = hours > 0
        ? '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}'
        : '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    Widget badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: isUrgent ? 0.15 : 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: badgeColor.withValues(alpha: isUrgent ? 0.4 : 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isUrgent ? Icons.timer_off_rounded : Icons.timer_rounded,
            size: 18,
            color: badgeColor,
          ),
          const SizedBox(width: 8),
          Text(
            l10n.doublesRegSpotReserved(timeStr),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: badgeColor,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );

    if (isUrgent) {
      badge = badge
          .animate(onPlay: (controller) => controller.repeat(reverse: true))
          .shimmer(
            duration: 600.ms,
            color: colors.error.withValues(alpha: 0.3),
          );
    }

    return Center(child: badge);
  }

  Widget _buildStep3(Tournament t, AppColorsExtension colors) {
    final l10n = AppLocalizations.of(context)!;
    final rawInviteLink =
        _teamInviteLink ??
        (_teamInviteToken != null
            ? '/tournaments/${widget.tournamentId}/join-team?pid=$_participantId&token=$_teamInviteToken'
            : null);
    final inviteLink = rawInviteLink == null
        ? null
        : rawInviteLink.startsWith('http://') ||
              rawInviteLink.startsWith('https://')
        ? rawInviteLink
        : 'https://sporto.asia${rawInviteLink.startsWith('/') ? '' : '/'}$rawInviteLink';
    final canPay =
        _entryFee != null &&
        _entryFee! > 0 &&
        !_isPaid &&
        _participantId != null &&
        (_teamStatus == 'COMPLETE' || _teamStatus == 'PENDING_APPROVAL');
    final isWaitlisted = _teamStatus == 'WAITLISTED';
    final statusLabel = switch (_teamStatus) {
      'PENDING_APPROVAL' => l10n.doublesRegStatusPendingApproval,
      'COMPLETE' => l10n.doublesRegStatusComplete,
      'WAITLISTED' => l10n.doublesRegStatusWaitlisted,
      _ => l10n.doublesRegStatusSuccess,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'BƯỚC 3',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: AppTheme.primary,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          statusLabel,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 20),
        if (_partnerContact != null && _partnerContact!.isNotEmpty) ...[
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                AppShareModal.show(
                  context: context,
                  title: l10n.doublesRegJoinTeamShareTitle(_teamNameCtrl.text),
                  subtitle: l10n.doublesRegPartnerSubtitle(t.name, _partnerContact!),
                  webUrl:
                      inviteLink ??
                      'https://sporto.asia/tournaments/${widget.tournamentId}',
                  imageUrl: t.logoUrl,
                  badgeText: l10n.doublesRegInviteBadge,
                );
              },
              icon: const Icon(Icons.share_rounded, size: 18),
              label: Text(l10n.doublesRegShareToPartner),
            ),
          ),
          const SizedBox(height: 16),
        ],
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colors.bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.border),
          ),
          child: Column(
            children: [
              Icon(
                isWaitlisted
                    ? Icons.hourglass_top_rounded
                    : Icons.check_circle_rounded,
                size: 48,
                color: isWaitlisted ? colors.warning : colors.success,
              ),
              const SizedBox(height: 16),
              Text(
                l10n.doublesRegYourTeam(_teamNameCtrl.text),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              if (_selectedPartner != null)
                Text(
                  l10n.doublesRegWithPartner(_selectedPartner!.fullName),
                  style: TextStyle(fontSize: 14, color: colors.textSecondary),
                ),
              if (_entryFee != null && _entryFee! > 0) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: colors.warning.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    l10n.doublesRegEntryFee(
                      '${NumberFormat('#,###', 'vi_VN').format(_entryFee!.ceil())}đ',
                    ),
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: colors.warning,
                    ),
                  ),
                ),
              ],
              if (_entryFee != null && _entryFee! > 0 && !isWaitlisted) ...[
                const SizedBox(height: 8),
                Text(
                  l10n.doublesRegPaymentStatus(
                    _isPaid ? l10n.doublesRegPaid : l10n.doublesRegUnpaid,
                  ),
                  style: TextStyle(fontSize: 13, color: colors.textSecondary),
                ),
              ],
              if (isWaitlisted) ...[
                const SizedBox(height: 12),
                Text(
                  l10n.doublesRegWaitlistInfo,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colors.textSecondary),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: FilledButton.icon(
            onPressed: () {
              if (canPay) {
                context.push(
                  '/payment/checkout',
                  extra: {
                    'tournamentId': widget.tournamentId,
                    'participantId': _participantId,
                    'divisionId': widget.division.id,
                    'amount': _entryFee,
                    'tournamentName': t.name,
                  },
                );
              } else {
                setState(() => _success = true);
              }
            },
            icon: canPay
                ? const Icon(Icons.payment_rounded)
                : const Icon(Icons.check_rounded),
            label: Text(
              canPay ? l10n.doublesRegProceedPayment : l10n.doublesRegComplete,
            ),
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: TextButton.icon(
            onPressed: () async {
              final withdrew = await WithdrawSheet.show(
                context,
                tournamentId: widget.tournamentId,
                divisionId: widget.division.id,
                // `_isPaid` cũng true với giải miễn phí (entryFee<=0) → phải kèm
                // đk có phí THỰC SỰ >0 thì mới cần nhập/hoàn bank. (fix #35)
                hasPaid: _isPaid && _entryFee != null && _entryFee! > 0,
              );
              if (!mounted || !withdrew) return;
              context.go('/intro/${widget.tournamentId}');
            },
            icon: Icon(
              Icons.exit_to_app_rounded,
              size: 16,
              color: colors.error,
            ),
            label: Text(
              l10n.registerWithdraw,
              style: TextStyle(color: colors.error, fontSize: 13),
            ),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildSuccess(AppColorsExtension colors) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: colors.bgDark,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: colors.success.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle_rounded,
                  size: 52,
                  color: colors.success,
                ),
              ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
              const SizedBox(height: 24),
              Text(
                l10n.doublesRegSuccess,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => context.go('/intro/${widget.tournamentId}'),
                child: Text(l10n.doublesRegViewDetail),
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () async {
                  final withdrew = await WithdrawSheet.show(
                    context,
                    tournamentId: widget.tournamentId,
                    divisionId: widget.division.id,
                    hasPaid: _entryFee != null && _entryFee! > 0,
                  );
                  if (!mounted || !withdrew) return;
                  context.go('/intro/${widget.tournamentId}');
                },
                icon: Icon(
                  Icons.exit_to_app_rounded,
                  size: 16,
                  color: colors.error,
                ),
                label: Text(
                  AppLocalizations.of(context)!.registerWithdraw,
                  style: TextStyle(color: colors.error, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
