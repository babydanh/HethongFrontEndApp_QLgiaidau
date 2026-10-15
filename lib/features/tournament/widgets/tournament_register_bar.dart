import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';

/// Thanh đăng ký cố định sát đáy trang chi tiết giải (giống web): card tóm tắt
/// lệ phí + hạn đăng ký, kèm nút đăng ký có nền màu.
///
/// Chỉ trình bày. Điều kiện hiện/ẩn (đăng ký đang mở, chưa khóa, chưa hết hạn)
/// và route đăng ký do màn gọi quyết định.
class TournamentRegisterBar extends StatelessWidget {
  const TournamentRegisterBar({
    super.key,
    required this.entryFee,
    required this.registrationEnd,
    required this.onRegister,
  });

  final double? entryFee;
  final DateTime? registrationEnd;
  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context)!;
    final fee = entryFee;
    final feeText = fee == null || fee <= 0
        ? l10n.freePrice
        : '${NumberFormat('#,###', 'vi_VN').format(fee)} đ';
    final end = registrationEnd;

    return Material(
      color: colors.bgCard,
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.18),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: colors.border)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 16,
                  runSpacing: 4,
                  children: [
                    _Fact(label: l10n.tournamentManagementKpiFee, value: feeText),
                    if (end != null)
                      _Fact(
                        label: l10n.tournamentManagementKpiRegistrationDeadline,
                        value: DateFormat('dd/MM/yyyy').format(end),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              FilledButton(
                onPressed: onRegister,
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 44),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  l10n.register,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: colors.textMuted,
          ),
        ),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: colors.textPrimary,
          ),
        ),
      ],
    );
  }
}
