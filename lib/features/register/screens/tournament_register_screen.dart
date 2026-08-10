import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/utils/error_parser.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament_registration.dart';
import 'package:app_quanly_giaidau/providers/app_providers.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:app_quanly_giaidau/providers/user_provider.dart';
import 'package:app_quanly_giaidau/shared/widgets/withdraw_sheet.dart';
import 'package:intl/intl.dart';

final _divisionsProvider =
    FutureProvider.family<List<TournamentDivisionOption>, String>((
      ref,
      tournamentId,
    ) async {
      return ref.read(tournamentRepositoryProvider).getDivisions(tournamentId);
    });

class TournamentRegisterScreen extends ConsumerStatefulWidget {
  final String tournamentId;
  final String? inviteCode;
  final String? divisionId;
  const TournamentRegisterScreen({
    super.key,
    required this.tournamentId,
    this.inviteCode,
    this.divisionId,
  });

  @override
  ConsumerState<TournamentRegisterScreen> createState() =>
      _TournamentRegisterScreenState();
}

class _TournamentRegisterScreenState
    extends ConsumerState<TournamentRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _inviteCtrl = TextEditingController();
  String? _selectedDiv;

  @override
  void initState() {
    super.initState();
    if (widget.divisionId != null && widget.divisionId!.isNotEmpty) {
      _selectedDiv = widget.divisionId;
    }
    _checkExistingRegistration();
  }

  Future<void> _checkExistingRegistration() async {
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.get(
        '/tournaments/${widget.tournamentId}/my-registration',
      );
      final raw = response.data;
      final payload = raw is Map && raw['data'] is Map ? raw['data'] : raw;
      final participant = payload is Map && payload['participant'] is Map
          ? payload['participant'] as Map
          : null;
      if (payload is Map &&
          payload['registered'] == true &&
          participant != null) {
        if (mounted) {
          setState(() {
            _alreadyRegistered = true;
            _existingParticipantId = participant['id']?.toString();
            _existingDivisionId = participant['tournamentDivisionId']
                ?.toString();
            _existingTeamStatus = participant['teamStatus']?.toString();
            _existingIsPaid = participant['isPaid'] == true;
            _checkingRegistration = false;
          });
        }
        return;
      }
    } catch (_) {}
    if (mounted) setState(() => _checkingRegistration = false);
  }

  String? _divisionError;
  bool _submitting = false;
  bool _success = false;
  AppLocalizations get l10n => AppLocalizations.of(context)!;
  String? _genderError;
  String? _eloError;
  bool _eloChecking = false;
  bool _inviteValidating = false;
  String? _inviteError;
  String? _localInviteCode;
  double? _registeredEntryFee;
  String? _registrationTeamStatus;
  bool _checkingRegistration = true;
  bool _alreadyRegistered = false;
  String? _existingParticipantId;
  String? _existingDivisionId;
  String? _existingTeamStatus;
  bool _existingIsPaid = false;
  bool _rankingConsent = false;

  String _getSubmitLabel(Tournament? t) {
    if (t?.registrationMode == 'APPROVAL') return l10n.registerSubmitApproval;
    return l10n.registerSubmitConfirm;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _inviteCtrl.dispose();
    super.dispose();
  }

  TournamentDivisionOption? get _selectedDivision {
    final divisions = ref
        .read(_divisionsProvider(widget.tournamentId))
        .asData
        ?.value;
    if (divisions == null || _selectedDiv == null) return null;
    try {
      return divisions.firstWhere((d) => d.id == _selectedDiv);
    } catch (_) {
      return null;
    }
  }

  void _onDivisionSelected(
    String id,
    List<TournamentDivisionOption> divisions,
  ) {
    setState(() {
      _selectedDiv = id;
      _divisionError = null;
      _genderError = null;
      _eloError = null;
    });
    // Find selected division for validation
    final div = _selectedDivision;
    if (div == null) return;

    // Check gender restriction
    final userAsync = ref.read(userProfileProvider);
    final user = userAsync.asData?.value;
    final divGender = _normalizedGender(div.genderRestriction);
    if (user != null && divGender != null && divGender != 'MIXED') {
      final userGender = _normalizedGender(user.gender);
      if (userGender != null && userGender != divGender) {
        setState(() {
          _genderError = divGender == 'MALE'
              ? l10n.registerGenderErrorMale
              : l10n.registerGenderErrorFemale;
        });
      }
    }

    // Check ELO
    if (div.categoryId != null && user != null) {
      _checkElo(user.id, div.categoryId!, div.minElo, div.maxElo);
    }
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
          () => _eloError =
              'ELO của bạn ($elo) thấp hơn yêu cầu tối thiểu (${minElo.toInt()})',
        );
      } else if (maxElo != null && elo > maxElo) {
        setState(
          () => _eloError =
              'ELO của bạn ($elo) cao hơn yêu cầu tối đa (${maxElo.toInt()})',
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _eloError =
              l10n.registerEloCheckError,
        );
      }
    } finally {
      if (mounted) setState(() => _eloChecking = false);
    }
  }

  Future<void> _validateInvite() async {
    final code = _inviteCtrl.text.trim();
    if (code.length < 6) {
      setState(() => _inviteError = l10n.registerInviteTooShort);
      return;
    }
    setState(() {
      _inviteValidating = true;
      _inviteError = null;
    });
    try {
      final dio = ref.read(dioClientProvider);
      await dio.dio.post(
        '/tournaments/${widget.tournamentId}/validate-invite',
        data: {'inviteCode': code},
      );
      if (mounted) setState(() => _localInviteCode = code);
    } catch (e) {
      if (mounted) {
        setState(() => _inviteError = l10n.registerInviteInvalid);
      }
    } finally {
      if (mounted) setState(() => _inviteValidating = false);
    }
  }

  Future<void> _register() async {
    if (_alreadyRegistered) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.registerAlreadyRegistered)),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    final userAsync = ref.read(userProfileProvider);
    final user = userAsync.asData?.value;
    if (user?.fullName == null ||
        user?.phoneNumber == null ||
        user?.gender == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.registerProfileIncomplete),
          ),
        );
      }
      return;
    }
    if (_genderError != null) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_genderError!)));
      }
      return;
    }
    if (_eloError != null) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_eloError!)));
      }
      return;
    }
    final tournament = ref.read(tournamentProvider(widget.tournamentId)).asData?.value;
    if (tournament?.isRanked == true && !_rankingConsent) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng đồng ý hiển thị kết quả và điểm ELO trên bảng xếp hạng.')),
        );
      }
      return;
    }
    final divisions = ref.read(_divisionsProvider(widget.tournamentId)).value;
    final divisionId =
        _selectedDiv ??
        (divisions != null && divisions.length == 1
            ? divisions.first.id
            : null);
    if (divisions != null && divisions.length > 1 && divisionId == null) {
      setState(() => _divisionError = l10n.registerSelectDivision);
      return;
    }
    // If doubles division, navigate to doubles flow
    final selectedDiv = divisions?.where((d) => d.id == divisionId).firstOrNull;
    if (selectedDiv != null &&
        (_normalizedMatchType(selectedDiv.matchType) == 'DOUBLES' ||
            _normalizedMatchType(selectedDiv.matchType) == 'MIXED_DOUBLES')) {
      final inviteCode = _localInviteCode ?? widget.inviteCode ?? '';
      context.push(
        '/register/${widget.tournamentId}/doubles?divisionId=$divisionId&invite=$inviteCode',
        extra: selectedDiv,
      );
      return;
    }
    final String effectiveTeamName = _nameCtrl.text.trim().isNotEmpty
        ? _nameCtrl.text.trim()
        : (user?.fullName?.trim().isNotEmpty == true
              ? user!.fullName!.trim()
              : l10n.registerTypeDefault);

    setState(() => _submitting = true);
    try {
      final result = await ref
          .read(tournamentRepositoryProvider)
          .registerParticipant(
            tournamentId: widget.tournamentId,
            teamName: effectiveTeamName,
            divisionId: divisionId,
            inviteCode: _localInviteCode ?? widget.inviteCode,
            rankingConsent: _rankingConsent,
          );
      if (!mounted) return;
      // Refresh the detail streams so the participant count reflects the
      // successful registration when the user returns to the tournament.
      ref.invalidate(tournamentProvider(widget.tournamentId));
      ref.invalidate(tournamentIntroProvider(widget.tournamentId));
      final t = ref.read(tournamentProvider(widget.tournamentId)).asData?.value;
      final effectiveFee = result.entryFee;
      _registrationTeamStatus = result.teamStatus;
      final canProceedToPayment =
          !result.isWaitlisted &&
          (result.teamStatus == 'COMPLETE' ||
              result.teamStatus == 'APPROVED' ||
              result.teamStatus == 'PENDING_APPROVAL');

      if (effectiveFee > 0 &&
          result.participantId.isNotEmpty &&
          canProceedToPayment) {
        context.push(
          '/payment/checkout',
          extra: {
            'tournamentId': widget.tournamentId,
            'participantId': result.participantId,
            'divisionId': divisionId,
            'amount': effectiveFee,
            'tournamentName': t?.name ?? 'Giải đấu',
          },
        );
      } else {
        setState(() {
          _success = true;
          _registeredEntryFee = effectiveFee;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ErrorParser.parse(e, l10n.registerError),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String _divisionTypeLabel(TournamentDivisionOption d) {
    final gender = switch (_normalizedGender(d.genderRestriction)) {
      'MALE' => 'Nam',
      'FEMALE' => l10n.registerDivFemale,
      'MIXED' => l10n.registerDivMixed,
      _ => '',
    };
    final type = switch (_normalizedMatchType(d.matchType)) {
      'SINGLES' => l10n.registerTypeSingles,
      'DOUBLES' => l10n.registerTypeDoubles,
      'MIXED_DOUBLES' => l10n.registerTypeMixedDoubles,
      _ => l10n.registerContentTitle,
    };
    if (type == l10n.registerTypeMixedDoubles || gender.isEmpty) return type;
    return '$type $gender';
  }

  String? _normalizedGender(String? value) {
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

  String? _normalizedMatchType(String? value) {
    final normalized = value
        ?.trim()
        .toUpperCase()
        .replaceAll('-', '_')
        .replaceAll(' ', '_');
    return switch (normalized) {
      'SINGLE' || 'SINGLES' || 'DON' => 'SINGLES',
      'DOUBLE' || 'DOUBLES' || 'DOI' => 'DOUBLES',
      'MIXED_DOUBLE' || 'MIXED_DOUBLES' || 'DOI_NAM_NU' => 'MIXED_DOUBLES',
      _ => null,
    };
  }

  List<String> _divisionMeta(TournamentDivisionOption d) {
    final items = <String>[_divisionTypeLabel(d)];
    if (d.minElo != null || d.maxElo != null) {
      final min = d.minElo?.toInt().toString() ?? '0';
      final max = d.maxElo?.toInt().toString() ?? '∞';
      items.add('ELO $min-$max');
    }
    if (d.maxParticipants != null) {
      items.add('Tối đa ${d.maxParticipants} đội');
    }
    if (d.entryFee != null && d.entryFee! > 0) {
      items.add(
        '${NumberFormat('#,###', 'vi_VN').format(d.entryFee!.ceil())}đ',
      );
    } else {
      items.add(l10n.registerFree);
    }
    return items;
  }

  String _getRegistrationCta(Tournament? t) {
    if (t?.registrationMode == 'APPROVAL') return l10n.registerSubmitApproval;
    return l10n.registerButton;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isAuth = ref.watch(authProvider).isAuthenticated;
    // Tải kèm mã mời để đọc được giải PRIVATE (backend yêu cầu `?invite=`).
    // Key đổi khi `_localInviteCode` đổi → tự refetch sau khi nhập mã.
    final tAsync = ref.watch(
      registerTournamentProvider((
        id: widget.tournamentId,
        invite: _localInviteCode ?? widget.inviteCode,
      )),
    );
    final divAsync = ref.watch(_divisionsProvider(widget.tournamentId));

    return Scaffold(
      backgroundColor: context.colors.bgDark,
      appBar: AppBar(
        title: Text(l10n.registerTitle),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: tAsync.when(
          data: (t) {
            if (t == null) {
              // Giải PRIVATE trả 403 (→ null) khi chưa có mã mời. Nếu chưa có
              // mã thì hiện cổng nhập mã; chỉ báo "không tìm thấy" khi đã có
              // mã mà vẫn tải không được (mã sai / giải không tồn tại).
              final hasCode =
                  widget.inviteCode != null || _localInviteCode != null;
              if (!hasCode) return _buildInviteGate(null);
              return Center(child: Text(l10n.registerTournamentNotFound));
            }
            if (!isAuth) return _buildLoginPrompt(t);
            if (_checkingRegistration) {
              return const Center(child: CircularProgressIndicator());
            }
            // Invite gate: nếu là PRIVATE và chưa có mã mời
            final needsInvite =
                (t.visibility == 'PRIVATE' ||
                    t.registrationMode == 'INVITE_ONLY') &&
                widget.inviteCode == null &&
                _localInviteCode == null;
            if (needsInvite) return _buildInviteGate(t);
            return divAsync.when(
              data: (divs) {
                final effectiveDivs = divs.isNotEmpty
                    ? divs
                    : [
                        TournamentDivisionOption(
                          id: 'default_${t.id}',
                          name: t.name.isNotEmpty ? t.name : l10n.registerContentTitle,
                          matchType:
                              t.format.toLowerCase() == 'doubles' ||
                                  t.name.toLowerCase().contains(l10n.registerTypeDoubles)
                              ? 'DOUBLES'
                              : 'SINGLES',
                          entryFee: t.entryFee,
                          maxParticipants: t.maxTeams,
                        ),
                      ];
                if (_alreadyRegistered) {
                  return _buildExistingRegistration(t, effectiveDivs);
                }
                return _buildForm(t, AsyncValue.data(effectiveDivs));
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) {
                final fallbackDivs = [
                  TournamentDivisionOption(
                    id: 'default_${t.id}',
                    name: t.name.isNotEmpty ? t.name : l10n.registerContentTitle,
                    matchType:
                        t.format.toLowerCase() == 'doubles' ||
                            t.name.toLowerCase().contains(l10n.registerTypeDoubles)
                        ? 'DOUBLES'
                        : 'SINGLES',
                    entryFee: t.entryFee,
                    maxParticipants: t.maxTeams,
                  ),
                ];
                if (_alreadyRegistered) {
                  return _buildExistingRegistration(t, fallbackDivs);
                }
                return _buildForm(t, AsyncValue.data(fallbackDivs));
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Lỗi: $e')),
        ),
      ),
    );
  }

  String _getSuccessTitle(Tournament? t) {
    if (_registrationTeamStatus == 'WAITLISTED') {
      return l10n.registerSuccessWaitlisted;
    }
    if (t?.registrationMode == 'APPROVAL') return 'Gửi yêu cầu thành công!';
    return l10n.registerSuccess;
  }

  Widget _buildExistingRegistration(
    Tournament tournament,
    List<TournamentDivisionOption> divisions,
  ) {
    TournamentDivisionOption? existingDivision;
    for (final division in divisions) {
      if (division.id == _existingDivisionId) {
        existingDivision = division;
        break;
      }
    }

    final fee = existingDivision?.entryFee ?? tournament.entryFee ?? 0;
    final status = _existingTeamStatus ?? '';
    final canPay =
        !_existingIsPaid &&
        fee > 0 &&
        (_existingParticipantId?.isNotEmpty ?? false) &&
        (status == 'COMPLETE' || status == 'APPROVED' || status == 'PENDING_APPROVAL');
    final statusLabel = switch (status) {
      'PENDING_PARTNER' => l10n.registerStatusPendingPartner,
      'PENDING_APPROVAL' => l10n.registerStatusPendingApproval,
      'APPROVED' => 'Đã xét duyệt',
      'WAITLISTED' => l10n.registerStatusWaitlisted,
      'COMPLETE' when _existingIsPaid => l10n.registerStatusCompletePaid,
      'COMPLETE' => l10n.registerStatusCompleteUnpaid,
      _ => l10n.registerAlreadyRegistered,
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.colors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.border),
      ),
      child: Column(
        children: [
          Icon(
            _existingIsPaid ? Icons.verified_rounded : Icons.how_to_reg_rounded,
            size: 52,
            color: _existingIsPaid ? context.colors.success : AppTheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            statusLabel,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.colors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (status == 'WAITLISTED') ...[
            const SizedBox(height: 8),
            Text(
              l10n.registerNoPaymentWaitlisted,
              textAlign: TextAlign.center,
              style: TextStyle(color: context.colors.textSecondary),
            ),
          ],
          if (canPay) ...[
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => context.push(
                  '/payment/checkout',
                  extra: {
                    'tournamentId': tournament.id,
                    'participantId': _existingParticipantId,
                    'divisionId': _existingDivisionId,
                    'amount': fee,
                    'tournamentName': tournament.name,
                  },
                ),
                icon: const Icon(Icons.payment_rounded),
                label: Text(
                  'Thanh toán ${NumberFormat('#,###', 'vi_VN').format(fee.ceil())}đ',
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => context.go('/intro/${tournament.id}'),
              child: Text(l10n.registerViewDetail),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccess(Tournament? t) => Scaffold(
    backgroundColor: context.colors.bgDark,
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
                color: context.colors.success.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle_rounded,
                size: 52,
                color: context.colors.success,
              ),
            ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
            const SizedBox(height: 24),
            Text(
              _getSuccessTitle(t),
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            if (_registeredEntryFee != null && _registeredEntryFee! > 0)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: context.colors.warning.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _registrationTeamStatus == 'WAITLISTED'
                      ? l10n.registerNoPaymentWaitlisted
                      : 'Phí tham gia ${NumberFormat('#,###', 'vi_VN').format(_registeredEntryFee!.ceil())}đ chưa thanh toán',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: context.colors.warning,
                  ),
                ),
              ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => context.go('/intro/${widget.tournamentId}'),
              child: Text(l10n.registerViewDetail),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () => WithdrawSheet.show(
                context,
                tournamentId: widget.tournamentId,
                divisionId: _selectedDiv,
                hasPaid: false,
              ),
              icon: Icon(
                Icons.exit_to_app_rounded,
                size: 16,
                color: context.colors.error,
              ),
              label: Text(
                l10n.registerWithdraw,
                style: TextStyle(color: context.colors.error, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _buildHeader(Tournament t) {
    final colors = context.colors;
    final fmt = NumberFormat('#,###', 'vi_VN');
    final hasFee = t.entryFee != null && t.entryFee! > 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.name,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.3,
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: colors.bgSurface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colors.border),
                ),
                child: Text(
                  'Tối đa: ${t.maxTeams} đội',
                  style: TextStyle(
                    color: colors.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: hasFee
                      ? AppTheme.primary.withValues(alpha: 0.12)
                      : colors.bgSurface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: hasFee
                        ? AppTheme.primary.withValues(alpha: 0.3)
                        : colors.border,
                  ),
                ),
                child: Text(
                  hasFee
                      ? 'Phí: ${fmt.format(t.entryFee!.ceil())}đ'
                      : l10n.registerFree,
                  style: TextStyle(
                    color: hasFee ? AppTheme.primary : colors.textMuted,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 250.ms);
  }

  Widget _buildInviteGate(Tournament? t) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.lock_rounded, size: 64, color: context.colors.textMuted),
        const SizedBox(height: 24),
        Text(
          l10n.registerPrivateTitle,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: context.colors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.registerPrivateDesc,
          style: TextStyle(fontSize: 14, color: context.colors.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        TextField(
          controller: _inviteCtrl,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: 8,
            color: context.colors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: l10n.registerInviteHint,
            filled: true,
            fillColor: context.colors.bgCard,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 16,
            ),
          ),
          maxLength: 20,
        ),
        if (_inviteError != null) ...[
          const SizedBox(height: 8),
          Text(
            _inviteError!,
            style: TextStyle(
              color: context.colors.error,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton.icon(
            onPressed: _inviteValidating ? null : _validateInvite,
            icon: _inviteValidating
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.login_rounded),
            label: Text(
              _inviteValidating ? l10n.registerInviteValidating : l10n.registerInviteConfirm,
            ),
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _buildLoginPrompt(Tournament t) => Column(
    children: [
      _buildHeader(t),
      const SizedBox(height: 24),
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: context.colors.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.colors.border),
        ),
        child: Column(
          children: [
            Icon(
              Icons.login_rounded,
              size: 48,
              color: context.colors.textMuted,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.registerLoginPrompt,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                final params = <String, String>{};
                if (widget.inviteCode?.isNotEmpty == true) {
                  params['invite'] = widget.inviteCode!;
                }
                if (widget.divisionId?.isNotEmpty == true) {
                  params['divisionId'] = widget.divisionId!;
                }
                final query = Uri(queryParameters: params).query;
                final redirect =
                    '/register/${widget.tournamentId}${query.isEmpty ? '' : '?$query'}';
                context.push(
                  '/login?redirect=${Uri.encodeComponent(redirect)}',
                );
              },
              icon: const Icon(Icons.login),
              label: Text(l10n.registerLoginButton),
            ),
          ],
        ),
      ),
    ],
  );

  Widget _buildForm(
    Tournament t,
    AsyncValue<List<TournamentDivisionOption>> divAsync,
  ) {
    // Check profile completeness
    final userAsync = ref.watch(userProfileProvider);
    final user = userAsync.asData?.value;
    final isIncomplete =
        user?.fullName == null ||
        user?.fullName?.isEmpty == true ||
        user?.phoneNumber == null ||
        user?.phoneNumber?.isEmpty == true ||
        user?.gender == null ||
        user?.gender?.isEmpty == true;

    final now = DateTime.now();
    final isRegistrationClosed =
        (t.status == 'REGISTRATION_CLOSED' ||
        t.status == 'IN_PROGRESS' ||
        t.status == 'COMPLETED' ||
        t.status == 'CANCELLED' ||
        (t.registrationEndDate != null && now.isAfter(t.registrationEndDate!)));
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(t),
        const SizedBox(height: 14),
        _RegistrationCountdownCard(
          targetDate:
              t.registrationEndDate ??
              t.startDate ??
              DateTime.now().add(const Duration(days: 7)),
        ),
        const SizedBox(height: 16),
        if (isRegistrationClosed) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.colors.warning.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: context.colors.warning.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.registerRegClosed,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: context.colors.warning,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.registerRegClosedDesc,
                  style: TextStyle(
                    color: context.colors.textSecondary,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (isIncomplete) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.colors.error.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: context.colors.error.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.warning_rounded,
                      color: context.colors.error,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l10n.registerProfileIncompleteTitle,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.registerProfileIncompleteDesc,
                  style: TextStyle(
                    color: context.colors.textSecondary,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => context.push('/profile/edit'),
                    icon: const Icon(Icons.edit_rounded, size: 16),
                    label: Text(
                      l10n.registerUpdateProfile,
                      style: const TextStyle(fontWeight: FontWeight.w700),
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
          ),
          const SizedBox(height: 24),
        ],
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: context.colors.bgCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: context.colors.border),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.registerInfoTitle,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 16),
                // Only show name input after division selected
                if (_selectedDivision != null)
                  if (_normalizedMatchType(_selectedDivision?.matchType) ==
                      'SINGLES')
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.primary.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.registerPlayerName,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: context.colors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user?.fullName ?? l10n.registerNameNotUpdated,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: context.colors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            l10n.registerNameFromAccount,
                            style: TextStyle(
                              fontSize: 11,
                              color: context.colors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.primary.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Text(
                        l10n.registerTeamNameNext,
                      ),
                    ),
                const SizedBox(height: 16),
                divAsync.when(
                  data: (divs) {
                    if (divs.isEmpty) return const SizedBox.shrink();
                    if (divs.length == 1 && _selectedDiv == null) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted && _selectedDiv == null) {
                          _onDivisionSelected(divs.first.id, divs);
                        }
                      });
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.registerContentTitle,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...divs.map((d) {
                          final id = d.id;
                          final name = d.name;
                          final sel = _selectedDiv == id;
                          final formatLabel = _divisionTypeLabel(d);
                          final hasFormatLabel =
                              formatLabel != l10n.registerContentTitle;
                          final meta = _divisionMeta(d)
                              .where((label) => label != formatLabel)
                              .toList();
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: GestureDetector(
                              onTap: () => _onDivisionSelected(id, divs),
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: context.colors.bgDark,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: sel
                                        ? AppTheme.primary
                                        : context.colors.border,
                                    width: sel ? 2 : 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            hasFormatLabel ? formatLabel : name,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w800,
                                              color: context.colors.textPrimary,
                                            ),
                                          ),
                                          if (hasFormatLabel &&
                                              name.trim().isNotEmpty &&
                                              name.trim() != formatLabel.trim())
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                top: 3,
                                              ),
                                              child: Text(
                                                name,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: context.colors.textMuted,
                                                ),
                                              ),
                                            ),
                                          const SizedBox(height: 8),
                                          Wrap(
                                            spacing: 6,
                                            runSpacing: 6,
                                            children: meta
                                                .map(
                                                  (label) => Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 8,
                                                          vertical: 4,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: sel
                                                          ? AppTheme.primary
                                                                .withValues(
                                                                  alpha: 0.10,
                                                                )
                                                          : context
                                                                .colors
                                                                .bgCard,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            999,
                                                          ),
                                                      border: Border.all(
                                                        color: sel
                                                            ? AppTheme.primary
                                                                  .withValues(
                                                                    alpha: 0.24,
                                                                  )
                                                            : context
                                                                  .colors
                                                                  .border,
                                                      ),
                                                    ),
                                                    child: Text(
                                                      label,
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        color: sel
                                                            ? AppTheme.primary
                                                            : context
                                                                  .colors
                                                                  .textSecondary,
                                                      ),
                                                    ),
                                                  ),
                                                )
                                                .toList(),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: sel
                                              ? AppTheme.primary
                                              : context.colors.border,
                                          width: 2,
                                        ),
                                      ),
                                      child: sel
                                          ? Center(
                                              child: Container(
                                                width: 10,
                                                height: 10,
                                                decoration: BoxDecoration(
                                                  color: AppTheme.primary,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                            )
                                          : null,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                        if (_divisionError != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              _divisionError!,
                              style: TextStyle(
                                fontSize: 12,
                                color: context.colors.error,
                              ),
                            ),
                          ),
                        if (_genderError != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: context.colors.error.withValues(
                                  alpha: 0.08,
                                ),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: context.colors.error.withValues(
                                    alpha: 0.2,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.transgender,
                                    size: 16,
                                    color: context.colors.error,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _genderError!,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: context.colors.error,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        if (_eloError != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: context.colors.warning.withValues(
                                  alpha: 0.15,
                                ),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: context.colors.warning.withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.trending_up,
                                    size: 16,
                                    color: Colors.amber,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _eloError!,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.amber,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        if (_eloChecking)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  l10n.registerEloSchedule,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                      ],
                    );
                  },
                  loading: () => const SizedBox(
                    height: 24,
                    child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  error: (error, _) => Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: context.colors.error.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      l10n.registerDivisionLoadError,
                    ),
                  ),
                ),
                if (t.isRanked) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: context.colors.bgSurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: context.colors.border),
                    ),
                    child: CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _rankingConsent,
                      onChanged: (value) => setState(() => _rankingConsent = value ?? false),
                      controlAffinity: ListTileControlAffinity.leading,
                      title: const Text('Đồng ý hiển thị kết quả và điểm ELO trên bảng xếp hạng', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                      subtitle: const Text('Giải có xếp hạng chỉ ghi nhận ELO sau khi bạn đồng ý.', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: (isRegistrationClosed || _submitting)
                        ? null
                        : _register,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      disabledBackgroundColor: context.colors.bgSurface,
                      foregroundColor: Colors.white,
                      disabledForegroundColor: context.colors.textMuted,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _submitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            isRegistrationClosed
                                ? l10n.registerRegClosed
                                : (_selectedDivision?.entryFee != null &&
                                      _selectedDivision!.entryFee! > 0)
                                ? '${_getSubmitLabel(t)} • ${NumberFormat('#,###', 'vi_VN').format(_selectedDivision!.entryFee!.ceil())}đ'
                                : (t.entryFee != null && t.entryFee! > 0)
                                ? '${_getSubmitLabel(t)} • ${NumberFormat('#,###', 'vi_VN').format(t.entryFee!.ceil())}đ'
                                : '${_getSubmitLabel(t)} (Miễn phí)',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ).animate().fadeIn(delay: 200.ms, duration: 300.ms),
        const SizedBox(height: 16),
        _buildTournamentHighlightsCard(t),
      ],
    );
  }

  Widget _buildTournamentHighlightsCard(Tournament t) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final startDateStr = t.startDate != null
        ? DateFormat('dd/MM/yyyy').format(t.startDate!)
        : l10n.registerNotScheduled;
    final endDateStr = t.endDate != null
        ? DateFormat('dd/MM/yyyy').format(t.endDate!)
        : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.registerTermsTitle,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: colors.textMuted,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 14),
          _buildInfoRow(
            Icons.event_available_rounded,
            l10n.registerScheduleTitle,
            endDateStr != null ? '$startDateStr - $endDateStr' : startDateStr,
            colors,
          ),
          if (t.locationAddress != null && t.locationAddress!.isNotEmpty)
            _buildInfoRow(
              Icons.location_on_rounded,
              l10n.registerLocationTitle,
              t.locationAddress!,
              colors,
            ),
          _buildInfoRow(
            Icons.verified_user_rounded,
            l10n.registerEloScheduleDesc,
            'Sơ đồ thi đấu công khai, tích lũy điểm ELO tự động sau giải',
            colors,
          ),
          _buildInfoRow(
            Icons.support_agent_rounded,
            l10n.registerSupportDesc,
            l10n.registerSupportDesc,
            colors,
          ),
        ],
      ),
    ).animate().fadeIn(delay: 350.ms, duration: 300.ms);
  }

  Widget _buildInfoRow(
    IconData icon,
    String title,
    String desc,
    AppColorsExtension colors,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(icon, size: 16, color: colors.textSecondary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: TextStyle(
                    fontSize: 11,
                    color: colors.textMuted,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RegistrationCountdownCard extends StatefulWidget {
  final DateTime targetDate;
  const _RegistrationCountdownCard({required this.targetDate});

  @override
  State<_RegistrationCountdownCard> createState() =>
      _RegistrationCountdownCardState();
}

class _RegistrationCountdownCardState
    extends State<_RegistrationCountdownCard> {
  Timer? _timer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _calculateRemaining();
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _calculateRemaining(),
    );
  }

  void _calculateRemaining() {
    final now = DateTime.now();
    final diff = widget.targetDate.difference(now);
    if (mounted) {
      setState(() {
        _remaining = diff.isNegative ? Duration.zero : diff;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;

    if (_remaining == Duration.zero) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: colors.error.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.error.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Icon(Icons.timer_off_rounded, color: colors.error, size: 20),
            const SizedBox(width: 10),
            Text(
              l10n.registerDeadlineExpired,
              style: TextStyle(
                color: colors.error,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    final days = _remaining.inDays;
    final hours = _remaining.inHours % 24;
    final minutes = _remaining.inMinutes % 60;
    final seconds = _remaining.inSeconds % 60;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.timer_outlined, color: colors.textSecondary, size: 16),
              const SizedBox(width: 8),
              Text(
                l10n.registerDeadline,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: colors.textMuted,
                  letterSpacing: 0.8,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: colors.bgSurface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: colors.border),
                ),
                child: Text(
                  l10n.registerOpenTag,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: colors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildTimeUnit('$days'.padLeft(2, '0'), l10n.registerDays, colors),
              _buildColon(colors),
              _buildTimeUnit('$hours'.padLeft(2, '0'), l10n.registerHours, colors),
              _buildColon(colors),
              _buildTimeUnit('$minutes'.padLeft(2, '0'), l10n.registerMinutes, colors),
              _buildColon(colors),
              _buildTimeUnit('$seconds'.padLeft(2, '0'), l10n.registerSeconds, colors),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeUnit(String value, String unit, AppColorsExtension colors) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: colors.bgCard,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: colors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: colors.textPrimary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          unit,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: colors.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildColon(AppColorsExtension colors) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        ':',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w900,
          color: colors.textMuted,
        ),
      ),
    );
  }
}



