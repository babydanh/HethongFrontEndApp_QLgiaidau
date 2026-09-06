import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/core/utils/error_parser.dart';
import 'package:app_quanly_giaidau/domain/entities/organizer_ops.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:app_quanly_giaidau/providers/user_provider.dart';

const List<Color> _kSlotAvatarColors = [
  Color(0xFF10B981), // Emerald
  Color(0xFF3B82F6), // Blue
  Color(0xFFF59E0B), // Amber
  Color(0xFF8B5CF6), // Purple
  Color(0xFFF43F5E), // Rose
  Color(0xFF6366F1), // Indigo
  Color(0xFF14B8A6), // Teal
  Color(0xFF06B6D4), // Cyan
];

const int _kSlotsPerPage = 16;

class CommunityTournamentRosterWidget extends ConsumerStatefulWidget {
  final String tournamentId;
  final String? communityId;
  final String? initialTournamentName;
  final String? categoryName;
  final String? status;
  final String? inviteCode;
  final int? maxParticipants;
  final DateTime? startDate;
  final bool showTopBar;

  const CommunityTournamentRosterWidget({
    super.key,
    required this.tournamentId,
    this.communityId,
    this.initialTournamentName,
    this.categoryName,
    this.status,
    this.inviteCode,
    this.maxParticipants,
    this.startDate,
    this.showTopBar = true,
  });

  @override
  ConsumerState<CommunityTournamentRosterWidget> createState() =>
      _CommunityTournamentRosterWidgetState();
}

