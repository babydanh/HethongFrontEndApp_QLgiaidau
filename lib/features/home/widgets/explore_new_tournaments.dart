import 'package:app_quanly_giaidau/core/config/app_constants.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/widgets/tournament_avatar.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

// Rules mirror Web `pickNewTournaments` (change kham-pha-giai-moi): the backend
// has no "registration opened at" / "started at" column, so both are derived.
const newTournamentLimit = 6;
const _openedWindow = Duration(days: 7);
const _startedWindow = Duration(hours: 48);

class NewTournaments {
  const NewTournaments({required this.opened, required this.started});

  final List<Tournament> opened;
  final List<Tournament> started;

  bool get isEmpty => opened.isEmpty && started.isEmpty;
}

bool _isFull(Tournament t) => t.capacity?.isFull == true;

/// Scheduled open date when it already passed, else `createdAt` (a tournament
/// created inside the window cannot have opened earlier).
DateTime _openedAt(Tournament t, DateTime now) {
  final scheduled = t.registrationStartDate;
  if (scheduled != null && !scheduled.isAfter(now)) return scheduled;
  return t.createdAt;
}

List<Tournament> _recent(
  Iterable<Tournament> tournaments,
  DateTime? Function(Tournament) timeOf,
  Duration window,
  DateTime now,
) {
  final byId = <String, ({Tournament tournament, DateTime time})>{};
  for (final t in tournaments) {
    final time = timeOf(t);
    if (time == null) continue;
    final age = now.difference(time);
    if (age.isNegative || age > window) continue;
    byId.putIfAbsent(t.id, () => (tournament: t, time: time));
  }
  final sorted = byId.values.toList()
    ..sort((a, b) => b.time.compareTo(a.time));
  return [for (final e in sorted.take(newTournamentLimit)) e.tournament];
}

/// "Just opened registration" (7 days) and "just started" (48 hours), newest
/// first, capped per group.
NewTournaments pickNewTournaments(List<Tournament> tournaments, DateTime now) {
  final open = tournaments.where(
    (t) => t.status == AppConstants.statusRegistration && !_isFull(t),
  );
  final running = tournaments.where(
    (t) => t.status == AppConstants.statusInProgress,
  );
  return NewTournaments(
    opened: _recent(open, (t) => _openedAt(t, now), _openedWindow, now),
    started: _recent(running, (t) => t.startDate, _startedWindow, now),
  );
}

/// Explore block: tournaments that just opened registration or just started.
/// Renders nothing while loading, on error, or when both groups are empty.
class ExploreNewTournaments extends ConsumerWidget {
  const ExploreNewTournaments({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tournaments = ref.watch(tournamentsProvider).asData?.value;
    if (tournaments == null) return const SizedBox.shrink();
    final picked = pickNewTournaments(tournaments, DateTime.now());
    if (picked.isEmpty) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;
    return Column(
      key: const ValueKey('explore_new_tournaments'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Group(title: l10n.exploreNewOpenedTitle, items: picked.opened, live: false),
        _Group(title: l10n.exploreNewStartedTitle, items: picked.started, live: true),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.title, required this.items, required this.live});

  final String title;
  final List<Tournament> items;
  final bool live;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: context.colors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          for (final t in items) _NewTournamentCard(tournament: t, live: live),
        ],
      ),
    );
  }
}

/// Flat card: the whole card opens the tournament, there is no register button.
class _NewTournamentCard extends StatelessWidget {
  const _NewTournamentCard({required this.tournament, required this.live});

  final Tournament tournament;
  final bool live;

  String _meta(AppLocalizations l10n, String locale) {
    final start = tournament.startDate;
    return [
      tournament.category,
      tournament.venueName ?? tournament.city,
      if (!live && start != null) DateFormat('dd/MM', locale).format(start),
    ].where((e) => e != null && e.trim().isNotEmpty).join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final locale = Localizations.localeOf(context).toString();
    final badgeColor = live ? const Color(0xFFE11D48) : const Color(0xFF047857);
    final maxSlots = tournament.capacity?.maxTeamSlots;
    final fee = tournament.entryFee ?? 0;
    final meta = _meta(l10n, locale);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: colors.bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: colors.border.withValues(alpha: 0.6)),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => context.push('/intro/${tournament.id}'),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                TournamentAvatar(
                  imageUrl: tournament.bannerUrl ?? tournament.logoUrl,
                  tournamentName: tournament.name,
                  sport: tournament.sport,
                  size: 56,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        live ? l10n.exploreNewBadgeLive : l10n.exploreNewBadgeOpen,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: badgeColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        tournament.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: colors.textPrimary,
                        ),
                      ),
                      if (meta.isNotEmpty)
                        Text(
                          meta,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.textSecondary,
                          ),
                        ),
                      if (!live && maxSlots != null && maxSlots > 0)
                        _SlotBar(
                          current: tournament.capacity!.occupiedTeamSlots.ceil(),
                          max: maxSlots,
                          label: l10n.exploreNewSlots(
                            tournament.capacity!.occupiedTeamSlots.ceil(),
                            maxSlots,
                          ),
                        ),
                    ],
                  ),
                ),
                if (!live)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Text(
                      fee > 0
                          ? NumberFormat.currency(
                              locale: locale,
                              name: 'VND',
                              decimalDigits: 0,
                            ).format(fee)
                          : l10n.exploreNewFree,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
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

class _SlotBar extends StatelessWidget {
  const _SlotBar({
    required this.current,
    required this.max,
    required this.label,
  });

  final int current;
  final int max;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (current / max).clamp(0.0, 1.0),
                minHeight: 6,
                backgroundColor: colors.border.withValues(alpha: 0.4),
                color: const Color(0xFF10B981),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: colors.textSecondary),
          ),
        ],
      ),
    );
  }
}
