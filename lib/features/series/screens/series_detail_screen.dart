import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/core/di/core_di_providers.dart';
import 'package:intl/intl.dart';

// ─── Models ───

class SeriesDetail {
  final String id;
  final String name;
  final String slug;
  final String? description;
  final String status;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? bannerUrl;
  final int legCount;
  final int participantCount;
  final List<SeriesLeg> legs;
  final List<SeriesRanking> rankings;

  const SeriesDetail({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    required this.status,
    this.startDate,
    this.endDate,
    this.bannerUrl,
    this.legCount = 0,
    this.participantCount = 0,
    this.legs = const [],
    this.rankings = const [],
  });

  factory SeriesDetail.fromJson(Map<String, dynamic> json) {
    final legsList =
        (json['legs'] ?? json['tournaments'] ?? []) as List<dynamic>?;
    final rankingsList = json['rankings'] as List<dynamic>?;

    return SeriesDetail(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      description: json['description'],
      status: json['status'] ?? 'UPCOMING',
      startDate: json['startDate'] != null
          ? DateTime.tryParse(json['startDate'])?.toLocal()
          : null,
      endDate: json['endDate'] != null
          ? DateTime.tryParse(json['endDate'])?.toLocal()
          : null,
      bannerUrl: json['bannerUrl'],
      legCount:
          json['_count']?['legs'] ?? json['legCount'] ?? legsList?.length ?? 0,
      participantCount:
          json['_count']?['participants'] ?? json['participantCount'] ?? 0,
      legs:
          legsList
              ?.map((j) => SeriesLeg.fromJson(j as Map<String, dynamic>))
              .toList() ??
          [],
      rankings:
          rankingsList
              ?.map((j) => SeriesRanking.fromJson(j as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class SeriesLeg {
  final String id;
  final String name;
  final String? slug;
  final String status;
  final DateTime? startDate;
  final int participantCount;

  const SeriesLeg({
    required this.id,
    required this.name,
    this.slug,
    required this.status,
    this.startDate,
    this.participantCount = 0,
  });

  factory SeriesLeg.fromJson(Map<String, dynamic> json) => SeriesLeg(
    id: json['id'] ?? '',
    name: json['name'] ?? json['title'] ?? '',
    slug: json['slug'],
    status: json['status'] ?? 'UPCOMING',
    startDate: json['startDate'] != null
        ? DateTime.tryParse(json['startDate'])?.toLocal()
        : null,
    participantCount:
        json['_count']?['participants'] ?? json['participantCount'] ?? 0,
  );
}

class SeriesRanking {
  final int position;
  final String participantName;
  final String? avatarUrl;
  final int points;
  final int totalWins;
  final int totalLosses;

  const SeriesRanking({
    required this.position,
    required this.participantName,
    this.avatarUrl,
    this.points = 0,
    this.totalWins = 0,
    this.totalLosses = 0,
  });

  factory SeriesRanking.fromJson(Map<String, dynamic> json) => SeriesRanking(
    position: json['position'] ?? json['rank'] ?? 0,
    participantName:
        json['fullName'] ?? json['name'] ?? json['participantName'] ?? '',
    avatarUrl: json['avatarUrl'] ?? json['avatar'],
    points: json['points'] ?? json['totalPoints'] ?? 0,
    totalWins: json['totalWins'] ?? json['wins'] ?? 0,
    totalLosses: json['totalLosses'] ?? json['losses'] ?? 0,
  );
}

// ─── Provider ───

final _seriesDetailProvider = FutureProvider.family<SeriesDetail?, String>((
  ref,
  slug,
) async {
  final dio = ref.read(dioClientProvider).dio;
  try {
    final response = await dio.get('/series/$slug');
    if (response.statusCode == 200) {
      final data = response.data['data'] ?? response.data;
      return SeriesDetail.fromJson(data as Map<String, dynamic>);
    }
    return null;
  } catch (_) {
    return null;
  }
});

// ─── Screen ───

class SeriesDetailScreen extends ConsumerWidget {
  final String slug;

  const SeriesDetailScreen({super.key, required this.slug});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final detailAsync = ref.watch(_seriesDetailProvider(slug));
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.bgDark,
      body: detailAsync.when(
        data: (detail) {
          if (detail == null) {
            return Scaffold(
              backgroundColor: colors.bgDark,
              appBar: AppBar(
                backgroundColor: colors.bgDark,
                leading: IconButton(
                  icon: Icon(
                    Icons.arrow_back_rounded,
                    color: colors.textPrimary,
                  ),
                  onPressed: () => context.pop(),
                ),
              ),
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.search_off_rounded,
                      size: 64,
                      color: colors.textMuted,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.seriesNotFound,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          return _SeriesDetailContent(detail: detail);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off_rounded, size: 48, color: colors.textMuted),
              const SizedBox(height: 12),
              Text(
                l10n.seriesLoadError,
                style: TextStyle(color: colors.textSecondary),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => ref.refresh(_seriesDetailProvider(slug)),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(l10n.infoRetry),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Content with Tabs ───

class _SeriesDetailContent extends ConsumerStatefulWidget {
  final SeriesDetail detail;

  const _SeriesDetailContent({required this.detail});

  @override
  ConsumerState<_SeriesDetailContent> createState() =>
      _SeriesDetailContentState();
}

class _SeriesDetailContentState extends ConsumerState<_SeriesDetailContent>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final d = widget.detail;
    final tabs = [
      l10n.seriesOverviewTab,
      l10n.seriesScheduleTab,
      l10n.seriesRankingsTab,
    ];
    final isActive = d.status == 'ONGOING' || d.status == 'ACTIVE';

    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) => [
        SliverAppBar(
          backgroundColor: colors.bgDark,
          expandedHeight: 200,
          floating: false,
          pinned: true,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () => context.pop(),
          ),
          flexibleSpace: FlexibleSpaceBar(
            background: _buildHeader(d, colors, isActive, l10n),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: Container(
              color: colors.bgDark,
              child: TabBar(
                controller: _tabController,
                indicatorColor: colors.info,
                indicatorWeight: 3,
                labelColor: colors.info,
                unselectedLabelColor: colors.textMuted,
                labelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
                tabs: tabs.map((t) => Tab(text: t)).toList(),
              ),
            ),
          ),
        ),
      ],
      body: TabBarView(
        controller: _tabController,
        children: [
          _OverviewTab(detail: d),
          _ScheduleTab(detail: d),
          _RankingsTab(detail: d),
        ],
      ),
    );
  }

  Widget _buildHeader(
    SeriesDetail d,
    AppColorsExtension colors,
    bool isActive,
    AppLocalizations l10n,
  ) {
    final statusLabel = isActive
        ? l10n.seriesStatusOngoing
        : (d.status == 'COMPLETED'
              ? l10n.seriesStatusCompleted
              : l10n.seriesStatusUpcoming);
    final statusColor = isActive
        ? colors.error
        : (d.status == 'COMPLETED' ? colors.success : colors.info);
    final fmt = NumberFormat.decimalPattern(
      Localizations.localeOf(context).toLanguageTag(),
    );

    return Stack(
      fit: StackFit.expand,
      children: [
        if (d.bannerUrl != null)
          Image.network(d.bannerUrl!, fit: BoxFit.cover)
        else
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [colors.info.withValues(alpha: 0.3), colors.bgDark],
              ),
            ),
          ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                colors.bgDark.withValues(alpha: 0.9),
              ],
            ),
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: statusColor,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                d.name,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Text(
                l10n.seriesSummary(d.legCount, fmt.format(d.participantCount)),
                style: TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Overview Tab ───

class _OverviewTab extends StatelessWidget {
  final SeriesDetail detail;

  const _OverviewTab({required this.detail});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context)!;
    final d = detail;

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        if (d.description != null && d.description!.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              l10n.tabAbout,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: colors.textPrimary,
              ),
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.bgCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colors.border),
            ),
            child: Text(
              d.description!,
              style: TextStyle(
                fontSize: 14,
                color: colors.textSecondary,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(
            l10n.profileTabInfo,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: colors.textPrimary,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.bgCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colors.border),
          ),
          child: Column(
            children: [
              _infoRow(
                l10n.filterStatus,
                _statusLabel(d.status, l10n),
                _statusColor(d.status),
                colors,
              ),
              const Divider(height: 20),
              _infoRow(l10n.seriesLegCount, '${d.legCount}', null, colors),
              const Divider(height: 20),
              _infoRow(
                l10n.seriesParticipantCount,
                '${d.participantCount}',
                null,
                colors,
              ),
              if (d.startDate != null) ...[
                const Divider(height: 20),
                _infoRow(
                  l10n.seriesStartDate,
                  DateFormat('dd/MM/yyyy').format(d.startDate!),
                  null,
                  colors,
                ),
              ],
              if (d.endDate != null) ...[
                const Divider(height: 20),
                _infoRow(
                  l10n.seriesEndDate,
                  DateFormat('dd/MM/yyyy').format(d.endDate!),
                  null,
                  colors,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  String _statusLabel(String status, AppLocalizations l10n) {
    switch (status) {
      case 'ONGOING':
      case 'ACTIVE':
        return l10n.seriesStatusOngoing;
      case 'COMPLETED':
        return l10n.seriesStatusCompleted;
      default:
        return l10n.seriesStatusUpcoming;
    }
  }

  Color? _statusColor(String status) {
    switch (status) {
      case 'ONGOING':
      case 'ACTIVE':
        return const Color(0xFFEF4444);
      case 'COMPLETED':
        return const Color(0xFF10B981);
      default:
        return const Color(0xFF2979FF);
    }
  }
}

// ─── Schedule Tab ───

class _ScheduleTab extends StatelessWidget {
  final SeriesDetail detail;

  const _ScheduleTab({required this.detail});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;

    if (detail.legs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_note_rounded,
              size: 48,
              color: colors.textMuted.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.series_scheduleEmpty,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: colors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: detail.legs.length,
      itemBuilder: (ctx, i) => _buildLegCard(detail.legs[i], colors, l10n),
    );
  }

  Widget _buildLegCard(
    SeriesLeg leg,
    AppColorsExtension colors,
    AppLocalizations l10n,
  ) {
    final isActive = leg.status == 'ONGOING' || leg.status == 'ACTIVE';
    final statusColor = isActive
        ? colors.error
        : (leg.status == 'COMPLETED' ? colors.success : colors.info);
    final statusLabel = isActive
        ? l10n.series_ongoing
        : (leg.status == 'COMPLETED'
              ? l10n.series_completed
              : l10n.series_upcoming);
    final dateStr = leg.startDate != null
        ? DateFormat('dd/MM/yyyy').format(leg.startDate!)
        : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isActive ? statusColor.withValues(alpha: 0.3) : colors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.emoji_events_rounded,
              color: statusColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  leg.name,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        statusLabel,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: statusColor,
                        ),
                      ),
                    ),
                    if (dateStr.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Text(
                        dateStr,
                        style: TextStyle(fontSize: 11, color: colors.textMuted),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (leg.slug != null)
            Icon(Icons.chevron_right_rounded, color: colors.textMuted),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }
}

// ─── Rankings Tab ───

class _RankingsTab extends StatelessWidget {
  final SeriesDetail detail;

  const _RankingsTab({required this.detail});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;

    if (detail.rankings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.leaderboard_outlined,
              size: 48,
              color: colors.textMuted.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.series_rankingsEmpty,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.series_rankingsUpdateHint,
              style: TextStyle(fontSize: 12, color: colors.textMuted),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: detail.rankings.length,
      itemBuilder: (ctx, i) =>
          _buildRankingRow(detail.rankings[i], i, colors, l10n),
    );
  }

  Widget _buildRankingRow(
    SeriesRanking rank,
    int index,
    AppColorsExtension colors,
    AppLocalizations l10n,
  ) {
    final medalColors = [
      const Color(0xFFFFD700),
      const Color(0xFFC0C0C0),
      const Color(0xFFCD7F32),
    ];
    final isPodium = index < 3;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPodium
              ? medalColors[index].withValues(alpha: 0.3)
              : colors.border,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: isPodium
                ? Icon(
                    Icons.emoji_events_rounded,
                    color: medalColors[index],
                    size: 20,
                  )
                : Text(
                    '${rank.position}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: colors.textMuted,
                    ),
                    textAlign: TextAlign.center,
                  ),
          ),
          const SizedBox(width: 12),
          CircleAvatar(
            radius: 18,
            backgroundColor: colors.bgSurface,
            backgroundImage: rank.avatarUrl != null
                ? NetworkImage(rank.avatarUrl!)
                : null,
            child: rank.avatarUrl == null
                ? Text(
                    rank.participantName.isNotEmpty
                        ? rank.participantName[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: colors.textMuted,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              rank.participantName,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                l10n.series_pointsSummary(rank.points),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: colors.textPrimary,
                ),
              ),
              Text(
                l10n.series_recordSummary(rank.totalWins, rank.totalLosses),
                style: TextStyle(fontSize: 10, color: colors.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Helpers ───

Widget _infoRow(
  String label,
  String value,
  Color? valueColor,
  AppColorsExtension colors,
) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: TextStyle(fontSize: 13, color: colors.textSecondary)),
      Text(
        value,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: valueColor ?? colors.textPrimary,
        ),
      ),
    ],
  );
}
