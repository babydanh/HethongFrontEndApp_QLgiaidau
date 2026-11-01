import 'package:flutter/material.dart';

import 'package:app_quanly_giaidau/core/config/app_constants.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/utils/status_helpers.dart';
import 'package:app_quanly_giaidau/core/widgets/sporto_brand_fallback.dart';
import 'package:app_quanly_giaidau/core/widgets/tournament_avatar.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';

/// Logo diameter; its lower half hangs below the banner image.
const double _logoSize = 58;
const double _logoOverlap = _logoSize / 2;

/// Ảnh bìa có nút sửa nhận diện, dùng làm `flexibleSpace` của hub quản lý.
/// Logo giải tròn đè lên mép dưới ảnh bìa (nửa dưới nằm ngoài ảnh).
class TournamentManagementBanner extends StatelessWidget {
  final Tournament tournament;
  final String Function(String? url) resolveImageUrl;
  final VoidCallback? onEdit;

  const TournamentManagementBanner({
    super.key,
    required this.tournament,
    required this.resolveImageUrl,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final fallback = ColoredBox(
      color: colors.bgSurface,
      child: const Center(
        child: SportoBrandFallback(
          withTagline: true,
          padding: EdgeInsets.symmetric(horizontal: 40, vertical: 24),
          semanticsLabel: 'SportO tournament fallback banner',
        ),
      ),
    );
    final imageUrl =
        _nonEmpty(tournament.bannerUrl) ?? _nonEmpty(tournament.logoUrl);

    final banner = Stack(
      fit: StackFit.expand,
      children: [
        imageUrl == null
            ? fallback
            : Image.network(
                resolveImageUrl(imageUrl),
                fit: BoxFit.cover,
                errorBuilder: (_, error, stackTrace) => fallback,
              ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.4),
                Colors.transparent,
                Colors.black.withValues(alpha: 0.35),
              ],
            ),
          ),
        ),
        if (onEdit != null)
          Positioned(
            right: 12,
            bottom: 12,
            child: Material(
              shape: const CircleBorder(),
              color: colors.bgCard.withValues(alpha: 0.92),
              child: IconButton(
                key: const ValueKey('tournament-overview-banner-edit'),
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                tooltip:
                    '${l10n.infoEdit} ${l10n.tournamentManagementBranding}',
                icon: const Icon(
                  Icons.edit_outlined,
                  color: AppTheme.primary,
                  size: 20,
                ),
                onPressed: onEdit,
              ),
            ),
          ),
      ],
    );
    final logoUrl = _nonEmpty(tournament.logoUrl);
    return Stack(
      fit: StackFit.expand,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: _logoOverlap),
          child: banner,
        ),
        Positioned(
          left: 16,
          bottom: 0,
          child: GestureDetector(
            key: const ValueKey('tournament-overview-logo'),
            onTap: onEdit,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TournamentAvatar(
                imageUrl: logoUrl == null ? null : resolveImageUrl(logoUrl),
                tournamentName: tournament.name,
                sport: tournament.sport,
                size: _logoSize,
                borderWidth: 2,
                borderColor: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  static String? _nonEmpty(String? value) {
    if (value == null || value.isEmpty) return null;
    return value;
  }
}

/// Tên giải và chip trạng thái/môn, hiển thị dưới banner (logo đè mép banner).
class TournamentManagementSummary extends StatelessWidget {
  final Tournament tournament;
  final VoidCallback? onEditInformation;

  const TournamentManagementSummary({
    super.key,
    required this.tournament,
    this.onEditInformation,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final t = tournament;
    final categoryName = t.category?.trim();
    final sportName = (categoryName != null && categoryName.isNotEmpty)
        ? categoryName
        : (AppConstants.sportNames[t.sport.trim().toLowerCase()] ?? t.sport);

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 960),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MergeSemantics(
                child: InkWell(
                  key: const ValueKey('tournament-overview-name-edit'),
                  onTap: onEditInformation,
                  borderRadius: BorderRadius.circular(8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          t.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        Icons.edit_outlined,
                        size: 16,
                        color: AppTheme.primary,
                        semanticLabel:
                            '${l10n.infoEdit} ${l10n.tournamentManagementGeneral}',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _Chip(
                    label: StatusHelper.getTournamentStatusLabel(
                      t.status,
                      l10n: l10n,
                    ),
                    color: StatusHelper.getTournamentStatusColor(
                      t.status,
                      context,
                    ),
                  ),
                  _Chip(label: sportName, color: AppTheme.primary),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;

  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
