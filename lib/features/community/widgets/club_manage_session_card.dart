import 'package:app_quanly_giaidau/data/models/club_match_session_model.dart';
import 'package:app_quanly_giaidau/data/models/social_session_model.dart';
import 'package:app_quanly_giaidau/features/social/widgets/social_session_card.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Sport icon when the API sends no club `category`.
const _defaultClubSessionSport = 'pickleball';

/// Club session row for the manage screens. Reuses [SocialSessionCard] so it
/// looks like the Social list; only the model mapping and status chip live here.
class ClubManageSessionCard extends StatelessWidget {
  final ClubMatchSessionModel session;
  final VoidCallback onTap;

  const ClubManageSessionCard({
    super.key,
    required this.session,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SocialSessionCard(
      session: toSocialSession(session, l10n),
      onTap: onTap,
      showStatIcons: true,
      badge: _StatusChip(status: session.status),
      caption: _caption(session, l10n),
    );
  }

  /// "15/11 18:05 · 3 trận"; parts without data are dropped.
  static String? _caption(ClubMatchSessionModel s, AppLocalizations l10n) {
    final start = s.startAt?.toLocal();
    final matches = s.matchCount ?? 0;
    final parts = [
      if (start != null)
        '${start.day}/${start.month} '
            '${start.hour.toString().padLeft(2, '0')}:'
            '${start.minute.toString().padLeft(2, '0')}',
      if (matches > 0) l10n.matchesCount(matches),
    ];
    return parts.isEmpty ? null : parts.join(' · ');
  }

  /// Maps a club session onto the Social card model. Venue stays empty so the
  /// card hides the location tag; the play format chip carries the ELO flag.
  static SocialSessionModel toSocialSession(
    ClubMatchSessionModel s,
    AppLocalizations l10n,
  ) => SocialSessionModel(
    id: s.id,
    communityId: s.communityId,
    hostUserId: '',
    title: s.resolvedName,
    playFormat: s.isRanked
        ? l10n.clubMatchSessionRankedShort
        : l10n.clubMatchSessionUnrankedShort,
    startAt: s.startAt ?? DateTime.fromMillisecondsSinceEpoch(0),
    venueName: '',
    venueAddress: '',
    maxSlots: s.maxParticipants,
    currentSlots: s.participantCount ?? 0,
    status: s.status,
    sport: s.sportSlug ?? _defaultClubSessionSport,
    sportName: s.sportName ?? '',
  );
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final muted = Theme.of(context).colorScheme.outline;
    final (label, color) = switch (status) {
      'OPEN' => (l10n.clubMatchSessionStatusOpenShort, const Color(0xFF10B981)),
      'LIVE' => (l10n.clubMatchSessionStatusLiveShort, const Color(0xFFEF4444)),
      'CLOSED' => (
        l10n.clubMatchSessionStatusClosedShort,
        const Color(0xFFF59E0B),
      ),
      'ENDED' => (l10n.clubMatchSessionStatusEndedShort, muted),
      'CANCELLED' => (l10n.clubMatchSessionStatusCancelledShort, muted),
      _ => (l10n.clubMatchSessionStatusUnknown, muted),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
