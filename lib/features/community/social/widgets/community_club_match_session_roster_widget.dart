import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/utils/error_parser.dart';
import 'package:app_quanly_giaidau/data/models/club_match_session_model.dart';
import 'package:app_quanly_giaidau/features/community/screens/club_match_sessions_screen.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/club_match_session_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
const int _kRosterSlotsPerPage = 16;

class CommunityClubMatchSessionRosterWidget extends ConsumerStatefulWidget {
  final String sessionId;
  final String communityId;

  const CommunityClubMatchSessionRosterWidget({
    super.key,
    required this.sessionId,
    required this.communityId,
  });

  @override
  ConsumerState<CommunityClubMatchSessionRosterWidget> createState() =>
      _CommunityClubMatchSessionRosterWidgetState();
}

class _CommunityClubMatchSessionRosterWidgetState
    extends ConsumerState<CommunityClubMatchSessionRosterWidget> {
  ClubMatchSessionModel? _session;
  List<ClubMatchParticipantModel> _participants = [];
  bool _loading = true;
  bool _busy = false;
  int _rosterPage = 1;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final repo = ref.read(clubMatchSessionRepositoryProvider);
      final values = await Future.wait([
        repo.get(widget.sessionId),
        repo.participants(widget.sessionId),
      ]);
      if (mounted) {
        setState(() {
          _session = values[0] as ClubMatchSessionModel;
          _participants = values[1] as List<ClubMatchParticipantModel>;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
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

  Future<void> _confirmWithdrawDialog(
    ClubMatchParticipantModel participant,
  ) async {
    final session = _session;
    if (session == null || _busy) return;
    final l10n = AppLocalizations.of(context)!;
    final sessionName = session.resolvedName;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Color(0xFFEF4444),
              size: 24,
            ),
            SizedBox(width: 8),
            Text(
              'Hủy tham gia giao lưu',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          'Bạn có chắc chắn muốn hủy tham gia "$sessionName" không?',
          style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'Hủy bỏ',
              style: TextStyle(color: Color(0xFF64748B)),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Xác nhận hủy'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);
    try {
      final repo = ref.read(clubMatchSessionRepositoryProvider);
      await repo.withdraw(session.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.clubMatchSessionWithdrawn),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
      await _load();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ErrorParser.parse(error, '', l10n)),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _handleJoin() async {
    final session = _session;
    if (session == null || _busy) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() => _busy = true);
    try {
      final repo = ref.read(clubMatchSessionRepositoryProvider);
      await repo.selfJoin(session.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.clubMatchSessionJoined),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
      await _load();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ErrorParser.parse(error, '', l10n)),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    final session = _session;
    if (session == null) return const SizedBox.shrink();
    final active = _participants
        .where((item) => item.status == 'ACTIVE')
        .toList();
    final totalSlots = session.maxParticipants < active.length
        ? active.length
        : session.maxParticipants;
    final totalPages = totalSlots <= 0
        ? 1
        : (totalSlots + _kRosterSlotsPerPage - 1) ~/ _kRosterSlotsPerPage;
    final currentPage = _rosterPage > totalPages ? totalPages : _rosterPage;
    final startIndex = (currentPage - 1) * _kRosterSlotsPerPage;
    final visibleSlotCount = totalSlots - startIndex < _kRosterSlotsPerPage
        ? totalSlots - startIndex
        : _kRosterSlotsPerPage;
    final currentUserId = session.viewerUserId ?? '';

    final formatBadge = switch (session.registrationMode.toUpperCase()) {
      'PAIR' => 'Đánh đôi',
      'SINGLE' => 'Đánh đơn',
      _ => 'Ghép tự do',
    };

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top Bar: MANG ĐẾN BỞI + Session Name + Link to Details ──
          GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => ClubMatchSessionDetailPage(session: session),
              ),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
                border: Border(
                  bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFE2E8F0),
                        width: 1,
                      ),
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
                          session.resolvedName,
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Xem buổi giao lưu',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 3),
                        Icon(
                          Icons.arrow_outward_rounded,
                          size: 13,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      '${l10n.clubMatchSessionParticipants} · ${active.length}',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: const Color(0xFFDBEAFE),
                          width: 0.8,
                        ),
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
                GestureDetector(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          ClubMatchSessionDetailPage(session: session),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${active.length}/$totalSlots',
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 16,
                        color: colors.textMuted,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 16,
              crossAxisSpacing: 8,
              childAspectRatio: 0.76,
            ),
            itemCount: visibleSlotCount,
            itemBuilder: (context, index) {
              final globalSlotIndex = startIndex + index;
              final item = globalSlotIndex < active.length
                  ? active[globalSlotIndex]
                  : null;
              final isSelf =
                  item != null &&
                  currentUserId.isNotEmpty &&
                  item.userId == currentUserId;
              final displayName = item?.displayName.trim().isNotEmpty == true
                  ? item!.displayName.trim()
                  : (item?.isMock == true
                        ? '${l10n.clubMatchSessionMockPlayer} ${globalSlotIndex + 1}'
                        : 'VĐV');

              if (item != null) {
                return GestureDetector(
                  onTap: isSelf && session.canWithdraw
                      ? () => _confirmWithdrawDialog(item)
                      : () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                ClubMatchSessionDetailPage(session: session),
                          ),
                        ),
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
                                color: isSelf
                                    ? const Color(0xFF3B82F6)
                                    : Colors.white,
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
                              child:
                                  item.avatarUrl != null &&
                                      item.avatarUrl!.isNotEmpty
                                  ? Image.network(
                                      item.avatarUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              Center(
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
                                child: const Icon(
                                  Icons.close_rounded,
                                  size: 12,
                                  color: Colors.white,
                                ),
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
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelf
                              ? FontWeight.w800
                              : FontWeight.w600,
                          color: isSelf
                              ? const Color(0xFF2563EB)
                              : colors.textPrimary,
                        ),
                      ),
                      if (isSelf)
                        const Text(
                          '(Bạn)',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2563EB),
                          ),
                        )
                      else if (item.isMock)
                        Text(
                          l10n.clubMatchSessionMockPlayer,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: colors.warning, fontSize: 9),
                        ),
                    ],
                  ),
                );
              }

              // Empty Slot
              final canTapEmptySlot =
                  session.canJoin && session.status == 'OPEN';
              return GestureDetector(
                onTap: canTapEmptySlot && !_busy ? _handleJoin : null,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFCBD5E1),
                          width: 1.5,
                          strokeAlign: BorderSide.strokeAlignCenter,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.add_rounded,
                          size: 22,
                          color: canTapEmptySlot
                              ? const Color(0xFF3B82F6)
                              : const Color(0xFF94A3B8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Slot #${globalSlotIndex + 1}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          if (totalPages > 1)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    tooltip: 'Trang trước',
                    onPressed: currentPage > 1
                        ? () => setState(() => _rosterPage = currentPage - 1)
                        : null,
                    icon: const Icon(Icons.chevron_left_rounded),
                  ),
                  Text(
                    'Trang $currentPage/$totalPages',
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Trang sau',
                    onPressed: currentPage < totalPages
                        ? () => setState(() => _rosterPage = currentPage + 1)
                        : null,
                    icon: const Icon(Icons.chevron_right_rounded),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
