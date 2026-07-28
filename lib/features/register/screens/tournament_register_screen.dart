import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
      final response = await dio.get('/tournaments/${widget.tournamentId}/my-registration');
      if (response.data != null && response.data['participantId'] != null) {
        if (mounted) {
          setState(() {
            _alreadyRegistered = true;
            _existingParticipantId = response.data['participantId']?.toString();
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
  String? _genderError;
  String? _eloError;
  bool _eloChecking = false;
  bool _inviteValidating = false;
  String? _inviteError;
  String? _localInviteCode;
  double? _registeredEntryFee;
  bool _checkingRegistration = true;
  bool _alreadyRegistered = false;
  String? _existingParticipantId;

  String _getSubmitLabel(Tournament? t) {
    if (t?.registrationMode == 'APPROVAL') return 'Gửi yêu cầu tham gia';
    return 'Xác nhận đăng ký';
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
    if (user != null &&
        div.genderRestriction != null &&
        div.genderRestriction != 'MIXED') {
      final userGender = user.gender?.toUpperCase();
      final divGender = div.genderRestriction!.toUpperCase();
      if (userGender != null && userGender != divGender) {
        setState(() {
          _genderError = divGender == 'MALE'
              ? 'Nội dung này chỉ dành cho Nam'
              : 'Nội dung này chỉ dành cho Nữ';
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
              'Không thể kiểm tra ELO. Vui lòng thử lại trước khi đăng ký.',
        );
      }
    } finally {
      if (mounted) setState(() => _eloChecking = false);
    }
  }

  Future<void> _validateInvite() async {
    final code = _inviteCtrl.text.trim();
    if (code.length < 6) {
      setState(() => _inviteError = 'Mã mời phải có ít nhất 6 ký tự');
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
        setState(() => _inviteError = 'Mã mời không hợp lệ hoặc đã hết hạn');
      }
    } finally {
      if (mounted) setState(() => _inviteValidating = false);
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    final userAsync = ref.read(userProfileProvider);
    final user = userAsync.asData?.value;
    if (user?.fullName == null ||
        user?.phoneNumber == null ||
        user?.gender == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vui lòng hoàn thiện hồ sơ trước khi đăng ký'),
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
    final divisions = ref.read(_divisionsProvider(widget.tournamentId)).value;
    final divisionId =
        _selectedDiv ??
        (divisions != null && divisions.length == 1
            ? divisions.first.id
            : null);
    if (divisions != null && divisions.length > 1 && divisionId == null) {
      setState(() => _divisionError = 'Hãy chọn nội dung thi đấu.');
      return;
    }
    // If doubles division, navigate to doubles flow
    final selectedDiv = divisions?.where((d) => d.id == divisionId).firstOrNull;
    if (selectedDiv != null &&
        (selectedDiv.matchType == 'DOUBLES' ||
            selectedDiv.matchType == 'MIXED_DOUBLES')) {
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
            : 'Vận động viên');

    setState(() => _submitting = true);
    try {
      final result = await ref
          .read(tournamentRepositoryProvider)
          .registerParticipant(
            tournamentId: widget.tournamentId,
            teamName: effectiveTeamName,
            divisionId: divisionId,
            inviteCode: _localInviteCode ?? widget.inviteCode,
          );
      if (!mounted) return;
      final t = ref.read(tournamentProvider(widget.tournamentId)).asData?.value;
      final effectiveFee = (result.entryFee > 0)
          ? result.entryFee
          : (selectedDiv?.entryFee ?? t?.entryFee ?? 0.0);

      if (effectiveFee > 0 && result.participantId.isNotEmpty) {
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          SnackBar(
            content: Text(
              ErrorParser.parse(e, 'Không thể đăng ký. Vui lòng thử lại.'),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String _divisionTypeLabel(TournamentDivisionOption d) {
    final gender = switch ((d.genderRestriction ?? '').toUpperCase()) {
      'MALE' => 'Nam',
      'FEMALE' => 'Nữ',
      'MIXED' => 'Nam nữ',
      _ => '',
    };
    final type = switch ((d.matchType ?? '').toUpperCase()) {
      'SINGLES' => 'Đơn',
      'DOUBLES' => 'Đôi',
      'MIXED_DOUBLES' => 'Đôi nam nữ',
      _ => 'Nội dung',
    };
    if (type == 'Đôi nam nữ' || gender.isEmpty) return type;
    return '$type $gender';
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
      items.add('${NumberFormat('#,###', 'vi_VN').format(d.entryFee!.ceil())}đ');
    } else {
      items.add('Miễn phí');
    }
    return items;
  }

  String _getRegistrationCta(Tournament? t) {
    if (t?.registrationMode == 'APPROVAL') return 'Gửi yêu cầu tham gia';
    return 'Đăng ký';
  }

  @override
  Widget build(BuildContext context) {
    final tAsync = ref.watch(tournamentIntroProvider(widget.tournamentId));
    final divAsync = ref.watch(_divisionsProvider(widget.tournamentId));
    final isAuth = ref.watch(authProvider).isAuthenticated;

    if (_success) {
      final t = tAsync.asData?.value;
      return _buildSuccess(t);
    }
    return Scaffold(
      backgroundColor: context.colors.bgDark,
      appBar: AppBar(
        title: Text(_getRegistrationCta(tAsync.asData?.value)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: tAsync.when(
          data: (t) {
            if (t == null) {
              return const Center(child: Text('Không tìm thấy giải'));
            }
            if (!isAuth) return _buildLoginPrompt(t);
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
                          name: t.name.isNotEmpty ? t.name : 'Nội dung chính',
                          matchType: t.format.toLowerCase() == 'doubles' ||
                                  t.name.toLowerCase().contains('đôi')
                              ? 'DOUBLES'
                              : 'SINGLES',
                          entryFee: t.entryFee,
                          maxParticipants: t.maxTeams,
                        )
                      ];
                return _buildForm(t, AsyncValue.data(effectiveDivs));
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) {
                final fallbackDivs = [
                  TournamentDivisionOption(
                    id: 'default_${t.id}',
                    name: t.name.isNotEmpty ? t.name : 'Nội dung chính',
                    matchType: t.format.toLowerCase() == 'doubles' ||
                            t.name.toLowerCase().contains('đôi')
                        ? 'DOUBLES'
                        : 'SINGLES',
                    entryFee: t.entryFee,
                    maxParticipants: t.maxTeams,
                  )
                ];
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
    if (t?.registrationMode == 'APPROVAL') return 'Gửi yêu cầu thành công!';
    return 'Đăng ký thành công!';
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
                  'Đã thanh toán ${NumberFormat('#,###', 'vi_VN').format(_registeredEntryFee!.ceil())}đ',
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
              child: const Text('Xem chi tiết'),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () => WithdrawSheet.show(
                context,
                tournamentId: widget.tournamentId,
                divisionId: _selectedDiv,
                hasPaid:
                    _registeredEntryFee != null && _registeredEntryFee! > 0,
              ),
              icon: Icon(
                Icons.exit_to_app_rounded,
                size: 16,
                color: context.colors.error,
              ),
              label: Text(
                'Rút lui khỏi giải',
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.bgSurface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colors.border),
                ),
                child: Text(
                  'Tối đa: ${t.maxTeams} đội',
                  style: TextStyle(color: colors.textMuted, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: hasFee ? AppTheme.primary.withValues(alpha: 0.12) : colors.bgSurface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: hasFee ? AppTheme.primary.withValues(alpha: 0.3) : colors.border,
                  ),
                ),
                child: Text(
                  hasFee ? 'Phí: ${fmt.format(t.entryFee!.ceil())}đ' : 'Miễn phí',
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

  Widget _buildInviteGate(Tournament t) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.lock_rounded, size: 64, color: context.colors.textMuted),
        const SizedBox(height: 24),
        Text(
          'Giải đấu riêng tư',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: context.colors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Vui lòng nhập mã mời để tham gia giải đấu này',
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
            hintText: 'Nhập mã mời',
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
              _inviteValidating ? 'Đang kiểm tra...' : 'Xác nhận mã mời',
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
            const Text(
              'Vui lòng đăng nhập để tham gia',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => context.push('/login'),
              icon: const Icon(Icons.login),
              label: const Text('Đăng nhập'),
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
    final isRegistrationClosed = (t.status == 'REGISTRATION_CLOSED' ||
        t.status == 'IN_PROGRESS' ||
        t.status == 'COMPLETED' ||
        t.status == 'CANCELLED' ||
        (t.registrationEndDate != null && now.isAfter(t.registrationEndDate!)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(t),
        const SizedBox(height: 14),
        _RegistrationCountdownCard(
          targetDate: t.registrationEndDate ??
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
              border: Border.all(color: context.colors.warning.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Giải đấu đã đóng đăng ký',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: context.colors.warning,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Ban tổ chức hiện đã ngắt nhận hồ sơ đăng ký mới cho giải đấu này.',
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
                    const Text(
                      'Hồ sơ chưa hoàn thiện',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Bạn cần cập nhật đầy đủ Họ tên, Số điện thoại và Giới tính trong hồ sơ cá nhân trước khi đăng ký.',
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
                    label: const Text(
                      'Cập nhật hồ sơ ngay',
                      style: TextStyle(fontWeight: FontWeight.w700),
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
                const Text(
                  'THÔNG TIN',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 16),
                // Only show name input after division selected
                if (_selectedDivision != null)
                  if (_selectedDivision?.matchType == 'SINGLES')
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Tên thi đấu', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: context.colors.textMuted)),
                          const SizedBox(height: 4),
                          Text(
                            user?.fullName ?? 'Chưa cập nhật',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: context.colors.textPrimary),
                          ),
                          const SizedBox(height: 2),
                          Text('Tên sẽ được lấy từ tài khoản của bạn', style: TextStyle(fontSize: 11, color: context.colors.textMuted)),
                        ],
                      ),
                    )
                  else
                    TextFormField(
                      controller: _nameCtrl,
                      style: TextStyle(color: context.colors.textPrimary),
                      decoration: InputDecoration(
                        labelText: 'Tên đội',
                        hintText: 'Nhập tên đội',
                        filled: true,
                        fillColor: context.colors.bgDark,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (v) => (v == null || v.trim().length < 3)
                          ? 'Tối thiểu 3 ký tự'
                          : null,
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
                        const Text(
                          'NỘI DUNG',
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
                          final meta = _divisionMeta(d);
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
                                            name,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w800,
                                              color: context.colors.textPrimary,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Wrap(
                                            spacing: 6,
                                            runSpacing: 6,
                                            children: meta
                                                .map(
                                                  (label) => Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: sel
                                                          ? AppTheme.primary
                                                              .withValues(
                                                                  alpha: 0.10)
                                                          : context
                                                              .colors.bgCard,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                        999,
                                                      ),
                                                      border: Border.all(
                                                        color: sel
                                                            ? AppTheme.primary
                                                                .withValues(
                                                                    alpha: 0.24)
                                                            : context
                                                                .colors.border,
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
                                                            : context.colors
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
                          const Padding(
                            padding: EdgeInsets.only(top: 8),
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
                                  'Đang kiểm tra ELO...',
                                  style: TextStyle(fontSize: 12),
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
                    child: const Text(
                      'Không thể tải nội dung thi đấu. Hãy thử lại.',
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: (isRegistrationClosed || _submitting) ? null : _register,
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
                                ? 'Giải đấu đã đóng đăng ký'
                                : (_selectedDivision?.entryFee != null && _selectedDivision!.entryFee! > 0)
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
    final colors = context.colors;
    final startDateStr = t.startDate != null
        ? DateFormat('dd/MM/yyyy').format(t.startDate!)
        : 'Chưa xếp lịch';
    final endDateStr =
        t.endDate != null ? DateFormat('dd/MM/yyyy').format(t.endDate!) : null;

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
            'QUYỀN LỢI & QUY ĐỊNH THAM GIA',
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
            'Thời gian thi đấu',
            endDateStr != null ? '$startDateStr - $endDateStr' : startDateStr,
            colors,
          ),
          if (t.locationAddress != null && t.locationAddress!.isNotEmpty)
            _buildInfoRow(
              Icons.location_on_rounded,
              'Địa điểm thi đấu',
              t.locationAddress!,
              colors,
            ),
          _buildInfoRow(
            Icons.verified_user_rounded,
            'Xếp lịch & ELO',
            'Sơ đồ thi đấu công khai, tích lũy điểm ELO tự động sau giải',
            colors,
          ),
          _buildInfoRow(
            Icons.support_agent_rounded,
            'Hỗ trợ VĐV',
            'Hỗ trợ hoàn hủy lệ phí & thắc mắc trực tiếp với Ban tổ chức',
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
              'Hạn đăng ký giải đấu đã kết thúc',
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
              Icon(
                Icons.timer_outlined,
                color: colors.textSecondary,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'HẠN ĐĂNG KÝ CÒN LẠI',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: colors.textMuted,
                  letterSpacing: 0.8,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: colors.bgSurface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: colors.border),
                ),
                child: Text(
                  'ĐANG MỞ',
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
              _buildTimeUnit('${days}'.padLeft(2, '0'), 'Ngày', colors),
              _buildColon(colors),
              _buildTimeUnit('${hours}'.padLeft(2, '0'), 'Giờ', colors),
              _buildColon(colors),
              _buildTimeUnit('${minutes}'.padLeft(2, '0'), 'Phút', colors),
              _buildColon(colors),
              _buildTimeUnit('${seconds}'.padLeft(2, '0'), 'Giây', colors),
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
