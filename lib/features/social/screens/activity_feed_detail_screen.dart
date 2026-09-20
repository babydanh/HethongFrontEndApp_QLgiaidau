import 'package:flutter/material.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/features/social/models/activity_feed_item.dart';

class ActivityFeedDetailScreen extends StatelessWidget {
  final ActivityFeedItem item;
  final Future<void> Function()? onJoin;
  final Future<void> Function()? onLeave;

  const ActivityFeedDetailScreen({
    super.key,
    required this.item,
    this.onJoin,
    this.onLeave,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final slots = item.slots;
    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết hoạt động')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          if (item.bannerUrl != null || item.imageUrls.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.network(
                item.bannerUrl ?? item.imageUrls.first,
                height: 190,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _placeholder(isDark),
              ),
            )
          else
            _placeholder(isDark),
          const SizedBox(height: 18),
          Text(
            item.typeLabel,
            style: const TextStyle(
              color: AppTheme.primary,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: .4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            item.title,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            item.description.isEmpty ? 'Chưa có mô tả.' : item.description,
            style: TextStyle(
              height: 1.45,
              color: isDark ? Colors.white70 : const Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 18),
          _info(
            Icons.sports_outlined,
            '${item.sport} · ${item.sportTier}',
            isDark,
          ),
          _info(
            Icons.schedule_rounded,
            '${item.playDate} · ${item.startTime}${item.endTime.isEmpty ? '' : ' - ${item.endTime}'}',
            isDark,
          ),
          _info(Icons.location_on_outlined, item.location, isDark),
          _info(
            Icons.person_outline_rounded,
            'Người tổ chức: ${item.hostName}',
            isDark,
          ),
          if (slots != null) ...[
            const SizedBox(height: 10),
            Card(
              elevation: 0,
              color: isDark ? Colors.white10 : const Color(0xFFF8FAFC),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    const Icon(
                      Icons.people_alt_outlined,
                      color: AppTheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${slots.current}/${slots.max} người · ${item.feeLabel}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    if (item.isJoined && onLeave != null)
                      OutlinedButton(
                        onPressed: onLeave,
                        child: const Text('Rút slot'),
                      )
                    else if (!item.isJoined && onJoin != null)
                      FilledButton(
                        onPressed: slots.current >= slots.max ? null : onJoin,
                        child: const Text('Tham gia'),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _placeholder(bool isDark) => Container(
    height: 150,
    decoration: BoxDecoration(
      color: isDark ? Colors.white10 : const Color(0xFFEFF6FF),
      borderRadius: BorderRadius.circular(18),
    ),
    child: const Center(
      child: Icon(Icons.sports_rounded, size: 52, color: AppTheme.primary),
    ),
  );

  Widget _info(IconData icon, String text, bool isDark) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 19,
          color: isDark ? Colors.white60 : const Color(0xFF64748B),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: isDark ? Colors.white70 : const Color(0xFF334155),
            ),
          ),
        ),
      ],
    ),
  );
}
