import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:app_quanly_giaidau/domain/entities/elo_history_log.dart';
import 'package:app_quanly_giaidau/providers/ranking_provider.dart';
import 'package:app_quanly_giaidau/features/rankings/widgets/elo_progress_chart.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/lavish_kit.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/lavish_kit_extras.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';

class EloHistoryScreen extends ConsumerStatefulWidget {
  final String userId;
  final String userName;
  final String? avatarUrl;
  final int currentElo;
  final String? tierName;
  final String? categoryId;
  final String? categoryName;
  final String? communityId;
  final String? initialScope;
  final String? matchType;
  final String? genderRestriction;
  final String? partnerId;
  final bool lockRatingScope;

  const EloHistoryScreen({
    super.key,
    required this.userId,
    required this.userName,
    this.avatarUrl,
    required this.currentElo,
    this.tierName,
    this.categoryId,
    this.categoryName,
    this.communityId,
    this.initialScope,
    this.matchType,
    this.genderRestriction,
    this.partnerId,
    this.lockRatingScope = false,
  });

  @override
  ConsumerState<EloHistoryScreen> createState() => _EloHistoryScreenState();
}

class _EloHistoryScreenState extends ConsumerState<EloHistoryScreen> {
  String? _selectedScope;
  int _limit = _pageSize;
  static const _pageSize = 50;

  @override
  void initState() {
    super.initState();
    _selectedScope =
        widget.initialScope == 'COMMUNITY' && widget.communityId == null
        ? null
        : widget.initialScope;
  }

