import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/widgets/match_card/live_match_card_v2.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/data/models/tournament_model.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/division_accordion.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/core/utils/navigation_helpers.dart';

class LiveTab extends StatefulWidget {
  final List<MatchModel> liveMatches;
  final String? tournamentId;
  final List<TournamentDivision> divisions;
  final String? selectedDivisionId;
  final ValueChanged<TournamentDivision>? onSelectDivision;

  const LiveTab({
    super.key,
    required this.liveMatches,
    this.tournamentId,
    this.divisions = const [],
    this.selectedDivisionId,
    this.onSelectDivision,
  });

  @override
  State<LiveTab> createState() => _LiveTabState();
}

class _LiveTabState extends State<LiveTab> {
  String? _selectedDivisionId;
  bool _expanded = true;

  @override
  void initState() {
    super.initState();
    _selectedDivisionId =
        widget.selectedDivisionId ??
        (widget.divisions.isNotEmpty ? widget.divisions.first.id : null);
  }

  @override
  void didUpdateWidget(covariant LiveTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedDivisionId != oldWidget.selectedDivisionId &&
        widget.selectedDivisionId != null) {
      setState(() {
        _selectedDivisionId = widget.selectedDivisionId;
        _expanded = true;
      });
    }
  }

  List<MatchModel> _liveMatchesOf(TournamentDivision division) =>
      widget.liveMatches.where((m) {
        final mDiv =
            m.divisionId ??
            m.scoreDetails?['division_id']?.toString() ??
            m.tournamentConfig?['division_id']?.toString();
        return mDiv != null && mDiv.isNotEmpty && mDiv == division.id;
      }).toList();

  void _openMatch(MatchModel match) {
    context.push(
      NavigationHelper.getLiveMatchRoute(
        widget.tournamentId ?? match.tournamentId ?? '',
        match.id,
      ),
    );
  }

  /// Nhãn số trận đang diễn ra cạnh tên hạng mục.
  Widget? _liveBadge(TournamentDivision division) {
    final count = _liveMatchesOf(division).length;
    if (count == 0) return null;
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: colors.error.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: colors.error,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: colors.error,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _divisionContent(TournamentDivision division) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context)!;
    final matches = _liveMatchesOf(division);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final match in matches)
            LiveMatchCardV2(
              match: match,
              isLive: true,
              onTap: () => _openMatch(match),
            ),
          if (matches.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 16,
                    color: colors.textMuted,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    l10n.liveDivisionEmpty,
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context)!;

    if (widget.liveMatches.isEmpty && widget.divisions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: colors.bgSurface,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.radio_outlined,
                size: 26,
                color: colors.textMuted.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              l10n.liveNoMatchesRunning,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.liveNoMatchesSubtitle,
              style: TextStyle(fontSize: 12, color: colors.textMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Nhiều hạng mục: cùng danh sách hạng mục như tab Đội/Bảng đấu, trận live
    // của hạng mục mở ngay dưới hàng của nó.
    if (widget.divisions.length > 1) {
      return ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(0, 2, 0, 140),
        children: [
          DivisionAccordion(
            divisions: widget.divisions,
            selectedDivisionId: _selectedDivisionId,
            expanded: _expanded,
            badgeBuilder: _liveBadge,
            contentBuilder: _divisionContent,
            onTapDivision: (div) {
              setState(() {
                if (_selectedDivisionId == div.id) {
                  _expanded = !_expanded;
                } else {
                  _selectedDivisionId = div.id;
                  _expanded = true;
                }
              });
              widget.onSelectDivision?.call(div);
            },
          ),
        ],
      );
    }

    // Khi chỉ có 1 division hoặc không có divisions
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 140),
      itemCount: widget.liveMatches.length,
      itemBuilder: (context, index) {
        final match = widget.liveMatches[index];
        return LiveMatchCardV2(
          match: match,
          isLive: true,
          onTap: () {
            context.push(
              NavigationHelper.getLiveMatchRoute(
                widget.tournamentId ?? match.tournamentId ?? '',
                match.id,
              ),
            );
          },
        );
      },
    );
  }
}
