import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
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
  const TournamentRegisterScreen({
    super.key,
    required this.tournamentId,
    this.inviteCode,
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
      context.push(
        '/register/${widget.tournamentId}/doubles?divisionId=$divisionId&invite=${widget.inviteCode ?? ''}',
        extra: selectedDiv,
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      final result = await ref
          .read(tournamentRepositoryProvider)
          .registerParticipant(
            tournamentId: widget.tournamentId,
            teamName: _nameCtrl.text,
            divisionId: divisionId,
            inviteCode: _localInviteCode ?? widget.inviteCode,
          );
      if (!mounted) return;
      setState(() {
        _success = true;
        _registeredEntryFee = result.entryFee;
      });
      if (result.entryFee > 0 && result.participantId.isNotEmpty) {
        context.push(
          '/payment/checkout',
          extra: {
            'tournamentId': widget.tournamentId,
            'participantId': result.participantId,
            'amount': result.entryFee,
          },
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tAsync = ref.watch(tournamentProvider(widget.tournamentId));
    final divAsync = ref.watch(_divisionsProvider(widget.tournamentId));
    final isAuth = ref.watch(authProvider).isAuthenticated;

    if (_success) {
      final t = tAsync.asData?.value;
      return _buildSuccess(t);
    }
    return Scaffold(
      backgroundColor: context.colors.bgDark,
      appBar: AppBar(title: const Text('Đăng ký'), centerTitle: true),
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
                t.visibility == 'PRIVATE' &&
                widget.inviteCode == null &&
                _localInviteCode == null;
            if (needsInvite) return _buildInviteGate(t);
            return _buildForm(t, divAsync);
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Lỗi: $e')),
        ),
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
            const Text(
              'Đăng ký thành công!',
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

  Widget _buildHeader(Tournament t) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
      ),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.emoji_events_rounded,
                color: Colors.amber,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tối đa: ${t.maxTeams} đội',
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (t.entryFee != null && t.entryFee! > 0) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: context.colors.warning.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Phí: ${NumberFormat('#,###', 'vi_VN').format(t.entryFee!.ceil())}đ',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ],
    ),
  ).animate().fadeIn(duration: 300.ms);

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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(t),
        const SizedBox(height: 24),
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
                TextFormField(
                  controller: _nameCtrl,
                  style: TextStyle(color: context.colors.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Tên đội / VĐV',
                    hintText: 'Nhập tên đội',
                    prefixIcon: Icon(
                      Icons.group_rounded,
                      color: context.colors.textMuted,
                    ),
                    filled: true,
                    fillColor: context.colors.bgDark,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (v) => (v == null || v.trim().length < 3)
                      ? 'Tối thiểu 3 ký tự'
                      : null,
                ),
                const SizedBox(height: 16),
                divAsync.when(
                  data: (divs) {
                    if (divs.isEmpty) return const SizedBox.shrink();
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
                                      child: Text(
                                        name,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: context.colors.textPrimary,
                                        ),
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
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _submitting ? null : _register,
                    icon: _submitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check_circle_outline_rounded),
                    label: Text(
                      _submitting ? 'Đang xử lý...' : 'Xác nhận đăng ký',
                    ),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ).animate().fadeIn(delay: 200.ms, duration: 300.ms),
      ],
    );
  }
}