  EloHistoryQuery get _query => (
    userId: widget.userId,
    categoryId: widget.categoryId,
    scope: _selectedScope,
    communityId: widget.communityId,
    matchType: widget.matchType,
    genderRestriction: widget.genderRestriction,
    partnerId: widget.partnerId,
    limit: _limit,
    cursor: null,
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final query = _query;
    final historyAsync = ref.watch(eloHistoryProvider(query));
    // Giữ danh sách cũ khi đang tải thêm (limit đổi) thay vì nháy skeleton.
    final history = historyAsync.asData?.value;

    final title = widget.categoryName != null && widget.categoryName!.isNotEmpty
        ? '${l10n.settingsEloHistory} · ${widget.categoryName}'
        : l10n.settingsEloHistory;

    Widget content;
    if (history == null && historyAsync.hasError) {
      content = LavishErrorState(
        onRetry: () => ref.invalidate(eloHistoryProvider(query)),
      );
    } else if (history == null) {
      content = const LavishRowSkeleton();
    } else if (history.isEmpty) {
      content = LavishEmptyState(
        icon: Icons.show_chart_rounded,
        title: l10n.publicProfileNoPlayedElo,
      );
    } else {
      content = _buildData(history);
    }

    return LavishScaffold(
      title: title,
      onBack: () {
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        } else {
          context.go('/home');
        }
      },
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 40),
        children: [_buildHeader(), _buildScopeFilter(), content],
      ),
    );
  }

  Widget _buildData(List<EloHistoryLog> history) {
    final l10n = AppLocalizations.of(context)!;
    final c = LavishColors.of(context);
    final sorted = List<EloHistoryLog>.from(history)
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final peakElo = sorted.fold<int>(
      widget.currentElo,
      (peak, h) => h.newElo > peak ? h.newElo : peak,
    );
    final results = history
        .map((h) => h.match?.result?.toUpperCase())
        .where((r) => r == 'WIN' || r == 'LOSS' || r == 'DRAW')
        .toList();
    final wins = results.where((r) => r == 'WIN').length;
    final fmt = NumberFormat.decimalPattern(
      Localizations.localeOf(context).toLanguageTag(),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LavishStatGrid(
          items: [
            LavishStat(
              label: l10n.publicProfilePeakElo,
              value: fmt.format(peakElo),
              tone: LavishTone.warn,
            ),
            LavishStat(
              label: l10n.publicProfileMatchesShort,
              value: '${history.length}',
            ),
            if (results.isNotEmpty)
              LavishStat(
                label: l10n.publicProfileWinRateShort,
                value: '${(wins * 100 / results.length).round()}%',
                tone: LavishTone.ok,
              ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
          child: EloProgressChart(
            data: sorted.map((h) {
              final date = DateTime.tryParse(h.createdAt) ?? DateTime.now();
              return (DateFormat('dd/MM').format(date), h.newElo);
            }).toList(),
            currentElo: widget.currentElo,
            tierName: widget.tierName,
            height: 200,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 6),
          child: Text(
            l10n.publicProfileActivity,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: c.muted,
            ),
          ),
        ),
        for (final log in history) _buildLogRow(log),
        if (history.length >= _limit)
          Padding(
            padding: const EdgeInsets.all(14),
            child: Center(
              child: LavishButton(
                buttonKey: const Key('elo_history_load_more'),
                kind: LavishButtonKind.outline,
                label: l10n.eloHistLoadMore,
                onPressed: () => setState(() => _limit += _pageSize),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildHeader() {
    final c = LavishColors.of(context);
    final name = widget.userName.trim();
    final initial = name.isEmpty ? '?' : name.characters.first.toUpperCase();
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.rowLine)),
      ),
      child: Row(
        children: [
          LavishIconBox(
            size: 48,
            child: Text(
              initial,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.userName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: c.text,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (widget.tierName != null) ...[
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: LavishPill(widget.tierName!),
                  ),
                ],
              ],
            ),
          ),
          Text(
            '${widget.currentElo}',
            style: const TextStyle(
              color: LavishColors.accent,
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScopeFilter() {
    if (widget.lockRatingScope) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;
    final scopes = <(String?, String)>[
      (null, l10n.infoAll),
      ('PUBLIC', l10n.eloHistoryPublicScope),
      if (widget.communityId != null)
        ('COMMUNITY', l10n.eloHistoryCommunityScope),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          for (final s in scopes)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: LavishChipButton(
                label: s.$2,
                selected: _selectedScope == s.$1,
                onPressed: () => setState(() {
                  _selectedScope = s.$1;
                  _limit = _pageSize;
                }),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLogRow(EloHistoryLog log) {
    final l10n = AppLocalizations.of(context)!;
    final c = LavishColors.of(context);
    final date = DateTime.tryParse(log.createdAt) ?? DateTime.now();
    final timeStr = DateFormat('dd/MM/yyyy HH:mm').format(date);
    final match = log.match;
    final result = match?.result?.toUpperCase();
    final resultLabel = result == 'WIN'
        ? l10n.publicProfileResultWin
        : result == 'LOSS'
        ? l10n.publicProfileResultLoss
        : result == 'DRAW'
        ? l10n.publicProfileResultDraw
        : null;
    final resultTone = result == 'WIN'
        ? LavishTone.ok
        : result == 'LOSS'
        ? LavishTone.bad
        : LavishTone.neutral;
    final gain = log.eloDiff >= 0;
    final tone = gain ? LavishTone.ok : LavishTone.bad;
    final diffStr = gain ? '+${log.eloDiff}' : '${log.eloDiff}';
    final title = match?.tournamentName?.isNotEmpty == true
        ? match!.tournamentName!
        : log.reason?.isNotEmpty == true
        ? log.reason!
        : l10n.publicProfileEloChange;
    final details = <String>[
      timeStr,
      if (match?.opponentName?.isNotEmpty == true) match!.opponentName!,
      if (match?.p1SetsWon != null && match?.p2SetsWon != null)
        '${match!.p1SetsWon} - ${match.p2SetsWon}',
    ];

    return LavishRow(
      title: title,
      subtitle: details.join(' · '),
      leading: LavishIconBox(
        tone: tone,
        child: Icon(
          gain ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
          size: 18,
        ),
      ),
      trailing: [
        if (resultLabel != null) LavishPill(resultLabel, tone: resultTone),
        Text(
          diffStr,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: LavishColors.of(context).solid(tone),
          ),
        ),
        Text(
          '${log.newElo}',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: c.muted,
          ),
        ),
      ],
    );
  }
}
