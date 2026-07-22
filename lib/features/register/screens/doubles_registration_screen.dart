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
import 'package:intl/intl.dart';

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
  List<UserSearchResult> _searchResults = [];
  UserSearchResult? _selectedPartner;
  bool _searching = false;
  bool _inviteLater = false;
  Timer? _searchDebounce;
  String? _genderError;
  String? _eloError;
  bool _eloChecking = false;

  // Step 2
  String? _teamInviteToken;
  String? _teamInviteLink;
  String? _participantId;
  Timer? _pollTimer;
  int _pollElapsed = 0;
  static const int _pollMaxDuration = 120; // seconds before timeout
  bool _gatesChecked = false;

  // Step 3
  double? _entryFee;

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

  Future<void> _handleStep1Submit() async {
    if (_teamNameCtrl.text.trim().length < 3) {
      _showError('Tên đội tối thiểu 3 ký tự');
      return;
    }
    // Gender gate
    if (_genderError != null || _eloError != null) {
      _showError(_genderError ?? _eloError!);
      return;
    }
    setState(() => _submitting = true);
    try {
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
          );
      if (!mounted) return;
      _participantId = result.participantId;
      _entryFee = result.entryFee;

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
          _teamInviteToken = regData['teamInviteToken']?.toString();
          _teamInviteLink = regData['teamInviteLink']?.toString();
        }
      } catch (_) {}

      if (mounted) {
        if (_selectedPartner != null || _inviteLater) {
          setState(() => _step = 2);
          _startPolling();
        } else {
          setState(() => _step = 3);
        }
      }
    } catch (e) {
      _showError('Lỗi: $e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollElapsed = 0;
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _pollElapsed += 3;
      if (_pollElapsed >= _pollMaxDuration) {
        _pollTimer?.cancel();
        if (mounted) {
          _showError('Đã hết thời gian chờ đồng đội. Bạn có thể tiếp tục sau.');
        }
        return;
      }
      _checkPartnerJoined();
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
      final teamStatus = regData['teamStatus']?.toString() ?? '';
      if (teamStatus == 'COMPLETE' ||
          teamStatus == 'PENDING' ||
          teamStatus == 'PENDING_APPROVAL') {
        _pollTimer?.cancel();
        if (mounted) {
          setState(() => _step = 3);
        }
      }
    } catch (_) {}
  }

  void _showError(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final tAsync = ref.watch(tournamentProvider(widget.tournamentId));
    final colors = context.colors;

    if (_success) return _buildSuccess(colors);
    return Scaffold(
      backgroundColor: colors.bgDark,
      appBar: AppBar(title: const Text('Đăng ký đôi'), centerTitle: true),
      body: tAsync.when(
        data: (t) {
          if (t == null) {
            return const Center(child: Text('Không tìm thấy giải'));
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
                if (_step == 2) _buildStep2(colors),
                if (_step == 3) _buildStep3(t, colors),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Lỗi: $e')),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'BƯỚC 1',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: AppTheme.primary,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Tạo đội',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _teamNameCtrl,
          style: TextStyle(color: colors.textPrimary),
          decoration: InputDecoration(
            labelText: 'Tên đội',
            hintText: 'Nhập tên đội của bạn',
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
                  'Đang kiểm tra ELO...',
                  style: TextStyle(fontSize: 13, color: colors.textSecondary),
                ),
              ],
            ),
          ),
        Row(
          children: [
            Expanded(
              child: Text(
                'TÌM ĐỒNG ĐỘI',
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
                'Mời sau',
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
              hintText: 'Nhập email hoặc SĐT đồng đội',
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
            label: Text(_submitting ? 'Đang xử lý...' : 'Tiếp theo'),
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

  Widget _buildStep2(AppColorsExtension colors) {
    final inviteLink =
        _teamInviteLink ??
        (_teamInviteToken != null
            ? '${Uri.base.origin}/tournaments/${widget.tournamentId}/join-team?pid=$_participantId&token=$_teamInviteToken'
            : null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'BƯỚC 2',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: AppTheme.primary,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Mời đồng đội',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Chia sẻ mã mời hoặc link này cho đồng đội của bạn',
          style: TextStyle(fontSize: 13, color: colors.textSecondary),
        ),
        const SizedBox(height: 24),
        if (inviteLink != null) ...[
          Center(
            child: QrImageView(
              data: inviteLink,
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
                  'Link mời:',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: colors.textMuted,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  inviteLink,
                  style: TextStyle(fontSize: 12, color: AppTheme.primary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: inviteLink));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã sao chép'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              icon: const Icon(Icons.copy_rounded, size: 16),
              label: const Text(
                'Sao chép link mời',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
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
              'Đang chờ đồng đội tham gia...',
              style: TextStyle(fontSize: 13, color: colors.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Center(
          child: Text(
            'Tự động hết hạn sau ${_pollMaxDuration - _pollElapsed}s',
            style: TextStyle(fontSize: 11, color: colors.textMuted),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: () {
              _pollTimer?.cancel();
              setState(() => _step = 3);
            },
            child: const Text('Bỏ qua, tiếp tục'),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildStep3(Tournament t, AppColorsExtension colors) {
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
          'Hoàn tất',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 20),
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
              Icon(Icons.check_circle_rounded, size: 48, color: colors.success),
              const SizedBox(height: 16),
              Text(
                'Đội của bạn: ${_teamNameCtrl.text}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              if (_selectedPartner != null)
                Text(
                  'Cùng: ${_selectedPartner!.fullName}',
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
                    'Phí tham gia: ${NumberFormat('#,###', 'vi_VN').format(_entryFee!.ceil())}đ',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: colors.warning,
                    ),
                  ),
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
              if (_entryFee != null &&
                  _entryFee! > 0 &&
                  _participantId != null) {
                context.push(
                  '/payment/checkout',
                  extra: {
                    'tournamentId': widget.tournamentId,
                    'participantId': _participantId,
                    'amount': _entryFee,
                  },
                );
              } else {
                setState(() => _success = true);
              }
            },
            icon: _entryFee != null && _entryFee! > 0
                ? const Icon(Icons.payment_rounded)
                : const Icon(Icons.check_rounded),
            label: Text(
              _entryFee != null && _entryFee! > 0
                  ? 'Tiến hành thanh toán'
                  : 'Hoàn tất',
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

  Widget _buildSuccess(AppColorsExtension colors) {
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
              const Text(
                'Đăng ký thành công!',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => context.go('/intro/${widget.tournamentId}'),
                child: const Text('Xem chi tiết'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
