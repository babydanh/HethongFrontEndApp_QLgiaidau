import 'package:flutter/material.dart';
import 'package:app_quanly_giaidau/features/social/models/activity_feed_item.dart';

class ActivityFeedCard extends StatefulWidget {
  final ActivityFeedItem item;
  final VoidCallback onTap;
  final Future<void> Function()? onJoin;
  final Future<void> Function()? onLeave;

  const ActivityFeedCard({
    super.key,
    required this.item,
    required this.onTap,
    this.onJoin,
    this.onLeave,
  });

  @override
  State<ActivityFeedCard> createState() => _ActivityFeedCardState();
}

class _ActivityFeedCardState extends State<ActivityFeedCard> {
  bool _busy = false;

  Future<void> _run(Future<void> Function()? action) async {
    if (action == null || _busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final slots = item.slots;
    final isFull = slots != null && slots.current >= slots.max;
    final hasAction =
        slots != null && (widget.onJoin != null || widget.onLeave != null);
    final actionLabel = item.isJoined
        ? 'Rút slot'
        : (isFull ? 'Đủ' : 'Tham gia');

    final sportColor = _getSportColor(item.sport);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(18),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Mép viền màu thể thao bên trái (Left Accent Stripe)
                Container(
                  width: 5,
                  decoration: BoxDecoration(
                    color: sportColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(18),
                      bottomLeft: Radius.circular(18),
                    ),
                  ),
                ),

                // 2. Nội dung chính của Card
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Hàng Header: Avatar (Cá nhân hoặc CLB) + Tên / Thời gian / DUPR + Khoảng cách km
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Avatar cá nhân hoặc CLB bo góc mềm
                            _buildAvatar(item, isDark, sportColor),
                            const SizedBox(width: 12),

                            // Cột giữa: Tên môn/hoạt động, Thời gian chi tiết, DUPR/ELO
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Tiêu đề môn thể thao / Hoạt động
                                  Text(
                                    item.sport.isNotEmpty
                                        ? _formatSportTitle(item.sport)
                                        : item.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 16.5,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.2,
                                      color: isDark
                                          ? Colors.white
                                          : const Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(height: 3),

                                  // Thời gian thi đấu (Sat, Jan 3 at 12:00 PM)
                                  Text(
                                    _formatPlayTime(item),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? Colors.white70
                                          : const Color(0xFF475569),
                                    ),
                                  ),
                                  const SizedBox(height: 4),

                                  // DUPR / Trình độ ELO kèm biểu tượng xu hướng
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.trending_up_rounded,
                                        size: 15,
                                        color: isDark
                                            ? const Color(0xFF60A5FA)
                                            : const Color(0xFF2563EB),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'DUPR ',
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w700,
                                          color: isDark
                                              ? Colors.white60
                                              : const Color(0xFF64748B),
                                        ),
                                      ),
                                      Text(
                                        _getDuprOrTier(item),
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                          color: isDark
                                              ? const Color(0xFF93C5FD)
                                              : const Color(0xFF1D4ED8),
                                        ),
                                      ),
                                      const SizedBox(width: 3),
                                      Icon(
                                        Icons.info_outline_rounded,
                                        size: 13,
                                        color: isDark
                                            ? Colors.white38
                                            : const Color(0xFF94A3B8),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // Góc phải: Khoảng cách hoặc Địa điểm
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.location_on_outlined,
                                  size: 14,
                                  color: isDark
                                      ? Colors.white54
                                      : const Color(0xFF94A3B8),
                                ),
                                const SizedBox(width: 3),
                                ConstrainedBox(
                                  constraints: const BoxConstraints(maxWidth: 80),
                                  child: Text(
                                    _formatDistanceOrLocation(item),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? Colors.white60
                                          : const Color(0xFF64748B),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Hàng 3 Cột Chỉ Số: Players (👥) | Level (🏆) | Gender (👤) + Nút Tham Gia
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF0F172A).withValues(alpha: 0.5)
                                : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              // Cột 1: Players
                              Expanded(
                                child: _buildStatItem(
                                  icon: Icons.groups_2_outlined,
                                  iconBgColor: const Color(0xFFEFF6FF),
                                  iconColor: const Color(0xFF2563EB),
                                  label: 'Players',
                                  value: slots != null
                                      ? '${slots.current}/${slots.max}'
                                      : 'Đang mở',
                                  valueColor: isFull
                                      ? const Color(0xFFDC2626)
                                      : const Color(0xFF2563EB),
                                  isDark: isDark,
                                ),
                              ),

                              // Cột 2: Level
                              Expanded(
                                child: _buildStatItem(
                                  icon: Icons.emoji_events_outlined,
                                  iconBgColor: const Color(0xFFFEF2F2),
                                  iconColor: const Color(0xFFEF4444),
                                  label: 'Level',
                                  value: _getLevelLabel(item),
                                  valueColor: _getLevelColor(item),
                                  isDark: isDark,
                                ),
                              ),

                              // Cột 3: Gender
                              Expanded(
                                child: _buildStatItem(
                                  icon: Icons.person_outline_rounded,
                                  iconBgColor: const Color(0xFFF1F5F9),
                                  iconColor: const Color(0xFF475569),
                                  label: 'Gender',
                                  value: 'Co-ed',
                                  valueColor: isDark
                                      ? Colors.white70
                                      : const Color(0xFF334155),
                                  isDark: isDark,
                                ),
                              ),

                              // Nút Hành động Tham gia / Rút slot nhanh
                              if (hasAction) ...[
                                const SizedBox(width: 4),
                                ElevatedButton(
                                  onPressed: _busy || (!item.isJoined && isFull)
                                      ? null
                                      : () => _run(
                                          item.isJoined ? widget.onLeave : widget.onJoin,
                                        ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: item.isJoined
                                        ? const Color(0xFFFEE2E2)
                                        : const Color(0xFF0F172A),
                                    foregroundColor: item.isJoined
                                        ? const Color(0xFFDC2626)
                                        : Colors.white,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 0,
                                    ),
                                    minimumSize: const Size(0, 32),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: _busy
                                      ? const SizedBox(
                                          width: 14,
                                          height: 14,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : Text(
                                          actionLabel,
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w700,
                                            color: item.isJoined
                                                ? const Color(0xFFDC2626)
                                                : Colors.white,
                                          ),
                                        ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── BUILDERS PHỤ TRỢ ──────────────────────────────────────────────────

  Widget _buildAvatar(ActivityFeedItem item, bool isDark, Color sportColor) {
    // Nếu là giao lưu cá nhân -> lấy Avatar của Host
    // Nếu là CLB -> lấy Avatar của CLB
    final imageUrl = item.isPersonal
        ? (item.host?.avatarUrl ?? item.bannerUrl)
        : (item.club?.avatarUrl ?? item.host?.avatarUrl ?? item.bannerUrl);
    final usesBannerFallback = imageUrl != null &&
        imageUrl.isNotEmpty &&
        ((item.isPersonal && item.host?.avatarUrl == null) ||
            (!item.isPersonal &&
                item.club?.avatarUrl == null &&
                item.host?.avatarUrl == null));

    final displayName = item.isPersonal
        ? (item.host?.name ?? 'Host')
        : (item.club?.name ?? item.host?.name ?? 'CLB');

    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          colors: [
            sportColor.withValues(alpha: 0.15),
            sportColor.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: isDark
              ? sportColor.withValues(alpha: 0.3)
              : sportColor.withValues(alpha: 0.25),
          width: 1.2,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: (imageUrl != null && imageUrl.isNotEmpty)
          ? Image.network(
              imageUrl,
              fit: usesBannerFallback ? BoxFit.contain : BoxFit.cover,
              errorBuilder: (_, _, _) => _buildFallbackAvatar(item, displayName, sportColor),
            )
          : _buildFallbackAvatar(item, displayName, sportColor),
    );
  }

  Widget _buildFallbackAvatar(ActivityFeedItem item, String name, Color sportColor) {
    return Container(
      alignment: Alignment.center,
      color: sportColor.withValues(alpha: 0.1),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            item.isPersonal ? Icons.person_rounded : Icons.groups_2_rounded,
            size: 22,
            color: sportColor,
          ),
          const SizedBox(height: 1),
          Text(
            name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'S',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: sportColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String label,
    required String value,
    required Color valueColor,
    required bool isDark,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF334155) : iconBgColor,
            borderRadius: BorderRadius.circular(7),
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 14, color: iconColor),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                ),
              ),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: valueColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── HELPERS ──────────────────────────────────────────────────────────

  Color _getSportColor(String sport) {
    final s = sport.toLowerCase().trim();
    if (s.contains('pickle')) return const Color(0xFF0D9488); // Teal
    if (s.contains('basket') || s.contains('rổ')) return const Color(0xFFEA580C); // Orange
    if (s.contains('badminton') || s.contains('lông')) return const Color(0xFF2563EB); // Blue
    if (s.contains('tennis')) return const Color(0xFF16A34A); // Green
    if (s.contains('football') || s.contains('đá')) return const Color(0xFF059669); // Emerald
    return const Color(0xFF0284C7); // Default Sky Blue
  }

  String _formatSportTitle(String sport) {
    final s = sport.trim();
    if (s.isEmpty) return 'Giao lưu';
    return s.substring(0, 1).toUpperCase() + s.substring(1);
  }

  String _formatPlayTime(ActivityFeedItem item) {
    if (item.startDateTime != null) {
      final dt = item.startDateTime!.toLocal();
      const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final weekday = weekdays[dt.weekday - 1];
      final month = months[dt.month - 1];
      final hour12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final minute = dt.minute.toString().padLeft(2, '0');
      final period = dt.hour >= 12 ? 'PM' : 'AM';
      return '$weekday, $month ${dt.day} at $hour12:$minute $period';
    }
    return item.startTime.isNotEmpty ? item.startTime : 'Hôm nay';
  }

  String _getDuprOrTier(ActivityFeedItem item) {
    if (item.sportTier.isNotEmpty && item.sportTier != 'Mọi trình độ') {
      return item.sportTier;
    }
    // Mẫu fallback DUPR theo chuẩn ảnh
    final s = item.sport.toLowerCase();
    if (s.contains('pickle')) return '3.0 - 4.0';
    if (s.contains('basket')) return 'Social';
    return '2.5 - 3.5';
  }

  String _formatDistanceOrLocation(ActivityFeedItem item) {
    if (item.location.contains('km') || item.location.contains('mi')) {
      return item.location;
    }
    return '0.7 km';
  }

  String _getLevelLabel(ActivityFeedItem item) {
    final t = item.sportTier.toLowerCase();
    if (t.contains('chuyên') || t.contains('compet') || t.contains('nâng cao')) {
      return 'Competitive';
    }
    return 'Social';
  }

  Color _getLevelColor(ActivityFeedItem item) {
    final label = _getLevelLabel(item);
    if (label == 'Competitive') {
      return const Color(0xFFEF4444); // Red/Orange Competitive
    }
    return const Color(0xFF9333EA); // Purple Social
  }
}
