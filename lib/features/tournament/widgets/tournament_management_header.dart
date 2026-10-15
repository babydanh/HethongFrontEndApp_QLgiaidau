import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:app_quanly_giaidau/core/config/app_constants.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/utils/status_helpers.dart';
import 'package:app_quanly_giaidau/core/widgets/sporto_brand_fallback.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';

/// Ảnh bìa có nút sửa nhận diện, dùng làm `flexibleSpace` của hub quản lý.
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

    return Stack(
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
  }

  static String? _nonEmpty(String? value) {
    if (value == null || value.isEmpty) return null;
    return value;
  }
}

/// Tên giải, chip trạng thái/môn và dải 4 chỉ số, hiển thị dưới banner.
class TournamentManagementSummary extends StatelessWidget {
  final Tournament tournament;
  final int teamCount;
  final VoidCallback? onEditGeneral;
  final VoidCallback? onEditSchedule;
  final VoidCallback? onEditRegistration;
  final VoidCallback? onEditFinance;
  final VoidCallback? onOpenAthletes;

  const TournamentManagementSummary({
    super.key,
    required this.tournament,
    required this.teamCount,
    this.onEditGeneral,
    this.onEditSchedule,
    this.onEditRegistration,
    this.onEditFinance,
    this.onOpenAthletes,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final t = tournament;
    final currency = NumberFormat('#,###', 'vi_VN');
    final fee = t.entryFee ?? 0;
    final deadline = t.registrationEndDate;
    final categoryName = t.category?.trim();
    final sportName = (categoryName != null && categoryName.isNotEmpty)
        ? categoryName
        : (AppConstants.sportNames[t.sport.trim().toLowerCase()] ?? t.sport);

    final kpis = <Widget>[
      _SummaryKpi(
        itemKey: const ValueKey('tournament-overview-dates-edit'),
        label: l10n.tournamentManagementKpiDates,
        value: _dateRange(t.startDate, t.endDate),
        onTap: onEditSchedule,
      ),
      _SummaryKpi(
        itemKey: const ValueKey('tournament-overview-athletes-edit'),
        label: l10n.tournamentManagementKpiAthletes,
        value: t.maxTeams > 0 ? '$teamCount/${t.maxTeams}' : '$teamCount',
        onTap: onOpenAthletes,
      ),
      _SummaryKpi(
        itemKey: const ValueKey('tournament-overview-entry-fee-edit'),
        label: l10n.tournamentManagementKpiFee,
        value: fee <= 0
            ? l10n.tournamentManagementKpiFree
            : '${currency.format(fee)} đ',
        onTap: onEditFinance,
      ),
      _SummaryKpi(
        itemKey: const ValueKey('tournament-management-kpi-deadline'),
        label: l10n.tournamentManagementKpiRegistrationDeadline,
        value: deadline == null ? '—' : DateFormat('dd/MM').format(deadline),
        onTap: onEditRegistration,
      ),
    ];

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 960),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MergeSemantics(
                      child: InkWell(
                        key: const ValueKey('tournament-overview-name-edit'),
                        onTap: onEditGeneral,
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
              const SizedBox(height: 10),
              DecoratedBox(
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: colors.border),
                    bottom: BorderSide(color: colors.border),
                  ),
                ),
                child: IntrinsicHeight(
                  child: Row(children: _withDividers(kpis, colors.border)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _withDividers(List<Widget> tiles, Color dividerColor) {
    return [
      for (var i = 0; i < tiles.length; i++) ...[
        if (i > 0) VerticalDivider(width: 1, thickness: 1, color: dividerColor),
        Expanded(child: tiles[i]),
      ],
    ];
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

class _SummaryKpi extends StatelessWidget {
  final Key itemKey;
  final String label;
  final String value;
  final VoidCallback? onTap;

  const _SummaryKpi({
    required this.itemKey,
    required this.label,
    required this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return MergeSemantics(
      child: InkWell(
        key: itemKey,
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: colors.textPrimary,
                    ),
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: colors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _dateRange(DateTime? start, DateTime? end) {
  if (start == null) return '—';
  final shortDate = DateFormat('dd/MM');
  if (end == null || _isSameDay(start, end)) return shortDate.format(start);
  if (start.year == end.year && start.month == end.month) {
    return '${start.day.toString().padLeft(2, '0')}–${shortDate.format(end)}';
  }
  return '${shortDate.format(start)}–${shortDate.format(end)}';
}

bool _isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}
