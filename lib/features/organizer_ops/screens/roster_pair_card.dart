import 'package:flutter/material.dart';

import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/domain/entities/roster_import.dart';
import 'package:app_quanly_giaidau/features/organizer_ops/screens/roster_import_draft.dart';
import 'package:app_quanly_giaidau/features/organizer_ops/screens/roster_import_widgets.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';

/// Trạng thái hiển thị của một thẻ cặp.
enum RosterCardStatus { ok, warning, blocked, loading }

/// Trạng thái thẻ từ mã cục bộ và kết quả preview của server.
///
/// `blocked`: mã chặn cục bộ, hoặc server báo dòng không đủ điều kiện.
/// `loading`: chưa có kết quả server và preview đang chạy.
/// `warning`: thiếu email, hoặc nội dung đôi mà dòng chưa có VĐV 2.
/// `NOT_FOUND` không phải cảnh báo: VĐV khách vẫn nhập được.
RosterCardStatus rosterCardStatus({
  required RosterDraftRow row,
  required RosterImportBatchPreviewRow? server,
  required bool previewing,
  required bool isDoublesDivision,
}) {
  if (!row.localEligible) return RosterCardStatus.blocked;
  if (server != null && !rosterIsRowEligible(server)) {
    return RosterCardStatus.blocked;
  }
  if (server == null && previewing) return RosterCardStatus.loading;
  final codes = server?.status ?? row.localStatus;
  if (codes.contains('MISSING_EMAIL') ||
      (isDoublesDivision && !row.hasPlayer2)) {
    return RosterCardStatus.warning;
  }
  return RosterCardStatus.ok;
}

/// Thẻ một cặp (hoặc một VĐV đơn): tên, SĐT mờ, icon tài khoản và tròn trạng thái.
class RosterPairCard extends StatelessWidget {
  const RosterPairCard({
    super.key,
    required this.row,
    required this.server,
    required this.previewing,
    required this.isDoublesDivision,
    required this.linked1,
    required this.linked2,
    required this.hasAccountCandidate1,
    required this.hasAccountCandidate2,
    required this.onTap,
  });

  final RosterDraftRow row;
  final RosterImportBatchPreviewRow? server;
  final bool previewing;
  final bool isDoublesDivision;
  final bool linked1;
  final bool linked2;
  final bool hasAccountCandidate1;
  final bool hasAccountCandidate2;
  final VoidCallback? onTap;

  /// Mã đầu tiên đáng hiện thành chữ nhỏ dưới tên; `FOUND`/`NOT_FOUND` không hiện.
  String? _reasonCode(RosterCardStatus status) {
    if (status == RosterCardStatus.ok || status == RosterCardStatus.loading) {
      return null;
    }
    final codes = <String>[
      ...row.localStatus,
      ...?server?.status,
    ].where((code) => code != 'FOUND' && code != 'NOT_FOUND');
    if (codes.isNotEmpty) return codes.first;
    if (status == RosterCardStatus.warning && !row.hasPlayer2) {
      return 'PLAYER2_REQUIRED';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final status = rosterCardStatus(
      row: row,
      server: server,
      previewing: previewing,
      isDoublesDivision: isDoublesDivision,
    );
    final parsed = row.parsed;
    final reason = _reasonCode(status);
    final accent = switch (status) {
      RosterCardStatus.blocked => colors.error,
      RosterCardStatus.warning => colors.warning,
      RosterCardStatus.ok => colors.success,
      RosterCardStatus.loading => colors.textMuted,
    };
    final showPlayer2 = isDoublesDivision || row.hasPlayer2;
    final serverReady = server != null;
    return Container(
      key: ValueKey('roster-row-${row.index}'),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: status == RosterCardStatus.blocked
            ? colors.error.withValues(alpha: 0.08)
            : colors.bgSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: status == RosterCardStatus.blocked
              ? colors.error.withValues(alpha: 0.4)
              : colors.border,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 64),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: _PlayerBlock(
                          name: parsed.player1Name,
                          fallback: parsed.player1Email,
                          phone: parsed.player1Phone,
                          linked: linked1,
                          noAccount:
                              serverReady &&
                              parsed.player1Email != null &&
                              !hasAccountCandidate1,
                        ),
                      ),
                      if (showPlayer2) ...[
                        Container(
                          width: 1,
                          height: 36,
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          color: colors.border,
                        ),
                        Expanded(
                          child: _PlayerBlock(
                            name: parsed.player2Name,
                            fallback: parsed.player2Email,
                            phone: parsed.player2Phone,
                            linked: linked2,
                            noAccount:
                                serverReady &&
                                parsed.player2Email != null &&
                                !hasAccountCandidate2,
                          ),
                        ),
                      ],
                      const SizedBox(width: 8),
                      _StatusDot(status: status, color: accent),
                    ],
                  ),
                  if (reason != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        rosterStatusLabel(l10n, reason),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: accent,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PlayerBlock extends StatelessWidget {
  const _PlayerBlock({
    required this.name,
    required this.fallback,
    required this.phone,
    required this.linked,
    required this.noAccount,
  });

  final String? name;
  final String? fallback;
  final String? phone;
  final bool linked;
  final bool noAccount;

  String _initial(String text) {
    final words = text.trim().split(RegExp(r'\s+'));
    final last = words.isEmpty ? '' : words.last;
    return last.isEmpty ? '' : last.substring(0, 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final title = name ?? fallback ?? '';
    return Row(
      children: [
        CircleAvatar(
          radius: 15,
          backgroundColor: colors.border,
          child: Text(
            _initial(title),
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (phone != null)
                Text(
                  phone!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: colors.textMuted, fontSize: 12),
                ),
            ],
          ),
        ),
        if (linked)
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Icon(
              Icons.link_rounded,
              size: 16,
              color: colors.success,
              semanticLabel: l10n.rosterListLinked,
            ),
          )
        else if (noAccount)
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Icon(
              Icons.person_outline_rounded,
              size: 16,
              color: colors.textMuted,
              semanticLabel: l10n.rosterListNoAccount,
            ),
          ),
      ],
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.status, required this.color});

  final RosterCardStatus status;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (status == RosterCardStatus.loading) {
      return SizedBox(
        key: const ValueKey('roster-card-status-loading'),
        width: 28,
        height: 28,
        child: Padding(
          padding: const EdgeInsets.all(5),
          child: CircularProgressIndicator(strokeWidth: 2, color: color),
        ),
      );
    }
    final icon = switch (status) {
      RosterCardStatus.blocked => Icons.close_rounded,
      RosterCardStatus.warning => Icons.priority_high_rounded,
      _ => Icons.check_rounded,
    };
    return Container(
      key: ValueKey('roster-card-status-${status.name}'),
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 18, color: color),
    );
  }
}
