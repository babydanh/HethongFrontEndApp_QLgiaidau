import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/domain/entities/lite_tournament_create_result.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';

/// Modal bottom sheet hiển thị sau khi tạo giải thành công (cho cả Quick & Club)
class TournamentSuccessModal extends StatelessWidget {
  final LiteTournamentCreateResult result;
  final VoidCallback? onManage;
  final VoidCallback? onViewDetail;

  const TournamentSuccessModal({
    super.key,
    required this.result,
    this.onManage,
    this.onViewDetail,
  });

  static void show(
    BuildContext context, {
    required LiteTournamentCreateResult result,
    VoidCallback? onManage,
    VoidCallback? onViewDetail,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TournamentSuccessModal(
        result: result,
        onManage: onManage,
        onViewDetail: onViewDetail,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final link = result.joinUrl?.isNotEmpty == true
        ? result.joinUrl!
        : LiteTournamentCreateResult.resolveUrl(
            '/tournaments/${result.id}${result.inviteCode != null ? '?invite=${result.inviteCode}' : ''}',
          );

    return Container(
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ─── Drag handle ───
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: colors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // ─── Success icon ───
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: colors.success.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle_rounded,
                  color: colors.success,
                  size: 34,
                ),
              ),
              const SizedBox(height: 14),

              // ─── Title ───
              Text(
                l10n.createClubTournament_successTitle,
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                result.name,
                style: TextStyle(fontSize: 13.5, color: colors.textSecondary),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 18),

              // ─── QR Code ───
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: QrImageView(
                  data: result.qrPayload ?? link,
                  version: QrVersions.auto,
                  size: 150,
                  backgroundColor: Colors.white,
                  padding: EdgeInsets.zero,
                ),
              ),
              const SizedBox(height: 16),

              // ─── Link Container ───
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: colors.bgSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.border),
                ),
                child: Text(
                  link,
                  style: TextStyle(fontSize: 12, color: colors.textMuted),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 16),

              // ─── Share & Copy Buttons ───
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: link));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(l10n.createClubTournament_linkCopied),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy_rounded, size: 18),
                      label: Text(
                        l10n.createClubTournament_copyLink,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        SharePlus.instance.share(
                          ShareParams(
                            text: l10n.createClubTournament_shareText(
                              result.name,
                              link,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.share_rounded, size: 18),
                      label: Text(
                        l10n.createClubTournament_share,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ─── Primary Action: Manage or View ───
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton.icon(
                  onPressed: () {
                    context.pop();
                    if (onManage != null) {
                      onManage!();
                    } else {
                      context.push('/lite-manage/${result.id}');
                    }
                  },
                  icon: const Icon(Icons.speed_rounded, size: 20),
                  label: Text(
                    l10n.createClubTournament_manageQuickly,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                  ),
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // ─── Secondary Action: Go to Tournament Detail ───
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    context.pop();
                    if (onViewDetail != null) {
                      onViewDetail!();
                    } else {
                      context.push('/tournaments/${result.id}');
                    }
                  },
                  child: Text(
                    'Xem thông tin giải đấu',
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
