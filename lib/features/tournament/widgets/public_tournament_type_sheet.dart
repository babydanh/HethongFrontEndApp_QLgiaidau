import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Bottom sheet displaying tournament creation options for public/world (outside club).
/// Offers:
/// 1. Quick Tournament (Giải Nhanh - Đơn giản & Công khai)
/// 2. Advanced Tournament (Giải Nâng Cao - Đầy đủ phân hạng, thể thức & lệ phí)
void showPublicTournamentTypeSheet(BuildContext context) {
  final colors = context.colors;
  final l10n = AppLocalizations.of(context)!;

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
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
              l10n.club_selectTournamentType,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Chọn hình thức tạo giải phù hợp với quy mô giải đấu của bạn',
              style: TextStyle(fontSize: 12, color: colors.textMuted),
            ),
            const SizedBox(height: 20),

            // Option 1: Giải Nhanh (Quick / Public)
            InkWell(
              onTap: () {
                Navigator.pop(ctx);
                context.push('/tournaments/create');
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF10B981).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.flash_on_rounded,
                        color: Color(0xFF10B981),
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
                                'Giải Nhanh (Công khai)',
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
                                  color: const Color(0xFF10B981),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'ĐƠN GIẢN',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tạo nhanh giải đấu tự do, công khai cho cộng đồng tham gia thi đấu ngay.',
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

            // Option 2: Giải Nâng Cao (Full / Advanced)
            InkWell(
              onTap: () {
                Navigator.pop(ctx);
                context.push('/tournaments/create-advanced');
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
                          Row(
                            children: [
                              Text(
                                'Giải Nâng Cao (Full)',
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
                                  color: const Color(0xFF2563EB),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'CHUYÊN NGHIỆP',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Cấu hình chi tiết nhiều phân hạng, thể thức vòng bảng, vòng loại, tài trợ và lệ phí.',
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
    ),
  );
}