class _CommunityTournamentRosterWidgetState
    extends ConsumerState<CommunityTournamentRosterWidget> {
  Tournament? _tournament;
  List<OrganizerOpsParticipant> _participants = [];
  bool _isLoading = true;
  bool _isJoining = false;
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void didUpdateWidget(covariant CommunityTournamentRosterWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tournamentId != widget.tournamentId) {
      _fetchData();
    }
  }

  Future<void> _fetchData() async {
    try {
      final repo = ref.read(tournamentRepositoryProvider);
      final results = await Future.wait([
        repo.getById(widget.tournamentId).catchError((_) => null),
        repo.getPublicParticipants(widget.tournamentId).catchError((_) => <OrganizerOpsParticipant>[]),
      ]);

      if (mounted) {
        setState(() {
          _tournament = results[0] as Tournament?;
          _participants = (results[1] as List<OrganizerOpsParticipant>?) ?? [];
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts[0].isEmpty) return '?';
    if (parts.length == 1) {
      return parts[0].length >= 2
          ? parts[0].substring(0, 2).toUpperCase()
          : parts[0].toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  Color _getColorByName(String name) {
    int hash = 0;
    for (int i = 0; i < name.length; i++) {
      hash = name.codeUnitAt(i) + ((hash << 5) - hash);
    }
    return _kSlotAvatarColors[hash.abs() % _kSlotAvatarColors.length];
  }

  int _findCurrentParticipantIndex(String currentUserId) {
    if (currentUserId.isEmpty || _participants.isEmpty) return -1;
    return _participants.indexWhere((p) =>
        p.members.any((m) => m.userId == currentUserId));
  }

  String _resolveFormatBadge() {
    final formatStr = (_tournament?.format ?? '').toLowerCase();
    final sportStr = (_tournament?.sport ?? widget.categoryName ?? '').toLowerCase();
    final isFootball = sportStr.contains('bóng đá') || sportStr.contains('football');

    if (isFootball) {
      return 'Bóng đá 7 người';
    }
    final isDoubles = formatStr.contains('doubles') || formatStr.contains('đôi');
    return isDoubles ? 'Đánh Đôi' : 'Đánh Đơn';
  }

  Future<void> _handleJoin() async {
    final authState = ref.read(authProvider);
    final userProfile = ref.read(userProfileProvider).asData?.value;

    if (!authState.isAuthenticated || userProfile == null || userProfile.id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đăng nhập để xác nhận tham gia')),
      );
      return;
    }

    final currentUserId = userProfile.id;
    if (_findCurrentParticipantIndex(currentUserId) >= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bạn đã có tên trong danh sách tham gia')),
      );
      return;
    }

    final maxCap = _tournament?.maxTeams ?? widget.maxParticipants ?? 16;
    final currentTotalPlayers = _participants.fold<int>(
      0,
      (sum, p) => sum + (p.members.isEmpty ? 1 : p.members.length),
    );
    if (currentTotalPlayers >= maxCap) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Giải đấu đã đủ số lượng người tham gia')),
      );
      return;
    }

    setState(() => _isJoining = true);
    try {
      final repo = ref.read(tournamentRepositoryProvider);
      final inviteCode = widget.inviteCode;
      if (inviteCode != null && inviteCode.isNotEmpty) {
        await repo.joinLite(inviteCode);
      } else {
        final name = userProfile.fullName;
        await repo.registerParticipant(
          tournamentId: widget.tournamentId,
          teamName: (name != null && name.trim().isNotEmpty) ? name.trim() : 'VĐV',
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã xác nhận tham gia giải đấu!'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
      await _fetchData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ErrorParser.parse(e, 'Không thể xác nhận tham gia giải đấu')),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isJoining = false);
    }
  }

  Future<void> _confirmWithdrawDialog(OrganizerOpsParticipant participant) async {
    final tournamentName = _tournament?.name ?? widget.initialTournamentName ?? 'Giải đấu';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 24),
            SizedBox(width: 8),
            Text(
              'Hủy tham gia giải đấu',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          'Bạn có chắc chắn muốn hủy đăng ký tham gia giải "$tournamentName" không?',
          style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Hủy bỏ', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Xác nhận rút lui', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final repo = ref.read(tournamentRepositoryProvider);
        await repo.withdraw(tournamentId: widget.tournamentId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã hủy tham gia giải đấu')),
          );
        }
        await _fetchData();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(ErrorParser.parse(e, 'Không thể hủy tham gia')),
              backgroundColor: const Color(0xFFEF4444),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final tournamentName = _tournament?.name ?? widget.initialTournamentName ?? 'Giải đấu';
    final effectiveMaxParticipants =
        _tournament?.divisions.firstOrNull?.maxParticipants ??
        _tournament?.maxTeams ??
        widget.maxParticipants ??
        16;
    final maxParticipants = effectiveMaxParticipants;
    final userProfile = ref.watch(userProfileProvider).asData?.value;
    final currentUserId = userProfile?.id ?? '';

    if (_isLoading) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
      );
    }

    // Flatten participants into individual roster items so doubles pairings
    // show both players in separate slots rather than collapsing into one.
    final List<_RosterSlotItem> rosterItems = [];
    for (final p in _participants) {
      if (p.members.isEmpty) {
        rosterItems.add(_RosterSlotItem(
          participant: p,
          member: null,
          displayName: p.teamName,
          avatarUrl: null,
          userId: '',
          partnerName: null,
        ));
      } else {
        final isPaired = p.members.length >= 2;
        for (int i = 0; i < p.members.length; i++) {
          final m = p.members[i];
          final partner = isPaired
              ? (i == 0 ? p.members[1].fullName : p.members[0].fullName)
              : null;
          rosterItems.add(_RosterSlotItem(
            participant: p,
            member: m,
            displayName: m.fullName.isNotEmpty ? m.fullName : p.teamName,
            avatarUrl: m.avatarUrl,
            userId: m.userId,
            partnerName: partner,
          ));
        }
      }
    }

    final totalSlots = maxParticipants > rosterItems.length
        ? maxParticipants
        : rosterItems.length;
    final totalPages = (totalSlots / _kSlotsPerPage).ceil().clamp(1, 999);
    final safePage = _currentPage.clamp(1, totalPages);

    final startIndex = (safePage - 1) * _kSlotsPerPage;
    final endIndex = (startIndex + _kSlotsPerPage).clamp(0, totalSlots);

    final userSlotIndex = currentUserId.isNotEmpty
        ? rosterItems.indexWhere((item) => item.userId == currentUserId)
        : -1;
    final isUserRegistered = userSlotIndex >= 0;
    final userPage = isUserRegistered ? (userSlotIndex ~/ _kSlotsPerPage) + 1 : null;

    final formatBadge = _resolveFormatBadge();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top Bar: MANG ĐẾN BỞI + Tournament Name + Link to Details ──
          if (widget.showTopBar)
            GestureDetector(
              onTap: () {
                if (widget.tournamentId.isNotEmpty) {
                  final inviteParam = (widget.inviteCode != null && widget.inviteCode!.isNotEmpty)
                      ? '?invite=${widget.inviteCode}'
                      : '';
                  context.push('/tournaments/${widget.tournamentId}$inviteParam');
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: const BoxDecoration(
                  color: Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
                  border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          "assets/images/sporto_v1_with_text.png",
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'MANG ĐẾN BỞI',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF94A3B8),
                              letterSpacing: 0.3,
                            ),
                          ),
                          Text(
                            tournamentName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: colors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Xem giải',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 3),
                          Icon(Icons.arrow_outward_rounded, size: 13, color: Colors.white),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ── Main Content Area ──
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Xác nhận tham gia · ${rosterItems.length}',
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: colors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFDBEAFE), width: 0.8),
                          ),
                          child: Text(
                            formatBadge,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF2563EB),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${rosterItems.length}/$maxParticipants người',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),

                // Helper banner when user is registered on a different page
                if (userPage != null && userPage != safePage) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFBFDBFE), width: 0.8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Bạn đang ở slot #${userSlotIndex + 1} (Trang $userPage)',
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E40AF),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => setState(() => _currentPage = userPage),
                          child: const Text(
                            'Xem vị trí →',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF2563EB),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 14),

                // 4-Column Circular Slots Grid
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: endIndex - startIndex,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 8,
                    childAspectRatio: 0.76,
                  ),
                  itemBuilder: (context, idx) {
                    final globalSlotIndex = startIndex + idx;
                    final isOccupied = globalSlotIndex < rosterItems.length;

                    if (isOccupied) {
                      final item = rosterItems[globalSlotIndex];
                      final participant = item.participant;
                      final displayName = item.displayName;
                      final isSelf = currentUserId.isNotEmpty && item.userId == currentUserId;
                      final avatarUrl = item.avatarUrl;
                      final partnerName = item.partnerName;

                      return GestureDetector(
                        onTap: () {
                          if (isSelf) _confirmWithdrawDialog(participant);
                        },
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Stack(
                              children: [
                                Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    color: _getColorByName(displayName),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelf ? const Color(0xFF3B82F6) : Colors.white,
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.08),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: ClipOval(
                                    child: avatarUrl != null && avatarUrl.isNotEmpty
                                        ? Image.network(
                                            avatarUrl,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) => Center(
                                              child: Text(
                                                _getInitials(displayName),
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                          )
                                        : Center(
                                            child: Text(
                                              _getInitials(displayName),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w800,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                  ),
                                ),
                                if (isSelf)
                                  Positioned(
                                    right: 0,
                                    top: 0,
                                    child: Container(
                                      width: 18,
                                      height: 18,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFEF4444),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.close_rounded, size: 12, color: Colors.white),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Text(
                              displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF2563EB),
                              ),
                            ),
                            if (isSelf)
                              const Text(
                                '(Bạn)',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF94A3B8),
                                ),
                              )
                            else if (partnerName != null && partnerName.isNotEmpty)
                              Text(
                                'Cặp: $partnerName',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                          ],
                        ),
                      );
                    }

                    // Empty Slot with Dashed Circle
                    return GestureDetector(
                      onTap: _isJoining ? null : _handleJoin,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFFCBD5E1),
                                width: 1.5,
                              ),
                            ),
                            child: Center(
                              child: _isJoining
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(Icons.add_rounded, size: 22, color: Color(0xFF94A3B8)),
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Slot #${globalSlotIndex + 1}',
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                // Pagination Toolbar (When totalPages > 1)
                if (totalPages > 1) ...[
                  const SizedBox(height: 14),
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Slot ${startIndex + 1} - $endIndex / $totalSlots',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                      Row(
                        children: [
                          // Prev
                          InkWell(
                            onTap: safePage > 1
                                ? () => setState(() => _currentPage = safePage - 1)
                                : null,
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: safePage > 1 ? Colors.white : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: safePage > 1 ? const Color(0xFFE2E8F0) : const Color(0xFFF1F5F9),
                                ),
                              ),
                              child: Text(
                                '‹ Trước',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: safePage > 1 ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),

                          // Page pills
                          ...List.generate(totalPages, (i) {
                            final pageNum = i + 1;
                            final isActive = pageNum == safePage;
                            final hasUser = pageNum == userPage;

                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 2),
                              child: GestureDetector(
                                onTap: () => setState(() => _currentPage = pageNum),
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Container(
                                      constraints: const BoxConstraints(minWidth: 26),
                                      height: 26,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: isActive ? const Color(0xFF2563EB) : const Color(0xFFF1F5F9),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '$pageNum',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          color: isActive ? Colors.white : const Color(0xFF475569),
                                        ),
                                      ),
                                    ),
                                    if (hasUser)
                                      Positioned(
                                        right: -2,
                                        top: -2,
                                        child: Container(
                                          width: 6,
                                          height: 6,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFF10B981),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          }),

                          const SizedBox(width: 6),

                          // Next
                          InkWell(
                            onTap: safePage < totalPages
                                ? () => setState(() => _currentPage = safePage + 1)
                                : null,
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: safePage < totalPages ? Colors.white : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: safePage < totalPages ? const Color(0xFFE2E8F0) : const Color(0xFFF1F5F9),
                                ),
                              ),
                              child: Text(
                                'Sau ›',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: safePage < totalPages ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RosterSlotItem {
  final OrganizerOpsParticipant participant;
  final OrganizerOpsMember? member;
  final String displayName;
  final String? avatarUrl;
  final String userId;
  final String? partnerName;

  const _RosterSlotItem({
    required this.participant,
    required this.member,
    required this.displayName,
    required this.avatarUrl,
    required this.userId,
    required this.partnerName,
  });
}
