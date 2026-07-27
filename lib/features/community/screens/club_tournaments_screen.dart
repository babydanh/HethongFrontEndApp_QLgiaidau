import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/core_di_providers.dart';
import 'package:app_quanly_giaidau/core/utils/status_helpers.dart';
import 'package:intl/intl.dart';

final _clubTournamentsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((
      ref,
      clubId,
    ) async {
      try {
        final dio = ref.read(dioClientProvider).dio;
        final response = await dio.get('/communities/$clubId/tournaments');
        if (response.statusCode == 200) {
          return ((response.data['data'] ?? []) as List)
              .cast<Map<String, dynamic>>();
        }
        return [];
      } catch (_) {
        return [];
      }
    });

class ClubTournamentsScreen extends ConsumerWidget {
  final String clubId;
  const ClubTournamentsScreen({super.key, required this.clubId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_clubTournamentsProvider(clubId));
    return Scaffold(
      backgroundColor: context.colors.bgDark,
      appBar: AppBar(
        title: const Text('Giải đấu'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => _showTypeSheet(context, clubId),
          ),
        ],
      ),
      body: async.when(
        data: (list) {
          if (list.isEmpty) return _buildEmpty(context);
          return RefreshIndicator(
            onRefresh: () async =>
                ref.refresh(_clubTournamentsProvider(clubId)),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              itemBuilder: (ctx, i) => _buildCard(context, list[i]),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Lỗi: $e')),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: context.colors.bgSurface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            Icons.emoji_events_outlined,
            size: 40,
            color: context.colors.textMuted.withValues(alpha: 0.4),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Chưa có giải đấu',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: () => _showTypeSheet(context, clubId),
          icon: const Icon(Icons.add),
          label: const Text('Tạo giải đấu'),
        ),
      ],
    ),
  );

  Widget _buildCard(BuildContext context, Map<String, dynamic> t) {
    final name = t['name'] ?? '';
    final status = t['status'] ?? '';
    final date = t['startDate'] != null
        ? DateTime.tryParse(t['startDate'])
        : null;
    final dateStr = date != null ? DateFormat('dd/MM/yyyy').format(date) : '';
    final isLive = StatusHelper.isTournamentInProgress(status);
    final isLite =
        t['isLite'] == true ||
        t['isQuick'] == true ||
        t['type'] == 'LITE' ||
        t['isClubLite'] == true ||
        (t['inviteCode'] != null && t['inviteCode'].toString().isNotEmpty);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.colors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isLive
              ? context.colors.error.withValues(alpha: 0.3)
              : context.colors.border,
        ),
      ),
      child: InkWell(
        onTap: () => context.push(
          isLite ? '/lite-manage/${t['id']}' : '/intro/${t['id']}',
        ),
        borderRadius: BorderRadius.circular(10),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color:
                    (isLite
                            ? const Color(0xFFF59E0B)
                            : (isLive
                                  ? context.colors.error
                                  : context.colors.info))
                        .withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isLite ? Icons.bolt_rounded : Icons.emoji_events_rounded,
                color: isLite
                    ? const Color(0xFFF59E0B)
                    : (isLive ? context.colors.error : context.colors.info),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: context.colors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isLite
                              ? const Color(0xFFF59E0B).withValues(alpha: 0.15)
                              : const Color(0xFF3B82F6).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isLite
                                ? const Color(0xFFF59E0B).withValues(alpha: 0.3)
                                : const Color(
                                    0xFF3B82F6,
                                  ).withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isLite
                                  ? Icons.bolt_rounded
                                  : Icons.workspace_premium_rounded,
                              size: 10,
                              color: isLite
                                  ? const Color(0xFFF59E0B)
                                  : const Color(0xFF3B82F6),
                            ),
                            const SizedBox(width: 2),
                            Text(
                              isLite ? 'Giải Nhanh' : 'Nâng Cao',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                color: isLite
                                    ? const Color(0xFFF59E0B)
                                    : const Color(0xFF3B82F6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (dateStr.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        dateStr,
                        style: TextStyle(
                          fontSize: 11,
                          color: context.colors.textMuted,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded, color: context.colors.textMuted),
          ],
        ),
      ),
    );
  }

  void _showTypeSheet(BuildContext context, String clubId) {
    final colors = context.colors;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        decoration: BoxDecoration(
          color: colors.bgCard,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Chọn loại giải đấu',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Chọn hình thức tạo giải phù hợp cho câu lạc bộ của bạn',
              style: TextStyle(fontSize: 12, color: colors.textMuted),
            ),
            const SizedBox(height: 20),

            // Option 1: Giải Nhanh (Lite)
            InkWell(
              onTap: () {
                Navigator.pop(ctx);
                context.push('/club/$clubId/create-tournament');
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.bolt_rounded,
                        color: Color(0xFFF59E0B),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Giải Nhanh (Lite)',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
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
                                  color: const Color(0xFFF59E0B),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  '30s',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tạo nhanh trong 30 giây. Sinh mã QR & Link mời chia sẻ trực tiếp cho các thành viên.',
                            style: TextStyle(
                              fontSize: 12,
                              color: colors.textSecondary,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: colors.textMuted),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Option 2: Giải Nâng Cao (Full)
            InkWell(
              onTap: () {
                Navigator.pop(ctx);
                context.push('/tournaments/create');
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.workspace_premium_rounded,
                        color: Color(0xFF3B82F6),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Giải Nâng Cao (Chuyên nghiệp)',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: colors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Đầy đủ cấu hình: Thể thức Vòng bảng, Knockout, Lịch thi đấu, Phí tham gia & Giải thưởng.',
                            style: TextStyle(
                              fontSize: 12,
                              color: colors.textSecondary,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: colors.textMuted),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
